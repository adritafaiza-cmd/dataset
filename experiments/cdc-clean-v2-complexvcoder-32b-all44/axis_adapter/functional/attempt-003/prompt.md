Please act as a professional Verilog designer.

Implement a single-clock AXI-Stream width converter.

Module name:
    axis_adapter

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
    S_DATA_WIDTH: See Behavior.
    S_KEEP_ENABLE: See Behavior.
    S_KEEP_WIDTH: See Behavior.
    M_DATA_WIDTH: See Behavior.
    M_KEEP_ENABLE: See Behavior.
    M_KEEP_WIDTH: See Behavior.
    ID_ENABLE: See Behavior.
    ID_WIDTH: See Behavior.
    DEST_ENABLE: See Behavior.
    DEST_WIDTH: See Behavior.
    USER_ENABLE: See Behavior.
    USER_WIDTH: See Behavior.

Behavior:
    - Convert S_DATA_WIDTH to M_DATA_WIDTH.
    - Preserve packet boundaries (tlast) and enabled sidebands.
    - Do not drop or reorder beats except as required by packing/unpacking.
    - After reset both interfaces are idle.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module axis_adapter #
(
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
    parameter USER_WIDTH = 1
)
(
    input  wire                     clk,
    input  wire                     rst,
    /*
     * AXI input
     */
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
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser
);
