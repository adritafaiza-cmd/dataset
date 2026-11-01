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
    localparam S_STOP = 4'd4;
    localparam S_ACK = 4'd5;

    reg [3:0] state;
    reg [3:0] next_state;

    // Command register
    reg [6:0] cmd_address;
    reg       cmd_read;
    reg       cmd_write;
    reg       cmd_write_multiple;
    reg       cmd_stop;
    reg       cmd_start;

    // Data registers
    reg [7:0] tx_data;
    reg       tx_valid;
    reg       tx_last;
    reg [7:0] rx_data;
    reg       rx_valid;
    reg       rx_last;

    // Bit counter
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    reg       shift_dir; // 0 = shift out, 1 = shift in

    // ACK tracking
    reg       ack_received;
    reg       missed_ack_reg;

    // Prescale counter
    reg [15:0] prescale_cnt;
    reg        prescale_done;

    // Bus control signals
    reg       scl_drive;
    reg       sda_drive;
    reg       scl_release;
    reg       sda_release;

    // Internal signals
    wire      scl_high;
    wire      sda_high;
    wire      scl_low;
    wire      sda_low;

    assign scl_high = scl_i & ~scl_t;
    assign sda_high = sda_i & ~sda_t;
    assign scl_low  = ~scl_i | scl_t;
    assign sda_low  = ~sda_i | sda_t;

    // Open-drain outputs
    assign scl_o = ~scl_drive;
    assign sda_o = ~sda_drive;
    assign scl_t = scl_release;
    assign sda_t = sda_release;

    // Status outputs
    assign busy = (state != S_IDLE);
    assign bus_control = (state != S_IDLE);
    assign bus_active = (state == S_START || state == S_ADDR || state == S_DATA || state == S_ACK || state == S_STOP);
    assign missed_ack = missed_ack_reg;

    // Handshake ready
    assign s_axis_cmd_ready = (state == S_IDLE) && !busy;
    assign s_axis_data_tready = (state == S_DATA) && shift_dir == 0 && bit_cnt == 0 && !tx_valid;
    assign m_axis_data_tvalid = rx_valid;
    assign m_axis_data_tlast = rx_last;
    assign m_axis_data_tdata = rx_data;

    // Prescale logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prescale_cnt <= 16'd0;
            prescale_done <= 1'b0;
        end else begin
            if (prescale_done) begin
                prescale_done <= 1'b0;
            end else if (prescale_cnt >= prescale) begin
                prescale_cnt <= 16'd0;
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
            cmd_address <= 7'd0;
            cmd_read <= 1'b0;
            cmd_write <= 1'b0;
            cmd_write_multiple <= 1'b0;
            cmd_stop <= 1'b0;
            cmd_start <= 1'b0;
            tx_data <= 8'd0;
            tx_valid <= 1'b0;
            tx_last <= 1'b0;
            rx_data <= 8'd0;
            rx_valid <= 1'b0;
            rx_last <= 1'b0;
            bit_cnt <= 3'd0;
            shift_reg <= 8'd0;
            shift_dir <= 1'b0;
            ack_received <= 1'b0;
            missed_ack_reg <= 1'b0;
            scl_drive <= 1'b1;
            sda_drive <= 1'b1;
            scl_release <= 1'b0;
            sda_release <= 1'b0;
        end else begin
            // Default: hold current state
            state <= next_state;

            // Handle command acceptance
            if (state == S_IDLE && s_axis_cmd_valid) begin
                cmd_address <= s_axis_cmd_address;
                cmd_read <= s_axis_cmd_read;
                cmd_write <= s_axis_cmd_write;
                cmd_write_multiple <= s_axis_cmd_write_multiple;
                cmd_stop <= s_axis_cmd_stop;
                cmd_start <= s_axis_cmd_start;
                missed_ack_reg <= 1'b0;
                rx_valid <= 1'b0;
                rx_last <= 1'b0;
            end

            // Handle data acceptance for write
            if (state == S_DATA && shift_dir == 0 && bit_cnt == 0 && !tx_valid && s_axis_data_tvalid) begin
                tx_data <= s_axis_data_tdata;
                tx_valid <= 1'b1;
                tx_last <= s_axis_data_tlast;
            end

            // State transitions
            case (state)
                S_IDLE: begin
                    if (s_axis_cmd_valid) begin
                        if (cmd_start || s_axis_cmd_start) begin
                            state <= S_START;
                            scl_drive <= 1'b1;
                            sda_drive <= 1'b1;
                            scl_release <= 1'b0;
                            sda_release <= 1'b0;
                        end else if (cmd_stop || s_axis_cmd_stop) begin
                            state <= S_STOP;
                            scl_drive <= 1'b1;
                            sda_drive <= 1'b1;
                            scl_release <= 1'b0;
                            sda_release <= 1'b0;
                        end else begin
                            state <= S_START;
                            scl_drive <= 1'b1;
                            sda_drive <= 1'b1;
                            scl_release <= 1'b0;
                            sda_release <= 1'b0;
                        end
                    end
                end

                S_START: begin
                    if (prescale_done) begin
                        // START condition: SDA high to low while SCL high
                        if (scl_high && sda_high) begin
                            sda_drive <= 1'b0;
                            sda_release <= 1'b0;
                        end
                        // After START, go to address phase
                        state <= S_ADDR;
                        bit_cnt <= 3'd7;
                        shift_reg <= {cmd_address, cmd_read};
                        shift_dir <= 1'b0;
                        scl_drive <= 1'b1;
                        sda_drive <= 1'b1;
                        scl_release <= 1'b0;
                        sda_release <= 1'b0;
                    end
                end

                S_ADDR: begin
                    if (prescale_done) begin
                        if (bit_cnt == 3'd0) begin
                            // All bits sent, wait for ACK
                            state <= S_ACK;
                            scl_drive <= 1'b1;
                            sda_drive <= 1'b1;
                            scl_release <= 1'b0;
                            sda_release <= 1'b0;
                        end else begin
                            // Clock out next bit
                            if (scl_high) begin
                                // SCL high, prepare next bit on SDA
                                sda_drive <= ~shift_reg[7];
                                sda_release <= 1'b0;
                                shift_reg <= {shift_reg[6:0], 1'b0};
                                bit_cnt <= bit_cnt - 1'b1;
                            end else begin
                                // SCL low, toggle SCL
                                scl_drive <= 1'b1;
                                scl_release <= 1'b0;
                            end
                        end
                    end
                end

                S_ACK: begin
                    if (prescale_done) begin
                        // Release SDA to read ACK
                        sda_drive <= 1'b1;
                        sda_release <= 1'b1;
                        // Wait for SCL high to sample ACK
                        if (scl_high) begin
                            ack_received <= ~sda_low; // ACK is SDA low
                            if (ack_received) begin
                                if (cmd_read) begin
                                    // Read mode: shift in data
                                    state <= S_DATA;
                                    bit_cnt <= 3'd7;
                                    shift_reg <= 8'd0;
                                    shift_dir <= 1'b1;
                                    scl_drive <= 1'b1;
                                    sda_drive <= 1'b1;
                                    scl_release <= 1'b0;
                                    sda_release <= 1'b0;
                                end else if (cmd_write) begin
                                    // Write mode: wait for data
                                    state <= S_DATA;
                                    bit_cnt <= 3'd0;
                                    shift_reg <= 8'd0;
                                    shift_dir <= 1'b0;
                                    scl_drive <= 1'b1;
                                    sda_drive <= 1'b1;
                                    scl_release <= 1'b0;
                                    sda_release <= 1'b0;
                                end else begin
                                    // No data, go to stop or idle
                                    if (cmd_stop || s_axis_cmd_stop) begin
                                        state <= S_STOP;
                                        scl_drive <= 1'b1;
                                        sda_drive <= 1'b1;
                                        scl_release <= 1'b0;
                                        sda_release <= 1'b0;
                                    end else begin
                                        state <= S_IDLE;
                                        scl_drive <= 1'b1;
                                        sda_drive <= 1'b1;
                                        scl_release <= 1'b0;
                                        sda_release <= 1'b0;
                                    end
                                end
                            end else begin
                                // NACK
                                missed_ack_reg <= 1'b1;
                                if (cmd_stop || s_axis_cmd_stop) begin
                                    state <= S_STOP;
                                    scl_drive <= 1'b1;
                                    sda_drive <= 1'b1;
                                    scl_release <= 1'b0;
                                    sda_release <= 1'b0;
                                end else begin
                                    state <= S_IDLE;
                                    scl_drive <= 1'b1;
                                    sda_drive <= 1'b1;
                                    scl_release <= 1'b0;
                                    sda_release <= 1'b0;
                                end
                            end
                        end else begin
                            // SCL low, toggle SCL
                            scl_drive <= 1'b1;
                            scl_release <= 1'b0;
                        end
                    end
                end

                S_DATA: begin
                    if (prescale_done) begin
                        if (shift_dir == 0) begin
                            // Write mode
                            if (bit_cnt == 3'd0) begin
                                if (tx_valid) begin
                                    // Start sending data
                                    bit_cnt <= 3'd7;
                                    shift_reg <= tx_data;
                                    tx_valid <= 1'b0;
                                end else begin
                                    // No data, wait
                                end
                            end else begin
                                if (scl_high) begin
                                    // SCL high, prepare next bit on SDA
                                    sda_drive <= ~shift_reg[7];
                                    sda_release <= 1'b0;
                                    shift_reg <= {shift_reg[6:0], 1'b0};
                                    bit_cnt <= bit_cnt - 1'b1;
                                end else begin
                                    // SCL low, toggle SCL
                                    scl_drive <= 1'b1;
                                    scl_release <= 1'b0;
                                end
                            end
                        end else begin
                            // Read mode
                            if (bit_cnt == 3'd0) begin
                                // All bits received, send ACK/NACK
                                state <= S_ACK;
                                scl_drive <= 1'b1;
                                sda_drive <= 1'b1;
                                scl_release <= 1'b0;
                                sda_release <= 1'b0;
                                // Output received data
                                rx_data <= shift_reg;
                                rx_valid <= 1'b1;
                                rx_last <= tx_last;
                            end else begin
                                if (scl_high) begin
                                    // SCL high, sample SDA
                                    shift_reg <= {shift_reg[6:0], ~sda_low};
                                    bit_cnt <= bit_cnt - 1'b1;
                                end else begin
                                    // SCL low, toggle SCL
                                    scl_drive <= 1'b1;
                                    scl_release <= 1'b0;
                                end
                            end
                        end
                    end
                end

                S_STOP: begin
                    if (prescale_done) begin
                        // STOP condition: SDA low to high while SCL high
                        if (scl_high && sda_low) begin
                            sda_drive <= 1'b1;
                            sda_release <= 1'b0;
                        end
                        // After STOP, go to idle
                        state <= S_IDLE;
                        scl_drive <= 1'b1;
                        sda_drive <= 1'b1;
                        scl_release <= 1'b0;
                        sda_release <= 1'b0;
                    end
                end

                default: begin
                    state <= S_IDLE;
                    scl_drive <= 1'b1;
                    sda_drive <= 1'b1;
                    scl_release <= 1'b0;
                    sda_release <= 1'b0;
                end
            endcase
        end
    end

    // Next state logic (combinational)
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (s_axis_cmd_valid) begin
                    next_state = S_START;
                end
            end
            S_START: begin
                if (prescale_done) begin
                    next_state = S_ADDR;
                end
            end
            S_ADDR: begin
                if (prescale_done) begin
                    if (bit_cnt == 3'd0) begin
                        next_state = S_ACK;
                    end
                end
            end
            S_ACK: begin
                if (prescale_done && scl_high) begin
                    if (ack_received) begin
                        if (cmd_read) begin
                            next_state = S_DATA;
                        end else if (cmd_write) begin
                            next_state = S_DATA;
                        end else begin
                            if (cmd_stop || s_axis_cmd_stop) begin
                                next_state = S_STOP;
                            end else begin
                                next_state = S_IDLE;
                            end
                        end
                    end else begin
                        if (cmd_stop || s_axis_cmd_stop) begin
                            next_state = S_STOP;
                        end else begin
                            next_state = S_IDLE;
                        end
                    end
                end
            end
            S_DATA: begin
                if (prescale_done) begin
                    if (shift_dir == 0) begin
                        // Write mode
                        if (bit_cnt == 3'd0 && !tx_valid) begin
                            // Wait for data
                        end else if (bit_cnt == 3'd0) begin
                            // Start sending
                        end
                    end else begin
                        // Read mode
                        if (bit_cnt == 3'd0) begin
                            next_state = S_ACK;
                        end
                    end
                end
            end
            S_STOP: begin
                if (prescale_done) begin
                    next_state = S_IDLE;
                end
            end
            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

endmodule
