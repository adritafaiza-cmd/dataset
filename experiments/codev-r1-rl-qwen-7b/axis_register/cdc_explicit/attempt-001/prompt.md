Please act as a professional Verilog designer.

Implement a single-clock AXI-Stream register slice.

Module name:
    axis_register

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

Output ports:
    s_axis_tready: Handshake ready.
    m_axis_tdata: Data payload.
    m_axis_tkeep: See Behavior.
    m_axis_tvalid: Handshake valid.
    m_axis_tlast: See Behavior.
    m_axis_tid: See Behavior.
    m_axis_tdest: See Behavior.
    m_axis_tuser: See Behavior.

Parameters:
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
    REG_TYPE: See Behavior.

Behavior:
    - REG_TYPE 0 is a wire, 1 is a simple buffer, 2 is a skid buffer that must not drop a beat when the output stalls.
    - Preserve tdata and enabled sidebands.
    - After reset the slice is empty.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module axis_register #
(
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
    parameter REG_TYPE = 2
)
(
    input  wire                   clk,
    input  wire                   rst,
    /*
     * AXI Stream input
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
     * AXI Stream output
     */
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser
);
