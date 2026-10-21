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

    // ========================================================================
    // Internal Signals
    // ========================================================================

    // State Machine States
    localparam IDLE = 3'd0;
    localparam START = 3'd1;
    localparam ADDR_SENT = 3'd2;
    localparam ACK_CHECK = 3'd3;
    localparam DATA_WRITE = 3'd4;
    localparam DATA_READ = 3'd5;
    localparam STOP_SENT = 3'd6;
    localparam STOP_WAIT = 3'd7;
    localparam BUS_ERROR = 3'd8;

    reg [2:0] state;

    // State Registers
    reg [7:0]  cmd_addr;
    reg        cmd_read;
    reg        cmd_write;
    reg        cmd_write_multiple;
    reg        cmd_stop;
    reg        cmd_valid;
    reg        cmd_ready;
    
    reg        data_valid;
    reg        data_ready;
    reg        data_last;
    reg [7:0]  data_in;
    reg        data_out;
    reg        data_out_valid;
    reg        data_out_last;
    reg        data_out_ready;

    reg        scl_state; // 0: Low, 1: High
    reg        sda_state; // 0: Low, 1: High
    reg        scl_edge;  // 1: Falling edge of SCL
    reg        sda_edge;  // 1: Falling edge of SDA
    reg        scl_high;  // Current SCL level
    reg        sda_high;  // Current SDA level
    reg        scl_rising; // SCL rising edge
    reg        sda_rising; // SDA rising edge
    reg        scl_falling; // SCL falling edge
    reg        sda_falling; // SDA falling edge

    reg        scl_timer;
    reg        sda_timer;
    reg        scl_count;
    reg        sda_count;
    reg        prescale_val;
    reg        prescale_count;
    reg        prescale_done;
    reg        scl_period;
    reg        sda_period;
    reg        scl_high_time;
    reg        sda_high_time;
    reg        scl_low_time;
    reg        sda_low_time;

    reg        scl_next;
    reg        sda_next;
    reg        scl_pulse;
    reg        sda_pulse;
    reg        scl_hold;
    reg        sda_hold;

    reg        ack_received;
    reg        ack_timeout;
    reg        bus_error_flag;
    reg        stop_flag;
    reg        idle_flag;
    reg        stop_on_idle_flag;

    // ========================================================================
    // Combinational Logic
    // ========================================================================

    always @(*) begin
        scl_o = 1'b1;
        sda_o = 1'b1;
        scl_t = 1'b1;
        sda_t = 1'b1;
        busy = 1'b0;
        bus_control = 1'b0;
        bus_active = 1'b0;
        missed_ack = 1'b0;
        scl_state = scl_state;
        sda_state = sda_state;
        scl_count = scl_count;
        sda_count = sda_count;
        prescale_count = prescale_count;
        scl_next = scl_state;
        sda_next = sda_state;
        scl_pulse = 1'b0;
        sda_pulse = 1'b0;
        scl_hold = 1'b0;
        sda_hold = 1'b0;
        data_out = 8'd0;
        data_out_valid = 1'b0;
        data_out_last = 1'b0;
        data_out_ready = 1'b0;
        data_ready = 1'b0;
        data_valid = 1'b0;
        data_last = 1'b0;
        data_in = 8'd0;
        cmd_ready = 1'b0;
        cmd_valid = 1'b0;
        ack_received = 1'b0;
        ack_timeout = 1'b0;
        bus_error_flag = 1'b0;
        stop_flag = 1'b0;
        idle_flag = 1'b0;
        stop_on_idle_flag = 1'b0;
        
        case (state)
            IDLE: begin
                idle_flag = 1'b1;
                if (stop_on_idle_flag) stop_flag = 1'b1;
                if (s_axis_cmd_valid) begin
                    cmd_ready = 1'b1;
                    cmd_valid = 1'b1;
                    cmd_addr = s_axis_cmd_address;
                    cmd_read = s_axis_cmd_read;
                    cmd_write = s_axis_cmd_write;
                    cmd_write_multiple = s_axis_cmd_write_multiple;
                    cmd_stop = s_axis_cmd_stop;
                    data_valid = 1'b1;
                    data_last = s_axis_data_tlast;
                    data_in = s_axis_data_tdata;
                    data_out_ready = 1'b1;
                end
            end

            START: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    state = ADDR_SENT;
                end
            end

            ADDR_SENT: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    state = ACK_CHECK;
                end
            end

            ACK_CHECK: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    if (sda_falling) begin
                        ack_received = 1'b1;
                        missed_ack = 1'b0;
                        if (cmd_write || cmd_write_multiple) begin
                            state = DATA_WRITE;
                        end else begin
                            state = DATA_READ;
                        end
                    end else begin
                        ack_received = 1'b0;
                        missed_ack = 1'b1;
                        bus_error_flag = 1'b1;
                        state = STOP_SENT;
                    end
                end
            end

            DATA_WRITE: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    if (sda_falling) begin
                        ack_received = 1'b1;
                        missed_ack = 1'b0;
                        if (data_valid) begin
                            data_out = data_in;
                            data_out_valid = 1'b1;
                            data_out_last = data_last;
                            data_valid = 1'b0;
                            data_last = 1'b0;
                            data_in = 8'd0;
                            data_out_ready = 1'b0;
                            if (cmd_write_multiple) begin
                                state = DATA_WRITE;
                            end else begin
                                state = STOP_SENT;
                            end
                        end else begin
                            state = STOP_SENT;
                        end
                    end else begin
                        ack_received = 1'b0;
                        missed_ack = 1'b1;
                        bus_error_flag = 1'b1;
                        state = STOP_SENT;
                    end
                end
            end

            DATA_READ: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    if (sda_falling) begin
                        ack_received = 1'b1;
                        missed_ack = 1'b0;
                        if (data_out_valid) begin
                            data_out_ready = 1'b1;
                            if (m_axis_data_tready) begin
                                m_axis_data_tdata = data_out;
                                m_axis_data_tvalid = 1'b1;
                                m_axis_data_tlast = data_out_last;
                                data_out_valid = 1'b0;
                                data_out_last = 1'b0;
                                data_out_ready = 1'b0;
                                if (data_out_last) begin
                                    state = STOP_SENT;
                                end else begin
                                    state = DATA_READ;
                                end
                            end else begin
                                data_out_ready = 1'b0;
                            end
                        end else begin
                            state = STOP_SENT;
                        end
                    end else begin
                        ack_received = 1'b0;
                        missed_ack = 1'b1;
                        bus_error_flag = 1'b1;
                        state = STOP_SENT;
                    end
                end
            end

            STOP_SENT: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    if (sda_rising) begin
                        stop_flag = 1'b1;
                        state = STOP_WAIT;
                    end
                end
            end

            STOP_WAIT: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    if (sda_rising) begin
                        stop_flag = 1'b1;
                        state = IDLE;
                    end
                end
            end

            BUS_ERROR: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    if (sda_rising) begin
                        stop_flag = 1'b1;
                        state = IDLE;
                    end
                end
            end
        endcase
    end

    // ========================================================================
    // Sequential Logic
    // ========================================================================

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            scl_state <= 1'b1;
            sda_state <= 1'b1;
            scl_count <= 0;
            sda_count <= 0;
            prescale_count <= 0;
            scl_high_time <= 0;
            sda_high_time <= 0;
            scl_low_time <= 0;
            sda_low_time <= 0;
            ack_received <= 1'b0;
            ack_timeout <= 1'b0;
            bus_error_flag <= 1'b0;
            stop_flag <= 1'b0;
            idle_flag <= 1'b0;
            stop_on_idle_flag <= 1'b0;
            scl_next <= 1'b1;
            sda_next <= 1'b1;
            scl_pulse <= 1'b0;
            sda_pulse <= 1'b0;
            scl_hold <= 1'b0;
            sda_hold <= 1'b0;
            data_out_valid <= 1'b0;
            data_out_last <= 1'b0;
            data_out_ready <= 1'b0;
            data_ready <= 1'b0;
            data_valid <= 1'b0;
            data_last <= 1'b0;
            data_in <= 8'd0;
            cmd_ready <= 1'b0;
            cmd_valid <= 1'b0;
            missed_ack <= 1'b0;
            busy <= 1'b0;
            bus_control <= 1'b0;
            bus_active <= 1'b0;
        end else begin
            state <= state;
            scl_state <= scl_next;
            sda_state <= sda_next;
            scl_count <= scl_count + 1;
            sda_count <= sda_count + 1;
            prescale_count <= prescale_count + 1;
            scl_high_time <= scl_high_time + 1;
            sda_high_time <= sda_high_time + 1;
            scl_low_time <= scl_low_time + 1;
            sda_low_time <= sda_low_time + 1;
            ack_received <= ack_received;
            ack_timeout <= ack_timeout;
            bus_error_flag <= bus_error_flag;
            stop_flag <= stop_flag;
            idle_flag <= idle_flag;
            stop_on_idle_flag <= stop_on_idle_flag;
            scl_next <= scl_next;
            sda_next <= sda_next;
            scl_pulse <= scl_pulse;
            sda_pulse <= sda_pulse;
            scl_hold <= scl_hold;
            sda_hold <= sda_hold;
            data_out_valid <= data_out_valid;
            data_out_last <= data_out_last;
            data_out_ready <= data_out_ready;
            data_ready <= data_ready;
            data_valid <= data_valid;
            data_last <= data_last;
            data_in <= data_in;
            cmd_ready <= cmd_ready;
            cmd_valid <= cmd_valid;
            missed_ack <= missed_ack;
            busy <= busy;
            bus_control <= bus_control;
            bus_active <= bus_active;
        end
    end

    // ========================================================================
    // Timing Control
    // ========================================================================

    always @(*) begin
        prescale_val = prescale;
        scl_period = prescale_val;
        sda_period = prescale_val;
        scl_high_time = prescale_val / 2;
        sda_high_time = prescale_val / 2;
        scl_low_time = prescale_val / 2;
        sda_low_time = prescale_val / 2;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prescale_count <= 0;
        end else begin
            if (prescale_count < prescale_val - 1) begin
                prescale_count <= prescale_count + 1;
            end else begin
                prescale_count <= 0;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_count <= 0;
            sda_count <= 0;
        end else begin
            if (scl_count < scl_period - 1) begin
                scl_count <= scl_count + 1;
            end else begin
                scl_count <= 0;
            end
            if (sda_count < sda_period - 1) begin
                sda_count <= sda_count + 1;
            end else begin
                sda_count <= 0;
            end
        end
    end

    // ========================================================================
    // Output Drivers
    // ========================================================================

    always @(*) begin
        scl_o = 1'b1;
        sda_o = 1'b1;
        scl_t = 1'b1;
        sda_t = 1'b1;
        busy = 1'b0;
        bus_control = 1'b0;
        bus_active = 1'b0;
        missed_ack = 1'b0;
        
        case (state)
            IDLE: begin
                if (stop_on_idle_flag) begin
                    scl_o = 1'b0;
                    sda_o = 1'b1;
                    scl_t = 1'b0;
                    sda_t = 1'b1;
                    busy = 1'b1;
                    bus_control = 1'b1;
                    bus_active = 1'b1;
                end
            end

            START: begin
                scl_o = 1'b0;
                sda_o = 1'b1;
                scl_t = 1'b0;
                sda_t = 1'b1;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
            end

            ADDR_SENT: begin
                scl_o = 1'b0;
                sda_o = 1'b0;
                scl_t = 1'b0;
                sda_t = 1'b0;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
            end

            ACK_CHECK: begin
                scl_o = 1'b0;
                sda_o = 1'b0;
                scl_t = 1'b0;
                sda_t = 1'b0;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
            end

            DATA_WRITE: begin
                scl_o = 1'b0;
                sda_o = data_out;
                scl_t = 1'b0;
                sda_t = data_out;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
            end

            DATA_READ: begin
                scl_o = 1'b0;
                sda_o = 1'b1;
                scl_t = 1'b0;
                sda_t = 1'b1;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
            end

            STOP_SENT: begin
                scl_o = 1'b0;
                sda_o = 1'b1;
                scl_t = 1'b0;
                sda_t = 1'b1;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
            end

            STOP_WAIT: begin
                scl_o = 1'b0;
                sda_o = 1'b1;
                scl_t = 1'b0;
                sda_t = 1'b1;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
            end

            BUS_ERROR: begin
                scl_o = 1'b0;
                sda_o = 1'b0;
                scl_t = 1'b0;
                sda_t = 1'b0;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
                missed_ack = 1'b1;
            end
        endcase
    end

    // ========================================================================
    // Edge Detection
    // ========================================================================

    always @(*) begin
        scl_edge = 1'b0;
        sda_edge = 1'b0;
        scl_rising = 1'b0;
        sda_rising = 1'b0;
        scl_falling = 1'b0;
        sda_falling = 1'b0;
        
        if (scl_i != scl_state) begin
            if (scl_i == 1'b1) scl_rising = 1'b1;
            else scl_falling = 1'b1;
        end
        if (sda_i != sda_state) begin
            if (sda_i == 1'b1) sda_rising = 1'b1;
            else sda_falling = 1'b1;
        end
    end

    // ========================================================================
    // State Machine Logic
    // ========================================================================

    always @(*) begin
        scl_next = scl_state;
        sda_next = sda_state;
        scl_pulse = 1'b0;
        sda_pulse = 1'b0;
        scl_hold = 1'b0;
        sda_hold = 1'b0;
        data_ready = 1'b0;
        data_valid = 1'b0;
        data_last = 1'b0;
        data_in = 8'd0;
        cmd_ready = 1'b0;
        cmd_valid = 1'b0;
        ack_received = 1'b0;
        ack_timeout = 1'b0;
        bus_error_flag = 1'b0;
        stop_flag = 1'b0;
        idle_flag = 1'b0;
        stop_on_idle_flag = 1'b0;
        
        case (state)
            IDLE: begin
                idle_flag = 1'b1;
                if (stop_on_idle_flag) stop_flag = 1'b1;
                if (s_axis_cmd_valid) begin
                    cmd_ready = 1'b1;
                    cmd_valid = 1'b1;
                    cmd_addr = s_axis_cmd_address;
                    cmd_read = s_axis_cmd_read;
                    cmd_write = s_axis_cmd_write;
                    cmd_write_multiple = s_axis_cmd_write_multiple;
                    cmd_stop = s_axis_cmd_stop;
                    data_valid = 1'b1;
                    data_last = s_axis_data_tlast;
                    data_in = s_axis_data_tdata;
                    data_out_ready = 1'b1;
                end
            end

            START: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    state = ADDR_SENT;
                end
            end

            ADDR_SENT: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    state = ACK_CHECK;
                end
            end

            ACK_CHECK: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    if (sda_falling) begin
                        ack_received = 1'b1;
                        missed_ack = 1'b0;
                        if (cmd_write || cmd_write_multiple) begin
                            state = DATA_WRITE;
                        end else begin
                            state = DATA_READ;
                        end
                    end else begin
                        ack_received = 1'b0;
                        missed_ack = 1'b1;
                        bus_error_flag = 1'b1;
                        state = STOP_SENT;
                    end
                end
            end

            DATA_WRITE: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    if (sda_falling) begin
                        ack_received = 1'b1;
                        missed_ack = 1'b0;
                        if (data_valid) begin
                            data_out = data_in;
                            data_out_valid = 1'b1;
                            data_out_last = data_last;
                            data_valid = 1'b0;
                            data_last = 1'b0;
                            data_in = 8'd0;
                            data_out_ready = 1'b0;
                            if (cmd_write_multiple) begin
                                state = DATA_WRITE;
                            end else begin
                                state = STOP_SENT;
                            end
                        end else begin
                            state = STOP_SENT;
                        end
                    end else begin
                        ack_received = 1'b0;
                        missed_ack = 1'b1;
                        bus_error_flag = 1'b1;
                        state = STOP_SENT;
                    end
                end
            end

            DATA_READ: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    if (sda_falling) begin
                        ack_received = 1'b1;
                        missed_ack = 1'b0;
                        if (data_out_valid) begin
                            data_out_ready = 1'b1;
                            if (m_axis_data_tready) begin
                                m_axis_data_tdata = data_out;
                                m_axis_data_tvalid = 1'b1;
                                m_axis_data_tlast = data_out_last;
                                data_out_valid = 1'b0;
                                data_out_last = 1'b0;
                                data_out_ready = 1'b0;
                                if (data_out_last) begin
                                    state = STOP_SENT;
                                end else begin
                                    state = DATA_READ;
                                end
                            end else begin
                                data_out_ready = 1'b0;
                            end
                        end else begin
                            state = STOP_SENT;
                        end
                    end else begin
                        ack_received = 1'b0;
                        missed_ack = 1'b1;
                        bus_error_flag = 1'b1;
                        state = STOP_SENT;
                    end
                end
            end

            STOP_SENT: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    if (sda_rising) begin
                        stop_flag = 1'b1;
                        state = STOP_WAIT;
                    end
                end
            end

            STOP_WAIT: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    if (sda_rising) begin
                        stop_flag = 1'b1;
                        state = IDLE;
                    end
                end
            end

            BUS_ERROR: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    if (sda_rising) begin
                        stop_flag = 1'b1;
                        state = IDLE;
                    end
                end
            end
        endcase
    end

    // ========================================================================
    // Output Drivers
    // ========================================================================

    always @(*) begin
        scl_o = 1'b1;
        sda_o = 1'b1;
        scl_t = 1'b1;
        sda_t = 1'b1;
        busy = 1'b0;
        bus_control = 1'b0;
        bus_active = 1'b0;
        missed_ack = 1'b0;
        
        case (state)
            IDLE: begin
                if (stop_on_idle_flag) begin
                    scl_o = 1'b0;
                    sda_o = 1'b1;
                    scl_t = 1'b0;
                    sda_t = 1'b1;
                    busy = 1'b1;
                    bus_control = 1'b1;
                    bus_active = 1'b1;
                end
            end

            START: begin
                scl_o = 1'b0;
                sda_o = 1'b1;
                scl_t = 1'b0;
                sda_t = 1'b1;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
            end

            ADDR_SENT: begin
                scl_o = 1'b0;
                sda_o = 1'b0;
                scl_t = 1'b0;
                sda_t = 1'b0;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
            end

            ACK_CHECK: begin
                scl_o = 1'b0;
                sda_o = 1'b0;
                scl_t = 1'b0;
                sda_t = 1'b0;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
            end

            DATA_WRITE: begin
                scl_o = 1'b0;
                sda_o = data_out;
                scl_t = 1'b0;
                sda_t = data_out;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
            end

            DATA_READ: begin
                scl_o = 1'b0;
                sda_o = 1'b1;
                scl_t = 1'b0;
                sda_t = 1'b1;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
            end

            STOP_SENT: begin
                scl_o = 1'b0;
                sda_o = 1'b1;
                scl_t = 1'b0;
                sda_t = 1'b1;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
            end

            STOP_WAIT: begin
                scl_o = 1'b0;
                sda_o = 1'b1;
                scl_t = 1'b0;
                sda_t = 1'b1;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
            end

            BUS_ERROR: begin
                scl_o = 1'b0;
                sda_o = 1'b0;
                scl_t = 1'b0;
                sda_t = 1'b0;
                busy = 1'b1;
                bus_control = 1'b1;
                bus_active = 1'b1;
                missed_ack = 1'b1;
            end
        endcase
    end

    // ========================================================================
    // Edge Detection
    // ========================================================================

    always @(*) begin
        scl_edge = 1'b0;
        sda_edge = 1'b0;
        scl_rising = 1'b0;
        sda_rising = 1'b0;
        scl_falling = 1'b0;
        sda_falling = 1'b0;
        
        if (scl_i != scl_state) begin
            if (scl_i == 1'b1) scl_rising = 1'b1;
            else scl_falling = 1'b1;
        end
        if (sda_i != sda_state) begin
            if (sda_i == 1'b1) sda_rising = 1'b1;
            else sda_falling = 1'b1;
        end
    end

    // ========================================================================
    // State Machine Logic
    // ========================================================================

    always @(*) begin
        scl_next = scl_state;
        sda_next = sda_state;
        scl_pulse = 1'b0;
        sda_pulse = 1'b0;
        scl_hold = 1'b0;
        sda_hold = 1'b0;
        data_ready = 1'b0;
        data_valid = 1'b0;
        data_last = 1'b0;
        data_in = 8'd0;
        cmd_ready = 1'b0;
        cmd_valid = 1'b0;
        ack_received = 1'b0;
        ack_timeout = 1'b0;
        bus_error_flag = 1'b0;
        stop_flag = 1'b0;
        idle_flag = 1'b0;
        stop_on_idle_flag = 1'b0;
        
        case (state)
            IDLE: begin
                idle_flag = 1'b1;
                if (stop_on_idle_flag) stop_flag = 1'b1;
                if (s_axis_cmd_valid) begin
                    cmd_ready = 1'b1;
                    cmd_valid = 1'b1;
                    cmd_addr = s_axis_cmd_address;
                    cmd_read = s_axis_cmd_read;
                    cmd_write = s_axis_cmd_write;
                    cmd_write_multiple = s_axis_cmd_write_multiple;
                    cmd_stop = s_axis_cmd_stop;
                    data_valid = 1'b1;
                    data_last = s_axis_data_tlast;
                    data_in = s_axis_data_tdata;
                    data_out_ready = 1'b1;
                end
            end

            START: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    state = ADDR_SENT;
                end
            end

            ADDR_SENT: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    state = ACK_CHECK;
                end
            end

            ACK_CHECK: begin
                idle_flag = 1'b0;
                if (scl_falling) begin
                    scl_state = 1'b0;
                    sda_state = 1'b0;
                    scl_next = 1'b1;
                    sda_next = 1'b1;
                    if (sda_falling) begin
                        ack_received = 1'b1;
                        missed_ack = 1'b0