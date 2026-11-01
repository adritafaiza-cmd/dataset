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
    localparam S_IDLE            = 4'd0;
    localparam S_START           = 4'd1;
    localparam S_SEND_BIT        = 4'd2;
    localparam S_SEND_ACK        = 4'd3;
    localparam S_RECV_BIT        = 4'd4;
    localparam S_RECV_ACK        = 4'd5;
    localparam S_STOP            = 4'd6;
    localparam S_DONE            = 4'd7;

    // Internal signals
    reg [3:0]  state;
    reg [3:0]  bit_count;
    reg [7:0]  tx_byte;
    reg [7:0]  rx_byte;
    reg        is_read;
    reg        is_write;
    reg        is_write_multiple;
    reg        need_stop;
    reg        ack_received;
    reg        missed_ack_reg;
    reg        scl_reg;
    reg        sda_reg;
    reg        scl_t_reg;
    reg        sda_t_reg;
    reg [15:0] prescale_reg;
    reg [15:0] counter;
    reg        counter_done;
    reg        bit_to_send;
    reg        bit_received;
    reg        send_ack;
    reg        stop_after;
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

    // Outputs
    assign scl_o = scl_reg;
    assign sda_o = sda_reg;
    assign scl_t = scl_t_reg;
    assign sda_t = sda_t_reg;
    assign busy = (state != S_IDLE);
    assign bus_control = (state != S_IDLE);
    assign bus_active = (state != S_IDLE);
    assign missed_ack = missed_ack_reg;
    assign s_axis_cmd_ready = (state == S_IDLE);
    assign s_axis_data_tready = (state == S_SEND_BIT || state == S_SEND_ACK) && is_write;
    assign m_axis_data_tdata = m_axis_data_tdata_reg;
    assign m_axis_data_tvalid = m_axis_data_tvalid_reg;
    assign m_axis_data_tlast = m_axis_data_tlast_reg;

    // SCL and SDA tri-state control
    // When scl_t is 1, scl_o drives the bus; when 0, it's high-impedance
    // For I2C master, we typically drive SCL and SDA when we have control
    // scl_t = 1 means we are driving SCL (output enabled)
    // scl_t = 0 means we are releasing SCL (input mode)
    // Similarly for SDA

    // Prescale counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prescale_reg <= 16'd1;
        end else begin
            prescale_reg <= prescale;
        end
    end

    // Main state machine
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
            ack_received <= 1'b0;
            missed_ack_reg <= 1'b0;
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            scl_t_reg <= 1'b0;
            sda_t_reg <= 1'b0;
            counter <= 16'd0;
            counter_done <= 1'b0;
            bit_to_send <= 1'b0;
            bit_received <= 1'b0;
            send_ack <= 1'b0;
            stop_after <= 1'b0;
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
        end else begin
            // Default: hold current values
            counter_done <= 1'b0;
            m_axis_data_tvalid_reg <= 1'b0;
            m_axis_data_tlast_reg <= 1'b0;

            case (state)
                S_IDLE: begin
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b1;
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b0;
                    missed_ack_reg <= 1'b0;
                    ack_received <= 1'b0;
                    need_stop <= 1'b0;
                    stop_after <= 1'b0;
                    if (s_axis_cmd_valid) begin
                        cmd_start <= s_axis_cmd_start;
                        cmd_read <= s_axis_cmd_read;
                        cmd_write <= s_axis_cmd_write;
                        cmd_write_multiple <= s_axis_cmd_write_multiple;
                        cmd_stop <= s_axis_cmd_stop;
                        cmd_address <= s_axis_cmd_address;
                        cmd_valid_reg <= 1'b1;
                        is_read <= s_axis_cmd_read;
                        is_write <= s_axis_cmd_write;
                        is_write_multiple <= s_axis_cmd_write_multiple;
                        if (s_axis_cmd_start) begin
                            state <= S_START;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b1;
                            counter <= 16'd0;
                        end else if (s_axis_cmd_stop) begin
                            state <= S_STOP;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b1;
                            counter <= 16'd0;
                        end else begin
                            // No start or stop, just idle
                            state <= S_IDLE;
                        end
                    end
                end

                S_START: begin
                    // START condition: SDA falls while SCL is high
                    if (counter < prescale_reg) begin
                        counter <= counter + 16'd1;
                    end else begin
                        counter_done <= 1'b1;
                    end
                    if (counter_done) begin
                        // First half: SCL high, SDA high
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b1;
                        scl_t_reg <= 1'b1;
                        sda_t_reg <= 1'b1;
                        counter <= 16'd0;
                        counter_done <= 1'b0;
                        // We need to do START in two steps:
                        // Step 1: SCL=1, SDA=1
                        // Step 2: SCL=1, SDA=0 (START)
                        // Step 3: SCL=0, SDA=0
                        // Let's use a sub-state approach
                        // For simplicity, let's do:
                        // S_START: SCL=1, SDA=1
                        // Then transition to S_START2: SCL=1, SDA=0
                        // Then S_START3: SCL=0, SDA=0
                        // Then send address
                        // Actually, let's simplify by doing the START condition
                        // in a single state with proper timing
                        // START: SDA transitions from 1 to 0 while SCL is high
                        // So: SCL=1, SDA=1 -> SCL=1, SDA=0 -> SCL=0, SDA=0
                        // Let's use bit_count as a sub-state counter
                        if (bit_count == 4'd0) begin
                            // SCL=1, SDA=1
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b1;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_count <= 4'd1;
                        end else if (bit_count == 4'd1) begin
                            // SCL=1, SDA=0 (START condition)
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_count <= 4'd2;
                        end else if (bit_count == 4'd2) begin
                            // SCL=0, SDA=0
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_count <= 4'd3;
                        end else begin
                            // Done with START, go to send address
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_count <= 4'd0;
                            tx_byte <= {cmd_address, cmd_read};
                            state <= S_SEND_BIT;
                        end
                    end
                end

                S_SEND_BIT: begin
                    // Send one bit of tx_byte
                    if (counter < prescale_reg) begin
                        counter <= counter + 16'd1;
                    end else begin
                        counter_done <= 1'b1;
                    end
                    if (counter_done) begin
                        counter <= 16'd0;
                        counter_done <= 1'b0;
                        if (bit_count < 4'd8) begin
                            // SCL low, SDA = bit to send
                            scl_reg <= 1'b0;
                            sda_reg <= tx_byte[7 - bit_count];
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_count <= bit_count + 4'd1;
                        end else begin
                            // All 8 bits sent, now send ACK
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b0; // Release SDA for ACK
                            bit_count <= 4'd0;
                            state <= S_SEND_ACK;
                        end
                    end
                end

                S_SEND_ACK: begin
                    // Wait for ACK from slave
                    if (counter < prescale_reg) begin
                        counter <= counter + 16'd1;
                    end else begin
                        counter_done <= 1'b1;
                    end
                    if (counter_done) begin
                        counter <= 16'd0;
                        counter_done <= 1'b0;
                        // SCL high, read SDA
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b0;
                        scl_t_reg <= 1'b1;
                        sda_t_reg <= 1'b0;
                        ack_received <= ~sda_i;
                        if (sda_i) begin
                            missed_ack_reg <= 1'b1;
                        end
                        scl_reg <= 1'b0;
                        sda_reg <= 1'b0;
                        scl_t_reg <= 1'b1;
                        sda_t_reg <= 1'b1;
                        if (is_write) begin
                            if (is_write_multiple) begin
                                // Check if more data
                                if (s_axis_data_tvalid && !s_axis_data_tlast) begin
                                    tx_byte <= s_axis_data_tdata;
                                    state <= S_SEND_BIT;
                                end else if (s_axis_data_tvalid && s_axis_data_tlast) begin
                                    tx_byte <= s_axis_data_tdata;
                                    state <= S_SEND_BIT;
                                    stop_after <= 1'b1;
                                end else begin
                                    // No more data, stop
                                    state <= S_STOP;
                                end
                            end else begin
                                // Single write, stop after
                                state <= S_STOP;
                            end
                        end else begin
                            // Read operation, go to receive data
                            state <= S_RECV_BIT;
                        end
                    end
                end

                S_RECV_BIT: begin
                    // Receive one bit from slave
                    if (counter < prescale_reg) begin
                        counter <= counter + 16'd1;
                    end else begin
                        counter_done <= 1'b1;
                    end
                    if (counter_done) begin
                        counter <= 16'd0;
                        counter_done <= 1'b0;
                        if (bit_count < 4'd8) begin
                            // SCL low, then high to sample
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b0; // Release SDA
                            bit_count <= bit_count + 4'd1;
                        end else begin
                            // All 8 bits received, send ACK
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_count <= 4'd0;
                            state <= S_RECV_ACK;
                        end
                    end
                end

                S_RECV_ACK: begin
                    // Send ACK to slave
                    if (counter < prescale_reg) begin
                        counter <= counter + 16'd1;
                    end else begin
                        counter_done <= 1'b1;
                    end
                    if (counter_done) begin
                        counter <= 16'd0;
                        counter_done <= 1'b0;
                        // SCL high, SDA low (ACK)
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b0;
                        scl_t_reg <= 1'b1;
                        sda_t_reg <= 1'b1;
                        scl_reg <= 1'b0;
                        sda_reg <= 1'b0;
                        scl_t_reg <= 1'b1;
                        sda_t_reg <= 1'b1;
                        // Output received byte
                        m_axis_data_tdata_reg <= rx_byte;
                        m_axis_data_tvalid_reg <= 1'b1;
                        m_axis_data_tlast_reg <= stop_after;
                        if (stop_after) begin
                            state <= S_STOP;
                        end else begin
                            // Continue receiving
                            state <= S_RECV_BIT;
                        end
                    end
                end

                S_STOP: begin
                    // STOP condition: SDA rises while SCL is high
                    if (counter < prescale_reg) begin
                        counter <= counter + 16'd1;
                    end else begin
                        counter_done <= 1'b1;
                    end
                    if (counter_done) begin
                        counter <= 16'd0;
                        counter_done <= 1'b0;
                        if (bit_count == 4'd0) begin
                            // SCL=0, SDA=0
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_count <= 4'd1;
                        end else if (bit_count == 4'd1) begin
                            // SCL=1, SDA=0
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_count <= 4'd2;
                        end else if (bit_count == 4'd2) begin
                            // SCL=1, SDA=1 (STOP condition)
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b1;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_count <= 4'd3;
                        end else begin
                            // Done
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            sda_t_reg <= 1'b0;
                            bit_count <= 4'd0;
                            state <= S_IDLE;
                        end
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

    // Receive bit sampling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_byte <= 8'd0;
        end else if (state == S_RECV_BIT && counter_done) begin
            rx_byte <= {rx_byte[6:0], sda_i};
        end
    end

endmodule
