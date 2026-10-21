Please act as a professional Verilog designer.

Implement a single-clock AXI-Stream FIFO.

Module name:
    axis_fifo

Language:
    Verilog-2001

Clocks:
    clk: Single clock.

Resets:
    rst: active-high.

Input ports:
    clk: Clock.
    rst: Active-high reset.
    s_axis_tdata: Data payload.
    s_axis_tkeep: See Behavior.
    s_axis_tvalid: Handshake valid.
    s_axis_tlast: See Behavior.
    s_axis_tid: See Behavior.
    s_axis_tdest: See Behavior.
    s_axis_tuser: See Behavior.
    m_axis_tready: Handshake ready.
    pause_req: See Behavior.

Output ports:
    s_axis_tready: Handshake ready.
    m_axis_tdata: Data payload.
    m_axis_tkeep: See Behavior.
    m_axis_tvalid: Handshake valid.
    m_axis_tlast: See Behavior.
    m_axis_tid: See Behavior.
    m_axis_tdest: See Behavior.
    m_axis_tuser: See Behavior.
    pause_ack: See Behavior.
    status_depth: See Behavior.
    status_depth_commit: See Behavior.
    status_overflow: See Behavior.
    status_bad_frame: See Behavior.
    status_good_frame: See Behavior.

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
    - Store DEPTH words. Preserve order, tlast, and enabled sidebands.
    - After reset the FIFO is empty.
    - FRAME_FIFO and drop/mark parameters change frame behavior as named.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

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
