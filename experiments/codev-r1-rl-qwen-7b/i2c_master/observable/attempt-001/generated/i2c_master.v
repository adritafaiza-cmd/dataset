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

    // States
    localparam [3:0]
        IDLE        = 4'd0,
        START       = 4'd1,
        ADDRESS     = 4'd2,
        WRITE_DATA  = 4'd3,
        READ_DATA   = 4'd4,
        ACK         = 4'd5,
        STOP        = 4'd6;

    reg [3:0] state, next_state;

    // SCL generation
    reg scl_en;
    reg [15:0] scl_counter;
    reg scl_phase;
    reg scl_out;

    // SDA generation
    reg sda_out;
    reg sda_en;

    // Data registers
    reg [7:0] tx_data;
    reg [7:0] rx_data;
    reg [2:0] bit_cnt;

    // Command and data handling
    reg [6:0] addr_reg;
    reg read_op;
    reg write_op;
    reg start_cmd;
    reg stop_cmd;
    reg write_multiple_cmd;

    // Status signals
    reg busy_reg;
    reg missed_ack_reg;

    // Host interface signals
    assign s_axis_cmd_ready = (state == IDLE);
    assign s_axis_data_tready = (state == WRITE_DATA && bit_cnt == 0);

    // SCL and SDA assignments
    assign scl_o = scl_t ? 1'bz : scl_out;
    assign sda_o = sda_t ? 1'bz : sda_out;

    // SCL and SDA enables
    assign scl_t = ~scl_en;
    assign sda_t = ~sda_en;

    // Busy and missed_ack
    assign busy = busy_reg;
    assign missed_ack = missed_ack_reg;

    // I2C interface connections
    assign bus_control = 1; // Always controlled by master
    assign bus_active = (state != IDLE);

    // SCL generation
    always @(posedge clk) begin
        if (rst) begin
            scl_counter <= 0;
            scl_phase <= 0;
            scl_out <= 1;
            scl_en <= 0;
        end else begin
            if (state != IDLE) begin
                scl_en <= 1;
                if (scl_counter >= prescale) begin
                    scl_counter <= 0;
                    scl_phase <= ~scl_phase;
                    scl_out <= scl_phase;
                end else begin
                    scl_counter <= scl_counter + 1;
                end
            end else begin
                scl_en <= 0;
                scl_out <= 1;
                scl_counter <= 0;
                scl_phase <= 0;
            end
        end
    end

    // SDA handling
    always @* begin
        case (state)
            IDLE: begin
                sda_out = 1;
                sda_en = 1;
            end
            START: begin
                sda_out = 0;
                sda_en = 0;
            end
            ADDRESS, WRITE_DATA, READ_DATA: begin
                sda_out = tx_data[7 - bit_cnt];
                sda_en = 0;
            end
            ACK: begin
                sda_en = 1; // Release for ACK check
                sda_out = 1;
            end
            STOP: begin
                sda_out = 1;
                sda_en = 0;
            end
            default: begin
                sda_out = 1;
                sda_en = 1;
            end
        endcase
    end

    // State machine
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            busy_reg <= 0;
            missed_ack_reg <= 0;
            addr_reg <= 0;
            read_op <= 0;
            write_op <= 0;
            start_cmd <= 0;
            stop_cmd <= 0;
            write_multiple_cmd <= 0;
            tx_data <= 0;
            rx_data <= 0;
            bit_cnt <= 0;
        end else begin
            if (s_axis_cmd_valid && s_axis_cmd_ready) begin
                addr_reg <= s_axis_cmd_address;
                read_op <= s_axis_cmd_read;
                write_op <= s_axis_cmd_write;
                start_cmd <= s_axis_cmd_start;
                stop_cmd <= s_axis_cmd_stop;
                write_multiple_cmd <= s_axis_cmd_write_multiple;
            end

            case (state)
                IDLE: begin
                    if (start_cmd) begin
                        state <= START;
                        busy_reg <= 1;
                        start_cmd <= 0;
                    end
                end
                START: begin
                    if (scl_phase) begin // Wait for SCL high
                        state <= ADDRESS;
                        tx_data <= {addr_reg, read_op ? 1'b1 : 1'b0};
                        bit_cnt <= 0;
                    end
                end
                ADDRESS: begin
                    if (scl_phase) begin // SCL high, increment bit
                        if (bit_cnt == 7) begin
                            state <= ACK;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end
                end
                ACK: begin
                    if (scl_phase) begin
                        if (sda_i) // No ACK
                            missed_ack_reg <= 1;
                        if (read_op)
                            state <= READ_DATA;
                        else if (write_multiple_cmd)
                            state <= WRITE_DATA;
                        else
                            state <= STOP;
                    end
                end
                WRITE_DATA: begin
                    if (scl_phase) begin
                        if (bit_cnt == 7) begin
                            if (s_axis_data_tvalid && !s_axis_data_tlast) begin
                                tx_data <= s_axis_data_tdata;
                                bit_cnt <= 0;
                            end else begin
                                state <= STOP;
                            end
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end
                end
                READ_DATA: begin
                    if (scl_phase) begin
                        if (bit_cnt == 7) begin
                            rx_data <= {sda_i, rx_data[7:1]};
                            if (s_axis_data_tready) begin
                                m_axis_data_tdata <= {sda_i, rx_data[7:1]};
                                m_axis_data_tvalid <= 1;
                                m_axis_data_tlast <= s_axis_data_tlast;
                            end
                            bit_cnt <= 0;
                            if (s_axis_data_tlast)
                                state <= STOP;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end
                end
                STOP: begin
                    if (scl_phase) begin
                        state <= IDLE;
                        busy_reg <= 0;
                        stop_cmd <= 0;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
