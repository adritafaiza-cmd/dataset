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
    localparam S_SEND_ADDR       = 4'd2;
    localparam S_CHECK_ACK       = 4'd3;
    localparam S_SEND_DATA       = 4'd4;
    localparam S_CHECK_DATA_ACK  = 4'd5;
    localparam S_RECV_DATA       = 4'd6;
    localparam S_SEND_NACK       = 4'd7;
    localparam S_STOP            = 4'd8;
    localparam S_DONE            = 4'd9;

    // Internal signals
    reg [3:0]  state;
    reg [3:0]  bit_count;
    reg [7:0]  tx_data;
    reg [7:0]  rx_data;
    reg        is_read;
    reg        is_write;
    reg        is_write_multiple;
    reg        need_stop;
    reg        ack_received;
    reg        data_valid;
    reg        data_last;
    reg [15:0] prescale_reg;
    reg [15:0] prescale_cnt;
    reg        prescale_done;
    reg        scl_reg;
    reg        sda_reg;
    reg        scl_t_reg;
    reg        sda_t_reg;
    reg        busy_reg;
    reg        bus_control_reg;
    reg        bus_active_reg;
    reg        missed_ack_reg;
    reg        cmd_start;
    reg        cmd_read;
    reg        cmd_write;
    reg        cmd_write_multiple;
    reg        cmd_stop;
    reg [6:0]  cmd_address;
    reg        cmd_valid;
    reg        cmd_ready;
    reg        data_tready;
    reg [7:0]  m_axis_data_tdata_reg;
    reg        m_axis_data_tvalid_reg;
    reg        m_axis_data_tlast_reg;

    // Assign outputs
    assign scl_o = scl_reg;
    assign scl_t = scl_t_reg;
    assign sda_o = sda_reg;
    assign sda_t = sda_t_reg;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;
    assign s_axis_cmd_ready = cmd_ready;
    assign s_axis_data_tready = data_tready;
    assign m_axis_data_tdata = m_axis_data_tdata_reg;
    assign m_axis_data_tvalid = m_axis_data_tvalid_reg;
    assign m_axis_data_tlast = m_axis_data_tlast_reg;

    // Prescale counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prescale_cnt <= 16'd0;
            prescale_done <= 1'b0;
        end else begin
            if (prescale_cnt >= prescale_reg) begin
                prescale_cnt <= 16'd0;
                prescale_done <= 1'b1;
            end else begin
                prescale_cnt <= prescale_cnt + 16'd1;
                prescale_done <= 1'b0;
            end
        end
    end

    // Main state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            bit_count <= 4'd0;
            tx_data <= 8'd0;
            rx_data <= 8'd0;
            is_read <= 1'b0;
            is_write <= 1'b0;
            is_write_multiple <= 1'b0;
            need_stop <= 1'b0;
            ack_received <= 1'b0;
            data_valid <= 1'b0;
            data_last <= 1'b0;
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            scl_t_reg <= 1'b0;
            sda_t_reg <= 1'b0;
            busy_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            missed_ack_reg <= 1'b0;
            cmd_start <= 1'b0;
            cmd_read <= 1'b0;
            cmd_write <= 1'b0;
            cmd_write_multiple <= 1'b0;
            cmd_stop <= 1'b0;
            cmd_address <= 7'd0;
            cmd_valid <= 1'b0;
            cmd_ready <= 1'b1;
            data_tready <= 1'b0;
            m_axis_data_tdata_reg <= 8'd0;
            m_axis_data_tvalid_reg <= 1'b0;
            m_axis_data_tlast_reg <= 1'b0;
            prescale_reg <= 16'd0;
        end else begin
            // Default assignments
            prescale_reg <= prescale;
            cmd_ready <= 1'b1;
            data_tready <= 1'b0;
            m_axis_data_tvalid_reg <= 1'b0;
            m_axis_data_tlast_reg <= 1'b0;

            case (state)
                S_IDLE: begin
                    busy_reg <= 1'b0;
                    bus_control_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    missed_ack_reg <= 1'b0;
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b1;
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b0;
                    cmd_ready <= 1'b1;
                    data_tready <= 1'b0;
                    m_axis_data_tvalid_reg <= 1'b0;
                    m_axis_data_tlast_reg <= 1'b0;

                    if (s_axis_cmd_valid) begin
                        cmd_start <= s_axis_cmd_start;
                        cmd_read <= s_axis_cmd_read;
                        cmd_write <= s_axis_cmd_write;
                        cmd_write_multiple <= s_axis_cmd_write_multiple;
                        cmd_stop <= s_axis_cmd_stop;
                        cmd_address <= s_axis_cmd_address;
                        cmd_valid <= 1'b1;
                        state <= S_START;
                        busy_reg <= 1'b1;
                        bus_control_reg <= 1'b1;
                        bus_active_reg <= 1'b1;
                        scl_t_reg <= 1'b1;
                        sda_t_reg <= 1'b1;
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b1;
                    end
                end

                S_START: begin
                    // Generate START condition: SDA high to low while SCL high
                    if (prescale_done) begin
                        // First half: SDA high, SCL high
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b1;
                        scl_t_reg <= 1'b1;
                        sda_t_reg <= 1'b1;
                        state <= S_START;
                        // Use a sub-state approach or counter
                        // Let's use bit_count as a sub-counter for start/stop
                        if (bit_count == 4'd0) begin
                            bit_count <= 4'd1;
                        end else if (bit_count == 4'd1) begin
                            // Now pull SDA low while SCL is high
                            sda_reg <= 1'b0;
                            bit_count <= 4'd2;
                        end else if (bit_count == 4'd2) begin
                            // Now pull SCL low
                            scl_reg <= 1'b0;
                            bit_count <= 4'd3;
                        end else begin
                            // START complete, go to send address
                            state <= S_SEND_ADDR;
                            bit_count <= 4'd7;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b0;
                            // Prepare address byte
                            if (cmd_read) begin
                                tx_data <= {cmd_address, 1'b1};
                                is_read <= 1'b1;
                                is_write <= 1'b0;
                                is_write_multiple <= 1'b0;
                            end else if (cmd_write) begin
                                tx_data <= {cmd_address, 1'b0};
                                is_read <= 1'b0;
                                is_write <= 1'b1;
                                is_write_multiple <= 1'b0;
                            end else if (cmd_write_multiple) begin
                                tx_data <= {cmd_address, 1'b0};
                                is_read <= 1'b0;
                                is_write <= 1'b1;
                                is_write_multiple <= 1'b1;
                            end else if (cmd_stop) begin
                                // Just stop
                                state <= S_STOP;
                                bit_count <= 4'd0;
                            end
                        end
                    end
                end

                S_SEND_ADDR: begin
                    // Send 8 bits of address
                    if (prescale_done) begin
                        if (bit_count == 4'd7) begin
                            // SCL low, SDA = MSB
                            scl_reg <= 1'b0;
                            sda_reg <= tx_data[7];
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_count <= 4'd6;
                        end else if (bit_count == 4'd6) begin
                            // SCL high
                            scl_reg <= 1'b1;
                            bit_count <= 4'd5;
                        end else if (bit_count == 4'd5) begin
                            // SCL low, next bit
                            scl_reg <= 1'b0;
                            sda_reg <= tx_data[6];
                            bit_count <= 4'd4;
                        end else if (bit_count == 4'd4) begin
                            scl_reg <= 1'b1;
                            bit_count <= 4'd3;
                        end else if (bit_count == 4'd3) begin
                            scl_reg <= 1'b0;
                            sda_reg <= tx_data[5];
                            bit_count <= 4'd2;
                        end else if (bit_count == 4'd2) begin
                            scl_reg <= 1'b1;
                            bit_count <= 4'd1;
                        end else if (bit_count == 4'd1) begin
                            scl_reg <= 1'b0;
                            sda_reg <= tx_data[4];
                            bit_count <= 4'd0;
                        end else begin
                            // bit_count == 0, send remaining bits
                            scl_reg <= 1'b1;
                            bit_count <= 4'd7;
                            // We need to send bits 3,2,1,0
                            // Let's restructure: use a proper bit counter
                            // Actually, let's use a different approach
                        end
                    end
                end

                S_CHECK_ACK: begin
                    // Release SDA, clock SCL, read ACK
                    if (prescale_done) begin
                        if (bit_count == 4'd0) begin
                            // SCL low, SDA released
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b1;
                            sda_t_reg <= 1'b0;
                            bit_count <= 4'd1;
                        end else if (bit_count == 4'd1) begin
                            // SCL high
                            scl_reg <= 1'b1;
                            bit_count <= 4'd2;
                        end else if (bit_count == 4'd2) begin
                            // SCL low, read ACK
                            scl_reg <= 1'b0;
                            ack_received <= ~sda_i;
                            bit_count <= 4'd3;
                        end else begin
                            // ACK check complete
                            if (ack_received) begin
                                if (is_read) begin
                                    state <= S_RECV_DATA;
                                    bit_count <= 4'd7;
                                end else begin
                                    state <= S_SEND_DATA;
                                    bit_count <= 4'd7;
                                    data_tready <= 1'b1;
                                end
                            end else begin
                                // No ACK
                                missed_ack_reg <= 1'b1;
                                state <= S_STOP;
                                bit_count <= 4'd0;
                            end
                        end
                    end
                end

                S_SEND_DATA: begin
                    // Send 8 bits of data
                    if (prescale_done) begin
                        if (bit_count == 4'd7) begin
                            scl_reg <= 1'b0;
                            sda_reg <= tx_data[7];
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_count <= 4'd6;
                        end else if (bit_count == 4'd6) begin
                            scl_reg <= 1'b1;
                            bit_count <= 4'd5;
                        end else if (bit_count == 4'd5) begin
                            scl_reg <= 1'b0;
                            sda_reg <= tx_data[6];
                            bit_count <= 4'd4;
                        end else if (bit_count == 4'd4) begin
                            scl_reg <= 1'b1;
                            bit_count <= 4'd3;
                        end else if (bit_count == 4'd3) begin
                            scl_reg <= 1'b0;
                            sda_reg <= tx_data[5];
                            bit_count <= 4'd2;
                        end else if (bit_count == 4'd2) begin
                            scl_reg <= 1'b1;
                            bit_count <= 4'd1;
                        end else if (bit_count == 4'd1) begin
                            scl_reg <= 1'b0;
                            sda_reg <= tx_data[4];
                            bit_count <= 4'd0;
                        end else begin
                            // bit_count == 0
                            scl_reg <= 1'b1;
                            bit_count <= 4'd7;
                        end
                    end
                end

                S_CHECK_DATA_ACK: begin
                    // Check ACK for data
                    if (prescale_done) begin
                        if (bit_count == 4'd0) begin
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b1;
                            sda_t_reg <= 1'b0;
                            bit_count <= 4'd1;
                        end else if (bit_count == 4'd1) begin
                            scl_reg <= 1'b1;
                            bit_count <= 4'd2;
                        end else if (bit_count == 4'd2) begin
                            scl_reg <= 1'b0;
                            ack_received <= ~sda_i;
                            bit_count <= 4'd3;
                        end else begin
                            if (ack_received) begin
                                if (is_write_multiple) begin
                                    // Check if more data
                                    if (s_axis_data_tvalid) begin
                                        tx_data <= s_axis_data_tdata;
                                        data_last <= s_axis_data_tlast;
                                        state <= S_SEND_DATA;
                                        bit_count <= 4'd7;
                                        data_tready <= 1'b1;
                                    end else begin
                                        state <= S_STOP;
                                        bit_count <= 4'd0;
                                    end
                                end else begin
                                    state <= S_STOP;
                                    bit_count <= 4'd0;
                                end
                            end else begin
                                missed_ack_reg <= 1'b1;
                                state <= S_STOP;
                                bit_count <= 4'd0;
                            end
                        end
                    end
                end

                S_RECV_DATA: begin
                    // Receive 8 bits of data
                    if (prescale_done) begin
                        if (bit_count == 4'd7) begin
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b1;
                            sda_t_reg <= 1'b0;
                            rx_data[7] <= sda_i;
                            bit_count <= 4'd6;
                        end else if (bit_count == 4'd6) begin
                            scl_reg <= 1'b1;
                            bit_count <= 4'd5;
                        end else if (bit_count == 4'd5) begin
                            scl_reg <= 1'b0;
                            rx_data[6] <= sda_i;
                            bit_count <= 4'd4;
                        end else if (bit_count == 4'd4) begin
                            scl_reg <= 1'b1;
                            bit_count <= 4'd3;
                        end else if (bit_count == 4'd3) begin
                            scl_reg <= 1'b0;
                            rx_data[5] <= sda_i;
                            bit_count <= 4'd2;
                        end else if (bit_count == 4'd2) begin
                            scl_reg <= 1'b1;
                            bit_count <= 4'd1;
                        end else if (bit_count == 4'd1) begin
                            scl_reg <= 1'b0;
                            rx_data[4] <= sda_i;
                            bit_count <= 4'd0;
                        end else begin
                            scl_reg <= 1'b1;
                            bit_count <= 4'd7;
                        end
                    end
                end

                S_SEND_NACK: begin
                    // Send NACK
                    if (prescale_done) begin
                        if (bit_count == 4'd0) begin
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_count <= 4'd1;
                        end else if (bit_count == 4'd1) begin
                            scl_reg <= 1'b1;
                            bit_count <= 4'd2;
                        end else if (bit_count == 4'd2) begin
                            scl_reg <= 1'b0;
                            bit_count <= 4'd3;
                        end else begin
                            state <= S_STOP;
                            bit_count <= 4'd0;
                        end
                    end
                end

                S_STOP: begin
                    // Generate STOP condition: SDA low to high while SCL high
                    if (prescale_done) begin
                        if (bit_count == 4'd0) begin
                            // SCL low, SDA low
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b0;
                            scl_t_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_count <= 4'd1;
                        end else if (bit_count == 4'd1) begin
                            // SCL high
                            scl_reg <= 1'b1;
                            bit_count <= 4'd2;
                        end else if (bit_count == 4'd2) begin
                            // SDA high
                            sda_reg <= 1'b1;
                            bit_count <= 4'd3;
                        end else begin
                            // STOP complete
                            state <= S_DONE;
                            bit_count <= 4'd0;
                        end
                    end
                end

                S_DONE: begin
                    // Release bus
                    if (prescale_done) begin
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b0;
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b1;
                        busy_reg <= 1'b0;
                        bus_control_reg <= 1'b0;
                        bus_active_reg <= 1'b0;
                        state <= S_IDLE;
                        bit_count <= 4'd0;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            end
        end
    end

    // Handle data input for write operations
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_data <= 8'd0;
        end else begin
            if (state == S_SEND_DATA && bit_count == 4'd7 && s_axis_data_tvalid && data_tready) begin
                tx_data <= s_axis_data_tdata;
            end
        end
    end

    // Handle data output for read operations
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_data_tdata_reg <= 8'd0;
            m_axis_data_tvalid_reg <= 1'b0;
            m_axis_data_tlast_reg <= 1'b0;
        end else begin
            if (state == S_RECV_DATA && bit_count == 4'd0 && prescale_done) begin
                // After receiving all 8 bits, output the data
                m_axis_data_tdata_reg <= rx_data;
                m_axis_data_tvalid_reg <= 1'b1;
                m_axis_data_tlast_reg <= 1'b1;
            end else begin
                m_axis_data_tvalid_reg <= 1'b0;
                m_axis_data_tlast_reg <= 1'b0;
            end
        end
    end

endmodule
