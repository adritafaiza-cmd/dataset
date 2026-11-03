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

    /*
     * Internal signals
     */
    wire [DATA_WIDTH-1:0]         fifo_din;
    wire [DATA_WIDTH-1:0]         fifo_dout;
    wire                          fifo_wr_en;
    wire                          fifo_rd_en;
    wire                          fifo_full;
    wire                          fifo_empty;
    wire [$clog2(DEPTH):0]        fifo_depth;
    wire [$clog2(DEPTH):0]        fifo_depth_commit;

    wire                          s_axis_tready_int;
    wire                          m_axis_tvalid_int;
    wire                          s_axis_tready_cdc;
    wire                          m_axis_tvalid_cdc;

    wire                          s_pause_ack_int;
    wire                          m_pause_ack_int;

    wire                          s_status_depth_int;
    wire                          s_status_depth_commit_int;
    wire                          s_status_overflow_int;
    wire                          s_status_bad_frame_int;
    wire                          s_status_good_frame_int;
    wire                          m_status_depth_int;
    wire                          m_status_depth_commit_int;
    wire                          m_status_overflow_int;
    wire                          m_status_bad_frame_int;
    wire                          m_status_good_frame_int;

    /*
     * CDC instances
     */
    cdc #(.WIDTH(1)) cdc_s_axis_tready (
        .src_clk(s_clk),
        .src_rst(s_rst),
        .src_in(s_axis_tready_int),
        .dst_clk(m_clk),
        .dst_rst(m_rst),
        .dst_out(s_axis_tready_cdc)
    );

    cdc #(.WIDTH(1)) cdc_m_axis_tvalid (
        .src_clk(m_clk),
        .src_rst(m_rst),
        .src_in(m_axis_tvalid_int),
        .dst_clk(s_clk),
        .dst_rst(s_rst),
        .dst_out(m_axis_tvalid_cdc)
    );

    cdc #(.WIDTH(1)) cdc_s_pause_ack (
        .src_clk(s_clk),
        .src_rst(s_rst),
        .src_in(s_pause_ack_int),
        .dst_clk(m_clk),
        .dst_rst(m_rst),
        .dst_out(s_pause_ack)
    );

    cdc #(.WIDTH(1)) cdc_m_pause_ack (
        .src_clk(m_clk),
        .src_rst(m_rst),
        .src_in(m_pause_ack_int),
        .dst_clk(s_clk),
        .dst_rst(s_rst),
        .dst_out(m_pause_ack)
    );

    /*
     * Async FIFO instance
     */
    async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) fifo_inst (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .din(fifo_din),
        .wr_en(fifo_wr_en),
        .full(fifo_full),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .dout(fifo_dout),
        .rd_en(fifo_rd_en),
        .empty(fifo_empty),
        .depth(fifo_depth),
        .depth_commit(fifo_depth_commit)
    );

    /*
     * Frame manager instance
     */
    frame_manager frame_manager_inst (
        .clk(s_clk),
        .rst(s_rst),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tuser(s_axis_tuser),
        .m_axis_tvalid(m_axis_tvalid_cdc),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tuser(m_axis_tuser),
        .s_status_bad_frame(s_status_bad_frame_int),
        .s_status_good_frame(s_status_good_frame_int),
        .m_status_bad_frame(m_status_bad_frame_int),
        .m_status_good_frame(m_status_good_frame_int)
    );

    /*
     * Pause manager instance
     */
    pause_manager pause_manager_inst (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_pause_req(s_pause_req),
        .s_pause_ack(s_pause_ack_int),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_pause_req(m_pause_req),
        .m_pause_ack(m_pause_ack_int)
    );

    /*
     * Status manager instance
     */
    status_manager status_manager_inst (
        .clk(s_clk),
        .rst(s_rst),
        .fifo_full(fifo_full),
        .fifo_depth(fifo_depth),
        .fifo_depth_commit(fifo_depth_commit),
        .s_status_depth(s_status_depth_int),
        .s_status_depth_commit(s_status_depth_commit_int),
        .s_status_overflow(s_status_overflow_int),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_status_depth(m_status_depth_int),
        .m_status_depth_commit(m_status_depth_commit_int),
        .m_status_overflow(m_status_overflow_int)
    );

    /*
     * FIFO data input
     */
    assign fifo_din = s_axis_tdata;

    /*
     * FIFO write enable
     */
    assign fifo_wr_en = s_axis_tvalid & s_axis_tready_int;

    /*
     * FIFO read enable
     */
    assign fifo_rd_en = m_axis_tvalid_cdc & m_axis_tready;

    /*
     * AXI input ready
     */
    assign s_axis_tready_int = ~fifo_full;

    /*
     * AXI output valid
     */
    assign m_axis_tvalid_int = ~fifo_empty;

    /*
     * AXI output data
     */
    assign m_axis_tdata = fifo_dout;
    assign m_axis_tkeep = s_axis_tkeep;
    assign m_axis_tlast = s_axis_tlast;
    assign m_axis_tid = s_axis_tid;
    assign m_axis_tdest = s_axis_tdest;
    assign m_axis_tuser = s_axis_tuser;

    /*
     * Status signals
     */
    assign s_status_depth = s_status_depth_int;
    assign s_status_depth_commit = s_status_depth_commit_int;
    assign s_status_overflow = s_status_overflow_int;
    assign s_status_bad_frame = s_status_bad_frame_int;
    assign s_status_good_frame = s_status_good_frame_int;
    assign m_status_depth = m_status_depth_int;
    assign m_status_depth_commit = m_status_depth_commit_int;
    assign m_status_overflow = m_status_overflow_int;
    assign m_status_bad_frame = m_status_bad_frame_int;
    assign m_status_good_frame = m_status_good_frame_int;

