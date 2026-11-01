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
    localparam S_ADDR          = 4'd2;
    localparam S_ACK_ADDR      = 4'd3;
    localparam S_DATA          = 4'd4;
    localparam S_ACK_DATA      = 4'd5;
    localparam S_STOP          = 4'd6;
    localparam S_WAIT_DATA     = 4'd7;
    localparam S_ACK_READ      = 4'd8;

    // Internal signals
    reg [3:0]  state;
    reg [3:0]  bit_cnt;
    reg [7:0]  tx_byte;
    reg [7:0]  rx_byte;
    reg        tx_bit;
    reg        rx_bit;
    reg        ack_bit;
    reg        is_read;
    reg        is_write;
    reg        is_write_multiple;
    reg        need_stop;
    reg        need_start;
    reg        addr_phase;
    reg        data_phase;
    reg        last_data;
    reg        cmd_pending;
    reg        data_pending;
    reg        scl_high;
    reg        sda_high;
    reg        scl_drive;
    reg        sda_drive;
    reg [15:0] prescale_cnt;
    reg        prescale_done;
    reg        missed_ack_reg;
    reg        bus_active_reg;
    reg        bus_control_reg;
    reg        busy_reg;

    // Command storage
    reg [6:0]  cmd_address;
    reg        cmd_start;
    reg        cmd_read;
    reg        cmd_write;
    reg        cmd_write_multiple;
    reg        cmd_stop;

    // Data storage
    reg [7:0]  data_byte;
    reg        data_last;

    // Output assignments
    assign s_axis_cmd_ready = (state == S_IDLE) && !busy_reg;
    assign s_axis_data_tready = (state == S_DATA) && !is_read && !busy_reg;
    assign m_axis_data_tdata = rx_byte;
    assign m_axis_data_tvalid = (state == S_ACK_READ) && !busy_reg;
    assign m_axis_data_tlast = last_data;
    assign scl_o = scl_drive;
    assign scl_t = ~scl_drive;
    assign sda_o = sda_drive;
    assign sda_t = ~sda_drive;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;

    // Prescale counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prescale_cnt <= 16'd0;
            prescale_done <= 1'b0;
        end else begin
            if (prescale_done) begin
                prescale_cnt <= 16'd0;
                prescale_done <= 1'b0;
            end else if (busy_reg) begin
                if (prescale_cnt == prescale) begin
                    prescale_done <= 1'b1;
                end else begin
                    prescale_cnt <= prescale_cnt + 1'b1;
                end
            end else begin
                prescale_cnt <= 16'd0;
            end
        end
    end

    // Main state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            bit_cnt <= 4'd0;
            tx_byte <= 8'd0;
            rx_byte <= 8'd0;
            tx_bit <= 1'b0;
            rx_bit <= 1'b0;
            ack_bit <= 1'b0;
            is_read <= 1'b0;
            is_write <= 1'b0;
            is_write_multiple <= 1'b0;
            need_stop <= 1'b0;
            need_start <= 1'b0;
            addr_phase <= 1'b0;
            data_phase <= 1'b0;
            last_data <= 1'b0;
            cmd_pending <= 1'b0;
            data_pending <= 1'b0;
            scl_high <= 1'b1;
            sda_high <= 1'b1;
            scl_drive <= 1'b1;
            sda_drive <= 1'b1;
            missed_ack_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            busy_reg <= 1'b0;
            cmd_address <= 7'd0;
            cmd_start <= 1'b0;
            cmd_read <= 1'b0;
            cmd_write <= 1'b0;
            cmd_write_multiple <= 1'b0;
            cmd_stop <= 1'b0;
            data_byte <= 8'd0;
            data_last <= 1'b0;
        end else begin
            // Default: hold current state
            case (state)
                S_IDLE: begin
                    // Release bus
                    scl_drive <= 1'b1;
                    sda_drive <= 1'b1;
                    scl_high <= 1'b1;
                    sda_high <= 1'b1;
                    busy_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    bus_control_reg <= 1'b0;
                    missed_ack_reg <= 1'b0;
                    
                    // Accept command
                    if (s_axis_cmd_valid && s_axis_cmd_ready) begin
                        cmd_address <= s_axis_cmd_address;
                        cmd_start <= s_axis_cmd_start;
                        cmd_read <= s_axis_cmd_read;
                        cmd_write <= s_axis_cmd_write;
                        cmd_write_multiple <= s_axis_cmd_write_multiple;
                        cmd_stop <= s_axis_cmd_stop;
                        cmd_pending <= 1'b1;
                        busy_reg <= 1'b1;
                        bus_control_reg <= 1'b1;
                        
                        if (s_axis_cmd_start) begin
                            state <= S_START;
                            bit_cnt <= 4'd0;
                            is_read <= s_axis_cmd_read;
                            is_write <= s_axis_cmd_write;
                            is_write_multiple <= s_axis_cmd_write_multiple;
                            need_stop <= s_axis_cmd_stop;
                            addr_phase <= 1'b1;
                            data_phase <= 1'b0;
                            last_data <= 1'b0;
                        end else if (s_axis_cmd_stop) begin
                            state <= S_STOP;
                            bit_cnt <= 4'd0;
                        end else begin
                            // No start or stop, just idle
                            cmd_pending <= 1'b0;
                            busy_reg <= 1'b0;
                            bus_control_reg <= 1'b0;
                        end
                    end
                end

                S_START: begin
                    // START condition: SDA high to low while SCL high
                    if (!prescale_done) begin
                        // Wait for prescale
                    end else begin
                        // Perform START
                        scl_drive <= 1'b1;
                        sda_drive <= 1'b0;
                        scl_high <= 1'b1;
                        sda_high <= 1'b0;
                        bus_active_reg <= 1'b1;
                        state <= S_ADDR;
                        bit_cnt <= 4'd7;
                        tx_byte <= {cmd_address, is_read};
                        addr_phase <= 1'b1;
                        data_phase <= 1'b0;
                        last_data <= 1'b0;
                    end
                end

                S_ADDR: begin
                    // Send address bits MSB first
                    if (!prescale_done) begin
                        // Wait for prescale
                    end else begin
                        if (bit_cnt == 4'd0) begin
                            // All 8 bits sent, go to ACK
                            state <= S_ACK_ADDR;
                            bit_cnt <= 4'd0;
                        end else begin
                            // Drive current bit
                            tx_bit <= tx_byte[bit_cnt];
                            sda_drive <= tx_byte[bit_cnt];
                            sda_high <= tx_byte[bit_cnt];
                            scl_drive <= 1'b1;
                            scl_high <= 1'b1;
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                S_ACK_ADDR: begin
                    // Receive ACK from slave
                    if (!prescale_done) begin
                        // Wait for prescale
                    end else begin
                        // Release SDA to read ACK
                        sda_drive <= 1'b1;
                        sda_high <= 1'b1;
                        scl_drive <= 1'b1;
                        scl_high <= 1'b1;
                        ack_bit <= sda_i;
                        
                        if (ack_bit) begin
                            // NACK
                            missed_ack_reg <= 1'b1;
                            state <= S_STOP;
                            bit_cnt <= 4'd0;
                        end else begin
                            // ACK
                            if (is_read) begin
                                // Read mode: wait for data from slave
                                state <= S_WAIT_DATA;
                                bit_cnt <= 4'd7;
                                rx_byte <= 8'd0;
                            end else begin
                                // Write mode: send data
                                state <= S_DATA;
                                bit_cnt <= 4'd7;
                                data_phase <= 1'b1;
                                last_data <= 1'b0;
                            end
                        end
                    end
                end

                S_WAIT_DATA: begin
                    // Wait for slave to drive data
                    if (!prescale_done) begin
                        // Wait for prescale
                    end else begin
                        // Sample data bit
                        rx_bit <= sda_i;
                        rx_byte <= {rx_byte[6:0], rx_bit};
                        
                        if (bit_cnt == 4'd0) begin
                            // All 8 bits received
                            state <= S_ACK_READ;
                            bit_cnt <= 4'd0;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                S_ACK_READ: begin
                    // Send ACK/NACK for read data
                    if (!prescale_done) begin
                        // Wait for prescale
                    end else begin
                        // Determine if we need more data
                        if (m_axis_data_tready) begin
                            // Data accepted, check if more needed
                            if (last_data) begin
                                // Last byte, send NACK
                                sda_drive <= 1'b1;
                                sda_high <= 1'b1;
                                scl_drive <= 1'b1;
                                scl_high <= 1'b1;
                                state <= S_STOP;
                                bit_cnt <= 4'd0;
                            end else begin
                                // Send ACK
                                sda_drive <= 1'b0;
                                sda_high <= 1'b0;
                                scl_drive <= 1'b1;
                                scl_high <= 1'b1;
                                state <= S_WAIT_DATA;
                                bit_cnt <= 4'd7;
                                rx_byte <= 8'd0;
                            end
                        end else begin
                            // Wait for ready
                        end
                    end
                end

                S_DATA: begin
                    // Send data bytes MSB first
                    if (!prescale_done) begin
                        // Wait for prescale
                    end else begin
                        if (bit_cnt == 4'd0) begin
                            // All 8 bits sent, go to ACK
                            state <= S_ACK_DATA;
                            bit_cnt <= 4'd0;
                        end else begin
                            // Drive current bit
                            tx_bit <= tx_byte[bit_cnt];
                            sda_drive <= tx_byte[bit_cnt];
                            sda_high <= tx_byte[bit_cnt];
                            scl_drive <= 1'b1;
                            scl_high <= 1'b1;
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                S_ACK_DATA: begin
                    // Receive ACK from slave
                    if (!prescale_done) begin
                        // Wait for prescale
                    end else begin
                        // Release SDA to read ACK
                        sda_drive <= 1'b1;
                        sda_high <= 1'b1;
                        scl_drive <= 1'b1;
                        scl_high <= 1'b1;
                        ack_bit <= sda_i;
                        
                        if (ack_bit) begin
                            // NACK
                            missed_ack_reg <= 1'b1;
                            state <= S_STOP;
                            bit_cnt <= 4'd0;
                        end else begin
                            // ACK
                            if (last_data) begin
                                // Last byte
                                if (need_stop) begin
                                    state <= S_STOP;
                                    bit_cnt <= 4'd0;
                                end else begin
                                    state <= S_IDLE;
                                    bit_cnt <= 4'd0;
                                    busy_reg <= 1'b0;
                                    bus_active_reg <= 1'b0;
                                    bus_control_reg <= 1'b0;
                                end
                            end else begin
                                // More data to send
                                state <= S_DATA;
                                bit_cnt <= 4'd7;
                                data_phase <= 1'b1;
                            end
                        end
                    end
                end

                S_STOP: begin
                    // STOP condition: SDA low to high while SCL high
                    if (!prescale_done) begin
                        // Wait for prescale
                    end else begin
                        // Perform STOP
                        scl_drive <= 1'b1;
                        sda_drive <= 1'b1;
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        state <= S_IDLE;
                        bit_cnt <= 4'd0;
                        busy_reg <= 1'b0;
                        bus_active_reg <= 1'b0;
                        bus_control_reg <= 1'b0;
                    end
                end

                default: begin
                    state <= S_IDLE;
                    busy_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    bus_control_reg <= 1'b0;
                end
            endcase

            // Handle data input for write operations
            if (state == S_DATA && !is_read && s_axis_data_tvalid && s_axis_data_tready) begin
                tx_byte <= s_axis_data_tdata;
                last_data <= s_axis_data_tlast;
            end

            // Handle data output for read operations
            if (state == S_ACK_READ && m_axis_data_tready) begin
                // Data is already in rx_byte, output is combinational
            end
        end
    end

endmodule
