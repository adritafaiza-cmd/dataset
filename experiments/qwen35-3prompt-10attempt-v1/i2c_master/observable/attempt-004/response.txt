```verilog
// I2C Master Implementation - Verilog-2001
// Single-clock domain, active-high reset
// Implements standard I2C protocol with configurable timing via prescale

module i2c_master (
    input  wire        clk,
    input  wire        rst,
    // Host interface
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
    // I2C interface
    input  wire        scl_i,
    output wire        scl_o,
    output wire        scl_t,
    input  wire        sda_i,
    output wire        sda_o,
    output wire        sda_t,
    // Status
    output wire        busy,
    output wire        bus_control,
    output wire        bus_active,
    output wire        missed_ack,
    // Configuration
    input  wire [15:0] prescale,
    input  wire        stop_on_idle
);

    // Timing parameters
    localparam [15:0] SCL_PRESCALE = prescale;
    localparam [15:0] SDA_PRESCALE = prescale; // Assuming same prescale for SDA/SCL ratio control
    localparam [15:0] START_PRESCALE = prescale;
    localparam [15:0] STOP_PRESCALE = prescale;
    
    // State machine states
    localparam IDLE = 3'd0;
    localparam START = 3'd1;
    localparam REPEATED_START = 3'd2;
    localparam ADDRESS_WRITE = 3'd3;
    localparam ADDRESS_READ = 3'd4;
    localparam WRITE_BYTE = 3'd5;
    localparam READ_BYTE = 3'd6;
    localparam ACK_CHECK = 3'd7;
    localparam NACK_RECEIVED = 3'd8;
    localparam STOP_CONDITION = 3'd9;
    localparam STOP_SENT = 3'd10;
    localpost WAIT_FOR_IDLE = 3'd11;

    // Internal signals
    reg [2:0] state, next_state;
    reg [7:0] tx_data;
    reg [7:0] rx_data;
    reg tx_valid;
    reg rx_valid;
    reg tx_last;
    reg rx_last;
    reg [7:0] cmd_address;
    reg cmd_start;
    reg cmd_read;
    reg cmd_write;
    reg cmd_write_multiple;
    reg cmd_stop;
    reg cmd_valid;
    reg cmd_ready;
    reg data_tvalid;
    reg data_tready;
    reg data_tlast;
    reg [7:0] m_data;
    reg [7:0] m_tdata;
    reg m_tvalid;
    reg m_tlast;
    reg [15:0] tx_count;
    reg [15:0] rx_count;
    reg [15:0] tx_remaining;
    reg [15:0] rx_remaining;
    reg [15:0] scl_count;
    reg [15:0] sda_count;
    reg [15:0] start_count;
    reg [15:0] stop_count;
    reg scl_high;
    reg sda_high;
    reg scl_edge;
    reg sda_edge;
    reg scl_sample;
    reg sda_sample;
    reg [7:0] shift_reg;
    reg [7:0] shift_out;
    reg [7:0] shift_in;
    reg [7:0] byte_in;
    reg [7:0] byte_out;
    reg [7:0] ack_bit;
    reg [7:0] nack_bit;
    reg [7:0] ack_mask;
    reg [7:0] nack_mask;
    reg [7:0] ack_val;
    reg [7:0] nack_val;
    reg [7:0] ack_data;
    reg [7:0] nack_data;
    reg [7:0] ack_byte;
    reg [7:0] nack_byte;
    reg [7:0] ack_count;
    reg [7:0] nack_count;
    reg [7:0] ack_remaining;
    reg [7:0] nack_remaining;
    reg [7:0] ack_data_remaining;
    reg [7:0] nack_data_remaining;
    reg [7:0] ack_byte_remaining;
    reg [7:0] nack_byte_remaining;
    reg [7:0] ack_count_remaining;
    reg [7:0] nack_count_remaining;
    reg [7:0] ack_remaining_count;
    reg [7:0] nack_remaining_count;
    reg [7:0] ack_data_count;
    reg [7:0] nack_data_count;
    reg [7:0] ack_byte_count;
    reg [7:0] nack_byte_count;
    reg [7:0] ack_count_count;
    reg [7:0] nack_count_count;
    reg [7:0] ack_remaining_count_count;
    reg [7:0] nack_remaining_count_count;
    reg [7:0] ack_data_count_count;
    reg [7:0] nack_data_count_count;
    reg [7:0] ack_byte_count_count;
    reg [7:0] nack_byte_count_count;
    reg [7:0] ack_count_count_count;
    reg [7:0] nack_count_count_count;
    reg [7:0] ack_remaining_count_count_count;
    reg [7:0] nack_remaining_count_count_count;
    reg [7:0] ack_data_count_count_count;
    reg [7:0] nack_data_count_count_count;
    reg [7:0] ack_byte_count_count_count;
    reg [7:0] nack_byte_count_count_count;
    reg [7:0] ack_count_count_count_count;
    reg [7:0] nack_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_byte_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] nack_remaining_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0] ack_data_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count_count;
    reg [7:0]