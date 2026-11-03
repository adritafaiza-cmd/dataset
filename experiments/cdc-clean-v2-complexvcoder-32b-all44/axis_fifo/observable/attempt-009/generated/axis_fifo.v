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

localparam FIFO_WIDTH = DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH + USER_ENABLE*USER_WIDTH;

reg [FIFO_WIDTH-1:0] fifo_din;
wire [FIFO_WIDTH-1:0] fifo_dout;
reg fifo_wr_en;
reg fifo_rd_en;
reg fifo_full;
reg fifo_empty;
reg [$clog2(DEPTH):0] fifo_depth;
reg [$clog2(DEPTH):0] fifo_depth_commit;

reg frame_valid;
reg frame_error;
reg [$clog2(DEPTH):0] frame_size;
reg [$clog2(DEPTH):0] frame_count;
reg pause_state;
reg s_axis_tready_int;
reg m_axis_tvalid_int;
reg status_overflow_reg;
reg status_bad_frame_reg;
reg status_good_frame_reg;

fifo_core #(
    .DATA_WIDTH(FIFO_WIDTH),
    .DEPTH(DEPTH),
    .RAM_PIPELINE(RAM_PIPELINE)
) fifo_inst (
    .clk(clk),
    .rst(rst),
    .din(fifo_din),
    .wr_en(fifo_wr_en),
    .rd_en(fifo_rd_en),
    .dout(fifo_dout),
    .full(fifo_full),
    .empty(fifo_empty),
    .depth(fifo_depth)
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        fifo_wr_en <= 0;
        fifo_rd_en <= 0;
        frame_valid <= 0;
        frame_error <= 0;
        frame_size <= 0;
        frame_count <= 0;
        pause_state <= 0;
        s_axis_tready_int <= 0;
        m_axis_tvalid_int <= 0;
        status_overflow_reg <= 0;
        status_bad_frame_reg <= 0;
        status_good_frame_reg <= 0;
        fifo_depth_commit <= 0;
    end else begin
        fifo_wr_en <= 0;
        fifo_rd_en <= 0;
        s_axis_tready_int <= 0;
        m_axis_tvalid_int <= 0;

        if (!pause_state || !FRAME_PAUSE) begin
            if (s_axis_tvalid && !fifo_full) begin
                fifo_wr_en <= 1;
                fifo_din <= {s_axis_tuser, s_axis_tdest, s_axis_tid, s_axis_tlast, s_axis_tkeep, s_axis_tdata};
                s_axis_tready_int <= 1;
                if (LAST_ENABLE && s_axis_tlast) begin
                    frame_valid <= 1;
                    frame_size <= frame_count + 1;
                    frame_count <= 0;
                end else begin
                    frame_count <= frame_count + 1;
                end
            end

            if (m_axis_tready && !fifo_empty) begin
                fifo_rd_en <= 1;
                m_axis_tvalid_int <= 1;
                if (LAST_ENABLE && fifo_dout[LAST_ENABLE-1]) begin
                    frame_valid <= 0;
                    if (DROP_BAD_FRAME && frame_error) begin
                        m_axis_tvalid_int <= 0;
                    end else begin
                        status_good_frame_reg <= 1;
                    end
                    frame_error <= 0;
                end
            end
        end

        if (PAUSE_ENABLE && pause_req && !pause_state) begin
            pause_state <= 1;
            pause_ack <= 1;
        end else if (PAUSE_ENABLE && !pause_req && pause_state) begin
            pause_state <= 0;
            pause_ack <= 0;
        end

        if (fifo_full && s_axis_tvalid) begin
            status_overflow_reg <= 1;
            if (DROP_WHEN_FULL) begin
                s_axis_tready_int <= 0;
            end else if (MARK_WHEN_FULL && USER_ENABLE) begin
                fifo_din[USER_WIDTH-1:0] <= fifo_din[USER_WIDTH-1:0] | (USER_BAD_FRAME_VALUE & USER_BAD_FRAME_MASK);
            end
        end else begin
            status_overflow_reg <= 0;
        end

        if (frame_valid && frame_count >= frame_size) begin
            frame_error <= 1;
        end

        if (fifo_wr_en && !fifo_full) begin
            fifo_depth_commit <= fifo_depth_commit + 1;
        end else if (fifo_rd_en && !fifo_empty) begin
            fifo_depth_commit <= fifo_depth_commit - 1;
        end
    end
end

assign s_axis_tready = s_axis_tready_int;
assign m_axis_tvalid = m_axis_tvalid_int;
assign m_axis_tdata = fifo_dout[DATA_WIDTH-1:0];
assign m_axis_tkeep = fifo_dout[DATA_WIDTH+KEEP_WIDTH-1:DATA_WIDTH];
assign m_axis_tlast = LAST_ENABLE ? fifo_dout[LAST_ENABLE-1] : 0;
assign m_axis_tid = ID_ENABLE ? fifo_dout[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE] : 0;
assign m_axis_tdest = DEST_ENABLE ? fifo_dout[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_WIDTH+DEST_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_WIDTH] : 0;
assign m_axis_tuser = USER_ENABLE ? fifo_dout[FIFO_WIDTH-1:FIFO_WIDTH-USER_WIDTH] : 0;
assign status_depth = fifo_depth;
assign status_depth_commit = fifo_depth_commit;
assign status_overflow = status_overflow_reg;
assign status_bad_frame = status_bad_frame_reg;
assign status_good_frame = status_good_frame_reg;

endmodule

module fifo_core #
(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 1024,
    parameter RAM_PIPELINE = 1
)
(
    input  wire         clk,
    input  wire         rst,
    input  wire [DATA_WIDTH-1:0] din,
    input  wire         wr_en,
    input  wire         rd_en,
    output reg [DATA_WIDTH-1:0] dout,
    output reg          full,
    output reg          empty,
    output reg [$clog2(DEPTH):0] depth
);

reg [$clog2(DEPTH):0] wr_ptr;
reg [$clog2(DEPTH):0] rd_ptr;
reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

always @(posedge clk or posedge rst) begin
    if (rst) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        full <= 0;
        empty <= 1;
        depth <= 0;
    end else begin
        if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
            depth <= depth + 1;
            if (wr_ptr == rd_ptr) begin
                full <= 1;
            end
            empty <= 0;
        end

        if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
            depth <= depth - 1;
            if (wr_ptr == rd_ptr) begin
                empty <= 1;
            end
            full <= 0;
        end
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        dout <= 0;
    end else begin
        if (rd_en && !empty) begin
            dout <= mem[rd_ptr];
        end
    end
end

endmodule
