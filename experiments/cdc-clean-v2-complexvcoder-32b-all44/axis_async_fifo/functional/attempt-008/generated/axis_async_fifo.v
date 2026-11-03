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
    wire s_wren;
    wire s_rden;
    wire m_wren;
    wire m_rden;
    wire fifo_full;
    wire fifo_empty;
    wire [$clog2(DEPTH):0] fifo_depth;
    wire [$clog2(DEPTH):0] fifo_depth_commit;
    wire fifo_overflow;
    wire fifo_bad_frame;
    wire fifo_good_frame;
    wire [DATA_WIDTH-1:0] fifo_tdata;
    wire [KEEP_WIDTH-1:0] fifo_tkeep;
    wire fifo_tvalid;
    wire fifo_tlast;
    wire [ID_WIDTH-1:0] fifo_tid;
    wire [DEST_WIDTH-1:0] fifo_tdest;
    wire [USER_WIDTH-1:0] fifo_tuser;
    wire s_pause_active;
    wire m_pause_active;

    /*
     * FIFO core instance
     */
    async_fifo_core #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .LAST_ENABLE(LAST_ENABLE),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE),
        .OUTPUT_FIFO_ENABLE(OUTPUT_FIFO_ENABLE),
        .FRAME_FIFO(FRAME_FIFO),
        .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
        .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
        .DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
        .DROP_BAD_FRAME(DROP_BAD_FRAME),
        .DROP_WHEN_FULL(DROP_WHEN_FULL),
        .MARK_WHEN_FULL(MARK_WHEN_FULL)
    ) fifo_core (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tid(s_axis_tid),
        .s_axis_tdest(s_axis_tdest),
        .s_axis_tuser(s_axis_tuser),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tid(m_axis_tid),
        .m_axis_tdest(m_axis_tdest),
        .m_axis_tuser(m_axis_tuser),
        .s_wren(s_wren),
        .s_rden(s_rden),
        .m_wren(m_wren),
        .m_rden(m_rden),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty),
        .fifo_depth(fifo_depth),
        .fifo_depth_commit(fifo_depth_commit),
        .fifo_overflow(fifo_overflow),
        .fifo_bad_frame(fifo_bad_frame),
        .fifo_good_frame(fifo_good_frame),
        .fifo_tdata(fifo_tdata),
        .fifo_tkeep(fifo_tkeep),
        .fifo_tvalid(fifo_tvalid),
        .fifo_tlast(fifo_tlast),
        .fifo_tid(fifo_tid),
        .fifo_tdest(fifo_tdest),
        .fifo_tuser(fifo_tuser)
    );

    /*
     * Source side status instance
     */
    fifo_status #(
        .DEPTH(DEPTH)
    ) s_status (
        .clk(s_clk),
        .rst(s_rst),
        .wren(s_wren),
        .rden(s_rden),
        .full(fifo_full),
        .depth(fifo_depth),
        .depth_commit(fifo_depth_commit),
        .overflow(fifo_overflow),
        .bad_frame(fifo_bad_frame),
        .good_frame(fifo_good_frame),
        .status_depth(s_status_depth),
        .status_depth_commit(s_status_depth_commit),
        .status_overflow(s_status_overflow),
        .status_bad_frame(s_status_bad_frame),
        .status_good_frame(s_status_good_frame)
    );

    /*
     * Master side status instance
     */
    fifo_status #(
        .DEPTH(DEPTH)
    ) m_status (
        .clk(m_clk),
        .rst(m_rst),
        .wren(m_wren),
        .rden(m_rden),
        .full(),
        .depth(fifo_depth),
        .depth_commit(fifo_depth_commit),
        .overflow(),
        .bad_frame(fifo_bad_frame),
        .good_frame(fifo_good_frame),
        .status_depth(m_status_depth),
        .status_depth_commit(m_status_depth_commit),
        .status_overflow(m_status_overflow),
        .status_bad_frame(m_status_bad_frame),
        .status_good_frame(m_status_good_frame)
    );

    /*
     * Pause control instance
     */
    pause_control pause_ctrl (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_pause_req(s_pause_req),
        .s_pause_ack(s_pause_ack),
        .s_pause_active(s_pause_active),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_pause_req(m_pause_req),
        .m_pause_ack(m_pause_ack),
        .m_pause_active(m_pause_active)
    );

    /*
     * Write enable logic
     */
    assign s_wren = s_axis_tvalid & s_axis_tready;

    /*
     * Read enable logic
     */
    assign m_rden = m_axis_tready & m_axis_tvalid;

