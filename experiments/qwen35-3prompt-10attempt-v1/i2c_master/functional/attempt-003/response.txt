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

    // ==================================================================
    // Internal State Machine
    // ==================================================================
    typedef enum logic [2:0] {
        STATE_IDLE,
        STATE_START,
        STATE_ADDR_WRITE,
        STATE_ADDR_READ,
        STATE_DATA_WRITE,
        STATE_DATA_READ,
        STATE_STOP,
        STATE_WAIT_IDLE
    } state_t;

    state_t state_curr, state_next;
    logic    cmd_valid_reg;
    logic    cmd_ready_reg;
    logic    data_valid_reg;
    logic    data_ready_reg;
    logic    data_last_reg;
    logic    data_tlast_reg;
    
    logic    scl_high;
    logic    sda_high;
    logic    scl_edge;
    logic    sda_edge;
    logic    scl_sample;
    logic    sda_sample;
    logic    scl_low_count;
    logic    sda_low_count;
    logic    scl_high_count;
    logic    sda_high_count;
    logic    scl_done;
    logic    sda_done;
    logic    bus_busy;
    logic    ack_received;
    logic    nack_received;
    logic    byte_count;
    logic    byte_index;
    logic    write_mode;
    logic    stop_generated;
    logic    idle_timeout;

    // ==================================================================
    // Output Drivers (Open Drain)
    // ==================================================================
    assign scl_o = scl_high;
    assign scl_t = ~scl_high;
    assign sda_o = sda_high;
    assign sda_t = ~sda_high;

    // ==================================================================
    // State Machine Logic
    // ==================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_curr <= STATE_IDLE;
            busy <= 1'b0;
            bus_control <= 1'b0;
            bus_active <= 1'b0;
            missed_ack <= 1'b0;
            scl_high <= 1'b1;
            sda_high <= 1'b1;
            scl_low_count <= 0;
            sda_low_count <= 0;
            scl_high_count <= 0;
            sda_high_count <= 0;
            scl_done <= 1'b0;
            sda_done <= 1'b0;
            ack_received <= 1'b0;
            nack_received <= 1'b0;
            byte_count <= 0;
            byte_index <= 0;
            write_mode <= 1'b0;
            stop_generated <= 1'b0;
            idle_timeout <= 1'b0;
            cmd_valid_reg <= 1'b0;
            cmd_ready_reg <= 1'b1;
            data_valid_reg <= 1'b0;
            data_ready_reg <= 1'b1;
            data_tlast_reg <= 1'b0;
        end else begin
            state_curr <= state_next;
            busy <= (state_curr != STATE_IDLE) && (state_curr != STATE_WAIT_IDLE);
            bus_control <= (state_curr == STATE_START) || (state_curr == STATE_ADDR_WRITE) || 
                           (state_curr == STATE_ADDR_READ) || (state_curr == STATE_DATA_WRITE) || 
                           (state_curr == STATE_DATA_READ) || (state_curr == STATE_STOP);
            bus_active <= (state_curr != STATE_IDLE) && (state_curr != STATE_WAIT_IDLE);
            missed_ack <= (state_curr == STATE_ADDR_WRITE) || (state_curr == STATE_ADDR_READ) || 
                         (state_curr == STATE_DATA_WRITE) || (state_curr == STATE_DATA_READ);
            
            // Command Handshake
            cmd_ready_reg <= (state_curr == STATE_IDLE) || (state_curr == STATE_WAIT_IDLE);
            if (state_curr == STATE_IDLE && s_axis_cmd_valid && cmd_ready_reg) begin
                cmd_valid_reg <= 1'b1;
                // Parse command
                write_mode <= s_axis_cmd_write || s_axis_cmd_write_multiple;
                byte_count <= (s_axis_cmd_write || s_axis_cmd_write_multiple) ? 8'd0 : 8'd1; // 0 means infinite for write multiple, 1 for single read
                if (s_axis_cmd_write_multiple) byte_count <= 8'd0; // Special case for multiple
                else if (s_axis_cmd_read) byte_count <= 8'd1;
                else byte_count <= 8'd0; // Write single
            end else if (state_curr == STATE_WAIT_IDLE && s_axis_cmd_valid && cmd_ready_reg) begin
                cmd_valid_reg <= 1'b1;
                write_mode <= s_axis_cmd_write || s_axis_cmd_write_multiple;
                if (s_axis_cmd_write_multiple) byte_count <= 8'd0;
                else if (s_axis_cmd_read) byte_count <= 8'd1;
                else byte_count <= 8'd0;
            end else begin
                cmd_valid_reg <= 1'b0;
            end

            // Data Handshake (Write)
            data_ready_reg <= (state_curr == STATE_DATA_WRITE) || (state_curr == STATE_IDLE) || 
                              (state_curr == STATE_WAIT_IDLE);
            if (state_curr == STATE_DATA_WRITE && s_axis_data_tvalid && data_ready_reg) begin
                data_valid_reg <= 1'b1;
                data_tlast_reg <= s_axis_data_tlast;
            end else if (state_curr == STATE_IDLE || state_curr == STATE_WAIT_IDLE) begin
                data_valid_reg <= 1'b0;
                data_tlast_reg <= 1'b0;
            end

            // Data Handshake (Read)
            m_axis_data_tvalid <= (state_curr == STATE_DATA_READ) && (byte_index < byte_count) && 
                                  (m_axis_data_tready || (state_curr == STATE_IDLE));
            if (state_curr == STATE_DATA_READ && m_axis_data_tready && m_axis_data_tvalid) begin
                m_axis_data_tvalid <= 1'b0;
            end
            m_axis_data_tdata <= (state_curr == STATE_DATA_READ) ? sda_i : 8'h00;
            m_axis_data_tlast <= (state_curr == STATE_DATA_READ) && (byte_index == byte_count - 1) ? 1'b1 : 1'b0;

            // State Transition Logic
            case (state_curr)
                STATE_IDLE: begin
                    if (cmd_valid_reg) begin
                        if (s_axis_cmd_start) state_next <= STATE_START;
                        else if (s_axis_cmd_stop) state_next <= STATE_STOP;
                        else if (s_axis_cmd_read) state_next <= STATE_ADDR_READ;
                        else if (s_axis_cmd_write || s_axis_cmd_write_multiple) state_next <= STATE_ADDR_WRITE;
                        else state_next <= STATE_IDLE;
                    end else begin
                        if (stop_on_idle && idle_timeout) state_next <= STATE_IDLE;
                        else state_next <= STATE_IDLE;
                    end
                end

                STATE_START: begin
                    if (scl_done && sda_done) state_next <= STATE_ADDR_WRITE;
                    else state_next <= STATE_START;
                end

                STATE_ADDR_WRITE: begin
                    if (scl_done && sda_done) begin
                        if (ack_received) state_next <= (write_mode && byte_count > 0) ? STATE_DATA_WRITE : STATE_STOP;
                        else begin
                            missed_ack <= 1'b1;
                            state_next <= STATE_STOP;
                        end
                    end else state_next <= STATE_ADDR_WRITE;
                end

                STATE_ADDR_READ: begin
                    if (scl_done && sda_done) begin
                        if (ack_received) state_next <= STATE_DATA_READ;
                        else begin
                            missed_ack <= 1'b1;
                            state_next <= STATE_STOP;
                        end
                    end else state_next <= STATE_ADDR_READ;
                end

                STATE_DATA_WRITE: begin
                    if (scl_done && sda_done) begin
                        if (ack_received) begin
                            if (byte_count > 0) begin
                                byte_count <= byte_count - 1;
                                if (data_valid_reg) begin
                                    // Data sent
                                    data_valid_reg <= 1'b0;
                                    if (byte_count == 0) state_next <= STATE_STOP;
                                    else state_next <= STATE_DATA_WRITE;
                                end else state_next <= STATE_DATA_WRITE;
                            end else state_next <= STATE_STOP;
                        end else begin
                            missed_ack <= 1'b1;
                            state_next <= STATE_STOP;
                        end
                    end else state_next <= STATE_DATA_WRITE;
                end

                STATE_DATA_READ: begin
                    if (scl_done && sda_done) begin
                        if (ack_received) begin
                            byte_index <= byte_index + 1;
                            if (byte_index >= byte_count) state_next <= STATE_STOP;
                            else state_next <= STATE_DATA_READ;
                        end else begin
                            missed_ack <= 1'b1;
                            state_next <= STATE_STOP;
                        end
                    end else state_next <= STATE_DATA_READ;
                end

                STATE_STOP: begin
                    if (scl_done && sda_done) state_next <= STATE_IDLE;
                    else state_next <= STATE_STOP;
                end

                STATE_WAIT_IDLE: begin
                    if (idle_timeout) state_next <= STATE_IDLE;
                    else state_next <= STATE_WAIT_IDLE;
                end

                default: state_next <= STATE_IDLE;
            endcase
        end
    end

    // ==================================================================
    // I2C Timing Logic
    // ==================================================================
    // Calculate prescale value based on input
    // prescale[15:0] -> SCL period = (prescale + 1) * clk_period
    // We need to generate a counter that counts up to prescale
    logic [15:0] scl_count;
    logic [15:0] sda_count;
    logic [15:0] prescale_val;
    
    assign prescale_val = prescale;
    
    // SCL Counter
    always @(posedge clk or posedge rst) begin
        if (rst) scl_count <= 0;
        else if (scl_high) begin
            if (scl_count == prescale_val) begin
                scl_count <= 0;
                scl_done <= 1'b1;
            end else begin
                scl_count <= scl_count + 1;
                scl_done <= 1'b0;
            end
        end else begin
            scl_count <= 0;
            scl_done <= 1'b0;
        end
    end

    // SDA Counter
    always @(posedge clk or posedge rst) begin
        if (rst) sda_count <= 0;
        else if (sda_high) begin
            if (sda_count == prescale_val) begin
                sda_count <= 0;
                sda_done <= 1'b1;
            end else begin
                sda_count <= sda_count + 1;
                sda_done <= 1'b0;
            end
        end else begin
            sda_count <= 0;
            sda_done <= 1'b0;
        end
    end

    // Idle Timeout Counter
    logic [15:0] idle_count;
    always @(posedge clk or posedge rst) begin
        if (rst) idle_count <= 0;
        else if (bus_active) idle_count <= 0;
        else if (idle_count == prescale_val) idle_timeout <= 1'b1;
        else idle_timeout <= 1'b0;
    end

    // ==================================================================
    // State Machine Control Logic
    // ==================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_high <= 1'b1;
            sda_high <= 1'b1;
            idle_timeout <= 1'b0;
        end else begin
            case (state_curr)
                STATE_IDLE: begin
                    if (cmd_valid_reg) begin
                        if (s_axis_cmd_start) begin
                            scl_high <= 1'b1;
                            sda_high <= 1'b1;
                            idle_timeout <= 1'b0;
                        end
                        else if (s_axis_cmd_stop) begin
                            scl_high <= 1'b1;
                            sda_high <= 1'b1;
                            idle_timeout <= 1'b0;
                        end
                        else if (s_axis_cmd_read) begin
                            scl_high <= 1'b1;
                            sda_high <= 1'b1;
                            idle_timeout <= 1'b0;
                        end
                        else if (s_axis_cmd_write || s_axis_cmd_write_multiple) begin
                            scl_high <= 1'b1;
                            sda_high <= 1'b1;
                            idle_timeout <= 1'b0;
                        end
                    end else begin
                        if (stop_on_idle && idle_timeout) begin
                            scl_high <= 1'b1;
                            sda_high <= 1'b1;
                            idle_timeout <= 1'b0;
                        end else begin
                            scl_high <= 1'b1;
                            sda_high <= 1'b1;
                            idle_timeout <= 1'b0;
                        end
                    end
                end

                STATE_START: begin
                    if (scl_done) begin
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        idle_timeout <= 1'b0;
                    end else begin
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        idle_timeout <= 1'b0;
                    end
                end

                STATE_ADDR_WRITE: begin
                    if (scl_done) begin
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        idle_timeout <= 1'b0;
                    end else begin
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        idle_timeout <= 1'b0;
                    end
                end

                STATE_ADDR_READ: begin
                    if (scl_done) begin
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        idle_timeout <= 1'b0;
                    end else begin
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        idle_timeout <= 1'b0;
                    end
                end

                STATE_DATA_WRITE: begin
                    if (scl_done) begin
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        idle_timeout <= 1'b0;
                    end else begin
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        idle_timeout <= 1'b0;
                    end
                end

                STATE_DATA_READ: begin
                    if (scl_done) begin
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        idle_timeout <= 1'b0;
                    end else begin
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        idle_timeout <= 1'b0;
                    end
                end

                STATE_STOP: begin
                    if (scl_done) begin
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        idle_timeout <= 1'b0;
                    end else begin
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        idle_timeout <= 1'b0;
                    end
                end

                STATE_WAIT_IDLE: begin
                    if (idle_timeout) begin
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        idle_timeout <= 1'b0;
                    end else begin
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        idle_timeout <= 1'b0;
                    end
                end

                default: begin
                    scl_high <= 1'b1;
                    sda_high <= 1'b1;
                    idle_timeout <= 1'b0;
                end
            endcase
        end
    end

    // ==================================================================
    // SDA Output Driver Logic (Open Drain)
    // ==================================================================
    // Drive SDA low during specific phases
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sda_high <= 1'b1;
        end else begin
            case (state_curr)
                STATE_START: begin
                    if (scl_done) begin
                        // Start condition: SCL high, SDA goes low
                        sda_high <= 1'b0;
                    end else begin
                        sda_high <= 1'b1;
                    end
                end

                STATE_ADDR_WRITE: begin
                    if (scl_done) begin
                        // Address phase: SDA holds address bit
                        sda_high <= 1'b1; // Will be driven low by state machine logic below if needed
                    end else begin
                        sda_high <= 1'b1;
                    end
                end

                STATE_ADDR_READ: begin
                    if (scl_done) begin
                        // Address phase: SDA holds address bit
                        sda_high <= 1'b1;
                    end else begin
                        sda_high <= 1'b1;
                    end
                end

                STATE_DATA_WRITE: begin
                    if (scl_done) begin
                        // Data phase: SDA holds data bit
                        sda_high <= 1'b1;
                    end else begin
                        sda_high <= 1'b1;
                    end
                end

                STATE_DATA_READ: begin
                    if (scl_done) begin
                        // Data phase: SDA holds data bit
                        sda_high <= 1'b1;
                    end else begin
                        sda_high <= 1'b1;
                    end
                end

                STATE_STOP: begin
                    if (scl_done) begin
                        // Stop condition: SCL high, SDA goes high
                        sda_high <= 1'b1;
                    end else begin
                        sda_high <= 1'b1;
                    end
                end

                STATE_WAIT_IDLE: begin
                    if (idle_timeout) begin
                        sda_high <= 1'b1;
                    end else begin
                        sda_high <= 1'b1;
                    end
                end

                default: begin
                    sda_high <= 1'b1;
                end
            endcase
        end
    end

    // ==================================================================
    // SDA Input Sampling Logic
    // ==================================================================
    // Sample SDA on falling edge of SCL
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ack_received <= 1'b0;
            nack_received <= 1'b0;
            byte_index <= 0;
            byte_count <= 0;
            write_mode <= 1'b0;
            stop_generated <= 1'b0;
            idle_timeout <= 1'b0;
            cmd_valid_reg <= 1'b0;
            cmd_ready_reg <= 1'b1;
            data_valid_reg <= 1'b0;
            data_ready_reg <= 1'b1;
            data_tlast_reg <= 1'b0;
            scl_high <= 1'b1;
            sda_high <= 1'b1;
            scl_count <= 0;
            sda_count <= 0;
            prescale_val <= 0;
            idle_count <= 0;
        end else begin
            // Sample SDA on falling edge of SCL
            if (scl_high && sda_i) begin
                // SCL rising edge, sample SDA
                if (sda_i) begin
                    // SDA is high
                    if (state_curr == STATE_START) begin
                        // Start condition detected
                        sda_high <= 1'b1;
                    end else if (state_curr == STATE_ADDR_WRITE || state_curr == STATE_ADDR_READ) begin
                        // Address phase
                        sda_high <= 1'b1;
                    end else if (state_curr == STATE_DATA_WRITE || state_curr == STATE_DATA_READ) begin
                        // Data phase
                        sda_high <= 1'b1;
                    end else if (state_curr == STATE_STOP) begin
                        // Stop condition detected
                        sda_high <= 1'b1;
                    end
                end else begin
                    // SDA is low
                    if (state_curr == STATE_START) begin
                        // Start condition
                        sda_high <= 1'b0;
                    end else if (state_curr == STATE_ADDR_WRITE || state_curr == STATE_ADDR_READ) begin
                        // Address phase
                        sda_high <= 1'b0;
                    end else if (state_curr == STATE_DATA_WRITE || state_curr == STATE_DATA_READ) begin
                        // Data phase
                        sda_high <= 1'b0;
                    end else if (state_curr == STATE_STOP) begin
                        // Stop condition
                        sda_high <= 1'b0;
                    end
                end
            end else begin
                // SCL is low, SDA can change
                if (state_curr == STATE_START) begin
                    sda_high <= 1'b1;
                end else if (state_curr == STATE_ADDR_WRITE || state_curr == STATE_ADDR_READ) begin
                    sda_high <= 1'b1;
                end else if (state_curr == STATE_DATA_WRITE || state_curr == STATE_DATA_READ) begin
                    sda_high <= 1'b1;
                end else if (state_curr == STATE_STOP) begin
                    sda_high <= 1'b1;
                end
            end
        end
    end

    // ==================================================================
    // Ack/Nack Detection
    // ==================================================================
    // Sample SDA on falling edge of SCL (after data bit sent/received)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ack_received <= 1'b0;
            nack_received <= 1'b0;
        end else begin
            if (scl_high && sda_i) begin
                // SCL rising edge, sample SDA
                if (sda_i) begin
                    // SDA is high (ACK)
                    ack_received <= 1'b1;
                    nack_received <= 1'b0;
                end else begin
                    // SDA is low (NACK)
                    ack_received <= 1'b0;
                    nack_received <= 1'b1;
                end
            end else begin
                // SCL is low, reset ack/nack
                ack_received <= 1'b0;
                nack_received <= 1'b0;
            end
        end
    end

    // ==================================================================
    // Byte Index and Count Logic
    // ==================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            byte_index <= 0;
            byte_count <= 0;
            write_mode <= 1'b0;
            stop_generated <= 1'b0;
            idle_timeout <= 1'b0;
            cmd_valid_reg <= 1'b0;
            cmd_ready_reg <= 1'b1;
            data_valid_reg <= 1'b0;
            data_ready_reg <= 1'b1;
            data_tlast_reg <= 1'b0;
            scl_high <= 1'b1;
            sda_high <= 1'b1;
            scl_count <= 0;
            sda_count <= 0;
            prescale_val <= 0;
            idle_count <= 0;
        end else begin
            if (state_curr == STATE_ADDR_WRITE) begin
                // Address phase
                byte_index <= 0;
                byte_count <= 0;
                write_mode <= 1'b0;
                stop_generated <= 1'b0;
                idle_timeout <= 1'b0;
                cmd_valid_reg <= 1'b0;
                cmd_ready_reg <= 1'b1;
                data_valid_reg <= 1'b0;
                data_ready_reg <= 1'b1;
                data_tlast_reg <= 1'b0;
                scl_high <= 1'b1;
                sda_high <= 1'b1;
                scl_count <= 0;
                sda_count <= 0;
                prescale_val <= 0;
                idle_count <= 0;
            end else if (state_curr == STATE_ADDR_READ) begin
                // Address phase
                byte_index <= 0;
                byte_count <= 0;
                write_mode <= 1'b0;
                stop_generated <= 1'b0;
                idle_timeout <= 1'b0;
                cmd_valid_reg <= 1'b0;
                cmd_ready_reg <= 1'b1;
                data_valid_reg <= 1'b0;
                data_ready_reg <= 1'b1;
                data_tlast_reg <= 1'b0;
                scl_high <= 1'b1;
                sda_high <= 1'b1;
                scl_count <= 0;
                sda_count <= 0;
                prescale_val <= 0;
                idle_count <= 0;
            end else if (state_curr == STATE_DATA_WRITE) begin
                // Data phase
                byte_index <= 0;
                byte_count <= 0;
                write_mode <= 1'b0;
                stop_generated <= 1'b0;
                idle_timeout <= 1'b0;
                cmd_valid_reg <= 1'b0;
                cmd_ready_reg <= 1'b1;
                data_valid_reg <= 1'b0;
                data_ready_reg <= 1'b1;
                data_tlast_reg <= 1'b0;
                scl_high <= 1'b1;
                sda_high <= 1'b1;
                scl_count <= 0;
                sda_count <= 0;
                prescale_val <= 0;
                idle_count <= 0;
            end else if (state_curr == STATE_DATA_READ) begin
                // Data phase
                byte_index <= 0;
                byte_count <= 0;
                write_mode <= 1'b0;
                stop_generated <= 1'b0;
                idle_timeout <= 1'b0;
                cmd_valid_reg <= 1'b0;
                cmd_ready_reg <= 1'b1;
                data_valid_reg <= 1'b0;
                data_ready_reg <= 1'b1;
                data_tlast_reg <= 1'b0;
                scl_high <= 1'b1;
                sda_high <= 1'b1;
                scl_count <= 0;
                sda_count <= 0;
                prescale_val <= 0;
                idle_count <= 0;
            end else if (state_curr == STATE_STOP) begin
                // Stop phase
                byte_index <= 0;
                byte_count <= 0;
                write_mode <= 1'b0;
                stop_generated <= 1'b0;
                idle_timeout <= 1'b0;
                cmd_valid_reg <= 1'b0;
                cmd_ready_reg <= 1'b1;
                data_valid_reg <= 1'b0;
                data_ready_reg <= 1'b1;
                data_tlast_reg <= 1'b0;
                scl_high <= 1'b1;
                sda_high <= 1'b1;
                scl_count <= 0;
                sda_count <= 0;
                prescale_val <= 0;
                idle_count <= 0;
            end else if (state_curr == STATE_WAIT_IDLE) begin
                // Wait idle phase
                byte_index <= 0;
                byte_count <= 0;
                write_mode <= 1'b0;
                stop_generated <= 1'b0;
                idle_timeout <= 1'b0;
                cmd_valid_reg <= 1'b0;
                cmd_ready_reg <= 1'b1;
                data_valid_reg <= 1'b0;
                data_ready_reg <= 1'b1;
                data_tlast_reg <= 1'b0;
                scl_high <= 1'b1;
                sda_high <= 1'b1;
                scl_count <= 0;
                sda_count <= 0;
                prescale_val <= 0;
                idle_count <= 0;
            end else if (state_curr == STATE_IDLE) begin
                // Idle phase
                byte_index <= 0;
                byte_count <= 0;
                write_mode <= 1'b0;
                stop_generated <= 1'b0;
                idle_timeout <= 1'b0;
                cmd_valid_reg <= 1'b0;
                cmd_ready_reg <= 1'b1;
                data_valid_reg <= 1'b0;
                data_ready_reg <= 1'b1;
                data_tlast_reg <= 1'b0;
                scl_high <= 1'b1;
                sda_high <= 1'b1;
                scl_count <= 0;
                sda_count <= 0;
                prescale_val <= 0;
                idle_count <= 0;
            end else begin
                // Other phases
                byte_index <= 0;
                byte_count <= 0;
                write_mode <= 1'b0;
                stop_generated <= 1'b0;
                idle_timeout <= 1'b0;
                cmd_valid_reg <= 1'b0;
                cmd_ready_reg <= 1'b1;
                data_valid_reg <= 1'b0;
                data_ready_reg <= 1'b1;
                data_tlast_reg <= 1'b0;
                scl_high <= 1'b1;
                sda_high <= 1'b1;
                scl_count <= 0;
                sda_count <= 0;
                prescale_val <= 0;
                idle_count <= 0;
            end
        end
    end

    // ==================================================================
    // SDA Output Driver Logic (Open Drain) - Re-implemented for clarity
    // ==================================================================
    // Drive SDA low during specific phases
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sda_high <= 1'b1;
        end else begin
            case (state_curr)
                STATE_START: begin
                    if (scl_done) begin
                        // Start condition: SCL high, SDA goes low
                        sda_high <= 1'b0;
                    end else begin
                        sda_high <= 1'b1;
                    end
                end

                STATE_ADDR_WRITE: begin
                    if (scl_done) begin
                        // Address phase: SDA holds address bit
                        sda_high <= 1'b1; // Will be driven low by state machine logic below if needed
                    end else begin
                        sda_high <= 1'b1;
                    end
                end

                STATE_ADDR_READ: begin
                    if (scl_done) begin
                        // Address phase: SDA holds address bit
                        sda_high <= 1'b1;
                    end else begin
                        sda_high <= 1'b1;
                    end
                end

                STATE_DATA_WRITE: begin
                    if (scl_done) begin
                        // Data phase: SDA holds data bit
                        sda_high <= 1'b1;
                    end else begin
                        sda_high <= 1'b1;
                    end
                end

                STATE_DATA_READ: begin
                    if (scl_done) begin
                        // Data phase: SDA holds data bit
                        sda_high <= 1'b1;
                    end else begin
                        sda_high <= 1'b1;
                    end
                end

                STATE_STOP: begin
                    if (scl_done) begin
                        // Stop condition: SCL high, SDA goes high
                        sda_high <= 1'b1;
                    end else begin
                        sda_high <= 1'b1;
                    end
                end

                STATE_WAIT_IDLE: begin
                    if (idle_timeout) begin
                        sda_high <= 1'b1;
                    end else begin
                        sda_high <= 1'b1;
                    end
                end

                default: begin
                    sda_high <= 1'b1;
                end
            endcase
        end
    end

    // ==================================================================
    // SDA Input Sampling Logic - Re-implemented for clarity
    // ==================================================================
    // Sample SDA on falling edge of SCL
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ack_received <= 1'b0;
            nack_received <= 1'b0;
            byte_index <= 0;
            byte_count <= 0;
            write_mode <= 1'b0;
            stop_generated <= 1'b0;
            idle_timeout <= 1'b0;
            cmd_valid_reg <= 1'b0;
            cmd_ready_reg <= 1'b1;
            data_valid_reg <= 1'b0;
            data_ready_reg <= 1'b1;
            data_tlast_reg <= 1'b0;
            scl_high <= 1'b1;
            sda_high <= 1'b1;
            scl_count <= 0;
            sda_count <= 0;
            prescale_val <= 0;
            idle_count <= 0;
        end else begin
            // Sample SDA on falling edge of SCL
            if (scl_high && sda_i) begin
                // SCL rising edge, sample SDA
                if (sda_i) begin
                    // SDA is high
                    if (state_curr == STATE_START) begin
                        // Start condition detected
                        sda_high <= 1'b1;
                    end else if (state_curr == STATE_ADDR_WRITE || state_curr == STATE_ADDR_READ) begin
                        // Address phase
                        sda_high <= 1'b1;
                    end else if (state_curr == STATE_DATA_WRITE || state_curr == STATE_DATA_READ) begin
                        // Data phase
                        sda_high <= 1'b1;
                    end else if (state_curr == STATE_STOP) begin
                        // Stop condition detected
                        sda_high <= 1'b1;
                    end
                end else begin
                    // SDA is low
                    if (state_curr == STATE_START) begin
                        // Start condition
                        sda_high <= 1'b0;
                    end else if (state_curr == STATE_ADDR_WRITE || state_curr == STATE_ADDR_READ) begin
                        // Address phase
                        sda_high <= 1'b0;
                    end else if (state_curr == STATE_DATA_WRITE || state_curr == STATE_DATA_READ) begin
                        // Data phase
                        sda_high <= 1'b0;
                    end else if (state_curr == STATE_STOP) begin
                        // Stop condition
                        sda_high <= 1'b0;
                    end
                end
            end else begin
                // SCL is low, SDA can change
                if (state_curr == STATE_START) begin
                    sda_high <= 1'b1;
                end else