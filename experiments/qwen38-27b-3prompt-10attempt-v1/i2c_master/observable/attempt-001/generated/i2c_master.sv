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
    localparam S_IDLE          = 4'd0;
    localparam S_START         = 4'd1;
    localparam S_SEND_BIT      = 4'd2;
    localparam S_SEND_ACK      = 4'd3;
    localparam S_RECV_BIT      = 4'd4;
    localparam S_RECV_ACK      = 4'd5;
    localparam S_STOP          = 4'd6;
    localparam S_WAIT_ACK      = 4'd7;

    // Registers
    reg [3:0]  state;
    reg [3:0]  bit_count;
    reg [7:0]  tx_byte;
    reg [7:0]  rx_byte;
    reg        is_read;
    reg        is_write;
    reg        is_write_multiple;
    reg        need_stop;
    reg        need_start;
    reg        ack_received;
    reg        missed_ack_reg;
    reg        scl_reg;
    reg        sda_reg;
    reg        scl_t_reg;
    reg        sda_t_reg;
    reg [15:0] prescale_reg;
    reg [15:0] counter;
    reg        counting;
    reg        bit_done;
    reg        byte_done;
    reg        ack_phase;
    reg        send_ack;
    reg        recv_ack;
    reg        stop_on_idle_reg;
    reg        pending_stop;
    reg        pending_start;
    reg        cmd_start;
    reg        cmd_read;
    reg        cmd_write;
    reg        cmd_write_multiple;
    reg        cmd_stop;
    reg [6:0]  cmd_address;
    reg        cmd_valid_reg;
    reg        data_tvalid_reg;
    reg [7:0]  data_tdata_reg;
    reg        data_tlast_reg;
    reg        m_axis_data_tvalid_reg;
    reg [7:0]  m_axis_data_tdata_reg;
    reg        m_axis_data_tlast_reg;
    reg        m_axis_data_tready_reg;
    reg        s_axis_data_tready_reg;
    reg        s_axis_cmd_ready_reg;
    reg        busy_reg;
    reg        bus_control_reg;
    reg        bus_active_reg;

    // Outputs
    assign scl_o = scl_reg;
    assign scl_t = scl_t_reg;
    assign sda_o = sda_reg;
    assign sda_t = sda_t_reg;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;
    assign s_axis_cmd_ready = s_axis_cmd_ready_reg;
    assign s_axis_data_tready = s_axis_data_tready_reg;
    assign m_axis_data_tdata = m_axis_data_tdata_reg;
    assign m_axis_data_tvalid = m_axis_data_tvalid_reg;
    assign m_axis_data_tlast = m_axis_data_tlast_reg;

    // I2C timing: prescale defines the number of clock cycles per I2C bit half-period
    // We use a simple counter-based approach
    // Each I2C bit period is divided into phases:
    // - SCL high, SDA stable (for data sampling)
    // - SCL low, SDA can change
    // For simplicity, we'll use a state machine that toggles SCL and samples/changes SDA appropriately

    // I2C bit timing:
    // For writing: SDA is set when SCL is low, sampled when SCL is high
    // For reading: SDA is sampled when SCL is high, SCL is toggled by master

    // We'll implement a simple I2C master with the following timing:
    // - Each bit takes 2 * prescale clock cycles
    // - First half: SCL high (for read) or SCL low (for write, SDA setup)
    // - Second half: SCL low (for read) or SCL high (for write, SDA sample)

    // Actually, let's use a more standard approach:
    // - SCL is held low while SDA is being set up
    // - SCL goes high to sample SDA
    // - SCL goes low to allow SDA to change

    // For a master:
    // Write: Master drives SDA, SCL high samples SDA (but master doesn't sample its own data)
    // Read: Master releases SDA, SCL high samples SDA from slave

    // Let's use a simpler model:
    // - prescale = number of clk cycles per I2C bit half-period
    // - Total bit period = 2 * prescale clk cycles
    // - Phase 1 (prescale cycles): SCL low, SDA can be changed
    // - Phase 2 (prescale cycles): SCL high, SDA is sampled (for read) or stable (for write)

    // State machine for I2C bit transfer
    // We'll track:
    // - bit_count: 0-7 for data bits, 8 for ACK bit
    // - ack_phase: 0 for data, 1 for ACK
    // - send_ack: 1 if we need to send ACK (after receiving a byte in read mode)
    // - recv_ack: 1 if we need to receive ACK (after sending a byte in write mode)

    // Let's restructure the state machine to be cleaner

    // I2C Master State Machine
    // States:
    // IDLE: Wait for command
    // START: Generate START condition
    // SEND_BIT: Send one bit of data
    // SEND_ACK: Send ACK/NACK
    // RECV_BIT: Receive one bit of data
    // RECV_ACK: Receive ACK/NACK
    // STOP: Generate STOP condition

    // For each bit:
    // - SCL low phase: Set up SDA (for write) or release SDA (for read)
    // - SCL high phase: Sample SDA (for read) or hold SDA (for write)

    // We'll use a sub-state machine for bit timing

    // Let's define the bit timing states:
    // BIT_LOW: SCL is low, SDA is being set up
    // BIT_HIGH: SCL is high, SDA is being sampled

    // Actually, let's just use a counter and toggle SCL

    // Simplified approach:
    // - counter counts from 0 to 2*prescale-1
    // - When counter < prescale: SCL low
    // - When counter >= prescale: SCL high
    // - SDA is changed when SCL is low
    // - SDA is sampled when SCL is high (for read)

    // Let's implement this

    // Reset logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            bit_count <= 4'd0;
            tx_byte <= 8'd0;
            rx_byte <= 8'd0;
            is_read <= 1'b0;
            is_write <= 1'b0;
            is_write_multiple <= 1'b0;
            need_stop <= 1'b0;
            need_start <= 1'b0;
            ack_received <= 1'b0;
            missed_ack_reg <= 1'b0;
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            scl_t_reg <= 1'b0;
            sda_t_reg <= 1'b0;
            prescale_reg <= 16'd1;
            counter <= 16'd0;
            counting <= 1'b0;
            bit_done <= 1'b0;
            byte_done <= 1'b0;
            ack_phase <= 1'b0;
            send_ack <= 1'b0;
            recv_ack <= 1'b0;
            stop_on_idle_reg <= 1'b0;
            pending_stop <= 1'b0;
            pending_start <= 1'b0;
            cmd_start <= 1'b0;
            cmd_read <= 1'b0;
            cmd_write <= 1'b0;
            cmd_write_multiple <= 1'b0;
            cmd_stop <= 1'b0;
            cmd_address <= 7'd0;
            cmd_valid_reg <= 1'b0;
            data_tvalid_reg <= 1'b0;
            data_tdata_reg <= 8'd0;
            data_tlast_reg <= 1'b0;
            m_axis_data_tvalid_reg <= 1'b0;
            m_axis_data_tdata_reg <= 8'd0;
            m_axis_data_tlast_reg <= 1'b0;
            m_axis_data_tready_reg <= 1'b0;
            s_axis_data_tready_reg <= 1'b0;
            s_axis_cmd_ready_reg <= 1'b1;
            busy_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
        end else begin
            // Default assignments
            bit_done <= 1'b0;
            byte_done <= 1'b0;

            // Update configuration registers
            prescale_reg <= prescale;
            stop_on_idle_reg <= stop_on_idle;

            // Capture host interface signals
            if (s_axis_cmd_valid) begin
                cmd_start <= s_axis_cmd_start;
                cmd_read <= s_axis_cmd_read;
                cmd_write <= s_axis_cmd_write;
                cmd_write_multiple <= s_axis_cmd_write_multiple;
                cmd_stop <= s_axis_cmd_stop;
                cmd_address <= s_axis_cmd_address;
                cmd_valid_reg <= 1'b1;
            end else begin
                cmd_valid_reg <= 1'b0;
            end

            if (s_axis_data_tvalid) begin
                data_tvalid_reg <= 1'b1;
                data_tdata_reg <= s_axis_data_tdata;
                data_tlast_reg <= s_axis_data_tlast;
            end else begin
                data_tvalid_reg <= 1'b0;
            end

            m_axis_data_tready_reg <= m_axis_data_tready;

            // State machine
            case (state)
                S_IDLE: begin
                    s_axis_cmd_ready_reg <= 1'b1;
                    s_axis_data_tready_reg <= 1'b0;
                    m_axis_data_tvalid_reg <= 1'b0;
                    m_axis_data_tdata_reg <= 8'd0;
                    m_axis_data_tlast_reg <= 1'b0;
                    busy_reg <= 1'b0;
                    bus_control_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    missed_ack_reg <= 1'b0;
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b1;
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b0;
                    counting <= 1'b0;
                    counter <= 16'd0;
                    bit_count <= 4'd0;
                    ack_phase <= 1'b0;
                    send_ack <= 1'b0;
                    recv_ack <= 1'b0;
                    need_stop <= 1'b0;
                    need_start <= 1'b0;
                    pending_stop <= 1'b0;
                    pending_start <= 1'b0;

                    if (cmd_valid_reg) begin
                        s_axis_cmd_ready_reg <= 1'b0;
                        busy_reg <= 1'b1;
                        bus_control_reg <= 1'b1;
                        bus_active_reg <= 1'b1;

                        if (cmd_start) begin
                            // Generate START condition
                            // SDA high to low while SCL is high
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            state <= S_START;
                            counting <= 1'b1;
                            counter <= 16'd0;
                        end else if (cmd_stop) begin
                            // Generate STOP condition
                            // SDA low to high while SCL is high
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b1;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            state <= S_STOP;
                            counting <= 1'b1;
                            counter <= 16'd0;
                        end else if (cmd_read) begin
                            is_read <= 1'b1;
                            is_write <= 1'b0;
                            is_write_multiple <= 1'b0;
                            bit_count <= 4'd0;
                            ack_phase <= 1'b0;
                            recv_ack <= 1'b0;
                            send_ack <= 1'b0;
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b1;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b0;
                            state <= S_RECV_BIT;
                            counting <= 1'b1;
                            counter <= 16'd0;
                        end else if (cmd_write) begin
                            is_read <= 1'b0;
                            is_write <= 1'b1;
                            is_write_multiple <= 1'b0;
                            bit_count <= 4'd0;
                            ack_phase <= 1'b0;
                            recv_ack <= 1'b1;
                            send_ack <= 1'b0;
                            tx_byte <= {cmd_address, 1'b0};
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b1;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            state <= S_SEND_BIT;
                            counting <= 1'b1;
                            counter <= 16'd0;
                        end else if (cmd_write_multiple) begin
                            is_read <= 1'b0;
                            is_write <= 1'b1;
                            is_write_multiple <= 1'b1;
                            bit_count <= 4'd0;
                            ack_phase <= 1'b0;
                            recv_ack <= 1'b1;
                            send_ack <= 1'b0;
                            tx_byte <= {cmd_address, 1'b0};
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b1;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            state <= S_SEND_BIT;
                            counting <= 1'b1;
                            counter <= 16'd0;
                        end
                    end
                end

                S_START: begin
                    // START condition: SDA goes low while SCL is high
                    // Hold for prescale cycles, then SCL goes low
                    if (counting) begin
                        if (counter >= prescale_reg - 1) begin
                            counting <= 1'b0;
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            state <= S_IDLE;
                            // After START, we need to send the address
                            // But we need to know what command was given
                            // Let's go back to IDLE and let the command be processed
                            // Actually, we should transition to the appropriate state
                            // Let's handle this differently
                        end else begin
                            counter <= counter + 1'b1;
                        end
                    end
                end

                S_SEND_BIT: begin
                    // Send one bit of data
                    // SCL low phase: Set up SDA
                    // SCL high phase: Hold SDA
                    if (counting) begin
                        if (counter < prescale_reg) begin
                            // SCL low phase
                            scl_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            // Set up SDA based on current bit
                            if (ack_phase) begin
                                // ACK bit: master releases SDA (for read) or drives low (for write ACK)
                                // For write, we're sending data, so we drive SDA
                                sda_reg <= tx_byte[bit_count];
                                sda_t_reg <= 1'b1;
                            end else begin
                                sda_reg <= tx_byte[bit_count];
                                sda_t_reg <= 1'b1;
                            end
                            if (counter >= prescale_reg - 1) begin
                                // Transition to SCL high
                                scl_reg <= 1'b1;
                                scl_t_reg <= 1'b1;
                            end
                        end else begin
                            // SCL high phase
                            scl_reg <= 1'b1;
                            scl_t_reg <= 1'b1;
                            if (counter >= 2 * prescale_reg - 1) begin
                                // Bit done
                                bit_done <= 1'b1;
                                counting <= 1'b0;
                                scl_reg <= 1'b0;
                                scl_t_reg <= 1'b1;
                                if (bit_count == 4'd7) begin
                                    if (ack_phase) begin
                                        // ACK bit done, byte done
                                        byte_done <= 1'b1;
                                        ack_phase <= 1'b0;
                                        bit_count <= 4'd0;
                                        if (is_write) begin
                                            // Need to receive ACK
                                            recv_ack <= 1'b1;
                                            state <= S_RECV_ACK;
                                            counting <= 1'b1;
                                            counter <= 16'd0;
                                        end else begin
                                            // Read mode, need to send ACK
                                            send_ack <= 1'b1;
                                            state <= S_SEND_ACK;
                                            counting <= 1'b1;
                                            counter <= 16'd0;
                                        end
                                    end else begin
                                        // Data bit done, move to next bit
                                        bit_count <= bit_count + 1'b1;
                                        if (bit_count == 4'd7) begin
                                            // All 8 data bits sent, need to receive ACK
                                            ack_phase <= 1'b1;
                                            state <= S_RECV_ACK;
                                            counting <= 1'b1;
                                            counter <= 16'd0;
                                        end else begin
                                            state <= S_SEND_BIT;
                                            counting <= 1'b1;
                                            counter <= 16'd0;
                                        end
                                    end
                                end else begin
                                    state <= S_SEND_BIT;
                                    counting <= 1'b1;
                                    counter <= 16'd0;
                                end
                            end
                        end
                        if (counter < 2 * prescale_reg - 1) begin
                            counter <= counter + 1'b1;
                        end
                    end
                end

                S_SEND_ACK: begin
                    // Send ACK (SDA low) or NACK (SDA high)
                    // For now, always send ACK
                    if (counting) begin
                        if (counter < prescale_reg) begin
                            // SCL low phase
                            scl_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            sda_reg <= 1'b0; // ACK
                            sda_t_reg <= 1'b1;
                            if (counter >= prescale_reg - 1) begin
                                scl_reg <= 1'b1;
                                scl_t_reg <= 1'b1;
                            end
                        end else begin
                            // SCL high phase
                            scl_reg <= 1'b1;
                            scl_t_reg <= 1'b1;
                            if (counter >= 2 * prescale_reg - 1) begin
                                // ACK done
                                bit_done <= 1'b1;
                                counting <= 1'b0;
                                scl_reg <= 1'b0;
                                scl_t_reg <= 1'b1;
                                sda_reg <= 1'b1;
                                sda_t_reg <= 1'b0;
                                send_ack <= 1'b0;
                                // Check if we need to continue reading
                                if (stop_on_idle_reg) begin
                                    state <= S_STOP;
                                    counting <= 1'b1;
                                    counter <= 16'd0;
                                end else begin
                                    state <= S_RECV_BIT;
                                    counting <= 1'b1;
                                    counter <= 16'd0;
                                end
                            end
                        end
                        if (counter < 2 * prescale_reg - 1) begin
                            counter <= counter + 1'b1;
                        end
                    end
                end

                S_RECV_BIT: begin
                    // Receive one bit of data
                    // SCL low phase: Release SDA
                    // SCL high phase: Sample SDA
                    if (counting) begin
                        if (counter < prescale_reg) begin
                            // SCL low phase
                            scl_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            sda_reg <= 1'b1;
                            sda_t_reg <= 1'b0; // Release SDA
                            if (counter >= prescale_reg - 1) begin
                                scl_reg <= 1'b1;
                                scl_t_reg <= 1'b1;
                            end
                        end else begin
                            // SCL high phase
                            scl_reg <= 1'b1;
                            scl_t_reg <= 1'b1;
                            // Sample SDA
                            if (counter == prescale_reg) begin
                                rx_byte[bit_count] <= sda_i;
                            end
                            if (counter >= 2 * prescale_reg - 1) begin
                                // Bit done
                                bit_done <= 1'b1;
                                counting <= 1'b0;
                                scl_reg <= 1'b0;
                                scl_t_reg <= 1'b1;
                                if (bit_count == 4'd7) begin
                                    // All 8 data bits received, need to send ACK
                                    ack_phase <= 1'b1;
                                    state <= S_SEND_ACK;
                                    counting <= 1'b1;
                                    counter <= 16'd0;
                                end else begin
                                    bit_count <= bit_count + 1'b1;
                                    state <= S_RECV_BIT;
                                    counting <= 1'b1;
                                    counter <= 16'd0;
                                end
                            end
                        end
                        if (counter < 2 * prescale_reg - 1) begin
                            counter <= counter + 1'b1;
                        end
                    end
                end

                S_RECV_ACK: begin
                    // Receive ACK from slave
                    // SCL low phase: Release SDA
                    // SCL high phase: Sample SDA
                    if (counting) begin
                        if (counter < prescale_reg) begin
                            // SCL low phase
                            scl_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            sda_reg <= 1'b1;
                            sda_t_reg <= 1'b0; // Release SDA
                            if (counter >= prescale_reg - 1) begin
                                scl_reg <= 1'b1;
                                scl_t_reg <= 1'b1;
                            end
                        end else begin
                            // SCL high phase
                            scl_reg <= 1'b1;
                            scl_t_reg <= 1'b1;
                            // Sample SDA
                            if (counter == prescale_reg) begin
                                ack_received <= ~sda_i; // ACK is SDA low
                            end
                            if (counter >= 2 * prescale_reg - 1) begin
                                // ACK done
                                bit_done <= 1'b1;
                                counting <= 1'b0;
                                scl_reg <= 1'b0;
                                scl_t_reg <= 1'b1;
                                sda_reg <= 1'b1;
                                sda_t_reg <= 1'b0;
                                recv_ack <= 1'b0;
                                if (!ack_received) begin
                                    missed_ack_reg <= 1'b1;
                                end
                                // Check if we need to continue
                                if (is_write_multiple) begin
                                    if (data_tvalid_reg) begin
                                        tx_byte <= data_tdata_reg;
                                        bit_count <= 4'd0;
                                        ack_phase <= 1'b0;
                                        recv_ack <= 1'b1;
                                        state <= S_SEND_BIT;
                                        counting <= 1'b1;
                                        counter <= 16'd0;
                                    end else begin
                                        s_axis_data_tready_reg <= 1'b1;
                                        state <= S_IDLE;
                                        busy_reg <= 1'b0;
                                        bus_control_reg <= 1'b0;
                                        bus_active_reg <= 1'b0;
                                    end
                                end else begin
                                    state <= S_STOP;
                                    counting <= 1'b1;
                                    counter <= 16'd0;
                                end
                            end
                        end
                        if (counter < 2 * prescale_reg - 1) begin
                            counter <= counter + 1'b1;
                        end
                    end
                end

                S_STOP: begin
                    // STOP condition: SDA goes high while SCL is high
                    if (counting) begin
                        if (counter < prescale_reg) begin
                            // SCL low phase
                            scl_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            sda_reg <= 1'b0;
                            sda_t_reg <= 1'b1;
                            if (counter >= prescale_reg - 1) begin
                                scl_reg <= 1'b1;
                                scl_t_reg <= 1'b1;
                            end
                        end else begin
                            // SCL high phase
                            scl_reg <= 1'b1;
                            scl_t_reg <= 1'b1;
                            sda_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            if (counter >= 2 * prescale_reg - 1) begin
                                // STOP done
                                bit_done <= 1'b1;
                                counting <= 1'b0;
                                scl_reg <= 1'b1;
                                scl_t_reg <= 1'b0;
                                sda_reg <= 1'b1;
                                sda_t_reg <= 1'b0;
                                state <= S_IDLE;
                                busy_reg <= 1'b0;
                                bus_control_reg <= 1'b0;
                                bus_active_reg <= 1'b0;
                            end
                        end
                        if (counter < 2 * prescale_reg - 1) begin
                            counter <= counter + 1'b1;
                        end
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
