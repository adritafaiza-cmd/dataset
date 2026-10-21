Please act as a professional Verilog designer.

Implement a single-clock I2C master.

Module name:
    i2c_master

Language:
    Verilog-2001

Clocks:
    clk: Single clock.

Resets:
    rst: active-high.

Input ports:
    clk: Clock.
    rst: Active-high reset.
    s_axis_cmd_address: Address.
    s_axis_cmd_start: See Behavior.
    s_axis_cmd_read: See Behavior.
    s_axis_cmd_write: See Behavior.
    s_axis_cmd_write_multiple: See Behavior.
    s_axis_cmd_stop: See Behavior.
    s_axis_cmd_valid: Handshake valid.
    s_axis_data_tdata: Data payload.
    s_axis_data_tvalid: Handshake valid.
    s_axis_data_tlast: Data payload.
    m_axis_data_tready: Handshake ready.
    scl_i: See Behavior.
    sda_i: See Behavior.
    prescale: See Behavior.
    stop_on_idle: See Behavior.

Output ports:
    s_axis_cmd_ready: Handshake ready.
    s_axis_data_tready: Handshake ready.
    m_axis_data_tdata: Data payload.
    m_axis_data_tvalid: Handshake valid.
    m_axis_data_tlast: Data payload.
    scl_o: See Behavior.
    scl_t: See Behavior.
    sda_o: See Behavior.
    sda_t: See Behavior.
    busy: See Behavior.
    bus_control: See Behavior.
    bus_active: See Behavior.
    missed_ack: See Behavior.

Parameters:
    None.

Behavior:
    - Accept commands on s_axis_cmd_* and write bytes on s_axis_data_*.
    - Drive open-drain style scl/sda outputs (o and t).
    - Return read bytes on m_axis_data_*.
    - prescale sets SCL timing. Honor start/stop/read/write command bits.
    - missed_ack reports a missing slave ACK.
    - After reset the bus drivers are released.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module i2c_master (
    input  wire        clk,
    input  wire        rst,
    /*
     * Host interface
     */
    input  wire [6:0]  s_axis_cmd_address,
    input  wire        s_axis_cmd_start,
    input  wire        s_axis_cmd_read,
    input  wire        s_axis_cmd_write,
    input  wire        s_axis_cmd_write_multiple,
    input  wire        s_axis_cmd_stop,
    input  wire        s_axis_cmd_valid,
    output wire        s_axis_cmd_ready,
    input  wire [7:0]  s_axis_data_tdata,
    input  wire        s_axis_data_tvalid,
    output wire        s_axis_data_tready,
    input  wire        s_axis_data_tlast,
    output wire [7:0]  m_axis_data_tdata,
    output wire        m_axis_data_tvalid,
    input  wire        m_axis_data_tready,
    output wire        m_axis_data_tlast,
    /*
     * I2C interface
     */
    input  wire        scl_i,
    output wire        scl_o,
    output wire        scl_t,
    input  wire        sda_i,
    output wire        sda_o,
    output wire        sda_t,
    /*
     * Status
     */
    output wire        busy,
    output wire        bus_control,
    output wire        bus_active,
    output wire        missed_ack,
    /*
     * Configuration
     */
    input  wire [15:0] prescale,
    input  wire        stop_on_idle
);
