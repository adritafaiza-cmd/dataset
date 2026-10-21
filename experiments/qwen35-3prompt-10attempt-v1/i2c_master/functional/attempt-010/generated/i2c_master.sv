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
        IDLE,
        START,
        SEND_ADDR,
        SEND_ADDR_ACK,
        SEND_DATA,
        SEND_DATA_ACK,
        SEND_DATA_NACK,
        SEND_DATA_STOP,
        WAIT_ACK,
        WAIT_NACK,
        STOP,
        STOP_WAIT,
        READ_DATA,
        READ_DATA_ACK,
        READ_DATA_NACK,
        READ_DATA_STOP,
        WAIT_STOP,
        IDLE_STOP
    } state_t;

    state_t state, next_state;
    logic    cmd_valid_reg;
    logic    cmd_ready_reg;
    logic    data_valid_reg;
    logic    data_ready_reg;
    logic    data_last_reg;
    logic    data_tdata_reg;
    logic    busy_reg;
    logic    missed_ack_reg;
    logic    stop_on_idle_reg;

    // ==================================================================
    // Command Interface Logic
    // ==================================================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_valid_reg <= 1'b0;
            cmd_ready_reg <= 1'b0;
        end else begin
            cmd_valid_reg <= s_axis_cmd_valid;
            cmd_ready_reg <= 1'b0; // Will be updated in combinational logic
        end
    end

    assign s_axis_cmd_ready = cmd_ready_reg;

    always_comb begin
        cmd_ready_reg = 1'b0;
        if (cmd_valid_reg) begin
            // Check if command is valid and not conflicting
            if (s_axis_cmd_start || s_axis_cmd_stop || 
                (s_axis_cmd_write && !s_axis_cmd_write_multiple) ||
                s_axis_cmd_write_multiple ||
                s_axis_cmd_read) begin
                cmd_ready_reg = 1'b1;
            end
        end
    end

    // ==================================================================
    // Data Interface Logic
    // ==================================================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            data_valid_reg <= 1'b0;
            data_ready_reg <= 1'b0;
            data_last_reg  <= 1'b0;
            data_tdata_reg <= 8'h00;
        end else begin
            data_valid_reg <= s_axis_data_tvalid;
            data_ready_reg <= 1'b0; // Will be updated in combinational logic
            data_last_reg  <= s_axis_data_tlast;
            data_tdata_reg <= s_axis_data_tdata;
        end
    end

    assign s_axis_data_tready = data_ready_reg;

    always_comb begin
        data_ready_reg = 1'b0;
        if (data_valid_reg) begin
            // Data is ready if we are expecting data (write or read)
            // and not in a state where we need to send data
            if (state == SEND_DATA || state == READ_DATA || 
                state == SEND_DATA_ACK || state == READ_DATA_ACK ||
                state == SEND_DATA_NACK || state == READ_DATA_NACK ||
                state == SEND_DATA_STOP || state == READ_DATA_STOP) begin
                data_ready_reg = 1'b1;
            end
        end
    end

    // ==================================================================
    // I2C Timing Control
    // ==================================================================
    // prescale is used to generate SCL frequency. 
    // Assuming prescale[15:0] defines the number of clock cycles for one SCL period.
    // High state duration = prescale[14:0], Low state duration = prescale[14:0]
    // Total period = prescale[15:0] * 2 (approx) or simply prescale[15:0] for half period.
    // Let's interpret prescale as the number of clk cycles for one SCL high time.
    // SCL period = 2 * prescale[14:0] + 1? 
    // Standard interpretation: prescale = number of clk cycles for SCL high.
    // We will use a counter to generate the SCL waveform.
    
    logic [15:0] scl_counter;
    logic        scl_high;
    logic        scl_edge;
    logic        sda_edge;
    logic        sda_state; // 0: low, 1: high
    logic        scl_state; // 0: low, 1: high
    logic        sda_driven; // 1: master driving, 0: open drain (input)
    logic        scl_driven; // 1: master driving, 0: open drain (input)
    
    // SCL Counter
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_counter <= 16'd0;
            scl_state   <= 1'b0;
        end else begin
            if (scl_driven) begin
                if (scl_counter == prescale) begin
                    scl_counter <= 16'd0;
                    scl_state   <= ~scl_state;
                end else begin
                    scl_counter <= scl_counter + 1'b1;
                end
            end else begin
                // If not driven, follow input scl_i
                scl_state <= scl_i;
                if (scl_i) scl_counter <= 16'd0; // Reset counter on rising edge of input if needed, 
                                                  // but usually we just mirror.
            end
        end
    end

    assign scl_o = scl_state;
    assign scl_t = scl_state; // Tri-state not needed for output, just drive logic
    assign scl_driven = (state != IDLE && state != IDLE_STOP && state != STOP_WAIT);

    // SDA Edge Detection
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sda_state <= 1'b0;
        end else begin
            sda_state <= sda_i;
        end
    end

    assign sda_edge = (sda_i & ~sda_state) | (~sda_i & sda_state);
    assign sda_driven = (state != IDLE && state != IDLE_STOP && state != STOP_WAIT);

    // ==================================================================
    // State Machine Logic
    // ==================================================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            missed_ack_reg <= 1'b0;
            busy_reg <= 1'b0;
            bus_control <= 1'b0;
            bus_active <= 1'b0;
            m_axis_data_tvalid <= 1'b0;
            m_axis_data_tlast <= 1'b0;
            m_axis_data_tdata <= 8'h00;
        end else begin
            state <= next_state;
            missed_ack_reg <= missed_ack_reg; // Hold previous value
            busy_reg <= (state != IDLE && state != IDLE_STOP && state != STOP_WAIT);
            bus_control <= (state != IDLE && state != IDLE_STOP && state != STOP_WAIT);
            bus_active <= (state != IDLE && state != IDLE_STOP && state != STOP_WAIT);
            
            // Output Data
            if (state == READ_DATA_ACK || state == READ_DATA_NACK || state == READ_DATA_STOP) begin
                m_axis_data_tvalid <= 1'b1;
                m_axis_data_tdata  <= data_tdata_reg;
                m_axis_data_tlast  <= data_last_reg;
            end else begin
                m_axis_data_tvalid <= 1'b0;
                m_axis_data_tlast  <= 1'b0;
                m_axis_data_tdata  <= 8'h00;
            end
        end
    end

    assign missed_ack = missed_ack_reg;

    always_comb begin
        next_state = state;
        missed_ack_reg = 1'b0;
        data_last_reg  = 1'b0; // Reset last flag unless coming from data interface
        data_tdata_reg = 8'h00;

        case (state)
            IDLE: begin
                if (s_axis_cmd_valid && s_axis_cmd_ready) begin
                    if (s_axis_cmd_start) next_state = START;
                    else if (s_axis_cmd_stop) next_state = STOP;
                    else if (s_axis_cmd_write) next_state = SEND_ADDR;
                    else if (s_axis_cmd_write_multiple) next_state = SEND_ADDR;
                    else if (s_axis_cmd_read) next_state = SEND_ADDR;
                end
                if (stop_on_idle && s_axis_cmd_valid && s_axis_cmd_ready && s_axis_cmd_stop) next_state = STOP;
            end

            START: begin
                // Wait for SCL low
                if (scl_state == 1'b0 && sda_edge) begin
                    // Start condition: SCL low, SDA high->low
                    next_state = SEND_ADDR;
                    // Drive SDA low
                    sda_o = 1'b0;
                    sda_t = 1'b0;
                end
            end

            SEND_ADDR: begin
                // Drive SDA low
                sda_o = 1'b0;
                sda_t = 1'b0;
                
                // Wait for SCL low
                if (scl_state == 1'b0 && sda_edge) begin
                    // Send Address MSB
                    sda_o = (s_axis_cmd_address[7]);
                    sda_t = (s_axis_cmd_address[7]);
                    next_state = WAIT_ACK;
                end
            end

            WAIT_ACK: begin
                // Wait for SCL low
                if (scl_state == 1'b0 && sda_edge) begin
                    // Check ACK (SDA low) or NACK (SDA high)
                    if (sda_i == 1'b0) begin
                        // ACK received
                        if (s_axis_cmd_write || s_axis_cmd_write_multiple) begin
                            next_state = SEND_DATA;
                            // Prepare data
                            data_last_reg = s_axis_data_tlast;
                            data_tdata_reg = s_axis_data_tdata;
                        end else if (s_axis_cmd_read) begin
                            next_state = READ_DATA;
                            // Prepare data
                            data_last_reg = s_axis_data_tlast;
                            data_tdata_reg = s_axis_data_tdata;
                        end else begin
                            next_state = STOP;
                        end
                    end else begin
                        // NACK received
                        missed_ack_reg = 1'b1;
                        next_state = STOP;
                    end
                end
            end

            SEND_DATA: begin
                // Drive SDA with data
                sda_o = data_tdata_reg;
                sda_t = data_tdata_reg;
                
                // Wait for SCL low
                if (scl_state == 1'b0 && sda_edge) begin
                    // Check ACK
                    if (sda_i == 1'b0) begin
                        if (data_last_reg) begin
                            next_state = READ_DATA; // Switch to read mode after last byte
                        end else begin
                            next_state = SEND_DATA_ACK;
                        end
                    end else begin
                        missed_ack_reg = 1'b1;
                        next_state = STOP;
                    end
                end
            end

            SEND_DATA_ACK: begin
                // Wait for SCL low
                if (scl_state == 1'b0 && sda_edge) begin
                    // Check ACK
                    if (sda_i == 1'b0) begin
                        if (data_last_reg) begin
                            next_state = READ_DATA;
                        end else begin
                            next_state = SEND_DATA_ACK; // Loop for more data
                        end
                    end else begin
                        missed_ack_reg = 1'b1;
                        next_state = STOP;
                    end
                end
            end

            SEND_DATA_NACK: begin
                // Wait for SCL low
                if (scl_state == 1'b0 && sda_edge) begin
                    // Check NACK
                    if (sda_i == 1'b1) begin
                        next_state = STOP;
                    end else begin
                        missed_ack_reg = 1'b1;
                        next_state = STOP;
                    end
                end
            end

            SEND_DATA_STOP: begin
                // Drive SDA with data
                sda_o = data_tdata_reg;
                sda_t = data_tdata_reg;
                
                // Wait for SCL low
                if (scl_state == 1'b0 && sda_edge) begin
                    // Check ACK
                    if (sda_i == 1'b0) begin
                        next_state = STOP;
                    end else begin
                        missed_ack_reg = 1'b1;
                        next_state = STOP;
                    end
                end
            end

            READ_DATA: begin
                // Drive SDA high (clocking in data)
                sda_o = 1'b1;
                sda_t = 1'b1;
                
                // Wait for SCL low
                if (scl_state == 1'b0 && sda_edge) begin
                    // Check ACK
                    if (sda_i == 1'b0) begin
                        if (data_last_reg) begin
                            next_state = READ_DATA_STOP;
                        end else begin
                            next_state = READ_DATA_ACK;
                        end
                    end else begin
                        missed_ack_reg = 1'b1;
                        next_state = STOP;
                    end
                end
            end

            READ_DATA_ACK: begin
                // Drive SDA high
                sda_o = 1'b1;
                sda_t = 1'b1;
                
                // Wait for SCL low
                if (scl_state == 1'b0 && sda_edge) begin
                    // Check ACK
                    if (sda_i == 1'b0) begin
                        if (data_last_reg) begin
                            next_state = READ_DATA_STOP;
                        end else begin
                            next_state = READ_DATA_ACK;
                        end
                    end else begin
                        missed_ack_reg = 1'b1;
                        next_state = STOP;
                    end
                end
            end

            READ_DATA_NACK: begin
                // Drive SDA high
                sda_o = 1'b1;
                sda_t = 1'b1;
                
                // Wait for SCL low
                if (scl_state == 1'b0 && sda_edge) begin
                    // Check NACK
                    if (sda_i == 1'b1) begin
                        next_state = STOP;
                    end else begin
                        missed_ack_reg = 1'b1;
                        next_state = STOP;
                    end
                end
            end

            READ_DATA_STOP: begin
                // Drive SDA high
                sda_o = 1'b1;
                sda_t = 1'b1;
                
                // Wait for SCL low
                if (scl_state == 1'b0 && sda_edge) begin
                    // Check ACK
                    if (sda_i == 1'b0) begin
                        next_state = STOP;
                    end else begin
                        missed_ack_reg = 1'b1;
                        next_state = STOP;
                    end
                end
            end

            STOP: begin
                // Wait for SCL low
                if (scl_state == 1'b0 && sda_edge) begin
                    // Send Stop condition: SDA low->high while SCL high
                    sda_o = 1'b0;
                    sda_t = 1'b0;
                    next_state = STOP_WAIT;
                end
            end

            STOP_WAIT: begin
                // Wait for SCL low
                if (scl_state == 1'b0 && sda_edge) begin
                    // SCL low, SDA low
                    sda_o = 1'b1;
                    sda_t = 1'b1;
                    next_state = IDLE_STOP;
                end
            end

            IDLE_STOP: begin
                // Wait for SCL low
                if (scl_state == 1'b0 && sda_edge) begin
                    // SCL low, SDA high
                    sda_o = 1'b1;
                    sda_t = 1'b1;
                    next_state = IDLE;
                end
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // ==================================================================
    // Output Drivers (Open Drain Simulation)
    // ==================================================================
    // Since this is Verilog-2001 and we need to simulate open-drain behavior with inputs,
    // we use a simple logic gate approach.
    // If master drives low, output is 0.
    // If master drives high (or idle), output is sda_i (if available) or 1 (if no input).
    // However, the problem statement asks for scl_o, scl_t, sda_o, sda_t.
    // Typically, 'o' is the net, 't' is the tri-state value.
    // We will implement the drivers using continuous assignments with logic.
    
    // SCL Driver
    assign scl_o = (scl_driven) ? 1'b0 : (scl_i);
    assign scl_t = (scl_driven) ? 1'b0 : 1'b1;

    // SDA Driver
    assign sda_o = (sda_driven) ? 1'b0 : (sda_i);
    assign sda_t = (sda_driven) ? 1'b0 : 1'b1;

    // Note: In a real hardware implementation, open-drain would be implemented with transistors.
    // In simulation, we assume the input scl_i/sda_i is present when the master is not driving.
    // If the master is driving, it forces the line low.
    // If the master is not driving, it reflects the input.
    // This assumes the external circuit provides the pull-up and the slave input.

endmodule
```<|im_end|>
