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

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [$clog2(DEPTH):0] fifo_depth, fifo_depth_commit;
    reg overflow_flag, frame_bad, frame_good;
    reg pause_state;

    wire fifo_full, fifo_empty;
    wire [DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE + DEST_ENABLE + USER_ENABLE - 1:0] fifo_wdata, fifo_rdata;
    wire fifo_wen, fifo_ren;

    // FIFO write data preparation
    assign fifo_wdata = {s_axis_tdata, s_axis_tkeep, LAST_ENABLE ? s_axis_tlast : 1'b0, ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}, DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}, USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}};

    // FIFO write enable
    assign fifo_wen = s_axis_tvalid && !fifo_full && (!PAUSE_ENABLE || !pause_state) && (!DROP_WHEN_FULL || !fifo_full) && (!MARK_WHEN_FULL || !fifo_full);

    // FIFO read enable
    assign fifo_ren = m_axis_tready && !fifo_empty && (!PAUSE_ENABLE || !pause_state);

    // AXI-Stream output signals
    assign m_axis_tdata = fifo_rdata[DATA_WIDTH-1:0];
    assign m_axis_tkeep = fifo_rdata[DATA_WIDTH + KEEP_WIDTH - 1:DATA_WIDTH];
    assign m_axis_tlast = LAST_ENABLE ? fifo_rdata[DATA_WIDTH + KEEP_WIDTH] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? fifo_rdata[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_WIDTH - 1:DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? fifo_rdata[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE + DEST_WIDTH - 1:DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? fifo_rdata[DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE + DEST_ENABLE + USER_WIDTH - 1:DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE + DEST_ENABLE] : {USER_WIDTH{1'b0}};
    assign m_axis_tvalid = !fifo_empty && (!PAUSE_ENABLE || !pause_state);

    // AXI-Stream input ready signal
    assign s_axis_tready = !fifo_full && (!PAUSE_ENABLE || !pause_state) && (!DROP_WHEN_FULL || !fifo_full);

    // Pause acknowledge
    assign pause_ack = pause_state;

    // Status signals
    assign status_depth = fifo_depth;
    assign status_depth_commit = fifo_depth_commit;
    assign status_overflow = overflow_flag;
    assign status_bad_frame = frame_bad;
    assign status_good_frame = frame_good;

    // FIFO core
    fifo_core #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE + DEST_ENABLE + USER_ENABLE)
    ) fifo_inst (
        .clk(clk),
        .rst(rst),
        .wdata(fifo_wdata),
        .wen(fifo_wen),
        .rdata(fifo_rdata),
        .ren(fifo_ren),
        .full(fifo_full),
        .empty(fifo_empty),
        .depth(fifo_depth),
        .depth_commit(fifo_depth_commit)
    );

    // Frame handling
    reg frame_start;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_start <= 1'b0;
            frame_last <= 1'b0;
            frame_bad <= 1'b0;
            frame_good <= 1'b0;
            pause_state <= 1'b0;
            overflow_flag <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                if (s_axis_tlast) begin
                    frame_last <= 1'b1;
                end else begin
                    frame_last <= 1'b0;
                end
                if (s_axis_tuser & USER_BAD_FRAME_MASK) begin
                    frame_bad <= 1'b1;
                end
            end

            if (m_axis_tvalid && m_axis_tready && m_axis_tlast) begin
                frame_good <= ~frame_bad;
                frame_bad <= 1'b0;
            end

            if (PAUSE_ENABLE) begin
                if (pause_req && !pause_state) begin
                    pause_state <= 1'b1;
                end else if (!pause_req && pause_state) begin
                    pause_state <= 1'b0;
                end
            end

            if (fifo_wen && fifo_full) begin
                overflow_flag <= 1'b1;
            end else if (fifo_ren && !fifo_empty) begin
                overflow_flag <= 1'b0;
            end
        end
    end

endmodule

module fifo_core #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [DATA_WIDTH-1:0]  wdata,
    input  wire                   wen,
    output wire [DATA_WIDTH-1:0]  rdata,
    input  wire                   ren,
    output wire                   full,
    output wire                   empty,
    output wire [$clog2(DEPTH):0] depth,
    output wire [$clog2(DEPTH):0] depth_commit
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray, wr_ptr_sync, rd_ptr_sync;
    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];

    // Memory write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if (wen && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= wdata;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Memory read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= 0;
        end else if (ren && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Gray code conversion
    assign wr_ptr_gray = (wr_ptr >> 1) ^ wr_ptr;
    assign rd_ptr_gray = (rd_ptr >> 1) ^ rd_ptr;

    // Cross-domain synchronization
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr_sync <= 0;
            rd_ptr_sync <= 0;
        end else begin
            wr_ptr_sync <= wr_ptr_gray;
            rd_ptr_sync <= rd_ptr_gray;
        end
    end

    // Binary conversion
    reg [ADDR_WIDTH:0] wr_ptr_bin, rd_ptr_bin;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr_bin <= 0;
            rd_ptr_bin <= 0;
        end else begin
            wr_ptr_bin <= (wr_ptr_sync[ADDR_WIDTH] ^ wr_ptr_sync[ADDR_WIDTH-1:0]);
            rd_ptr_bin <= (rd_ptr_sync[ADDR_WIDTH] ^ rd_ptr_sync[ADDR_WIDTH-1:0]);
        end
    end

    // Status signals
    assign full = (wr_ptr_bin == {1'b1, rd_ptr_bin[ADDR_WIDTH-1:0]});
    assign empty = (wr_ptr_bin == rd_ptr_bin);
    assign depth = wr_ptr_bin - rd_ptr_bin;
    assign depth_commit = depth;

    // Memory read data
    assign rdata = mem[rd_ptr_bin[ADDR_WIDTH-1:0]];

endmodule
