`timescale 1ns / 1ps

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
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
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

    wire s_to_m_sync_tvalid;
    wire s_to_m_sync_tready;
    wire s_to_m_sync_tlast;
    wire [DATA_WIDTH-1:0] s_to_m_sync_tdata;
    wire [KEEP_WIDTH-1:0] s_to_m_sync_tkeep;
    wire [ID_WIDTH-1:0] s_to_m_sync_tid;
    wire [DEST_WIDTH-1:0] s_to_m_sync_tdest;
    wire [USER_WIDTH-1:0] s_to_m_sync_tuser;

    wire m_to_s_sync_tvalid;
    wire m_to_s_sync_tready;
    wire m_to_s_sync_tlast;
    wire [DATA_WIDTH-1:0] m_to_s_sync_tdata;
    wire [KEEP_WIDTH-1:0] m_to_s_sync_tkeep;
    wire [ID_WIDTH-1:0] m_to_s_sync_tid;
    wire [DEST_WIDTH-1:0] m_to_s_sync_tdest;
    wire [USER_WIDTH-1:0] m_to_s_sync_tuser;

    fifo_sync #(
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
        .RAM_PIPELINE(RAM_PIPELINE)
    ) s_to_m_sync (
        .clk(s_clk),
        .rst(s_rst),
        .din(s_axis_tdata),
        .dink(s_axis_tkeep),
        .wr_en(s_axis_tvalid),
        .rd_en(m_axis_tready),
        .wlast(s_axis_tlast),
        .dout(s_to_m_sync_tdata),
        .doutk(s_to_m_sync_tkeep),
        .full(s_to_m_sync_tvalid),
        .empty(s_to_m_sync_tready)
    );

    fifo_sync #(
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
        .RAM_PIPELINE(RAM_PIPELINE)
    ) m_to_s_sync (
        .clk(m_clk),
        .rst(m_rst),
        .din(m_axis_tdata),
        .dink(m_axis_tkeep),
        .wr_en(m_axis_tvalid),
        .rd_en(s_axis_tready),
        .wlast(m_axis_tlast),
        .dout(m_to_s_sync_tdata),
        .doutk(m_to_s_sync_tkeep),
        .full(m_to_s_sync_tvalid),
        .empty(m_to_s_sync_tready)
    );

    assign s_axis_tready = s_to_m_sync_tready;
    assign m_axis_tvalid = m_to_s_sync_tvalid;
    assign m_axis_tdata = m_to_s_sync_tdata;
    assign m_axis_tkeep = m_to_s_sync_tkeep;
    assign m_axis_tlast = m_to_s_sync_tlast;
    assign m_axis_tid = m_to_s_sync_tid;
    assign m_axis_tdest = m_to_s_sync_tdest;
    assign m_axis_tuser = m_to_s_sync_tuser;

    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

    assign s_status_depth = 0;
    assign s_status_depth_commit = 0;
    assign s_status_overflow = 0;
    assign s_status_bad_frame = 0;
    assign s_status_good_frame = 0;
    assign m_status_depth = 0;
    assign m_status_depth_commit = 0;
    assign m_status_overflow = 0;
    assign m_status_bad_frame = 0;
    assign m_status_good_frame = 0;

endmodule
