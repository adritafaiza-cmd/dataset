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

    wire [DATA_WIDTH-1:0] fifo_core_m_axis_tdata;
    wire [KEEP_WIDTH-1:0] fifo_core_m_axis_tkeep;
    wire                  fifo_core_m_axis_tvalid;
    wire                  fifo_core_m_axis_tready;
    wire                  fifo_core_m_axis_tlast;
    wire [ID_WIDTH-1:0]   fifo_core_m_axis_tid;
    wire [DEST_WIDTH-1:0] fifo_core_m_axis_tdest;
    wire [USER_WIDTH-1:0] fifo_core_m_axis_tuser;
    wire [$clog2(DEPTH):0] fifo_core_s_status_depth;
    wire [$clog2(DEPTH):0] fifo_core_s_status_depth_commit;
    wire                  fifo_core_s_status_overflow;
    wire                  fifo_core_s_status_bad_frame;
    wire                  fifo_core_s_status_good_frame;
    wire [$clog2(DEPTH):0] fifo_core_m_status_depth;
    wire [$clog2(DEPTH):0] fifo_core_m_status_depth_commit;
    wire                  fifo_core_m_status_overflow;
    wire                  fifo_core_m_status_bad_frame;
    wire                  fifo_core_m_status_good_frame;

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
        .MARK_WHEN_FULL(MARK_WHEN_FULL),
        .PAUSE_ENABLE(PAUSE_ENABLE),
        .FRAME_PAUSE(FRAME_PAUSE)
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
        .m_axis_tdata(fifo_core_m_axis_tdata),
        .m_axis_tkeep(fifo_core_m_axis_tkeep),
        .m_axis_tvalid(fifo_core_m_axis_tvalid),
        .m_axis_tready(fifo_core_m_axis_tready),
        .m_axis_tlast(fifo_core_m_axis_tlast),
        .m_axis_tid(fifo_core_m_axis_tid),
        .m_axis_tdest(fifo_core_m_axis_tdest),
        .m_axis_tuser(fifo_core_m_axis_tuser),
        .s_status_depth(fifo_core_s_status_depth),
        .s_status_depth_commit(fifo_core_s_status_depth_commit),
        .s_status_overflow(fifo_core_s_status_overflow),
        .s_status_bad_frame(fifo_core_s_status_bad_frame),
        .s_status_good_frame(fifo_core_s_status_good_frame),
        .m_status_depth(fifo_core_m_status_depth),
        .m_status_depth_commit(fifo_core_m_status_depth_commit),
        .m_status_overflow(fifo_core_m_status_overflow),
        .m_status_bad_frame(fifo_core_m_status_bad_frame),
        .m_status_good_frame(fifo_core_m_status_good_frame)
    );

    status_logic s_status_logic (
        .clk(s_clk),
        .rst(s_rst),
        .fifo_depth(fifo_core_s_status_depth),
        .fifo_depth_commit(fifo_core_s_status_depth_commit),
        .fifo_overflow(fifo_core_s_status_overflow),
        .fifo_bad_frame(fifo_core_s_status_bad_frame),
        .fifo_good_frame(fifo_core_s_status_good_frame),
        .status_depth(s_status_depth),
        .status_depth_commit(s_status_depth_commit),
        .status_overflow(s_status_overflow),
        .status_bad_frame(s_status_bad_frame),
        .status_good_frame(s_status_good_frame)
    );

    status_logic m_status_logic (
        .clk(m_clk),
        .rst(m_rst),
        .fifo_depth(fifo_core_m_status_depth),
        .fifo_depth_commit(fifo_core_m_status_depth_commit),
        .fifo_overflow(fifo_core_m_status_overflow),
        .fifo_bad_frame(fifo_core_m_status_bad_frame),
        .fifo_good_frame(fifo_core_m_status_good_frame),
        .status_depth(m_status_depth),
        .status_depth_commit(m_status_depth_commit),
        .status_overflow(m_status_overflow),
        .status_bad_frame(m_status_bad_frame),
        .status_good_frame(m_status_good_frame)
    );

    pause_logic s_pause_logic (
        .clk(s_clk),
        .rst(s_rst),
        .pause_req(s_pause_req),
        .pause_ack(s_pause_ack)
    );

    pause_logic m_pause_logic (
        .clk(m_clk),
        .rst(m_rst),
        .pause_req(m_pause_req),
        .pause_ack(m_pause_ack)
    );

    assign m_axis_tdata = fifo_core_m_axis_tdata;
    assign m_axis_tkeep = fifo_core_m_axis_tkeep;
    assign m_axis_tvalid = fifo_core_m_axis_tvalid;
    assign fifo_core_m_axis_tready = m_axis_tready;
    assign m_axis_tlast = fifo_core_m_axis_tlast;
    assign m_axis_tid = fifo_core_m_axis_tid;
    assign m_axis_tdest = fifo_core_m_axis_tdest;
    assign m_axis_tuser = fifo_core_m_axis_tuser;

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
    parameter MARK_WHEN_FULL = 0,
    parameter PAUSE_ENABLE = 0,
    parameter FRAME_PAUSE = FRAME_FIFO
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

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH:0] wptr_gray, rptr_gray, wptr_bin, rptr_bin;
    reg [ADDR_WIDTH:0] wptr_gray_nxt, rptr_gray_nxt;
    reg [ADDR_WIDTH:0] wptr_bin_nxt, rptr_bin_nxt;

    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] mem_tkeep [DEPTH-1:0];
    reg [ID_WIDTH-1:0] mem_tid [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_tdest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_tuser [DEPTH-1:0];
    reg mem_tlast [DEPTH-1:0];

    reg s_axis_tready_reg;
    reg m_axis_tvalid_reg;
    reg m_axis_tlast_reg;
    reg [DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg [ID_WIDTH-1:0] m_axis_tid_reg;
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;

    reg [ADDR_WIDTH:0] s_status_depth_reg;
    reg [ADDR_WIDTH:0] s_status_depth_commit_reg;
    reg s_status_overflow_reg;
    reg s_status_bad_frame_reg;
    reg s_status_good_frame_reg;

    reg [ADDR_WIDTH:0] m_status_depth_reg;
    reg [ADDR_WIDTH:0] m_status_depth_commit_reg;
    reg m_status_overflow_reg;
    reg m_status_bad_frame_reg;
    reg m_status_good_frame_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wptr_gray <= 0;
            wptr_bin <= 0;
            s_axis_tready_reg <= 0;
            s_status_depth_reg <= 0;
            s_status_depth_commit_reg <= 0;
            s_status_overflow_reg <= 0;
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
        end else begin
            wptr_gray <= wptr_gray_nxt;
            wptr_bin <= wptr_bin_nxt;
            s_axis_tready_reg <= (wptr_gray_nxt != rptr_gray);
            s_status_depth_reg <= wptr_bin_nxt - rptr_bin;
            s_status_depth_commit_reg <= s_status_depth_reg;
            s_status_overflow_reg <= (wptr_gray_nxt == {~rptr_gray[ADDR_WIDTH], rptr_gray[ADDR_WIDTH-1:0]});
            s_status_bad_frame_reg <= 0; // Placeholder for bad frame detection
            s_status_good_frame_reg <= 0; // Placeholder for good frame detection
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rptr_gray <= 0;
            rptr_bin <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_status_depth_reg <= 0;
            m_status_depth_commit_reg <= 0;
            m_status_overflow_reg <= 0;
            m_status_bad_frame_reg <= 0;
            m_status_good_frame_reg <= 0;
        end else begin
            rptr_gray <= rptr_gray_nxt;
            rptr_bin <= rptr_bin_nxt;
            m_axis_tvalid_reg <= (wptr_gray != rptr_gray_nxt);
            m_axis_tlast_reg <= mem_tlast[rptr_bin];
            m_axis_tdata_reg <= mem[rptr_bin];
            m_axis_tkeep_reg <= mem_tkeep[rptr_bin];
            m_axis_tid_reg <= mem_tid[rptr_bin];
            m_axis_tdest_reg <= mem_tdest[rptr_bin];
            m_axis_tuser_reg <= mem_tuser[rptr_bin];
            m_status_depth_reg <= wptr_bin - rptr_bin_nxt;
            m_status_depth_commit_reg <= m_status_depth_reg;
            m_status_overflow_reg <= 0; // Placeholder for overflow detection
            m_status_bad_frame_reg <= 0; // Placeholder for bad frame detection
            m_status_good_frame_reg <= 0; // Placeholder for good frame detection
        end
    end

    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

    assign wptr_gray_nxt = s_axis_tvalid & s_axis_tready_reg ? (wptr_gray + 1) : wptr_gray;
    assign rptr_gray_nxt = m_axis_tvalid_reg & m_axis_tready ? (rptr_gray + 1) : rptr_gray;

    assign wptr_bin_nxt = gray_to_bin(wptr_gray_nxt);
    assign rptr_bin_nxt = gray_to_bin(rptr_gray_nxt);

    function [ADDR_WIDTH:0] gray_to_bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        begin
            bin = gray[ADDR_WIDTH];
            for (i = ADDR_WIDTH - 1; i >= 0; i = i - 1) begin
                bin[i] = bin[i+1] ^ gray[i];
            end
            gray_to_bin = bin;
        end
    endfunction

    always @(posedge s_clk) begin
        if (s_axis_tvalid & s_axis_tready_reg) begin
            mem[wptr_bin] <= s_axis_tdata;
            mem_tkeep[wptr_bin] <= s_axis_tkeep;
            mem_tlast[wptr_bin] <= s_axis_tlast;
            mem_tid[wptr_bin] <= s_axis_tid;
            mem_tdest[wptr_bin] <= s_axis_tdest;
            mem_tuser[wptr_bin] <= s_axis_tuser;
        end
    end

    assign s_status_depth = s_status_depth_reg;
    assign s_status_depth_commit = s_status_depth_commit_reg;
    assign s_status_overflow = s_status_overflow_reg;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;

    assign m_status_depth = m_status_depth_reg;
    assign m_status_depth_commit = m_status_depth_commit_reg;
    assign m_status_overflow = m_status_overflow_reg;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

endmodule

module status_logic (
    input  wire                   clk,
    input  wire                   rst,
    input  wire [$clog2(DEPTH):0] fifo_depth,
    input  wire [$clog2(DEPTH):0] fifo_depth_commit,
    input  wire                   fifo_overflow,
    input  wire                   fifo_bad_frame,
    input  wire                   fifo_good_frame,
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

    reg [$clog2(DEPTH):0] status_depth_reg;
    reg [$clog2(DEPTH):0] status_depth_commit_reg;
    reg status_overflow_reg;
    reg status_bad_frame_reg;
    reg status_good_frame_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_depth_reg <= 0;
            status_depth_commit_reg <= 0;
            status_overflow_reg <= 0;
            status_bad_frame_reg <= 0;
            status_good_frame_reg <= 0;
        end else begin
            status_depth_reg <= fifo_depth;
            status_depth_commit_reg <= fifo_depth_commit;
            status_overflow_reg <= fifo_overflow;
            status_bad_frame_reg <= fifo_bad_frame;
            status_good_frame_reg <= fifo_good_frame;
        end
    end

    assign status_depth = status_depth_reg;
    assign status_depth_commit = status_depth_commit_reg;
    assign status_overflow = status_overflow_reg;
    assign status_bad_frame = status_bad_frame_reg;
    assign status_good_frame = status_good_frame_reg;

endmodule

module pause_logic (
    input  wire clk,
    input  wire rst,
    input  wire pause_req,
    output wire pause_ack
);

    reg pause_ack_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_ack_reg <= 0;
        end else begin
            pause_ack_reg <= pause_req;
        end
    end

    assign pause_ack = pause_ack_reg;

endmodule
