Please act as a professional Verilog designer.

Implement an asynchronous AXI-Stream FIFO.

Module name:
    axis_async_fifo

Language:
    Verilog-2001

Clocks:
    s_clk: Independent asynchronous clock (async to m_clk).
    m_clk: Independent asynchronous clock (async to s_clk).

Resets:
    s_rst: active-high.
    m_rst: active-high.

Input ports:
    s_clk: Clock.
    s_rst: Active-high reset.
    s_axis_tdata: Data payload.
    s_axis_tkeep: See Behavior.
    s_axis_tvalid: Handshake valid.
    s_axis_tlast: See Behavior.
    s_axis_tid: See Behavior.
    s_axis_tdest: See Behavior.
    s_axis_tuser: See Behavior.
    m_clk: Clock.
    m_rst: Active-high reset.
    m_axis_tready: Handshake ready.
    s_pause_req: See Behavior.
    m_pause_req: See Behavior.

Output ports:
    s_axis_tready: Handshake ready.
    m_axis_tdata: Data payload.
    m_axis_tkeep: See Behavior.
    m_axis_tvalid: Handshake valid.
    m_axis_tlast: See Behavior.
    m_axis_tid: See Behavior.
    m_axis_tdest: See Behavior.
    m_axis_tuser: See Behavior.
    s_pause_ack: See Behavior.
    m_pause_ack: See Behavior.
    s_status_depth: See Behavior.
    s_status_depth_commit: See Behavior.
    s_status_overflow: See Behavior.
    s_status_bad_frame: See Behavior.
    s_status_good_frame: See Behavior.
    m_status_depth: See Behavior.
    m_status_depth_commit: See Behavior.
    m_status_overflow: See Behavior.
    m_status_bad_frame: See Behavior.
    m_status_good_frame: See Behavior.

Parameters:
    DEPTH: See Behavior.
    DATA_WIDTH: Data width in bits.
    KEEP_ENABLE: See Behavior.
    KEEP_WIDTH: See Behavior.
    LAST_ENABLE: See Behavior.
    ID_ENABLE: See Behavior.
    ID_WIDTH: See Behavior.
    DEST_ENABLE: See Behavior.
    DEST_WIDTH: See Behavior.
    USER_ENABLE: See Behavior.
    USER_WIDTH: See Behavior.
    RAM_PIPELINE: See Behavior.
    OUTPUT_FIFO_ENABLE: See Behavior.
    FRAME_FIFO: See Behavior.
    USER_BAD_FRAME_VALUE: See Behavior.
    USER_BAD_FRAME_MASK: See Behavior.
    DROP_OVERSIZE_FRAME: See Behavior.
    DROP_BAD_FRAME: See Behavior.
    DROP_WHEN_FULL: See Behavior.
    MARK_WHEN_FULL: See Behavior.
    PAUSE_ENABLE: See Behavior.
    FRAME_PAUSE: See Behavior.

Behavior:
    - A transfer is accepted when tvalid and tready are both high.
    - Deliver beats in order with tlast and the enabled sidebands.
    - s_axis_tready must go low when the FIFO cannot accept another beat, unless a drop/mark-when-full parameter is set.
    - After reset the FIFO is empty.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

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