endmodule

module async_fifo_core #
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
    parameter MARK_WHEN_FULL = 0
)
(
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
    output wire                   s_wren,
    output wire                   s_rden,
    output wire                   m_wren,
    output wire                   m_rden,
    output wire                   fifo_full,
    output wire                   fifo_empty,
    output wire [$clog2(DEPTH):0] fifo_depth,
    output wire [$clog2(DEPTH):0] fifo_depth_commit,
    output wire                   fifo_overflow,
    output wire                   fifo_bad_frame,
    output wire                   fifo_good_frame,
    output wire [DATA_WIDTH-1:0]  fifo_tdata,
    output wire [KEEP_WIDTH-1:0]  fifo_tkeep,
    output wire                   fifo_tvalid,
    output wire                   fifo_tlast,
    output wire [ID_WIDTH-1:0]    fifo_tid,
    output wire [DEST_WIDTH-1:0]  fifo_tdest,
    output wire [USER_WIDTH-1:0]  fifo_tuser
);

    /*
     * Internal signals
     */
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] keep_mem [0:DEPTH-1];
    reg last_mem [0:DEPTH-1];
    reg [ID_WIDTH-1:0] tid_mem [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] tdest_mem [0:DEPTH-1];
    reg [USER_WIDTH-1:0] user_mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr;
    reg [$clog2(DEPTH):0] rd_ptr;
    reg [$clog2(DEPTH):0] wr_ptr_gray;
    reg [$clog2(DEPTH):0] rd_ptr_gray;
    reg [$clog2(DEPTH):0] wr_ptr_gray_sync;
    reg [$clog2(DEPTH):0] rd_ptr_gray_sync;
    reg [$clog2(DEPTH):0] wr_ptr_gray_sync2;
    reg [$clog2(DEPTH):0] rd_ptr_gray_sync2;
    reg [$clog2(DEPTH):0] fifo_depth_reg;
    reg [$clog2(DEPTH):0] fifo_depth_commit_reg;
    reg fifo_full_reg;
    reg fifo_empty_reg;
    reg fifo_overflow_reg;
    reg fifo_bad_frame_reg;
    reg fifo_good_frame_reg;
    reg [DATA_WIDTH-1:0] fifo_tdata_reg;
    reg [KEEP_WIDTH-1:0] fifo_tkeep_reg;
    reg fifo_tvalid_reg;
    reg fifo_tlast_reg;
    reg [ID_WIDTH-1:0] fifo_tid_reg;
    reg [DEST_WIDTH-1:0] fifo_tdest_reg;
    reg [USER_WIDTH-1:0] fifo_tuser_reg;

    /*
     * Gray code conversion
     */
    function [$clog2(DEPTH):0] bin_to_gray;
        input [$clog2(DEPTH):0] bin;
        begin
            bin_to_gray = bin ^ (bin >> 1);
        end
    endfunction

    /*
     * Gray to binary conversion
     */
    function [$clog2(DEPTH):0] gray_to_bin;
        input [$clog2(DEPTH):0] gray;
        integer i;
        reg [$clog2(DEPTH):0] bin;
        begin
            bin = gray;
            for (i = 1; i <= $clog2(DEPTH); i = i << 1) begin
                bin = bin ^ (bin >> i);
            end
            gray_to_bin = bin;
        end
    endfunction

    /*
     * Write pointer logic
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (s_wren) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= bin_to_gray(wr_ptr + 1);
        end
    end

    /*
     * Read pointer logic
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (m_rden) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= bin_to_gray(rd_ptr + 1);
        end
    end

    /*
     * Gray code synchronization
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr_gray_sync <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr_gray_sync <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync;
        end
    end

    /*
     * FIFO depth calculation
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            fifo_depth_reg <= 0;
            fifo_depth_commit_reg <= 0;
        end else begin
            if (s_wren & ~fifo_full_reg) begin
                fifo_depth_reg <= fifo_depth_reg + 1;
            end else if (m_rden & ~fifo_empty_reg) begin
                fifo_depth_reg <= fifo_depth_reg - 1;
            end
            fifo_depth_commit_reg <= fifo_depth_reg;
        end
    end

    /*
     * FIFO full and empty flags
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            fifo_full_reg <= 0;
            fifo_empty_reg <= 1;
        end else begin
            fifo_full_reg <= (wr_ptr_gray_sync2 == {~rd_ptr_gray_sync2[$clog2(DEPTH)], rd_ptr_gray_sync2[$clog2(DEPTH)-1:0]});
            fifo_empty_reg <= (wr_ptr_gray_sync2 == rd_ptr_gray_sync2);
        end
    end

    /*
     * FIFO overflow flag
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            fifo_overflow_reg <= 0;
        end else begin
            fifo_overflow_reg <= fifo_full_reg & s_wren;
        end
    end

    /*
     * FIFO bad frame flag
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            fifo_bad_frame_reg <= 0;
        end else if (s_axis_tvalid & s_axis_tready & (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
            fifo_bad_frame_reg <= 1;
        end else if (m_rden & fifo_tvalid_reg & fifo_tlast_reg) begin
            fifo_bad_frame_reg <= 0;
        end
    end

    /*
     * FIFO good frame flag
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            fifo_good_frame_reg <= 0;
        end else if (s_axis_tvalid & s_axis_tready & (s_axis_tuser & USER_BAD_FRAME_MASK) != USER_BAD_FRAME_VALUE) begin
            fifo_good_frame_reg <= 1;
        end else if (m_rden & fifo_tvalid_reg & fifo_tlast_reg) begin
            fifo_good_frame_reg <= 0;
        end
    end

    /*
     * Write operation
     */
    always @(posedge s_clk) begin
        if (s_wren) begin
            mem[wr_ptr] <= s_axis_tdata;
            if (KEEP_ENABLE) begin
                keep_mem[wr_ptr] <= s_axis_tkeep;
            end
            if (LAST_ENABLE) begin
                last_mem[wr_ptr] <= s_axis_tlast;
            end
            if (ID_ENABLE) begin
                tid_mem[wr_ptr] <= s_axis_tid;
            end
            if (DEST_ENABLE) begin
                tdest_mem[wr_ptr] <= s_axis_tdest;
            end
            if (USER_ENABLE) begin
                user_mem[wr_ptr] <= s_axis_tuser;
            end
        end
    end

    /*
     * Read operation
     */
    always @(posedge m_clk) begin
        if (m_rden) begin
            fifo_tdata_reg <= mem[rd_ptr];
            if (KEEP_ENABLE) begin
                fifo_tkeep_reg <= keep_mem[rd_ptr];
            end
            if (LAST_ENABLE) begin
                fifo_tlast_reg <= last_mem[rd_ptr];
            end
            if (ID_ENABLE) begin
                fifo_tid_reg <= tid_mem[rd_ptr];
            end
            if (DEST_ENABLE) begin
                fifo_tdest_reg <= tdest_mem[rd_ptr];
            end
            if (USER_ENABLE) begin
                fifo_tuser_reg <= user_mem[rd_ptr];
            end
        end
    end

    /*
     * FIFO valid signal
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            fifo_tvalid_reg <= 0;
        end else if (m_rden) begin
            fifo_tvalid_reg <= 1;
        end else if (m_axis_tready) begin
            fifo_tvalid_reg <= 0;
        end
    end

    /*
     * FIFO outputs
     */
    assign fifo_full = fifo_full_reg;
    assign fifo_empty = fifo_empty_reg;
    assign fifo_depth = fifo_depth_reg;
    assign fifo_depth_commit = fifo_depth_commit_reg;
    assign fifo_overflow = fifo_overflow_reg;
    assign fifo_bad_frame = fifo_bad_frame_reg;
    assign fifo_good_frame = fifo_good_frame_reg;
    assign fifo_tdata = fifo_tdata_reg;
    assign fifo_tkeep = fifo_tkeep_reg;
    assign fifo_tvalid = fifo_tvalid_reg;
    assign fifo_tlast = fifo_tlast_reg;
    assign fifo_tid = fifo_tid_reg;
    assign fifo_tdest = fifo_tdest_reg;
    assign fifo_tuser = fifo_tuser_reg;

    /*
     * Handshake signals
     */
    assign s_axis_tready = ~fifo_full_reg;
    assign m_axis_tvalid = fifo_tvalid_reg;
    assign s_wren = s_axis_tvalid & s_axis_tready;
    assign m_rden = m_axis_tready & m_axis_tvalid;

