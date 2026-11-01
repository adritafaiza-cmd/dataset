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
    localparam S_ADDR_ACK      = 4'd3;
    localparam S_WRITE_DATA    = 4'd4;
    localparam S_WRITE_ACK     = 4'd5;
    localparam S_READ_DATA     = 4'd6;
    localparam S_READ_ACK      = 4'd7;
    localparam S_STOP          = 4'd8;
    localparam S_DONE          = 4'd9;

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
    reg        addr_valid;
    reg [6:0]  addr_reg;
    reg        cmd_valid_reg;
    reg        data_valid_reg;
    reg        data_last_reg;
    reg        data_tdata_reg;
    reg        m_axis_data_tvalid_reg;
    reg [7:0]  m_axis_data_tdata_reg;
    reg        m_axis_data_tlast_reg;
    reg        missed_ack_reg;
    reg        scl_o_reg;
    reg        sda_o_reg;
    reg        scl_t_reg;
    reg        sda_t_reg;
    reg        busy_reg;
    reg        bus_control_reg;
    reg        bus_active_reg;

    // Prescale counter
    reg [15:0] prescale_cnt;
    reg        prescale_done;

    // Command latch
    reg        cmd_start_reg;
    reg        cmd_read_reg;
    reg        cmd_write_reg;
    reg        cmd_write_multiple_reg;
    reg        cmd_stop_reg;

    // Data latch
    reg [7:0]  data_tdata_reg;
    reg        data_tlast_reg;

    // Output assignments
    assign s_axis_cmd_ready = (state == S_IDLE) && !busy_reg;
    assign s_axis_data_tready = (state == S_WRITE_DATA) && (bit_cnt == 4'd0) && !busy_reg;
    assign m_axis_data_tdata = m_axis_data_tdata_reg;
    assign m_axis_data_tvalid = m_axis_data_tvalid_reg;
    assign m_axis_data_tlast = m_axis_data_tlast_reg;
    assign scl_o = scl_o_reg;
    assign scl_t = scl_t_reg;
    assign sda_o = sda_o_reg;
    assign sda_t = sda_t_reg;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;

    // Prescale logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prescale_cnt <= 16'd0;
            prescale_done <= 1'b0;
        end else begin
            if (prescale_done) begin
                prescale_done <= 1'b0;
            end else if (prescale_cnt == prescale) begin
                prescale_done <= 1'b1;
            end else begin
                prescale_cnt <= prescale_cnt + 16'd1;
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
            addr_valid <= 1'b0;
            addr_reg <= 7'd0;
            cmd_valid_reg <= 1'b0;
            data_valid_reg <= 1'b0;
            data_last_reg <= 1'b0;
            data_tdata_reg <= 8'd0;
            m_axis_data_tvalid_reg <= 1'b0;
            m_axis_data_tdata_reg <= 8'd0;
            m_axis_data_tlast_reg <= 1'b0;
            missed_ack_reg <= 1'b0;
            scl_o_reg <= 1'b1;
            sda_o_reg <= 1'b1;
            scl_t_reg <= 1'b1;
            sda_t_reg <= 1'b1;
            busy_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            cmd_start_reg <= 1'b0;
            cmd_read_reg <= 1'b0;
            cmd_write_reg <= 1'b0;
            cmd_write_multiple_reg <= 1'b0;
            cmd_stop_reg <= 1'b0;
        end else begin
            // Default: hold current values
            m_axis_data_tvalid_reg <= 1'b0;
            m_axis_data_tlast_reg <= 1'b0;

            case (state)
                S_IDLE: begin
                    busy_reg <= 1'b0;
                    bus_control_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    scl_o_reg <= 1'b1;
                    sda_o_reg <= 1'b1;
                    scl_t_reg <= 1'b1;
                    sda_t_reg <= 1'b1;
                    missed_ack_reg <= 1'b0;

                    if (s_axis_cmd_valid) begin
                        // Latch command
                        addr_reg <= s_axis_cmd_address;
                        cmd_start_reg <= s_axis_cmd_start;
                        cmd_read_reg <= s_axis_cmd_read;
                        cmd_write_reg <= s_axis_cmd_write;
                        cmd_write_multiple_reg <= s_axis_cmd_write_multiple;
                        cmd_stop_reg <= s_axis_cmd_stop;
                        is_read <= s_axis_cmd_read;
                        is_write <= s_axis_cmd_write;
                        is_write_multiple <= s_axis_cmd_write_multiple;
                        need_stop <= s_axis_cmd_stop;
                        need_start <= s_axis_cmd_start;
                        addr_valid <= 1'b1;
                        busy_reg <= 1'b1;
                        bus_control_reg <= 1'b1;
                        bus_active_reg <= 1'b1;

                        if (s_axis_cmd_start) begin
                            state <= S_START;
                        end else if (s_axis_cmd_stop) begin
                            state <= S_STOP;
                        end else begin
                            state <= S_ADDR;
                            bit_cnt <= 4'd0;
                            tx_byte <= {s_axis_cmd_address, s_axis_cmd_read};
                        end
                    end
                end

                S_START: begin
                    // Generate START condition: SDA high to low while SCL high
                    if (prescale_done) begin
                        // SCL high, SDA high
                        scl_o_reg <= 1'b1;
                        scl_t_reg <= 1'b0;
                        sda_o_reg <= 1'b1;
                        sda_t_reg <= 1'b0;
                        state <= S_START;
                        // Need to wait for SDA to go low
                        // We'll use a sub-state or counter
                        // For simplicity, we'll do START in two steps
                        // Step 1: SCL high, SDA high
                        // Step 2: SCL high, SDA low
                        // Step 3: SCL low
                        // We'll use bit_cnt as a sub-counter
                        if (bit_cnt == 4'd0) begin
                            bit_cnt <= 4'd1;
                        end else if (bit_cnt == 4'd1) begin
                            // Now pull SDA low
                            sda_o_reg <= 1'b0;
                            sda_t_reg <= 1'b0;
                            bit_cnt <= 4'd2;
                        end else if (bit_cnt == 4'd2) begin
                            // Now pull SCL low
                            scl_o_reg <= 1'b0;
                            scl_t_reg <= 1'b0;
                            bit_cnt <= 4'd0;
                            state <= S_ADDR;
                            tx_byte <= {addr_reg, is_read};
                        end
                    end
                end

                S_ADDR: begin
                    // Transmit address byte (7 bits + R/W bit)
                    if (prescale_done) begin
                        if (bit_cnt < 4'd8) begin
                            // Drive SDA with current bit
                            tx_bit <= tx_byte[7];
                            sda_o_reg <= tx_byte[7];
                            sda_t_reg <= 1'b0;
                            scl_o_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            tx_byte <= {tx_byte[6:0], 1'b0};
                            bit_cnt <= bit_cnt + 4'd1;
                        end else begin
                            // Address sent, wait for ACK
                            state <= S_ADDR_ACK;
                            bit_cnt <= 4'd0;
                            scl_o_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            sda_o_reg <= 1'b1;
                            sda_t_reg <= 1'b1; // Release SDA
                        end
                    end
                end

                S_ADDR_ACK: begin
                    // Sample ACK from slave
                    if (prescale_done) begin
                        if (bit_cnt == 4'd0) begin
                            // SCL high, sample SDA
                            scl_o_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            ack_bit <= sda_i;
                            bit_cnt <= 4'd1;
                        end else if (bit_cnt == 4'd1) begin
                            // SCL low
                            scl_o_reg <= 1'b0;
                            scl_t_reg <= 1'b0;
                            if (ack_bit) begin
                                // NACK
                                missed_ack_reg <= 1'b1;
                                state <= S_STOP;
                            end else begin
                                // ACK
                                if (is_read) begin
                                    state <= S_READ_DATA;
                                end else begin
                                    state <= S_WRITE_DATA;
                                end
                                bit_cnt <= 4'd0;
                            end
                        end
                    end
                end

                S_WRITE_DATA: begin
                    // Transmit data byte
                    if (prescale_done) begin
                        if (bit_cnt == 4'd0) begin
                            // Load data
                            if (s_axis_data_tvalid) begin
                                tx_byte <= s_axis_data_tdata;
                                data_last_reg <= s_axis_data_tlast;
                            end
                            bit_cnt <= 4'd1;
                        end else if (bit_cnt < 4'd9) begin
                            // Drive SDA with current bit
                            tx_bit <= tx_byte[7];
                            sda_o_reg <= tx_byte[7];
                            sda_t_reg <= 1'b0;
                            scl_o_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            tx_byte <= {tx_byte[6:0], 1'b0};
                            bit_cnt <= bit_cnt + 4'd1;
                        end else begin
                            // Data sent, wait for ACK
                            state <= S_WRITE_ACK;
                            bit_cnt <= 4'd0;
                            scl_o_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            sda_o_reg <= 1'b1;
                            sda_t_reg <= 1'b1; // Release SDA
                        end
                    end
                end

                S_WRITE_ACK: begin
                    // Sample ACK from slave
                    if (prescale_done) begin
                        if (bit_cnt == 4'd0) begin
                            // SCL high, sample SDA
                            scl_o_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            ack_bit <= sda_i;
                            bit_cnt <= 4'd1;
                        end else if (bit_cnt == 4'd1) begin
                            // SCL low
                            scl_o_reg <= 1'b0;
                            scl_t_reg <= 1'b0;
                            if (ack_bit) begin
                                // NACK
                                missed_ack_reg <= 1'b1;
                                state <= S_STOP;
                            end else begin
                                // ACK
                                if (is_write_multiple && !data_last_reg) begin
                                    state <= S_WRITE_DATA;
                                end else begin
                                    state <= S_STOP;
                                end
                                bit_cnt <= 4'd0;
                            end
                        end
                    end
                end

                S_READ_DATA: begin
                    // Receive data byte
                    if (prescale_done) begin
                        if (bit_cnt < 4'd8) begin
                            // SCL high, sample SDA
                            scl_o_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            sda_o_reg <= 1'b1;
                            sda_t_reg <= 1'b1; // Release SDA
                            rx_bit <= sda_i;
                            rx_byte <= {rx_byte[6:0], sda_i};
                            bit_cnt <= bit_cnt + 4'd1;
                        end else begin
                            // Data received, send ACK/NACK
                            state <= S_READ_ACK;
                            bit_cnt <= 4'd0;
                            scl_o_reg <= 1'b0;
                            scl_t_reg <= 1'b0;
                        end
                    end
                end

                S_READ_ACK: begin
                    // Send ACK/NACK to slave
                    if (prescale_done) begin
                        if (bit_cnt == 4'd0) begin
                            // Drive SDA with ACK (0) or NACK (1)
                            // For now, always ACK (0)
                            sda_o_reg <= 1'b0;
                            sda_t_reg <= 1'b0;
                            scl_o_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            bit_cnt <= 4'd1;
                        end else if (bit_cnt == 4'd1) begin
                            // SCL low
                            scl_o_reg <= 1'b0;
                            scl_t_reg <= 1'b0;
                            // Output received byte
                            m_axis_data_tdata_reg <= rx_byte;
                            m_axis_data_tvalid_reg <= 1'b1;
                            m_axis_data_tlast_reg <= 1'b0;
                            state <= S_STOP;
                            bit_cnt <= 4'd0;
                        end
                    end
                end

                S_STOP: begin
                    // Generate STOP condition: SDA low to high while SCL high
                    if (prescale_done) begin
                        if (bit_cnt == 4'd0) begin
                            // SCL low, SDA low
                            scl_o_reg <= 1'b0;
                            scl_t_reg <= 1'b0;
                            sda_o_reg <= 1'b0;
                            sda_t_reg <= 1'b0;
                            bit_cnt <= 4'd1;
                        end else if (bit_cnt == 4'd1) begin
                            // SCL high, SDA low
                            scl_o_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            sda_o_reg <= 1'b0;
                            sda_t_reg <= 1'b0;
                            bit_cnt <= 4'd2;
                        end else if (bit_cnt == 4'd2) begin
                            // SCL high, SDA high
                            scl_o_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            sda_o_reg <= 1'b1;
                            sda_t_reg <= 1'b0;
                            bit_cnt <= 4'd3;
                        end else if (bit_cnt == 4'd3) begin
                            // Release bus
                            scl_o_reg <= 1'b1;
                            scl_t_reg <= 1'b1;
                            sda_o_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            state <= S_IDLE;
                            bit_cnt <= 4'd0;
                            busy_reg <= 1'b0;
                            bus_control_reg <= 1'b0;
                            bus_active_reg <= 1'b0;
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