endmodule

module async_fifo #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8
)
(
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [DATA_WIDTH-1:0]  din,
    input  wire                   wr_en,
    output wire                   full,
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [DATA_WIDTH-1:0]  dout,
    input  wire                   rd_en,
    output wire                   empty,
    output wire [$clog2(DEPTH):0] depth,
    output wire [$clog2(DEPTH):0] depth_commit
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;
    reg [ADDR_WIDTH:0] wr_ptr_gray;
    reg [ADDR_WIDTH:0] rd_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync;

    wire [ADDR_WIDTH:0] wr_ptr_bin;
    wire [ADDR_WIDTH:0] rd_ptr_bin;
    wire [ADDR_WIDTH:0] depth_int;
    wire [ADDR_WIDTH:0] depth_commit_int;

    /*
     * Write pointer logic
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en & ~full) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
        end
    end

    /*
     * Read pointer logic
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en & ~empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
        end
    end

    /*
     * Gray code synchronization
     */
    cdc #(.WIDTH(ADDR_WIDTH+1)) cdc_wr_ptr (
        .src_clk(s_clk),
        .src_rst(s_rst),
        .src_in(wr_ptr_gray),
        .dst_clk(m_clk),
        .dst_rst(m_rst),
        .dst_out(wr_ptr_gray_sync)
    );

    cdc #(.WIDTH(ADDR_WIDTH+1)) cdc_rd_ptr (
        .src_clk(m_clk),
        .src_rst(m_rst),
        .src_in(rd_ptr_gray),
        .dst_clk(s_clk),
        .dst_rst(s_rst),
        .dst_out(rd_ptr_gray_sync)
    );

    /*
     * Binary conversion
     */
    assign wr_ptr_bin = wr_ptr_gray_sync ^ (wr_ptr_gray_sync >> 1);
    assign rd_ptr_bin = rd_ptr_gray_sync ^ (rd_ptr_gray_sync >> 1);

    /*
     * FIFO memory
     */
    always @(posedge s_clk) begin
        if (wr_en & ~full) begin
            mem[wr_ptr_bin] <= din;
        end
    end

    assign dout = mem[rd_ptr_bin];

    /*
     * Full and empty flags
     */
    assign full = (wr_ptr_gray == {~rd_ptr_gray_sync[ADDR_WIDTH], rd_ptr_gray_sync[ADDR_WIDTH-1:0]});
    assign empty = (wr_ptr_gray_sync == {~rd_ptr_gray, rd_ptr_gray[ADDR_WIDTH-1:0]});

    /*
     * Depth calculation
     */
    assign depth_int = (wr_ptr_bin >= rd_ptr_bin) ? (wr_ptr_bin - rd_ptr_bin) : (DEPTH - rd_ptr_bin + wr_ptr_bin);
    assign depth_commit_int = (wr_ptr_bin >= rd_ptr_bin) ? (wr_ptr_bin - rd_ptr_bin) : (DEPTH - rd_ptr_bin + wr_ptr_bin);

    assign depth = depth_int;
    assign depth_commit = depth_commit_int;

endmodule

