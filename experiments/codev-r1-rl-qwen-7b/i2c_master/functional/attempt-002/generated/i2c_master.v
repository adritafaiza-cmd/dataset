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
    localparam IDLE         = 4'd0;
    localparam START        = 4'd1;
    localparam ADDRESS      = 4'd2;
    localparam ACK_ADDR     = 4'd3;
    localparam WRITE_DATA   = 4'd4;
    localparam READ_DATA    = 4'd5;
    localparam ACK_DATA     = 4'd6;
    localparam STOP         = 4'd7;

    reg [3:0] state, next_state;

    // SCL generation
    reg [15:0] prescale_counter;
    reg scl_phase; // 0: high, 1: low
    reg scl_out;

    // SDA control
    reg sda_out;
    reg sda_enable;

    // Data registers
    reg [7:0] tx_data;
    reg [7:0] rx_data;
    reg tx_valid;
    reg rx_valid;

    // Command registers
    reg cmd_start;
    reg cmd_read;
    reg cmd_write;
    reg cmd_write_multiple;
    reg cmd_stop;

    // Handshake signals
    assign s_axis_cmd_ready = (state == IDLE);
    assign s_axis_data_tready = (state == WRITE_DATA && !tx_valid);

    // SCL generation
    always @(posedge clk) begin
        if (rst) begin
            prescale_counter <= 0;
            scl_phase <= 0;
            scl_out <= 1;
        end else begin
            if (scl_phase) begin
                if (prescale_counter >= prescale) begin
                    scl_phase <= 0;
                    scl_out <= 0;
                    prescale_counter <= 0;
                end else begin
                    prescale_counter <= prescale_counter + 1;
                end
            end else begin
                if (prescale_counter >= prescale) begin
                    scl_phase <= 1;
                    scl_out <= 1;
                    prescale_counter <= 0;
                end else begin
                    prescale_counter <= prescale_counter + 1;
                end
            end
        end
    end

    // SCL and SDA assignments
    assign scl_t = scl_phase; // High when in high phase
    assign scl_o = scl_out;

    assign sda_t = sda_enable;
    assign sda_o = sda_out;

    // State machine
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            sda_out <= 1;
            sda_enable <= 1;
            scl_out <= 1;
            scl_phase <= 0;
            prescale_counter <= 0;
        end else begin
            state <= next_state;
            // Default assignments
            sda_enable <= 1;
            sda_out <= 1;
            case (state)
                IDLE: begin
                    if (s_axis_cmd_valid && s_axis_cmd_ready) begin
                        if (s_axis_cmd_start) begin
                            next_state <= START;
                        end else if (s_axis_cmd_write) begin
                            next_state <= ADDRESS;
                            tx_data <= {s_axis_cmd_address, 1'b0};
                        end else if (s_axis_cmd_read) begin
                            next_state <= ADDRESS;
                            tx_data <= {s_axis_cmd_address, 1'b1};
                        end else if (s_axis_cmd_stop) begin
                            next_state <= STOP;
                        end
                    end
                end
                START: begin
                    // Generate start condition: SDA goes low while SCL is high
                    sda_enable <= 0;
                    sda_out <= 0;
                    next_state <= ADDRESS;
                end
                ADDRESS: begin
                    // Send address byte
                    if (tx_valid) begin
                        next_state <= ACK_ADDR;
                    end
                end
                ACK_ADDR: begin
                    // Check ACK
                    if (sda_i == 0) begin
                        // Proceed
                        if (cmd_write) begin
                            next_state <= WRITE_DATA;
                        end else begin
                            next_state <= READ_DATA;
                        end
                    end else begin
                        // NACK, error handling
                        next_state <= STOP;
                    end
                end
                WRITE_DATA: begin
                    // Send data byte
                    if (tx_valid) begin
                        next_state <= ACK_DATA;
                    end
                end
                READ_DATA: begin
                    // Read data byte
                    if (rx_valid) begin
                        next_state <= ACK_DATA;
                    end
                end
                ACK_DATA: begin
                    // Send ACK/NACK
                    if (cmd_read) begin
                        // Master sends ACK
                        sda_enable <= 0;
                        sda_out <= 0;
                    end
                    next_state <= (cmd_write_multiple) ? WRITE_DATA : STOP;
                end
                STOP: begin
                    // Generate stop condition: SDA goes high while SCL is high
                    sda_enable <= 0;
                    sda_out <= 1;
                    next_state <= IDLE;
                end
                default: next_state <= IDLE;
            endcase
        end
    end

    // Data handling
    assign m_axis_data_tvalid = rx_valid;
    assign m_axis_data_tdata = rx_data;
    assign m_axis_data_tlast = s_axis_data_tlast;

    // Missed ACK
    assign missed_ack = (state == ACK_ADDR && sda_i != 0) || (state == ACK_DATA && sda_i != 0);

    // Status signals
    assign busy = (state != IDLE);
    assign bus_control = 1;
    assign bus_active = (state != IDLE);

endmodule
