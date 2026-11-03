Please act as a professional Verilog designer.

Implement a single-clock AXI-Stream switch.

Module name:
    axis_switch

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
    S_COUNT: See Behavior.
    M_COUNT: See Behavior.
    DATA_WIDTH: Data width in bits.
    KEEP_ENABLE: See Behavior.
    KEEP_WIDTH: See Behavior.
    ID_ENABLE: See Behavior.
    S_ID_WIDTH: See Behavior.
    M_ID_WIDTH: See Behavior.
    M_DEST_WIDTH: See Behavior.
    S_DEST_WIDTH: See Behavior.
    USER_ENABLE: See Behavior.
    USER_WIDTH: See Behavior.
    M_BASE: See Behavior.
    M_TOP: See Behavior.
    M_CONNECT: See Behavior.
    UPDATE_TID: See Behavior.
    S_REG_TYPE: See Behavior.
    M_REG_TYPE: See Behavior.
    ARB_TYPE_ROUND_ROBIN: See Behavior.
    ARB_LSB_HIGH_PRIORITY: See Behavior.

Behavior:
    - Route S_COUNT inputs to M_COUNT outputs using tdest.
    - Do not drop or duplicate a beat that is granted.
    - When ARB_TYPE_ROUND_ROBIN is set, arbitrate fairly among inputs that want the same output.
    - After reset all ports are idle.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module axis_switch #
(
    parameter S_COUNT = 4,
    parameter M_COUNT = 4,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter S_ID_WIDTH = 8,
    parameter M_ID_WIDTH = S_ID_WIDTH+$clog2(S_COUNT),
    parameter M_DEST_WIDTH = 1,
    parameter S_DEST_WIDTH = M_DEST_WIDTH+$clog2(M_COUNT),
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter M_BASE = 0,
    parameter M_TOP = 0,
    parameter M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}},
    parameter UPDATE_TID = 0,
    parameter S_REG_TYPE = 0,
    parameter M_REG_TYPE = 2,
    parameter ARB_TYPE_ROUND_ROBIN = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 1
)
(
    input  wire                             clk,
    input  wire                             rst,
    /*
     * AXI Stream inputs
     */
    input  wire [S_COUNT*DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire [S_COUNT*KEEP_WIDTH-1:0]    s_axis_tkeep,
    input  wire [S_COUNT-1:0]               s_axis_tvalid,
    output wire [S_COUNT-1:0]               s_axis_tready,
    input  wire [S_COUNT-1:0]               s_axis_tlast,
    input  wire [S_COUNT*S_ID_WIDTH-1:0]    s_axis_tid,
    input  wire [S_COUNT*S_DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [S_COUNT*USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI Stream outputs
     */
    output wire [M_COUNT*DATA_WIDTH-1:0]    m_axis_tdata,
    output wire [M_COUNT*KEEP_WIDTH-1:0]    m_axis_tkeep,
    output wire [M_COUNT-1:0]               m_axis_tvalid,
    input  wire [M_COUNT-1:0]               m_axis_tready,
    output wire [M_COUNT-1:0]               m_axis_tlast,
    output wire [M_COUNT*M_ID_WIDTH-1:0]    m_axis_tid,
    output wire [M_COUNT*M_DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [M_COUNT*USER_WIDTH-1:0]    m_axis_tuser
);
