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
    reg        cmd_start;
    reg        cmd_read;
    reg        cmd_write;
    reg        cmd_write_multiple;
    reg        cmd_stop;
    reg [6:0]  cmd_address;

    // I2C bit timing
    reg [15:0] tick_counter;
    reg        tick_done;
    reg        scl_high;
    reg        sda_high;
    reg        scl_drive;
    reg        sda_drive;
    reg        scl_enable;
    reg        sda_enable;

    // Prescale configuration
    wire [15:0] prescale_val = prescale;

    // I2C bus signals
    assign scl_o = scl_drive;
    assign sda_o = sda_drive;
    assign scl_t = scl_enable;
    assign sda_t = sda_enable;

    // Status outputs
    assign busy = (state != S_IDLE);
    assign bus_control = (state != S_IDLE);
    assign bus_active = (state != S_IDLE) && (state != S_DONE);
    assign missed_ack = (state == S_CHECK_ACK && !ack_received) || 
                        (state == S_CHECK_DATA_ACK && !ack_received);

    // AXI command ready
    assign s_axis_cmd_ready = (state == S_IDLE);

    // AXI data ready
    assign s_axis_data_tready = (state == S_SEND_DATA) && is_write && !is_write_multiple;

    // AXI data output
    assign m_axis_data_tdata = rx_data;
    assign m_axis_data_tvalid = (state == S_RECV_DATA) && bit_count == 4'd0 && data_valid;
    assign m_axis_data_tlast = data_last;

    // Tick generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tick_counter <= 16'd0;
            tick_done <= 1'b0;
        end else begin
            if (tick_done) begin
                tick_counter <= 16'd0;
                tick_done <= 1'b0;
            end else if (state != S_IDLE) begin
                if (tick_counter == prescale_val) begin
                    tick_counter <= 16'd0;
                    tick_done <= 1'b1;
                end else begin
                    tick_counter <= tick_counter + 16'd1;
                end
            end else begin
                tick_counter <= 16'd0;
                tick_done <= 1'b0;
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
            cmd_start <= 1'b0;
            cmd_read <= 1'b0;
            cmd_write <= 1'b0;
            cmd_write_multiple <= 1'b0;
            cmd_stop <= 1'b0;
            cmd_address <= 7'd0;
            scl_high <= 1'b1;
            sda_high <= 1'b1;
            scl_drive <= 1'b1;
            sda_drive <= 1'b1;
            scl_enable <= 1'b0;
            sda_enable <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    scl_high <= 1'b1;
                    sda_high <= 1'b1;
                    scl_drive <= 1'b1;
                    sda_drive <= 1'b1;
                    scl_enable <= 1'b0;
                    sda_enable <= 1'b0;
                    data_valid <= 1'b0;
                    data_last <= 1'b0;
                    if (s_axis_cmd_valid) begin
                        cmd_start <= s_axis_cmd_start;
                        cmd_read <= s_axis_cmd_read;
                        cmd_write <= s_axis_cmd_write;
                        cmd_write_multiple <= s_axis_cmd_write_multiple;
                        cmd_stop <= s_axis_cmd_stop;
                        cmd_address <= s_axis_cmd_address;
                        is_read <= s_axis_cmd_read;
                        is_write <= s_axis_cmd_write;
                        is_write_multiple <= s_axis_cmd_write_multiple;
                        need_stop <= s_axis_cmd_stop;
                        if (s_axis_cmd_start) begin
                            state <= S_START;
                        end else if (s_axis_cmd_stop) begin
                            state <= S_STOP;
                        end else begin
                            state <= S_IDLE;
                        end
                    end
                end

                S_START: begin
                    // Generate START condition: SDA high->low while SCL high
                    if (!tick_done) begin
                        // Phase 1: SCL high, SDA high
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        scl_drive <= 1'b1;
                        sda_drive <= 1'b1;
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b1;
                    end else begin
                        // Phase 2: SCL high, SDA low (START)
                        scl_high <= 1'b1;
                        sda_high <= 1'b0;
                        scl_drive <= 1'b1;
                        sda_drive <= 1'b0;
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b1;
                        state <= S_SEND_ADDR;
                        bit_count <= 4'd7;
                        tx_data <= {cmd_address, is_read};
                    end
                end

                S_SEND_ADDR: begin
                    if (!tick_done) begin
                        // SCL low, drive SDA
                        scl_high <= 1'b0;
                        sda_high <= tx_data[bit_count];
                        scl_drive <= 1'b0;
                        sda_drive <= tx_data[bit_count];
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b1;
                    end else begin
                        // SCL high, sample SDA
                        scl_high <= 1'b1;
                        sda_high <= tx_data[bit_count];
                        scl_drive <= 1'b1;
                        sda_drive <= tx_data[bit_count];
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b1;
                        if (bit_count == 4'd0) begin
                            state <= S_CHECK_ACK;
                            bit_count <= 4'd0;
                        end else begin
                            bit_count <= bit_count - 4'd1;
                        end
                    end
                end

                S_CHECK_ACK: begin
                    if (!tick_done) begin
                        // SCL low, release SDA to read ACK
                        scl_high <= 1'b0;
                        sda_high <= 1'b1;
                        scl_drive <= 1'b0;
                        sda_drive <= 1'b1;
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b0;
                    end else begin
                        // SCL high, sample SDA for ACK
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        scl_drive <= 1'b1;
                        sda_drive <= 1'b1;
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b0;
                        ack_received <= !sda_i;
                        if (ack_received) begin
                            if (is_read) begin
                                state <= S_RECV_DATA;
                                bit_count <= 4'd7;
                            end else begin
                                state <= S_SEND_DATA;
                                bit_count <= 4'd7;
                            end
                        end else begin
                            // NACK received
                            if (need_stop) begin
                                state <= S_STOP;
                            end else begin
                                state <= S_DONE;
                            end
                        end
                    end
                end

                S_SEND_DATA: begin
                    if (!tick_done) begin
                        // SCL low, drive SDA
                        scl_high <= 1'b0;
                        sda_high <= tx_data[bit_count];
                        scl_drive <= 1'b0;
                        sda_drive <= tx_data[bit_count];
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b1;
                    end else begin
                        // SCL high, sample SDA
                        scl_high <= 1'b1;
                        sda_high <= tx_data[bit_count];
                        scl_drive <= 1'b1;
                        sda_drive <= tx_data[bit_count];
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b1;
                        if (bit_count == 4'd0) begin
                            state <= S_CHECK_DATA_ACK;
                            bit_count <= 4'd0;
                        end else begin
                            bit_count <= bit_count - 4'd1;
                        end
                    end
                end

                S_CHECK_DATA_ACK: begin
                    if (!tick_done) begin
                        // SCL low, release SDA to read ACK
                        scl_high <= 1'b0;
                        sda_high <= 1'b1;
                        scl_drive <= 1'b0;
                        sda_drive <= 1'b1;
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b0;
                    end else begin
                        // SCL high, sample SDA for ACK
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        scl_drive <= 1'b1;
                        sda_drive <= 1'b1;
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b0;
                        ack_received <= !sda_i;
                        if (ack_received) begin
                            if (is_write_multiple) begin
                                // Check if more data available
                                if (s_axis_data_tvalid) begin
                                    tx_data <= s_axis_data_tdata;
                                    data_last <= s_axis_data_tlast;
                                    state <= S_SEND_DATA;
                                    bit_count <= 4'd7;
                                end else if (need_stop) begin
                                    state <= S_STOP;
                                end else begin
                                    state <= S_DONE;
                                end
                            end else begin
                                // Single write, done
                                if (need_stop) begin
                                    state <= S_STOP;
                                end else begin
                                    state <= S_DONE;
                                end
                            end
                        end else begin
                            // NACK received
                            if (need_stop) begin
                                state <= S_STOP;
                            end else begin
                                state <= S_DONE;
                            end
                        end
                    end
                end

                S_RECV_DATA: begin
                    if (!tick_done) begin
                        // SCL low, release SDA to read data
                        scl_high <= 1'b0;
                        sda_high <= 1'b1;
                        scl_drive <= 1'b0;
                        sda_drive <= 1'b1;
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b0;
                    end else begin
                        // SCL high, sample SDA
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        scl_drive <= 1'b1;
                        sda_drive <= 1'b1;
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b0;
                        rx_data[bit_count] <= sda_i;
                        if (bit_count == 4'd0) begin
                            state <= S_SEND_NACK;
                            bit_count <= 4'd0;
                            data_valid <= 1'b1;
                        end else begin
                            bit_count <= bit_count - 4'd1;
                        end
                    end
                end

                S_SEND_NACK: begin
                    if (!tick_done) begin
                        // SCL low, drive SDA high (NACK)
                        scl_high <= 1'b0;
                        sda_high <= 1'b1;
                        scl_drive <= 1'b0;
                        sda_drive <= 1'b1;
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b1;
                    end else begin
                        // SCL high, SDA high (NACK)
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        scl_drive <= 1'b1;
                        sda_drive <= 1'b1;
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b1;
                        if (need_stop) begin
                            state <= S_STOP;
                        end else begin
                            state <= S_DONE;
                        end
                    end
                end

                S_STOP: begin
                    // Generate STOP condition: SDA low->high while SCL high
                    if (!tick_done) begin
                        // Phase 1: SCL high, SDA low
                        scl_high <= 1'b1;
                        sda_high <= 1'b0;
                        scl_drive <= 1'b1;
                        sda_drive <= 1'b0;
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b1;
                    end else begin
                        // Phase 2: SCL high, SDA high (STOP)
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        scl_drive <= 1'b1;
                        sda_drive <= 1'b1;
                        scl_enable <= 1'b1;
                        sda_enable <= 1'b1;
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    scl_high <= 1'b1;
                    sda_high <= 1'b1;
                    scl_drive <= 1'b1;
                    sda_drive <= 1'b1;
                    scl_enable <= 1'b0;
                    sda_enable <= 1'b0;
                    data_valid <= 1'b0;
                    data_last <= 1'b0;
                    state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end
            end
        end
    end

    // Handle data loading for write operations
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_data <= 8'd0;
        end else begin
            case (state)
                S_SEND_DATA: begin
                    if (is_write_multiple && s_axis_data_tvalid && bit_count == 4'd7) begin
                        tx_data <= s_axis_data_tdata;
                    end
                end
                default: ;
            end
        end
    end

endmodule
