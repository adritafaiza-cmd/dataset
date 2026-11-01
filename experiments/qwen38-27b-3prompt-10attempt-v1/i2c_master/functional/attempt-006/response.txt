```verilog
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

    // State machine states
    localparam S_IDLE = 4'd0;
    localparam S_START = 4'd1;
    localparam S_ADDR = 4'd2;
    localparam S_DATA = 4'd3;
    localparam S_ACK = 4'd4;
    localparam S_STOP = 4'd5;
    localparam S_WAIT = 4'd6;

    reg [3:0] state, state_next;
    reg [15:0] counter, counter_next;
    reg [7:0] shift_reg, shift_reg_next;
    reg [2:0] bit_count, bit_count_next;
    reg [7:0] data_out, data_out_next;
    reg [7:0] data_in, data_in_next;
    reg       data_valid, data_valid_next;
    reg       data_last, data_last_next;
    reg       ack_received, ack_received_next;
    reg       missed_ack_reg, missed_ack_reg_next;
    reg       scl_drive, scl_drive_next;
    reg       sda_drive, sda_drive_next;
    reg       scl_release, scl_release_next;
    reg       sda_release, sda_release_next;
    reg       bus_active_reg, bus_active_reg_next;
    reg       busy_reg, busy_reg_next;
    reg       bus_control_reg, bus_control_reg_next;
    reg       cmd_start, cmd_read, cmd_write, cmd_write_multiple, cmd_stop;
    reg [6:0] cmd_address;
    reg       data_pending, data_pending_next;
    reg       write_multiple_reg, write_multiple_reg_next;
    reg       read_mode, read_mode_next;
    reg       stop_pending, stop_pending_next;
    reg       addr_phase, addr_phase_next;
    reg       data_phase, data_phase_next;
    reg       ack_phase, ack_phase_next;
    reg       start_phase, start_phase_next;
    reg       stop_phase, stop_phase_next;
    reg       wait_phase, wait_phase_next;
    reg       scl_high, scl_high_next;
    reg       sda_high, sda_high_next;
    reg       scl_stable, scl_stable_next;
    reg       sda_stable, sda_stable_next;
    reg       scl_was_high, scl_was_high_next;
    reg       sda_was_high, sda_was_high_next;
    reg       scl_was_low, scl_was_low_next;
    reg       sda_was_low, sda_was_low_next;
    reg       scl_rising, scl_rising_next;
    reg       scl_falling, scl_falling_next;
    reg       sda_rising, sda_rising_next;
    reg       sda_falling, sda_falling_next;
    reg       start_detected, start_detected_next;
    reg       stop_detected, stop_detected_next;
    reg       scl_i_reg, scl_i_reg_next;
    reg       sda_i_reg, sda_i_reg_next;
    reg       scl_i_d1, scl_i_d1_next;
    reg       sda_i_d1, sda_i_d1_next;
    reg       scl_i_d2, scl_i_d2_next;
    reg       sda_i_d2, sda_i_d2_next;
    reg       scl_i_d3, scl_i_d3_next;
    reg       sda_i_d3, sda_i_d3_next;
    reg       scl_i_d4, scl_i_d4_next;
    reg       sda_i_d4, sda_i_d4_next;
    reg       sda_i_d5, sda_i_d5_next;
    reg       scl_i_d5, scl_i_d5_next;
    reg       sda_i_d6, sda_i_d6_next;
    reg       scl_i_d6, scl_i_d6_next;
    reg       sda_i_d7, sda_i_d7_next;
    reg       scl_i_d7, scl_i_d7_next;
    reg       sda_i_d8, sda_i_d8_next;
    reg       scl_i_d8, scl_i_d8_next;
    reg       sda_i_d9, sda_i_d9_next;
    reg       scl_i_d9, scl_i_d9_next;
    reg       sda_i_d10, sda_i_d10_next;
    reg       scl_i_d10, scl_i_d10_next;
    reg       sda_i_d11, sda_i_d11_next;
    reg       scl_i_d11, scl_i_d11_next;
    reg       sda_i_d12, sda_i_d12_next;
    reg       scl_i_d12, scl_i_d12_next;
    reg       sda_i_d13, sda_i_d13_next;
    reg       scl_i_d13, scl_i_d13_next;
    reg       sda_i_d14, sda_i_d14_next;
    reg       scl_i_d14, scl_i_d14_next;
    reg       sda_i_d15, sda_i_d15_next;
    reg       scl_i_d15, scl_i_d15_next;
    reg       sda_i_d16, sda_i_d16_next;
    reg       scl_i_d16, scl_i_d16_next;
    reg       sda_i_d17, sda_i_d17_next;
    reg       scl_i_d17, scl_i_d17_next;
    reg       sda_i_d18, sda_i_d18_next;
    reg       scl_i_d18, scl_i_d18_next;
    reg       sda_i_d19, sda_i_d19_next;
    reg       scl_i_d19, scl_i_d19_next;
    reg       sda_i_d20, sda_i_d20_next;
    reg       scl_i_d20, scl_i_d20_next;
    reg       sda_i_d21, sda_i_d21_next;
    reg       scl_i_d21, scl_i_d21_next;
    reg       sda_i_d22, sda_i_d22_next;
    reg       scl_i_d22, scl_i_d22_next;
    reg       sda_i_d23, sda_i_d23_next;
    reg       scl_i_d23, scl_i_d23_next;
    reg       sda_i_d24, sda_i_d24_next;
    reg       scl_i_d24, scl_i_d24_next;
    reg       sda_i_d25, sda_i_d25_next;
    reg       scl_i_d25, scl_i_d25_next;
    reg       sda_i_d26, sda_i_d26_next;
    reg       scl_i_d26, scl_i_d26_next;
    reg       sda_i_d27, sda_i_d27_next;
    reg       scl_i_d27, scl_i_d27_next;
    reg       sda_i_d28, sda_i_d28_next;
    reg       scl_i_d28, scl_i_d28_next;
    reg       sda_i_d29, sda_i_d29_next;
    reg       scl_i_d29, scl_i_d29_next;
    reg       sda_i_d30, sda_i_d30_next;
    reg       scl_i_d30, scl_i_d30_next;
    reg       sda_i_d31, sda_i_d31_next;
    reg       scl_i_d31, scl_i_d31_next;
    reg       sda_i_d32, sda_i_d32_next;
    reg       scl_i_d32, scl_i_d32_next;
    reg       sda_i_d33, sda_i_d33_next;
    reg       scl_i_d33, scl_i_d33_next;
    reg       sda_i_d34, sda_i_d34_next;
    reg       scl_i_d34, scl_i_d34_next;
    reg       sda_i_d35, sda_i_d35_next;
    reg       scl_i_d35, scl_i_d35_next;
    reg       sda_i_d36, sda_i_d36_next;
    reg       scl_i_d36, scl_i_d36_next;
    reg       sda_i_d37, sda_i_d37_next;
    reg       scl_i_d37, scl_i_d37_next;
    reg       sda_i_d38, sda_i_d38_next;
    reg       scl_i_d38, scl_i_d38_next;
    reg       sda_i_d39, sda_i_d39_next;
    reg       scl_i_d39, scl_i_d39_next;
    reg       sda_i_d40, sda_i_d40_next;
    reg       scl_i_d40, scl_i_d40_next;
    reg       sda_i_d41, sda_i_d41_next;
    reg       scl_i_d41, scl_i_d41_next;
    reg       sda_i_d42, sda_i_d42_next;
    reg       scl_i_d42, scl_i_d42_next;
    reg       sda_i_d43, sda_i_d43_next;
    reg       scl_i_d43, scl_i_d43_next;
    reg       sda_i_d44, sda_i_d44_next;
    reg       scl_i_d44, scl_i_d44_next;
    reg       sda_i_d45, sda_i_d45_next;
    reg       scl_i_d45, scl_i_d45_next;
    reg       sda_i_d46, sda_i_d46_next;
    reg       scl_i_d46, scl_i_d46_next;
    reg       sda_i_d47, sda_i_d47_next;
    reg       scl_i_d47, scl_i_d47_next;
    reg       sda_i_d48, sda_i_d48_next;
    reg       scl_i_d48, scl_i_d48_next;
    reg       sda_i_d49, sda_i_d49_next;
    reg       scl_i_d49, scl_i_d49_next;
    reg       sda_i_d50, sda_i_d50_next;
    reg       scl_i_d50, scl_i_d50_next;
    reg       sda_i_d51, sda_i_d51_next;
    reg       scl_i_d51, scl_i_d51_next;
    reg       sda_i_d52, sda_i_d52_next;
    reg       scl_i_d52, scl_i_d52_next;
    reg       sda_i_d53, sda_i_d53_next;
    reg       scl_i_d53, scl_i_d53_next;
    reg       sda_i_d54, sda_i_d54_next;
    reg       scl_i_d54, scl_i_d54_next;
    reg       sda_i_d55, sda_i_d55_next;
    reg       scl_i_d55, scl_i_d55_next;
    reg       sda_i_d56, sda_i_d56_next;
    reg       scl_i_d56, scl_i_d56_next;
    reg       sda_i_d57, sda_i_d57_next;
    reg       scl_i_d57, scl_i_d57_next;
    reg       sda_i_d58, sda_i_d58_next;
    reg       scl_i_d58, scl_i_d58_next;
    reg       sda_i_d59, sda_i_d59_next;
    reg       scl_i_d59, scl_i_d59_next;
    reg       sda_i_d60, sda_i_d60_next;
    reg       scl_i_d60, scl_i_d60_next;
    reg       sda_i_d61, sda_i_d61_next;
    reg       scl_i_d61, scl_i_d61_next;
    reg       sda_i_d62, sda_i_d62_next;
    reg       scl_i_d62, scl_i_d62_next;
    reg       sda_i_d63, sda_i_d63_next;
    reg       scl_i_d63, scl_i_d63_next;

    // Simplified state machine
    localparam ST_IDLE = 3'd0;
    localparam ST_START = 3'd1;
    localparam ST_ADDR = 3'd2;
    localparam ST_DATA = 3'd3;
    localparam ST_ACK = 3'd4;
    localparam ST_STOP = 3'd5;
    localparam ST_DONE = 3'd6;

    reg [2:0] fsm_state, fsm_state_next;
    reg [15:0] tick_counter, tick_counter_next;
    reg [7:0] tx_shift, tx_shift_next;
    reg [7:0] rx_shift, rx_shift_next;
    reg [2:0] bit_idx, bit_idx_next;
    reg       scl_out, scl_out_next;
    reg       sda_out, sda_out_next;
    reg       scl_en, scl_en_next;
    reg       sda_en, sda_en_next;
    reg       scl_released, scl_released_next;
    reg       sda_released, sda_released_next;
    reg       busy_out, busy_out_next;
    reg       bus_ctrl_out, bus_ctrl_out_next;
    reg       bus_act_out, bus_act_out_next;
    reg       miss_ack_out, miss_ack_out_next;
    reg       cmd_valid_reg, cmd_valid_reg_next;
    reg       cmd_start_reg, cmd_start_reg_next;
    reg       cmd_read_reg, cmd_read_reg_next;
    reg       cmd_write_reg, cmd_write_reg_next;
    reg       cmd_wmulti_reg, cmd_wmulti_reg_next;
    reg       cmd_stop_reg, cmd_stop_reg_next;
    reg [6:0] addr_reg, addr_reg_next;
    reg       data_valid_reg, data_valid_reg_next;
    reg       data_last_reg, data_last_reg_next;
    reg [7:0] data_out_reg, data_out_reg_next;
    reg       data_last_out, data_last_out_next;
    reg       data_valid_out, data_valid_out_next;
    reg       ack_bit, ack_bit_next;
    reg       phase, phase_next;
    reg       scl_high_phase, scl_high_phase_next;
    reg       sda_high_phase, sda_high_phase_next;
    reg       scl_low_phase, scl_low_phase_next;
    reg       sda_low_phase, sda_low_phase_next;
    reg       scl_stable_phase, scl_stable_phase_next;
    reg       sda_stable_phase, sda_stable_phase_next;
    reg       scl_rising_edge, scl_rising_edge_next;
    reg       scl_falling_edge, scl_falling_edge_next;
    reg       sda_rising_edge, sda_rising_edge_next;
    reg       sda_falling_edge, sda_falling_edge_next;
    reg       start_cond, start_cond_next;
    reg       stop_cond, stop_cond_next;
    reg       scl_i_sample, scl_i_sample_next;
    reg       sda_i_sample, sda_i_sample_next;
    reg       scl_i_d1_reg, scl_i_d1_reg_next;
    reg       sda_i_d1_reg, sda_i_d1_reg_next;
    reg       scl_i_d2_reg, scl_i_d2_reg_next;
    reg       sda_i_d2_reg, sda_i_d2_reg_next;
    reg       scl_i_d3_reg, scl_i_d3_reg_next;
    reg       sda_i_d3_reg, sda_i_d3_reg_next;
    reg       scl_i_d4_reg, scl_i_d4_reg_next;
    reg       sda_i_d4_reg, sda_i_d4_reg_next;
    reg       scl_i_d5_reg, scl_i_d5_reg_next;
    reg       sda_i_d5_reg, sda_i_d5_reg_next;
    reg       scl_i_d6_reg, scl_i_d6_reg_next;
    reg       sda_i_d6_reg, sda_i_d6_reg_next;
    reg       scl_i_d7_reg, scl_i_d7_reg_next;
    reg       sda_i_d7_reg, sda_i_d7_reg_next;
    reg       scl_i_d8_reg, scl_i_d8_reg_next;
    reg       sda_i_d8_reg, sda_i_d8_reg_next;
    reg       scl_i_d9_reg, scl_i_d9_reg_next;
    reg       sda_i_d9_reg, sda_i_d9_reg_next;
    reg       scl_i_d10_reg, scl_i_d10_reg_next;
    reg       sda_i_d10_reg, sda_i_d10_reg_next;
    reg       scl_i_d11_reg, scl_i_d11_reg_next;
    reg       sda_i_d11_reg, sda_i_d11_reg_next;
    reg       scl_i_d12_reg, scl_i_d12_reg_next;
    reg       sda_i_d12_reg, sda_i_d12_reg_next;
    reg       scl_i_d13_reg, scl_i_d13_reg_next;
    reg       sda_i_d13_reg, sda_i_d13_reg_next;
    reg       scl_i_d14_reg, scl_i_d14_reg_next;
    reg       sda_i_d14_reg, sda_i_d14_reg_next;
    reg       scl_i_d15_reg, scl_i_d15_reg_next;
    reg       sda_i_d15_reg, sda_i_d15_reg_next;
    reg       scl_i_d16_reg, scl_i_d16_reg_next;
    reg       sda_i_d16_reg, sda_i_d16_reg_next;
    reg       scl_i_d17_reg, scl_i_d17_reg_next;
    reg       sda_i_d17_reg, sda_i_d17_reg_next;
    reg       scl_i_d18_reg, scl_i_d18_reg_next;
    reg       sda_i_d18_reg, sda_i_d18_reg_next;
    reg       scl_i_d19_reg, scl_i_d19_reg_next;
    reg       sda_i_d19_reg, sda_i_d19_reg_next;
    reg       scl_i_d20_reg, scl_i_d20_reg_next;
    reg       sda_i_d20_reg, sda_i_d20_reg_next;
    reg       scl_i_d21_reg, scl_i_d21_reg_next;
    reg       sda_i_d21_reg, sda_i_d21_reg_next;
    reg       scl_i_d22_reg, scl_i_d22_reg_next;
    reg       sda_i_d22_reg, sda_i_d22_reg_next;
    reg       scl_i_d23_reg, scl_i_d23_reg_next;
    reg       sda_i_d23_reg, sda_i_d23_reg_next;
    reg       scl_i_d24_reg, scl_i_d24_reg_next;
    reg       sda_i_d24_reg, sda_i_d24_reg_next;
    reg       scl_i_d25_reg, scl_i_d25_reg_next;
    reg       sda_i_d25_reg, sda_i_d25_reg_next;
    reg       scl_i_d26_reg, scl_i_d26_reg_next;
    reg       sda_i_d26_reg, sda_i_d26_reg_next;
    reg       scl_i_d27_reg, scl_i_d27_reg_next;
    reg       sda_i_d27_reg, sda_i_d27_reg_next;
    reg       scl_i_d28_reg, scl_i_d28_reg_next;
    reg       sda_i_d28_reg, sda_i_d28_reg_next;
    reg       scl_i_d29_reg, scl_i_d29_reg_next;
    reg       sda_i_d29_reg, sda_i_d29_reg_next;
    reg       scl_i_d30_reg, scl_i_d30_reg_next;
    reg       sda_i_d30_reg, sda_i_d30_reg_next;
    reg       scl_i_d31_reg, scl_i_d31_reg_next;
    reg       sda_i_d31_reg, sda_i_d31_reg_next;
    reg       scl_i_d32_reg, scl_i_d32_reg_next;
    reg       sda_i_d32_reg, sda_i_d32_reg_next;
    reg       scl_i_d33_reg, scl_i_d33_reg_next;
    reg       sda_i_d33_reg, sda_i_d33_reg_next;
    reg       scl_i_d34_reg, scl_i_d34_reg_next;
    reg       sda_i_d34_reg, sda_i_d34_reg_next;
    reg       scl_i_d35_reg, scl_i_d35_reg_next;
    reg       sda_i_d35_reg, sda_i_d35_reg_next;
    reg       scl_i_d36_reg, scl_i_d36_reg_next;
    reg       sda_i_d36_reg, sda_i_d36_reg_next;
    reg       scl_i_d37_reg, scl_i_d37_reg_next;
    reg       sda_i_d37_reg, sda_i_d37_reg_next;
    reg       scl_i_d38_reg, scl_i_d38_reg_next;
    reg       sda_i_d38_reg, sda_i_d38_reg_next;
    reg       scl_i_d39_reg, scl_i_d39_reg_next;
    reg       sda_i_d39_reg, sda_i_d39_reg_next;
    reg       scl_i_d40_reg, scl_i_d40_reg_next;
    reg       sda_i_d40_reg, sda_i_d40_reg_next;
    reg       scl_i_d41_reg, scl_i_d41_reg_next;
    reg       sda_i_d41_reg, sda_i_d41_reg_next;
    reg       scl_i_d42_reg, scl_i_d42_reg_next;
    reg       sda_i_d42_reg, sda_i_d42_reg_next;
    reg       scl_i_d43_reg, scl_i_d43_reg_next;
    reg       sda_i_d43_reg, sda_i_d43_reg_next;
    reg       scl_i_d44_reg, scl_i_d44_reg_next;
    reg       sda_i_d44_reg, sda_i_d44_reg_next;
    reg       scl_i_d45_reg, scl_i_d45_reg_next;
    reg       sda_i_d45_reg, sda_i_d45_reg_next;
    reg       scl_i_d46_reg, scl_i_d46_reg_next;
    reg       sda_i_d46_reg, sda_i_d46_reg_next;
    reg       scl_i_d47_reg, scl_i_d47_reg_next;
    reg       sda_i_d47_reg, sda_i_d47_reg_next;
    reg       scl_i_d48_reg, scl_i_d48_reg_next;
    reg       sda_i_d48_reg, sda_i_d48_reg_next;
    reg       scl_i_d49_reg, scl_i_d49_reg_next;
    reg       sda_i_d49_reg, sda_i_d49_reg_next;
    reg       scl_i_d50_reg, scl_i_d50_reg_next;
    reg       sda_i_d50_reg, sda_i_d50_reg_next;
    reg       scl_i_d51_reg, scl_i_d51_reg_next;
    reg       sda_i_d51_reg, sda_i_d51_reg_next;
    reg       scl_i_d52_reg, scl_i_d52_reg_next;
    reg       sda_i_d52_reg, sda_i_d52_reg_next;
    reg       scl_i_d53_reg, scl_i_d53_reg_next;
    reg       sda_i_d53_reg, sda_i_d53_reg_next;
    reg       scl_i_d54_reg, scl_i_d54_reg_next;
    reg       sda_i_d54_reg, sda_i_d54_reg_next;
    reg       scl_i_d55_reg, scl_i_d55_reg_next;
    reg       sda_i_d55_reg, sda_i_d55_reg_next;
    reg       scl_i_d56_reg, scl_i_d56_reg_next;
    reg       sda_i_d56_reg, sda_i_d56_reg_next;
    reg       scl_i_d57_reg, scl_i_d57_reg_next;
    reg       sda_i_d57_reg, sda_i_d57_reg_next;
    reg       scl_i_d58_reg, scl_i_d58_reg_next;
    reg       sda_i_d58_reg, sda_i_d58_reg_next;
    reg       scl_i_d59_reg, scl_i_d59_reg_next;
    reg       sda_i_d59_reg, sda_i_d59_reg_next;
    reg       scl_i_d60_reg, scl_i_d60_reg_next;
    reg       sda_i_d60_reg, sda_i_d60_reg_next;
    reg       scl_i_d61_reg, scl_i_d61_reg_next;
    reg       sda_i_d61_reg, sda_i_d61_reg_next;
    reg       scl_i_d62_reg, scl_i_d62_reg_next;
    reg       sda_i_d62_reg, sda_i_d62_reg_next;
    reg       scl_i_d63_reg, scl_i_d63_reg_next;
    reg       sda_i_d63_reg, sda_i_d63_reg_next;

    // Simplified implementation
    localparam IDLE = 3'd0;
    localparam START = 3'd1;
    localparam ADDR = 3'd2;
    localparam DATA = 3'd3;
    localparam ACK = 3'd4;
    localparam STOP = 3'd5;
    localparam DONE = 3'd6;

    reg [2:0] cur_state, nxt_state;
    reg [15:0] cnt, cnt_next;
    reg [7:0] tx_data, tx_data_next;
    reg [7:0] rx_data, rx_data_next;
    reg [2:0] bit_cnt, bit_cnt_next;
    reg scl_drv, scl_drv_next;
    reg sda_drv, sda_drv_next;
    reg scl_tristate, scl_tristate_next;
    reg sda_tristate, sda_tristate_next;
    reg busy_sig, busy_sig_next;
    reg bus_ctrl_sig, bus_ctrl_sig_next;
    reg bus_act_sig, bus_act_sig_next;
    reg miss_ack_sig, miss_ack_sig_next;
    reg cmd_valid_latch, cmd_valid_latch_next;
    reg cmd_start_latch, cmd_start_latch_next;
    reg cmd_read_latch, cmd_read_latch_next;
    reg cmd_write_latch, cmd_write_latch_next;
    reg cmd_wmulti_latch, cmd_wmulti_latch_next;
    reg cmd_stop_latch, cmd_stop_latch_next;
    reg [6:0] addr_latch, addr_latch_next;
    reg data_valid_latch, data_valid_latch_next;
    reg data_last_latch, data_last_latch_next;
    reg [7:0] data_out_latch, data_out_latch_next;
    reg data_last_out_sig, data_last_out_sig_next;
    reg data_valid_out_sig, data_valid_out_sig_next;
    reg ack_bit_reg, ack_bit_reg_next;
    reg phase_reg, phase_reg_next;
    reg scl_high_reg, scl_high_reg_next;
    reg sda_high_reg, sda_high_reg_next;
    reg scl_low_reg, scl_low_reg_next;
    reg sda_low_reg, sda_low_reg_next;
    reg scl_stable_reg, scl_stable_reg_next;
    reg sda_stable_reg, sda_stable_reg_next;
    reg scl_rise_reg, scl_rise_reg_next;
    reg scl_fall_reg, scl_fall_reg_next;
    reg sda_rise_reg, sda_rise_reg_next;
    reg sda_fall_reg, sda_fall_reg_next;
    reg start_cond_reg, start_cond_reg_next;
    reg stop_cond_reg, stop_cond_reg_next;
    reg scl_i_smp, scl_i_smp_next;
    reg sda_i_smp, sda_i_smp_next;
    reg scl_i_d1, scl_i_d1_next;
    reg sda_i_d1, sda_i_d1_next;
    reg scl_i_d2, scl_i_d2_next;
    reg sda_i_d2, sda_i_d2_next;
    reg scl_i_d3, scl_i_d3_next;
    reg sda_i_d3, sda_i_d3_next;
    reg scl_i_d4, scl_i_d4_next;
    reg sda_i_d4, sda_i_d4_next;
    reg scl_i_d5, scl_i_d5_next;
    reg sda_i_d5, sda_i_d5_next;
    reg scl_i_d6, scl_i_d6_next;
    reg sda_i_d6, sda_i_d6_next;
    reg scl_i_d7, scl_i_d7_next;
    reg sda_i_d7, sda_i_d7_next;
    reg scl_i_d8, scl_i_d8_next;
    reg sda_i_d8, sda_i_d8_next;
    reg scl_i_d9, scl_i_d9_next;
    reg sda_i_d9, sda_i_d9_next;
    reg scl_i_d10, scl_i_d10_next;
    reg sda_i_d10, sda_i_d10_next;
    reg scl_i_d11, scl_i_d11_next;
    reg sda_i_d11, sda_i_d11_next;
    reg scl_i_d12, scl_i_d12_next;
    reg sda_i_d12, sda_i_d12_next;
    reg scl_i_d13, scl_i_d13_next;
    reg sda_i_d13, sda_i_d13_next;
    reg scl_i_d14, scl_i_d14_next;
    reg sda_i_d14, sda_i_d14_next;
    reg scl_i_d15, scl_i_d15_next;
    reg sda_i_d15, sda_i_d15_next;
    reg scl_i_d16, scl_i_d16_next;
    reg sda_i_d16, sda_i_d16_next;
    reg scl_i_d17, scl_i_d17_next;
    reg sda_i_d17, sda_i_d17_next;
    reg scl_i_d18, scl_i_d18_next;
    reg sda_i_d18, sda_i_d18_next;
    reg scl_i_d19, scl_i_d19_next;
    reg sda_i_d19, sda_i_d19_next;
    reg scl_i_d20, scl_i_d20_next;
    reg sda_i_d20, sda_i_d20_next;
    reg scl_i_d21, scl_i_d21_next;
    reg sda_i_d21, sda_i_d21_next;
    reg scl_i_d22, scl_i_d22_next;
    reg sda_i_d22, sda_i_d22_next;
    reg scl_i_d23, scl_i_d23_next;
    reg sda_i_d23, sda_i_d23_next;
    reg scl_i_d24, scl_i_d24_next;
    reg sda_i_d24, sda_i_d24_next;
    reg scl_i_d25, scl_i_d25_next;
    reg sda_i_d25, sda_i_d25_next;
    reg scl_i_d26, scl_i_d26_next;
    reg sda_i_d26, sda_i_d26_next;
    reg scl_i_d27, scl_i_d27_next;
    reg sda_i_d27, sda_i_d27_next;
    reg scl_i_d28, scl_i_d28_next;
    reg sda_i_d28, sda_i_d28_next;
    reg scl_i_d29, scl_i_d29_next;
    reg sda_i_d29, sda_i_d29_next;
    reg scl_i_d30, scl_i_d30_next;
    reg sda_i_d30, sda_i_d30_next;
    reg scl_i_d31, scl_i_d31_next;
    reg sda_i_d31, sda_i_d31_next;
    reg scl_i_d32, scl_i_d32_next;
    reg sda_i_d32, sda_i_d32_next;
    reg scl_i_d33, scl_i_d33_next;
    reg sda_i_d33, sda_i_d33_next;
    reg scl_i_d34, scl_i_d34_next;
    reg sda