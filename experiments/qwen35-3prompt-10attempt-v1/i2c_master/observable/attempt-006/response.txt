```verilog
`timescale 1ns/1ps

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

    // Internal timing parameters
    localparam int unsigned SCL_PERIOD = 256; // Base period in clk cycles
    localparam int unsigned SDA_HOLD    = 4;   // Hold time in clk cycles
    localparam int unsigned SDA_SETUP   = 4;   // Setup time in clk cycles
    localparam int unsigned START_DELAY = 4;   // Delay after start before data
    localparam int unsigned STOP_DELAY  = 4;   // Delay after stop before release

    // State Machine States
    localparam int unsigned IDLE = 0;
    localparam int unsigned START = 1;
    localparam int unsigned START_WAIT = 2;
    localparam int unsigned ADDR_WRITE = 3;
    localparam int unsigned ADDR_READ = 4;
    localparam int unsigned DATA_WRITE = 5;
    localparam int unsigned DATA_READ = 6;
    localparam int unsigned ACK_CHECK = 7;
    localparam int unsigned STOP_GEN = 8;
    localparam int unsigned STOP_WAIT = 9;
    localparam int unsigned ERROR = 10;

    reg [3:0] state;
    reg [7:0] state_data; // Data to shift out or expected data
    reg [7:0] shift_reg;  // Shift register for SDA/SCL
    reg [7:0] cmd_addr;
    reg [7:0] cmd_data;
    reg [7:0] rx_data;
    reg [7:0] rx_count;
    reg [7:0] tx_count;
    reg [7:0] tx_limit;
    reg [7:0] scl_count;
    reg [7:0] sda_hold_count;
    reg [7:0] sda_setup_count;
    reg [7:0] stop_count;
    reg [7:0] delay_count;
    reg [7:0] prescale_val;
    reg [7:0] next_state;
    reg [7:0] next_state_data;
    reg [7:0] next_shift_reg;
    reg [7:0] next_rx_count;
    reg [7:0] next_tx_count;
    reg [7:0] next_tx_limit;
    reg [7:0] next_scl_count;
    reg [7:0] next_sda_hold_count;
    reg [7:0] next_sda_setup_count;
    reg [7:0] next_stop_count;
    reg [7:0] next_delay_count;
    reg [7:0] next_prescale_val;
    reg [7:0] next_rx_data;
    reg [7:0] next_shift_reg; // Redundant for clarity in logic
    reg [7:0] next_state_data; // Redundant for clarity in logic

    // Control signals
    reg [7:0] scl_out;
    reg [7:0] sda_out;
    reg [7:0] scl_t_out;
    reg [7:0] sda_t_out;
    reg [7:0] scl_i_sample;
    reg [7:0] sda_i_sample;
    reg [7:0] ack_received;
    reg [7:0] missed_ack_flag;
    reg [7:0] bus_ctrl_flag;
    reg [7:0] bus_active_flag;
    reg [7:0] busy_flag;
    reg [7:0] cmd_valid_flag;
    reg [7:0] data_valid_flag;
    reg [7:0] data_ready_flag;
    reg [7:0] last_flag;
    reg [7:0] stop_flag;
    reg [7:0] write_multiple_flag;
    reg [7:0] read_flag;
    reg [7:0] write_flag;
    reg [7:0] start_flag;
    reg [7:0] addr_flag;
    reg [7:0] cmd_addr_flag;
    reg [7:0] cmd_data_flag;
    reg [7:0] cmd_stop_flag;
    reg [7:0] cmd_start_flag;
    reg [7:0] cmd_write_flag;
    reg [7:0] cmd_read_flag;
    reg [7:0] cmd_write_multiple_flag;
    reg [7:0] cmd_valid_flag;
    reg [7:0] s_axis_cmd_ready_flag;
    reg [7:0] s_axis_data_tready_flag;
    reg [7:0] m_axis_data_tvalid_flag;
    reg [7:0] m_axis_data_tlast_flag;
    reg [7:0] m_axis_data_tdata_flag;
    reg [7:0] s_axis_data_tvalid_flag;
    reg [7:0] s_axis_data_tdata_flag;
    reg [7:0] s_axis_data_tlast_flag;
    reg [7:0] s_axis_data_tready_flag;
    reg [7:0] s_axis_cmd_address_flag;
    reg [7:0] s_axis_cmd_start_flag;
    reg [7:0] s_axis_cmd_read_flag;
    reg [7:0] s_axis_cmd_write_flag;
    reg [7:0] s_axis_cmd_write_multiple_flag;
    reg [7:0] s_axis_cmd_stop_flag;
    reg [7:0] s_axis_cmd_valid_flag;
    reg [7:0] s_axis_data_tdata_flag;
    reg [7:0] s_axis_data_tvalid_flag;
    reg [7:0] s_axis_data_tlast_flag;
    reg [7:0] s_axis_data_tready_flag;
    reg [7:0] m_axis_data_tdata_flag;
    reg [7:0] m_axis_data_tvalid_flag;
    reg [7:0] m_axis_data_tready_flag;
    reg [7:0] m_axis_data_tlast_flag;
    reg [7:0] scl_i_flag;
    reg [7:0] sda_i_flag;
    reg [7:0] scl_o_flag;
    reg [7:0] sda_o_flag;
    reg [7:0] scl_t_flag;
    reg [7:0] sda_t_flag;
    reg [7:0] busy_flag;
    reg [7:0] bus_control_flag;
    reg [7:0] bus_active_flag;
    reg [7:0] missed_ack_flag;
    reg [7:0] prescale_flag;
    reg [7:0] stop_on_idle_flag;

    // State Register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            shift_reg <= 8'h00;
            state_data <= 8'h00;
            rx_data <= 8'h00;
            rx_count <= 8'h00;
            tx_count <= 8'h00;
            tx_limit <= 8'h00;
            scl_count <= 8'h00;
            sda_hold_count <= 8'h00;
            sda_setup_count <= 8'h00;
            stop_count <= 8'h00;
            delay_count <= 8'h00;
            prescale_val <= 8'h00;
            ack_received <= 8'h00;
            missed_ack_flag <= 8'h00;
            bus_ctrl_flag <= 8'h00;
            bus_active_flag <= 8'h00;
            busy_flag <= 8'h00;
            cmd_valid_flag <= 8'h00;
            data_valid_flag <= 8'h00;
            data_ready_flag <= 8'h00;
            last_flag <= 8'h00;
            stop_flag <= 8'h00;
            write_multiple_flag <= 8'h00;
            read_flag <= 8'h00;
            write_flag <= 8'h00;
            start_flag <= 8'h00;
            addr_flag <= 8'h00;
            cmd_addr_flag <= 8'h00;
            cmd_data_flag <= 8'h00;
            cmd_stop_flag <= 8'h00;
            cmd_start_flag <= 8'h00;
            cmd_write_flag <= 8'h00;
            cmd_read_flag <= 8'h00;
            cmd_write_multiple_flag <= 8'h00;
            cmd_valid_flag <= 8'h00;
            s_axis_cmd_ready_flag <= 8'h00;
            s_axis_data_tready_flag <= 8'h00;
            m_axis_data_tvalid_flag <= 8'h00;
            m_axis_data_tlast_flag <= 8'h00;
            m_axis_data_tdata_flag <= 8'h00;
            s_axis_data_tvalid_flag <= 8'h00;
            s_axis_data_tdata_flag <= 8'h00;
            s_axis_data_tlast_flag <= 8'h00;
            s_axis_data_tready_flag <= 8'h00;
            s_axis_cmd_address_flag <= 8'h00;
            s_axis_cmd_start_flag <= 8'h00;
            s_axis_cmd_read_flag <= 8'h00;
            s_axis_cmd_write_flag <= 8'h00;
            s_axis_cmd_write_multiple_flag <= 8'h00;
            s_axis_cmd_stop_flag <= 8'h00;
            s_axis_cmd_valid_flag <= 8'h00;
            s_axis_data_tdata_flag <= 8'h00;
            s_axis_data_tvalid_flag <= 8'h00;
            s_axis_data_tlast_flag <= 8'h00;
            s_axis_data_tready_flag <= 8'h00;
            m_axis_data_tdata_flag <= 8'h00;
            m_axis_data_tvalid_flag <= 8'h00;
            m_axis_data_tready_flag <= 8'h00;
            m_axis_data_tlast_flag <= 8'h00;
            scl_i_flag <= 8'h00;
            sda_i_flag <= 8'h00;
            scl_o_flag <= 8'h00;
            sda_o_flag <= 8'h00;
            scl_t_flag <= 8'h00;
            sda_t_flag <= 8'h00;
            busy_flag <= 8'h00;
            bus_control_flag <= 8'h00;
            bus_active_flag <= 8'h00;
            missed_ack_flag <= 8'h00;
            prescale_flag <= 8'h00;
            stop_on_idle_flag <= 8'h00;
        end else begin
            state <= next_state;
            shift_reg <= next_shift_reg;
            state_data <= next_state_data;
            rx_data <= next_rx_data;
            rx_count <= next_rx_count;
            tx_count <= next_tx_count;
            tx_limit <= next_tx_limit;
            scl_count <= next_scl_count;
            sda_hold_count <= next_sda_hold_count;
            sda_setup_count <= next_sda_setup_count;
            stop_count <= next_stop_count;
            delay_count <= next_delay_count;
            prescale_val <= next_prescale_val;
            ack_received <= 8'h00;
            missed_ack_flag <= missed_ack_flag;
            bus_ctrl_flag <= bus_ctrl_flag;
            bus_active_flag <= bus_active_flag;
            busy_flag <= busy_flag;
            cmd_valid_flag <= cmd_valid_flag;
            data_valid_flag <= data_valid_flag;
            data_ready_flag <= data_ready_flag;
            last_flag <= last_flag;
            stop_flag <= stop_flag;
            write_multiple_flag <= write_multiple_flag;
            read_flag <= read_flag;
            write_flag <= write_flag;
            start_flag <= start_flag;
            addr_flag <= addr_flag;
            cmd_addr_flag <= cmd_addr_flag;
            cmd_data_flag <= cmd_data_flag;
            cmd_stop_flag <= cmd_stop_flag;
            cmd_start_flag <= cmd_start_flag;
            cmd_write_flag <= cmd_write_flag;
            cmd_read_flag <= cmd_read_flag;
            cmd_write_multiple_flag <= cmd_write_multiple_flag;
            cmd_valid_flag <= cmd_valid_flag;
            s_axis_cmd_ready_flag <= s_axis_cmd_ready_flag;
            s_axis_data_tready_flag <= s_axis_data_tready_flag;
            m_axis_data_tvalid_flag <= m_axis_data_tvalid_flag;
            m_axis_data_tlast_flag <= m_axis_data_tlast_flag;
            m_axis_data_tdata_flag <= m_axis_data_tdata_flag;
            s_axis_data_tvalid_flag <= s_axis_data_tvalid_flag;
            s_axis_data_tdata_flag <= s_axis_data_tdata_flag;
            s_axis_data_tlast_flag <= s_axis_data_tlast_flag;
            s_axis_data_tready_flag <= s_axis_data_tready_flag;
            s_axis_cmd_address_flag <= s_axis_cmd_address_flag;
            s_axis_cmd_start_flag <= s_axis_cmd_start_flag;
            s_axis_cmd_read_flag <= s_axis_cmd_read_flag;
            s_axis_cmd_write_flag <= s_axis_cmd_write_flag;
            s_axis_cmd_write_multiple_flag <= s_axis_cmd_write_multiple_flag;
            s_axis_cmd_stop_flag <= s_axis_cmd_stop_flag;
            s_axis_cmd_valid_flag <= s_axis_cmd_valid_flag;
            s_axis_data_tdata_flag <= s_axis_data_tdata_flag;
            s_axis_data_tvalid_flag <= s_axis_data_tvalid_flag;
            s_axis_data_tlast_flag <= s_axis_data_tlast_flag;
            s_axis_data_tready_flag <= s_axis_data_tready_flag;
            m_axis_data_tdata_flag <= m_axis_data_tdata_flag;
            m_axis_data_tvalid_flag <= m_axis_data_tvalid_flag;
            m_axis_data_tready_flag <= m_axis_data_tready_flag;
            m_axis_data_tlast_flag <= m_axis_data_tlast_flag;
            scl_i_flag <= scl_i_flag;
            sda_i_flag <= sda_i_flag;
            scl_o_flag <= scl_o_flag;
            sda_o_flag <= sda_o_flag;
            scl_t_flag <= scl_t_flag;
            sda_t_flag <= sda_t_flag;
            busy_flag <= busy_flag;
            bus_control_flag <= bus_control_flag;
            bus_active_flag <= bus_active_flag;
            missed_ack_flag <= missed_ack_flag;
            prescale_flag <= prescale_flag;
            stop_on_idle_flag <= stop_on_idle_flag;
        end
    end

    // Output Registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_o <= 1'b0;
            sda_o <= 1'b0;
            scl_t <= 1'b0;
            sda_t <= 1'b0;
            busy <= 1'b0;
            bus_control <= 1'b0;
            bus_active <= 1'b0;
            missed_ack <= 1'b0;
        end else begin
            scl_o <= scl_o;
            sda_o <= sda_o;
            scl_t <= scl_t;
            sda_t <= sda_t;
            busy <= busy;
            bus_control <= bus_control;
            bus_active <= bus_active;
            missed_ack <= missed_ack;
        end
    end

    // Logic for scl_o and sda_o
    assign scl_o = (state == START) ? 1'b0 : (state == START_WAIT) ? 1'b0 : (state == ADDR_WRITE) ? 1'b0 : (state == ADDR_READ) ? 1'b0 : (state == DATA_WRITE) ? 1'b0 : (state == DATA_READ) ? 1'b0 : (state == ACK_CHECK) ? 1'b0 : (state == STOP_GEN) ? 1'b0 : (state == STOP_WAIT) ? 1'b0 : (state == ERROR) ? 1'b0 : 1'b1;
    assign sda_o = (state == START) ? 1'b1 : (state == START_WAIT) ? 1'b1 : (state == ADDR_WRITE) ? 1'b1 : (state == ADDR_READ) ? 1'b1 : (state == DATA_WRITE) ? 1'b1 : (state == DATA_READ) ? 1'b1 : (state == ACK_CHECK) ? 1'b1 : (state == STOP_GEN) ? 1'b1 : (state == STOP_WAIT) ? 1'b1 : (state == ERROR) ? 1'b1 : 1'b1;

    // Logic for scl_t and sda_t
    assign scl_t = (state == START) ? 1'b0 : (state == START_WAIT) ? 1'b0 : (state == ADDR_WRITE) ? 1'b0 : (state == ADDR_READ) ? 1'b0 : (state == DATA_WRITE) ? 1'b0 : (state == DATA_READ) ? 1'b0 : (state == ACK_CHECK) ? 1'b0 : (state == STOP_GEN) ? 1'b0 : (state == STOP_WAIT) ? 1'b0 : (state == ERROR) ? 1'b0 : 1'b1;
    assign sda_t = (state == START) ? 1'b1 : (state == START_WAIT) ? 1'b1 : (state == ADDR_WRITE) ? 1'b1 : (state == ADDR_READ) ? 1'b1 : (state == DATA_WRITE) ? 1'b1 : (state == DATA_READ) ? 1'b1 : (state == ACK_CHECK) ? 1'b1 : (state == STOP_GEN) ? 1'b1 : (state == STOP_WAIT) ? 1'b1 : (state == ERROR) ? 1'b1 : 1'b1;

    // Logic for busy, bus_control, bus_active, missed_ack
    assign busy = (state != IDLE);
    assign bus_control = (state == START) || (state == START_WAIT) || (state == ADDR_WRITE) || (state == ADDR_READ) || (state == DATA_WRITE) || (state == DATA_READ) || (state == ACK_CHECK) || (state == STOP_GEN) || (state == STOP_WAIT) || (state == ERROR);
    assign bus_active = (state == START) || (state == START_WAIT) || (state == ADDR_WRITE) || (state == ADDR_READ) || (state == DATA_WRITE) || (state == DATA_READ) || (state == ACK_CHECK) || (state == STOP_GEN) || (state == STOP_WAIT) || (state == ERROR);
    assign missed_ack = (state == ACK_CHECK) && (ack_received == 8'h00);

    // Logic for scl_i_sample and sda_i_sample
    assign scl_i_sample = scl_i;
    assign sda_i_sample = sda_i;

    // Logic for ack_received
    assign ack_received = (state == ACK_CHECK) ? (sda_i_sample == 1'b0) ? 8'h01 : 8'h00 : 8'h00;

    // Logic for missed_ack_flag
    assign missed_ack_flag = (state == ACK_CHECK) && (ack_received == 8'h00) ? 8'h01 : 8'h00;

    // Logic for bus_ctrl_flag
    assign bus_ctrl_flag = (state == START) || (state == START_WAIT) || (state == ADDR_WRITE) || (state == ADDR_READ) || (state == DATA_WRITE) || (state == DATA_READ) || (state == ACK_CHECK) || (state == STOP_GEN) || (state == STOP_WAIT) || (state == ERROR);

    // Logic for bus_active_flag
    assign bus_active_flag = (state == START) || (state == START_WAIT) || (state == ADDR_WRITE) || (state == ADDR_READ) || (state == DATA_WRITE) || (state == DATA_READ) || (state == ACK_CHECK) || (state == STOP_GEN) || (state == STOP_WAIT) || (state == ERROR);

    // Logic for busy_flag
    assign busy_flag = (state != IDLE);

    // Logic for cmd_valid_flag
    assign cmd_valid_flag = s_axis_cmd_valid;

    // Logic for data_valid_flag
    assign data_valid_flag = s_axis_data_tvalid;

    // Logic for data_ready_flag
    assign data_ready_flag = s_axis_data_tready;

    // Logic for last_flag
    assign last_flag = s_axis_data_tlast;

    // Logic for stop_flag
    assign stop_flag = s_axis_cmd_stop;

    // Logic for write_multiple_flag
    assign write_multiple_flag = s_axis_cmd_write_multiple;

    // Logic for read_flag
    assign read_flag = s_axis_cmd_read;

    // Logic for write_flag
    assign write_flag = s_axis_cmd_write;

    // Logic for start_flag
    assign start_flag = s_axis_cmd_start;

    // Logic for addr_flag
    assign addr_flag = s_axis_cmd_address;

    // Logic for cmd_addr_flag
    assign cmd_addr_flag = s_axis_cmd_address;

    // Logic for cmd_data_flag
    assign cmd_data_flag = s_axis_data_tdata;

    // Logic for cmd_stop_flag
    assign cmd_stop_flag = s_axis_cmd_stop;

    // Logic for cmd_start_flag
    assign cmd_start_flag = s_axis_cmd_start;

    // Logic for cmd_write_flag
    assign cmd_write_flag = s_axis_cmd_write;

    // Logic for cmd_read_flag
    assign cmd_read_flag = s_axis_cmd_read;

    // Logic for cmd_write_multiple_flag
    assign cmd_write_multiple_flag = s_axis_cmd_write_multiple;

    // Logic for cmd_valid_flag
    assign cmd_valid_flag = s_axis_cmd_valid;

    // Logic for s_axis_cmd_ready_flag
    assign s_axis_cmd_ready_flag = s_axis_cmd_ready;

    // Logic for s_axis_data_tready_flag
    assign s_axis_data_tready_flag = s_axis_data_tready;

    // Logic for m_axis_data_tvalid_flag
    assign m_axis_data_tvalid_flag = m_axis_data_tvalid;

    // Logic for m_axis_data_tlast_flag
    assign m_axis_data_tlast_flag = m_axis_data_tlast;

    // Logic for m_axis_data_tdata_flag
    assign m_axis_data_tdata_flag = m_axis_data_tdata;

    // Logic for s_axis_data_tvalid_flag
    assign s_axis_data_tvalid_flag = s_axis_data_tvalid;

    // Logic for s_axis_data_tdata_flag
    assign s_axis_data_tdata_flag = s_axis_data_tdata;

    // Logic for s_axis_data_tlast_flag
    assign s_axis_data_tlast_flag = s_axis_data_tlast;

    // Logic for s_axis_data_tready_flag
    assign s_axis_data_tready_flag = s_axis_data_tready;

    // Logic for s_axis_cmd_address_flag
    assign s_axis_cmd_address_flag = s_axis_cmd_address;

    // Logic for s_axis_cmd_start_flag
    assign s_axis_cmd_start_flag = s_axis_cmd_start;

    // Logic for s_axis_cmd_read_flag
    assign s_axis_cmd_read_flag = s_axis_cmd_read;

    // Logic for s_axis_cmd_write_flag
    assign s_axis_cmd_write_flag = s_axis_cmd_write;

    // Logic for s_axis_cmd_write_multiple_flag
    assign s_axis_cmd_write_multiple_flag = s_axis_cmd_write_multiple;

    // Logic for s_axis_cmd_stop_flag
    assign s_axis_cmd_stop_flag = s_axis_cmd_stop;

    // Logic for s_axis_cmd_valid_flag
    assign s_axis_cmd_valid_flag = s_axis_cmd_valid;

    // Logic for s_axis_data_tdata_flag
    assign s_axis_data_tdata_flag = s_axis_data_tdata;

    // Logic for s_axis_data_tvalid_flag
    assign s_axis_data_tvalid_flag = s_axis_data_tvalid;

    // Logic for s_axis_data_tlast_flag
    assign s_axis_data_tlast_flag = s_axis_data_tlast;

    // Logic for s_axis_data_tready_flag
    assign s_axis_data_tready_flag = s_axis_data_tready;

    // Logic for m_axis_data_tdata_flag
    assign m_axis_data_tdata_flag = m_axis_data_tdata;

    // Logic for m_axis_data_tvalid_flag
    assign m_axis_data_tvalid_flag = m_axis_data_tvalid;

    // Logic for m_axis_data_tready_flag
    assign m_axis_data_tready_flag = m_axis_data_tready;

    // Logic for m_axis_data_tlast_flag
    assign m_axis_data_tlast_flag = m_axis_data_tlast;

    // Logic for scl_i_flag
    assign scl_i_flag = scl_i;

    // Logic for sda_i_flag
    assign sda_i_flag = sda_i;

    // Logic for scl_o_flag
    assign scl_o_flag = scl_o;

    // Logic for sda_o_flag
    assign sda_o_flag = sda_o;

    // Logic for scl_t_flag
    assign scl_t_flag = scl_t;

    // Logic for sda_t_flag
    assign sda_t_flag = sda_t;

    // Logic for busy_flag
    assign busy_flag = busy;

    // Logic for bus_control_flag
    assign bus_control_flag = bus_control;

    // Logic for bus_active_flag
    assign bus_active_flag = bus_active;

    // Logic for missed_ack_flag
    assign missed_ack_flag = missed_ack;

    // Logic for prescale_flag
    assign prescale_flag = prescale;

    // Logic for stop_on_idle_flag
    assign stop_on_idle_flag = stop_on_idle;

    // Logic for next_state
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (s_axis_cmd_valid && s_axis_cmd_start) begin
                    next_state = START;
                end
            end
            START: begin
                if (scl_count == prescale_val) begin
                    next_state = START_WAIT;
                end
            end
            START_WAIT: begin
                if (scl_count == prescale_val) begin
                    next_state = ADDR_WRITE;
                end
            end
            ADDR_WRITE: begin
                if (scl_count == prescale_val) begin
                    next_state = DATA_WRITE;
                end
            end
            ADDR_READ: begin
                if (scl_count == prescale_val) begin
                    next_state = DATA_READ;
                end
            end
            DATA_WRITE: begin
                if (scl_count == prescale_val) begin
                    next_state = ACK_CHECK;
                end
            end
            DATA_READ: begin
                if (scl_count == prescale_val) begin
                    next_state = ACK_CHECK;
                end
            end
            ACK_CHECK: begin
                if (scl_count == prescale_val) begin
                    next_state = STOP_GEN;
                end
            end
            STOP_GEN: begin
                if (scl_count == prescale_val) begin
                    next_state = STOP_WAIT;
                end
            end
            STOP_WAIT: begin
                if (scl_count == prescale_val) begin
                    next_state = IDLE;
                end
            end
            ERROR: begin
                next_state = IDLE;
            end
        endcase
    end

    // Logic for next_state_data
    always @(*) begin
        next_state_data = state_data;
        case (state)
            START: begin
                next_state_data = 8'h00;
            end
            START_WAIT: begin
                next_state_data = 8'h00;
            end
            ADDR_WRITE: begin
                next_state_data = cmd_addr;
            end
            ADDR_READ: begin
                next_state_data = cmd_addr;
            end
            DATA_WRITE: begin
                next_state_data = cmd_data;
            end
            DATA_READ: begin
                next_state_data = rx_data;
            end
            ACK_CHECK: begin
                next_state_data = 8'h00;
            end
            STOP_GEN: begin
                next_state_data = 8'h00;
            end
            STOP_WAIT: begin
                next_state_data = 8'h00;
            end
            ERROR: begin
                next_state_data = 8'h00;
            end
        endcase
    end

    // Logic for next_shift_reg
    always @(*) begin
        next_shift_reg = shift_reg;
        case (state)
            START: begin
                next_shift_reg = 8'h00;
            end
            START_WAIT: begin
                next_shift_reg = 8'h00;
            end
            ADDR_WRITE: begin
                next_shift_reg = cmd_addr;
            end
            ADDR_READ: begin
                next_shift_reg = cmd_addr;
            end
            DATA_WRITE: begin
                next_shift_reg = cmd_data;
            end
            DATA_READ: begin
                next_shift_reg = rx_data;
            end
            ACK_CHECK: begin
                next_shift_reg = 8'h00;
            end
            STOP_GEN: begin
                next_shift_reg = 8'h00;
            end
            STOP_WAIT: begin
                next_shift_reg = 8'h00;
            end
            ERROR: begin
                next_shift_reg = 8'h00;
            end
        endcase
    end

    // Logic for next_rx_count
    always @(*) begin
        next_rx_count = rx_count;
        case (state)
            START: begin
                next_rx_count = 8'h00;
            end
            START_WAIT: begin
                next_rx_count = 8'h00;
            end
            ADDR_WRITE: begin
                next_rx_count = 8'h00;
            end
            ADDR_READ: begin
                next_rx_count = 8'h00;
            end
            DATA_WRITE: begin
                next_rx_count = 8'h00;
            end
            DATA_READ: begin
                next_rx_count = rx_count + 8'h01;
            end
            ACK_CHECK: begin
                next_rx_count = 8'h00;
            end
            STOP_GEN: begin
                next_rx_count = 8'h00;
            end
            STOP_WAIT: begin
                next_rx_count = 8'h00;
            end
            ERROR: begin
                next_rx_count = 8'h00;
            end
        endcase
    end

    // Logic for next_tx_count
    always @(*) begin
        next_tx_count = tx_count;
        case (state)
            START: begin
                next_tx_count = 8'h00;
            end
            START_WAIT: begin
                next_tx_count = 8'h00;
            end
            ADDR_WRITE: begin
                next_tx_count = 8'h00;
            end
            ADDR_READ: begin
                next_tx_count = 8'h00;
            end
            DATA_WRITE: begin
                next_tx_count = tx_count + 8'h01;
            end
            DATA_READ: begin
                next_tx_count = 8'h00;
            end
            ACK_CHECK: begin
                next_tx_count = 8'h00;
            end
            STOP_GEN: begin
                next_tx_count = 8'h00;
            end
            STOP_WAIT: begin
                next_tx_count = 8'h00;
            end
            ERROR: begin
                next_tx_count = 8'h00;
            end
        endcase
    end

    // Logic for next_tx_limit
    always @(*) begin
        next_tx_limit = tx_limit;
        case (state)
            START: begin
                next_tx_limit = 8'h00;
            end
            START_WAIT: begin
                next_tx_limit = 8'h00;
            end
            ADDR_WRITE: begin
                next_tx_limit = 8'h00;
            end
            ADDR_READ: begin
                next_tx_limit = 8'h00;
            end
            DATA_WRITE: begin
                next_tx_limit = tx_limit + 8'h01;
            end
            DATA_READ: begin
                next_tx_limit = 8'h00;
            end
            ACK_CHECK: begin
                next_tx_limit = 8'h00;
            end
            STOP_GEN: begin
                next_tx_limit = 8'h00;
            end
            STOP_WAIT: begin
                next_tx_limit = 8'h00;
            end
            ERROR: begin
                next_tx_limit = 8'h00;
            end
        endcase
    end

    // Logic for next_scl_count
    always @(*) begin
        next_scl_count = scl_count;
        case (state)
            START: begin
                next_scl_count = scl_count + 8'h01;
            end
            START_WAIT: begin
                next_scl_count = scl_count + 8'h01;
            end
            ADDR_WRITE: begin
                next_scl_count = scl_count + 8'h01;
            end
            ADDR_READ: begin
                next_scl_count = scl_count + 8'h01;
            end
            DATA_WRITE: begin
                next_scl_count = scl_count + 8'h01;
            end
            DATA_READ: begin
                next_scl_count = scl_count + 8'h01;
            end
            ACK_CHECK: begin
                next_scl_count = scl_count + 8'h01;
            end
            STOP_GEN: begin
                next_scl_count = scl_count + 8'h01;
            end
            STOP_WAIT: begin
                next_scl_count = scl_count + 8'h01;
            end
            ERROR: begin
                next_scl_count = scl_count + 8'h01;
            end
        endcase
    end

    // Logic for next_sda_hold_count
    always @(*) begin
        next_sda_hold_count = sda_hold_count;
        case (state)
            START: begin
                next_sda_hold_count = sda_hold_count + 8'h01;
            end
            START_WAIT: begin
                next_sda_hold_count = sda_hold_count + 8'h01;
            end
            ADDR_WRITE: begin
                next_sda_hold_count = sda_hold_count + 8'h01;
            end
            ADDR_READ: begin
                next_sda_hold_count = sda_hold_count + 8'h01;
            end
            DATA_WRITE: begin
                next_sda_hold_count = sda_hold_count + 8'h01;
            end
            DATA_READ: begin
                next_sda_hold_count = sda_hold_count + 8'h01;
            end
            ACK_CHECK: begin
                next_sda_hold_count = sda_hold_count + 8'h01;
            end