endmodule

module fifo_status #
(
    parameter DEPTH = 4096
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   wren,
    input  wire                   rden,
    input  wire                   full,
    input  wire [$clog2(DEPTH):0] depth,
    input  wire [$clog2(DEPTH):0] depth_commit,
    input  wire                   overflow,
    input  wire                   bad_frame,
    input  wire                   good_frame,
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

    /*
     * Status signals
     */
    reg [$clog2(DEPTH):0] status_depth_reg;
    reg [$clog2(DEPTH):0] status_depth_commit_reg;
    reg status_overflow_reg;
    reg status_bad_frame_reg;
    reg status_good_frame_reg;

    /*
     * Status update logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_depth_reg <= 0;
            status_depth_commit_reg <= 0;
            status_overflow_reg <= 0;
            status_bad_frame_reg <= 0;
            status_good_frame_reg <= 0;
        end else begin
            status_depth_reg <= depth;
            status_depth_commit_reg <= depth_commit;
            status_overflow_reg <= overflow;
            status_bad_frame_reg <= bad_frame;
            status_good_frame_reg <= good_frame;
        end
    end

    /*
     * Status outputs
     */
    assign status_depth = status_depth_reg;
    assign status_depth_commit = status_depth_commit_reg;
    assign status_overflow = status_overflow_reg;
    assign status_bad_frame = status_bad_frame_reg;
    assign status_good_frame = status_good_frame_reg;

endmodule

module pause_control
(
    input  wire s_clk,
    input  wire s_rst,
    input  wire s_pause_req,
    output wire s_pause_ack,
    output wire s_pause_active,
    input  wire m_clk,
    input  wire m_rst,
    input  wire m_pause_req,
    output wire m_pause_ack,
    output wire m_pause_active
);

    /*
     * Internal signals
     */
    reg s_pause_active_reg;
    reg m_pause_active_reg;

    /*
     * Source side pause logic
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_active_reg <= 0;
        end else if (s_pause_req) begin
            s_pause_active_reg <= 1;
        end else if (m_pause_ack) begin
            s_pause_active_reg <= 0;
        end
    end

    assign s_pause_ack = m_pause_req & ~m_pause_active_reg;

    /*
     * Master side pause logic
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_active_reg <= 0;
        end else if (m_pause_req) begin
            m_pause_active_reg <= 1;
        end else if (s_pause_ack) begin
            m_pause_active_reg <= 0;
        end
    end

    assign m_pause_ack = s_pause_req & ~s_pause_active_reg;

    /*
     * Pause active outputs
     */
    assign s_pause_active = s_pause_active_reg;
    assign m_pause_active = m_pause_active_reg;

endmodule
