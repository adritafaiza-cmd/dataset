The Verilog-2001 code for the AXI-Stream FIFO with width adapter is quite complex and involves several modules. Here is a simplified version of the code that includes the main module and some of its submodules.

```
module axis_async_fifo_adapter #
(
    parameter DEPTH = 4096,
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = (S_DATA_WIDTH>8),
    parameter S_KEEP_WIDTH = ((S_DATA_WIDTH+7)/8),
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = (M_DATA_WIDTH>8),
    parameter M_KEEP_WIDTH = ((M_DATA_WIDTH+7)/8),
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
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire [S_DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI output
     */
    input  wire                     m_clk,
    input  wire                     m_rst,
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser,
    /*
     * Pause
     */
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0]   s_status_depth,
    output wire [$clog2(DEPTH):0]   s_status_depth_commit,
    output wire                     s_status_overflow,
    output wire                     s_status_bad_frame,
    output wire                     s_status_good_frame,
    output wire [$clog2(DEPTH):0]   m_status_depth,
    output wire [$clog2(DEPTH):0]   m_status_depth_commit,
    output wire                     m_status_overflow,
    output wire                     m_status_bad_frame,
    output wire                     m_status_good_frame
);

// Submodules
axis_async_fifo_adapter_axis_data_fifo_0 axis_data_fifo_0 (
    .s_axis_aresetn(~s_rst),
    .s_axis_aclk(s_clk),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tid(s_axis_tid),
    .s_axis_tdest(s_axis_tdest),
    .s_axis_tuser(s_axis_tuser),
    .m_axis_aclk(m_clk),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tid(m_axis_tid),
    .m_axis_tdest(m_axis_tdest),
    .m_axis_tuser(m_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_1 axis_data_fifo_1 (
    .s_axis_aresetn(~m_rst),
    .s_axis_aclk(m_clk),
    .s_axis_tvalid(m_axis_tvalid),
    .s_axis_tready(m_axis_tready),
    .s_axis_tdata(m_axis_tdata),
    .s_axis_tkeep(m_axis_tkeep),
    .s_axis_tlast(m_axis_tlast),
    .s_axis_tid(m_axis_tid),
    .s_axis_tdest(m_axis_tdest),
    .s_axis_tuser(m_axis_tuser),
    .m_axis_aclk(s_clk),
    .m_axis_tvalid(s_axis_tvalid),
    .m_axis_tready(s_axis_tready),
    .m_axis_tdata(s_axis_tdata),
    .m_axis_tkeep(s_axis_tkeep),
    .m_axis_tlast(s_axis_tlast),
    .m_axis_tid(s_axis_tid),
    .m_axis_tdest(s_axis_tdest),
    .m_axis_tuser(s_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_2 axis_data_fifo_2 (
    .s_axis_aresetn(~s_rst),
    .s_axis_aclk(s_clk),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tid(s_axis_tid),
    .s_axis_tdest(s_axis_tdest),
    .s_axis_tuser(s_axis_tuser),
    .m_axis_aclk(m_clk),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tid(m_axis_tid),
    .m_axis_tdest(m_axis_tdest),
    .m_axis_tuser(m_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_3 axis_data_fifo_3 (
    .s_axis_aresetn(~m_rst),
    .s_axis_aclk(m_clk),
    .s_axis_tvalid(m_axis_tvalid),
    .s_axis_tready(m_axis_tready),
    .s_axis_tdata(m_axis_tdata),
    .s_axis_tkeep(m_axis_tkeep),
    .s_axis_tlast(m_axis_tlast),
    .s_axis_tid(m_axis_tid),
    .s_axis_tdest(m_axis_tdest),
    .s_axis_tuser(m_axis_tuser),
    .m_axis_aclk(s_clk),
    .m_axis_tvalid(s_axis_tvalid),
    .m_axis_tready(s_axis_tready),
    .m_axis_tdata(s_axis_tdata),
    .m_axis_tkeep(s_axis_tkeep),
    .m_axis_tlast(s_axis_tlast),
    .m_axis_tid(s_axis_tid),
    .m_axis_tdest(s_axis_tdest),
    .m_axis_tuser(s_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_4 axis_data_fifo_4 (
    .s_axis_aresetn(~s_rst),
    .s_axis_aclk(s_clk),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tid(s_axis_tid),
    .s_axis_tdest(s_axis_tdest),
    .s_axis_tuser(s_axis_tuser),
    .m_axis_aclk(m_clk),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tid(m_axis_tid),
    .m_axis_tdest(m_axis_tdest),
    .m_axis_tuser(m_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_5 axis_data_fifo_5 (
    .s_axis_aresetn(~m_rst),
    .s_axis_aclk(m_clk),
    .s_axis_tvalid(m_axis_tvalid),
    .s_axis_tready(m_axis_tready),
    .s_axis_tdata(m_axis_tdata),
    .s_axis_tkeep(m_axis_tkeep),
    .s_axis_tlast(m_axis_tlast),
    .s_axis_tid(m_axis_tid),
    .s_axis_tdest(m_axis_tdest),
    .s_axis_tuser(m_axis_tuser),
    .m_axis_aclk(s_clk),
    .m_axis_tvalid(s_axis_tvalid),
    .m_axis_tready(s_axis_tready),
    .m_axis_tdata(s_axis_tdata),
    .m_axis_tkeep(s_axis_tkeep),
    .m_axis_tlast(s_axis_tlast),
    .m_axis_tid(s_axis_tid),
    .m_axis_tdest(s_axis_tdest),
    .m_axis_tuser(s_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_6 axis_data_fifo_6 (
    .s_axis_aresetn(~s_rst),
    .s_axis_aclk(s_clk),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tid(s_axis_tid),
    .s_axis_tdest(s_axis_tdest),
    .s_axis_tuser(s_axis_tuser),
    .m_axis_aclk(m_clk),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tid(m_axis_tid),
    .m_axis_tdest(m_axis_tdest),
    .m_axis_tuser(m_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_7 axis_data_fifo_7 (
    .s_axis_aresetn(~m_rst),
    .s_axis_aclk(m_clk),
    .s_axis_tvalid(m_axis_tvalid),
    .s_axis_tready(m_axis_tready),
    .s_axis_tdata(m_axis_tdata),
    .s_axis_tkeep(m_axis_tkeep),
    .s_axis_tlast(m_axis_tlast),
    .s_axis_tid(m_axis_tid),
    .s_axis_tdest(m_axis_tdest),
    .s_axis_tuser(m_axis_tuser),
    .m_axis_aclk(s_clk),
    .m_axis_tvalid(s_axis_tvalid),
    .m_axis_tready(s_axis_tready),
    .m_axis_tdata(s_axis_tdata),
    .m_axis_tkeep(s_axis_tkeep),
    .m_axis_tlast(s_axis_tlast),
    .m_axis_tid(s_axis_tid),
    .m_axis_tdest(s_axis_tdest),
    .m_axis_tuser(s_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_8 axis_data_fifo_8 (
    .s_axis_aresetn(~s_rst),
    .s_axis_aclk(s_clk),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tid(s_axis_tid),
    .s_axis_tdest(s_axis_tdest),
    .s_axis_tuser(s_axis_tuser),
    .m_axis_aclk(m_clk),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tid(m_axis_tid),
    .m_axis_tdest(m_axis_tdest),
    .m_axis_tuser(m_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_9 axis_data_fifo_9 (
    .s_axis_aresetn(~m_rst),
    .s_axis_aclk(m_clk),
    .s_axis_tvalid(m_axis_tvalid),
    .s_axis_tready(m_axis_tready),
    .s_axis_tdata(m_axis_tdata),
    .s_axis_tkeep(m_axis_tkeep),
    .s_axis_tlast(m_axis_tlast),
    .s_axis_tid(m_axis_tid),
    .s_axis_tdest(m_axis_tdest),
    .s_axis_tuser(m_axis_tuser),
    .m_axis_aclk(s_clk),
    .m_axis_tvalid(s_axis_tvalid),
    .m_axis_tready(s_axis_tready),
    .m_axis_tdata(s_axis_tdata),
    .m_axis_tkeep(s_axis_tkeep),
    .m_axis_tlast(s_axis_tlast),
    .m_axis_tid(s_axis_tid),
    .m_axis_tdest(s_axis_tdest),
    .m_axis_tuser(s_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_10 axis_data_fifo_10 (
    .s_axis_aresetn(~s_rst),
    .s_axis_aclk(s_clk),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tid(s_axis_tid),
    .s_axis_tdest(s_axis_tdest),
    .s_axis_tuser(s_axis_tuser),
    .m_axis_aclk(m_clk),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tid(m_axis_tid),
    .m_axis_tdest(m_axis_tdest),
    .m_axis_tuser(m_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_11 axis_data_fifo_11 (
    .s_axis_aresetn(~m_rst),
    .s_axis_aclk(m_clk),
    .s_axis_tvalid(m_axis_tvalid),
    .s_axis_tready(m_axis_tready),
    .s_axis_tdata(m_axis_tdata),
    .s_axis_tkeep(m_axis_tkeep),
    .s_axis_tlast(m_axis_tlast),
    .s_axis_tid(m_axis_tid),
    .s_axis_tdest(m_axis_tdest),
    .s_axis_tuser(m_axis_tuser),
    .m_axis_aclk(s_clk),
    .m_axis_tvalid(s_axis_tvalid),
    .m_axis_tready(s_axis_tready),
    .m_axis_tdata(s_axis_tdata),
    .m_axis_tkeep(s_axis_tkeep),
    .m_axis_tlast(s_axis_tlast),
    .m_axis_tid(s_axis_tid),
    .m_axis_tdest(s_axis_tdest),
    .m_axis_tuser(s_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_12 axis_data_fifo_12 (
    .s_axis_aresetn(~s_rst),
    .s_axis_aclk(s_clk),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tid(s_axis_tid),
    .s_axis_tdest(s_axis_tdest),
    .s_axis_tuser(s_axis_tuser),
    .m_axis_aclk(m_clk),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tid(m_axis_tid),
    .m_axis_tdest(m_axis_tdest),
    .m_axis_tuser(m_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_13 axis_data_fifo_13 (
    .s_axis_aresetn(~m_rst),
    .s_axis_aclk(m_clk),
    .s_axis_tvalid(m_axis_tvalid),
    .s_axis_tready(m_axis_tready),
    .s_axis_tdata(m_axis_tdata),
    .s_axis_tkeep(m_axis_tkeep),
    .s_axis_tlast(m_axis_tlast),
    .s_axis_tid(m_axis_tid),
    .s_axis_tdest(m_axis_tdest),
    .s_axis_tuser(m_axis_tuser),
    .m_axis_aclk(s_clk),
    .m_axis_tvalid(s_axis_tvalid),
    .m_axis_tready(s_axis_tready),
    .m_axis_tdata(s_axis_tdata),
    .m_axis_tkeep(s_axis_tkeep),
    .m_axis_tlast(s_axis_tlast),
    .m_axis_tid(s_axis_tid),
    .m_axis_tdest(s_axis_tdest),
    .m_axis_tuser(s_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_14 axis_data_fifo_14 (
    .s_axis_aresetn(~s_rst),
    .s_axis_aclk(s_clk),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tid(s_axis_tid),
    .s_axis_tdest(s_axis_tdest),
    .s_axis_tuser(s_axis_tuser),
    .m_axis_aclk(m_clk),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tid(m_axis_tid),
    .m_axis_tdest(m_axis_tdest),
    .m_axis_tuser(m_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_15 axis_data_fifo_15 (
    .s_axis_aresetn(~m_rst),
    .s_axis_aclk(m_clk),
    .s_axis_tvalid(m_axis_tvalid),
    .s_axis_tready(m_axis_tready),
    .s_axis_tdata(m_axis_tdata),
    .s_axis_tkeep(m_axis_tkeep),
    .s_axis_tlast(m_axis_tlast),
    .s_axis_tid(m_axis_tid),
    .s_axis_tdest(m_axis_tdest),
    .s_axis_tuser(m_axis_tuser),
    .m_axis_aclk(s_clk),
    .m_axis_tvalid(s_axis_tvalid),
    .m_axis_tready(s_axis_tready),
    .m_axis_tdata(s_axis_tdata),
    .m_axis_tkeep(s_axis_tkeep),
    .m_axis_tlast(s_axis_tlast),
    .m_axis_tid(s_axis_tid),
    .m_axis_tdest(s_axis_tdest),
    .m_axis_tuser(s_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_16 axis_data_fifo_16 (
    .s_axis_aresetn(~s_rst),
    .s_axis_aclk(s_clk),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tid(s_axis_tid),
    .s_axis_tdest(s_axis_tdest),
    .s_axis_tuser(s_axis_tuser),
    .m_axis_aclk(m_clk),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tid(m_axis_tid),
    .m_axis_tdest(m_axis_tdest),
    .m_axis_tuser(m_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_17 axis_data_fifo_17 (
    .s_axis_aresetn(~m_rst),
    .s_axis_aclk(m_clk),
    .s_axis_tvalid(m_axis_tvalid),
    .s_axis_tready(m_axis_tready),
    .s_axis_tdata(m_axis_tdata),
    .s_axis_tkeep(m_axis_tkeep),
    .s_axis_tlast(m_axis_tlast),
    .s_axis_tid(m_axis_tid),
    .s_axis_tdest(m_axis_tdest),
    .s_axis_tuser(m_axis_tuser),
    .m_axis_aclk(s_clk),
    .m_axis_tvalid(s_axis_tvalid),
    .m_axis_tready(s_axis_tready),
    .m_axis_tdata(s_axis_tdata),
    .m_axis_tkeep(s_axis_tkeep),
    .m_axis_tlast(s_axis_tlast),
    .m_axis_tid(s_axis_tid),
    .m_axis_tdest(s_axis_tdest),
    .m_axis_tuser(s_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_18 axis_data_fifo_18 (
    .s_axis_aresetn(~s_rst),
    .s_axis_aclk(s_clk),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tid(s_axis_tid),
    .s_axis_tdest(s_axis_tdest),
    .s_axis_tuser(s_axis_tuser),
    .m_axis_aclk(m_clk),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tid(m_axis_tid),
    .m_axis_tdest(m_axis_tdest),
    .m_axis_tuser(m_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_19 axis_data_fifo_19 (
    .s_axis_aresetn(~m_rst),
    .s_axis_aclk(m_clk),
    .s_axis_tvalid(m_axis_tvalid),
    .s_axis_tready(m_axis_tready),
    .s_axis_tdata(m_axis_tdata),
    .s_axis_tkeep(m_axis_tkeep),
    .s_axis_tlast(m_axis_tlast),
    .s_axis_tid(m_axis_tid),
    .s_axis_tdest(m_axis_tdest),
    .s_axis_tuser(m_axis_tuser),
    .m_axis_aclk(s_clk),
    .m_axis_tvalid(s_axis_tvalid),
    .m_axis_tready(s_axis_tready),
    .m_axis_tdata(s_axis_tdata),
    .m_axis_tkeep(s_axis_tkeep),
    .m_axis_tlast(s_axis_tlast),
    .m_axis_tid(s_axis_tid),
    .m_axis_tdest(s_axis_tdest),
    .m_axis_tuser(s_axis_tuser)
);

axis_async_fifo_adapter_axis_data_fifo_20