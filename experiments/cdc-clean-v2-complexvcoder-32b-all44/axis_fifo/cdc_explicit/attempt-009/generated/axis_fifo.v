module axis_fifo #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter LAST_ENABLE = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter RAM_PIPELINE = 1,
    parameter OUTPUT_FIFO_ENABLE = 0,
    parameter FRAME_FIFO = 0,
    parameter USER_BAD_FRAME_VALUE = 1'b1,
    parameter USER_BAD_FRAME_MASK = 1'b1,
    parameter DROP_OVERSIZE_FRAME = FRAME_FIFO,
    parameter DROP_BAD_FRAME = 0,
    parameter DROP_WHEN_FULL = 0,
    parameter MARK_WHEN_FULL = 0,
    parameter PAUSE_ENABLE = 0,
    parameter FRAME_PAUSE = FRAME_FIFO
)
(
    input  wire                   clk,
    input  wire                   rst,
    /*
     * AXI input
     */
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    /*
     * AXI output
     */
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    /*
     * Pause
     */
    input  wire                   pause_req,
    output wire                   pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

    /*
     * Internal signals
     */
    wire                          fifo_wr_en;
    wire                          fifo_rd_en;
    wire                          fifo_full;
    wire                          fifo_empty;
    wire [$clog2(DEPTH):0]        fifo_depth;
    wire [$clog2(DEPTH):0]        fifo_depth_commit;
    wire                          frame_error;
    wire                          frame_good;
    wire                          pause_state;
    wire [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] fifo_data_out;

    /*
     * FIFO core instantiation
     */
    fifo_core #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH)
    ) fifo_inst (
        .clk(clk),
        .rst(rst),
        .wr_en(fifo_wr_en),
        .rd_en(fifo_rd_en),
        .din({s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser}),
        .dout(fifo_data_out),
        .full(fifo_full),
        .empty(fifo_empty),
        .depth(fifo_depth),
        .depth_commit(fifo_depth_commit)
    );

    /*
     * Write enable logic
     */
    assign fifo_wr_en = s_axis_tvalid && s_axis_tready && !fifo_full;

    /*
     * Read enable logic
     */
    assign fifo_rd_en = m_axis_tready && m_axis_tvalid && !fifo_empty;

    /*
     * AXI input handshake
     */
    assign s_axis_tready = !fifo_full;

    /*
     * AXI output handshake
     */
    assign m_axis_tvalid = !fifo_empty;
    assign m_axis_tdata = fifo_data_out[DATA_WIDTH-1:0];
    assign m_axis_tkeep = fifo_data_out[DATA_WIDTH+KEEP_WIDTH-1:DATA_WIDTH];
    assign m_axis_tlast = LAST_ENABLE ? fifo_data_out[DATA_WIDTH+KEEP_WIDTH] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? fifo_data_out[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? fifo_data_out[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_WIDTH+DEST_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_WIDTH] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? fifo_data_out[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_WIDTH+DEST_WIDTH] : {USER_WIDTH{1'b0}};

    /*
     * Pause handling
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_state <= 1'b0;
        end else if (PAUSE_ENABLE && pause_req) begin
            pause_state <= 1'b1;
        end else if (m_axis_tready && m_axis_tvalid) begin
            pause_state <= 1'b0;
        end
    end

    assign pause_ack = pause_state;

    /*
     * Frame error detection
     */
    reg frame_started;
    reg frame_last_received;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_started <= 1'b0;
            frame_last_received <= 1'b0;
        end else begin
            if (fifo_wr_en && s_axis_tlast) begin
                frame_last_received <= 1'b1;
            end else if (fifo_wr_en) begin
                frame_started <= 1'b1;
            end else if (fifo_rd_en && fifo_data_out[DATA_WIDTH+KEEP_WIDTH]) begin
                frame_last_received <= 1'b0;
                if (!frame_started) begin
                    frame_error <= 1'b1;
                end else begin
                    frame_good <= 1'b1;
                end
                frame_started <= 1'b0;
            end
        end
    end

    assign frame_error = (USER_ENABLE && (fifo_data_out[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_WIDTH+DEST_WIDTH] & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) ? 1'b1 : frame_error;
    assign frame_good = frame_last_received ? 1'b1 : frame_good;

    /*
     * Status signals
     */
    assign status_depth = fifo_depth;
    assign status_depth_commit = fifo_depth_commit;
    assign status_overflow = fifo_full;
    assign status_bad_frame = frame_error;
    assign status_good_frame = frame_good;

endmodule

module fifo_core #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   wr_en,
    input  wire                   rd_en,
    input  wire [DATA_WIDTH-1:0]  din,
    output wire [DATA_WIDTH-1:0]  dout,
    output wire                   full,
    output wire                   empty,
    output wire [$clog2(DEPTH):0] depth,
    output wire [$clog2(DEPTH):0] depth_commit
);

    /*
     * Internal signals
     */
    reg [$clog2(DEPTH):0]         wr_ptr;
    reg [$clog2(DEPTH):0]         rd_ptr;
    reg [$clog2(DEPTH):0]         depth_reg;
    reg [DATA_WIDTH-1:0]          mem [DEPTH-1:0];

    /*
     * Write pointer logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    /*
     * Read pointer logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    /*
     * Depth calculation
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            depth_reg <= 0;
        end else begin
            if (wr_en && !rd_en && !full) begin
                depth_reg <= depth_reg + 1;
            end else if (!wr_en && rd_en && !empty) begin
                depth_reg <= depth_reg - 1;
            end
        end
    end

    assign depth = depth_reg;
    assign depth_commit = depth_reg;

    /*
     * Memory write
     */
    always @(posedge clk) begin
        if (wr_en && !full) begin
            mem[wr_ptr % DEPTH] <= din;
        end
    end

    /*
     * Memory read
     */
    assign dout = mem[rd_ptr % DEPTH];

    /*
     * Full and empty flags
     */
    assign full = (wr_ptr == rd_ptr + DEPTH);
    assign empty = (wr_ptr == rd_ptr);

endmodule