module cdc #
(
    parameter WIDTH = 1
)
(
    input  wire                   src_clk,
    input  wire                   src_rst,
    input  wire [WIDTH-1:0]       src_in,
    input  wire                   dst_clk,
    input  wire                   dst_rst,
    output reg  [WIDTH-1:0]       dst_out
);

    /*
     * Double synchronization stage
     */
    reg [WIDTH-1:0] sync_stage1;

    always @(posedge dst_clk or posedge dst_rst) begin
        if (dst_rst) begin
            sync_stage1 <= 0;
            dst_out <= 0;
        end else begin
            sync_stage1 <= src_in;
            dst_out <= sync_stage1;
        end
    end

endmodule

module frame_manager #
(
    parameter DATA_WIDTH = 8,
    parameter USER_WIDTH = 1
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   s_axis_tvalid,
    input  wire                   s_axis_tlast,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    input  wire                   m_axis_tvalid,
    input  wire                   m_axis_tlast,
    input  wire [USER_WIDTH-1:0]  m_axis_tuser,
    output reg                    s_status_bad_frame,
    output reg                    s_status_good_frame,
    output reg                    m_status_bad_frame,
    output reg                    m_status_good_frame
);

    reg frame_started;
    reg frame_valid;
    reg frame_good;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_started <= 0;
            frame_valid <= 0;
            frame_good <= 1;
            s_status_bad_frame <= 0;
            s_status_good_frame <= 0;
            m_status_bad_frame <= 0;
            m_status_good_frame <= 0;
        end else begin
            if (s_axis_tvalid) begin
                if (!frame_started) begin
                    frame_started <= 1;
                    frame_good <= (s_axis_tuser == USER_BAD_FRAME_VALUE) ? 0 : 1;
                end
                if (s_axis_tlast) begin
                    frame_valid <= 1;
                end
            end

            if (m_axis_tvalid && m_axis_tlast) begin
                m_status_bad_frame <= ~frame_good;
                m_status_good_frame <= frame_good;
                frame_started <= 0;
                frame_valid <= 0;
            end

            if (frame_valid && !frame_started) begin
                s_status_bad_frame <= ~frame_good;
                s_status_good_frame <= frame_good;
                frame_valid <= 0;
            end
        end
    end

endmodule

module pause_manager #
(
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire                   s_pause_req,
    output reg                    s_pause_ack,
    input  wire                   m_clk,
    input  wire                   m_rst,
    input  wire                   m_pause_req,
    output reg                    m_pause_ack
);

    /*
     * Pause request handling
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack <= 0;
        end else begin
            s_pause_ack <= s_pause_req;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack <= 0;
        end else begin
            m_pause_ack <= m_pause_req;
        end
    end

endmodule

module status_manager #
(
    parameter DEPTH = 4096
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   fifo_full,
    input  wire [$clog2(DEPTH):0] fifo_depth,
    input  wire [$clog2(DEPTH):0] fifo_depth_commit,
    output reg  [$clog2(DEPTH):0] s_status_depth,
    output reg  [$clog2(DEPTH):0] s_status_depth_commit,
    output reg                    s_status_overflow,
    input  wire                   m_clk,
    input  wire                   m_rst,
    output reg  [$clog2(DEPTH):0] m_status_depth,
    output reg  [$clog2(DEPTH):0] m_status_depth_commit,
    output reg                    m_status_overflow
);

    /*
     * Status synchronization
     */
    cdc #(.WIDTH($clog2(DEPTH)+1)) cdc_depth (
        .src_clk(clk),
        .src_rst(rst),
        .src_in(fifo_depth),
        .dst_clk(m_clk),
        .dst_rst(m_rst),
        .dst_out(m_status_depth)
    );

    cdc #(.WIDTH($clog2(DEPTH)+1)) cdc_depth_commit (
        .src_clk(clk),
        .src_rst(rst),
        .src_in(fifo_depth_commit),
        .dst_clk(m_clk),
        .dst_rst(m_rst),
        .dst_out(m_status_depth_commit)
    );

    cdc #(.WIDTH(1)) cdc_full (
        .src_clk(clk),
        .src_rst(rst),
        .src_in(fifo_full),
        .dst_clk(m_clk),
        .dst_rst(m_rst),
        .dst_out(m_status_overflow)
    );

    /*
     * Status reporting
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_status_depth <= 0;
            s_status_depth_commit <= 0;
            s_status_overflow <= 0;
        end else begin
            s_status_depth <= fifo_depth;
            s_status_depth_commit <= fifo_depth_commit;
            s_status_overflow <= fifo_full;
        end
    end

endmodule
