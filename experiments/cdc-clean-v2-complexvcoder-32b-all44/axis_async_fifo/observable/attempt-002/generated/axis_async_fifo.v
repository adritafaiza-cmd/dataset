module axis_async_fifo #
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
    /*
     * AXI input
     */
    input  wire                   s_clk,
    input  wire                   s_rst,
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
    input  wire                   m_clk,
    input  wire                   m_rst,
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
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] s_status_depth,
    output wire [$clog2(DEPTH):0] s_status_depth_commit,
    output wire                   s_status_overflow,
    output wire                   s_status_bad_frame,
    output wire                   s_status_good_frame,
    output wire [$clog2(DEPTH):0] m_status_depth,
    output wire [$clog2(DEPTH):0] m_status_depth_commit,
    output wire                   m_status_overflow,
    output wire                   m_status_bad_frame,
    output wire                   m_status_good_frame
);

    wire fifo_wfull;
    wire fifo_walmost_full;
    wire [$clog2(DEPTH):0] fifo_wdepth;
    wire [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] fifo_wdata;
    wire fifo_rempty;
    wire [$clog2(DEPTH):0] fifo_rdepth;
    wire [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] fifo_rdata;
    wire fifo_ren;

    // Concatenate all sidebands with tdata into a single word for FIFO
    assign fifo_wdata = {s_axis_tuser, s_axis_tdest, s_axis_tid, s_axis_tlast, s_axis_tkeep, s_axis_tdata};

    // Deconcatenate all sidebands from FIFO output
    assign m_axis_tdata = fifo_rdata[DATA_WIDTH-1:0];
    assign m_axis_tkeep = fifo_rdata[DATA_WIDTH+KEEP_WIDTH-1:DATA_WIDTH];
    assign m_axis_tlast = LAST_ENABLE ? fifo_rdata[DATA_WIDTH+KEEP_WIDTH] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? fifo_rdata[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? fifo_rdata[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? fifo_rdata[DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH] : {USER_WIDTH{1'b0}};

    // FIFO instantiation
    async_fifo #(
        .WIDTH(DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH),
        .DEPTH(DEPTH)
    ) fifo_inst (
        .fifo_wclk(s_clk),
        .fifo_wrst(s_rst),
        .fifo_wdata(fifo_wdata),
        .fifo_wen(s_axis_tvalid && !fifo_wfull),
        .fifo_wfull(fifo_wfull),
        .fifo_walmost_full(fifo_walmost_full),
        .fifo_wdepth(fifo_wdepth),
        .fifo_rclk(m_clk),
        .fifo_rrst(m_rst),
        .fifo_rdata(fifo_rdata),
        .fifo_ren(fifo_ren),
        .fifo_rempty(fifo_rempty),
        .fifo_rdepth(fifo_rdepth)
    );

    // AXI ready signals
    assign s_axis_tready = !fifo_wfull;
    assign fifo_ren = !fifo_rempty && m_axis_tready;
    assign m_axis_tvalid = !fifo_rempty;

    // Status signals
    assign s_status_depth = fifo_wdepth;
    assign s_status_depth_commit = fifo_wdepth;
    assign s_status_overflow = fifo_wfull;
    assign s_status_bad_frame = 1'b0; // Not implemented in this version
    assign s_status_good_frame = 1'b0; // Not implemented in this version
    assign m_status_depth = fifo_rdepth;
    assign m_status_depth_commit = fifo_rdepth;
    assign m_status_overflow = 1'b0; // Not implemented in this version
    assign m_status_bad_frame = 1'b0; // Not implemented in this version
    assign m_status_good_frame = 1'b0; // Not implemented in this version

    // Pause signals (not implemented in this version)
    assign s_pause_ack = 1'b0;
    assign m_pause_ack = 1'b0;

endmodule

module async_fifo #
(
    parameter WIDTH = 8,
    parameter DEPTH = 4096
)
(
    input  wire clk_w,
    input  wire rst_w,
    input  wire [WIDTH-1:0] wdata,
    input  wire wen,
    output wire wfull,
    output wire walmost_full,
    output wire [$clog2(DEPTH):0] wdepth,
    input  wire clk_r,
    input  wire rst_r,
    output wire [WIDTH-1:0] rdata,
    input  wire ren,
    output wire rempty,
    output wire [$clog2(DEPTH):0] rdepth
);

    reg [$clog2(DEPTH):0] wr_ptr, wr_ptr_gray;
    reg [$clog2(DEPTH):0] rd_ptr, rd_ptr_gray;
    reg [$clog2(DEPTH):0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    reg [WIDTH-1:0] mem [DEPTH-1:0];

    // Write pointer logic
    always @(posedge clk_w or posedge rst_w) begin
        if (rst_w) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wen && !wfull) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
        end
    end

    // Read pointer logic
    always @(posedge clk_r or posedge rst_r) begin
        if (rst_r) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (ren && !rempty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
        end
    end

    // Gray code synchronization
    always @(posedge clk_w or posedge rst_w) begin
        if (rst_w) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    always @(posedge clk_r or posedge rst_r) begin
        if (rst_r) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Write full and almost full detection
    wire [$clog2(DEPTH):0] wr_ptr_bin_sync;
    wire [$clog2(DEPTH):0] rd_ptr_bin_sync;
    assign wr_ptr_bin_sync = {wr_ptr_gray_sync[$clog2(DEPTH)], wr_ptr_gray_sync[$clog2(DEPTH)-1:0] ^ wr_ptr_gray_sync[$clog2(DEPTH):1]};
    assign rd_ptr_bin_sync = {rd_ptr_gray_sync[$clog2(DEPTH)], rd_ptr_gray_sync[$clog2(DEPTH)-1:0] ^ rd_ptr_gray_sync[$clog2(DEPTH):1]};

    assign wfull = (wr_ptr_bin_sync == rd_ptr_bin_sync + DEPTH);
    assign walmost_full = (wr_ptr_bin_sync == rd_ptr_bin_sync + DEPTH - 1);

    // Read empty detection
    assign rempty = (wr_ptr_gray_sync == rd_ptr_gray);

    // Write depth
    assign wdepth = wr_ptr_bin_sync - rd_ptr_bin_sync;

    // Read depth
    assign rdepth = wr_ptr_bin_sync - rd_ptr_bin_sync;

    // Memory write
    always @(posedge clk_w) begin
        if (wen && !wfull) begin
            mem[wr_ptr[$clog2(DEPTH)-1:0]] <= wdata;
        end
    end

    // Memory read
    always @(posedge clk_r) begin
        if (ren && !rempty) begin
            rdata <= mem[rd_ptr[$clog2(DEPTH)-1:0]];
        end
    end

endmodule
