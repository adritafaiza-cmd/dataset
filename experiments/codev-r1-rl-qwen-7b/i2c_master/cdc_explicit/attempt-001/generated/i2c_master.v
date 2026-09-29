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
    reg [15:0] prescale_counter;
    reg scl_phase;
    reg scl_enable;
    reg scl_out;

    // SDA generation
    reg sda_enable;
    reg sda_out;

    // Data handling
    reg [7:0] shift_reg;
    reg [2:0] bit_count;
    reg read_mode;

    // Command handling
    reg cmd_start, cmd_stop, cmd_read, cmd_write, cmd_write_multiple;
    reg cmd_valid;

    // Data interface
    reg [7:0] data_out;
    reg data_valid;
    reg data_last;

    // Missed ACK
    reg missed_ack_reg;

    // Status signals
    reg busy_reg;
    reg bus_control_reg;
    reg bus_active_reg;

    // Assign outputs
    assign s_axis_cmd_ready = (state == IDLE) || (state == STOP && cmd_stop);

    assign s_axis_data_tready = (state == WRITE_DATA) && (bit_count == 0);

    assign scl_o = scl_out;
    assign scl_t = ~scl_enable;

    assign sda_o = sda_out;
    assign sda_t = ~sda_enable;

    assign missed_ack = missed_ack_reg;

    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;

    assign m_axis_data_tdata = data_out;
    assign m_axis_data_tvalid = data_valid;
    assign m_axis_data_tlast = data_last;

    // State machine and SCL generation
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            prescale_counter <= 0;
            scl_phase <= 0;
            scl_enable <= 0;
            scl_out <= 1;
            sda_enable <= 0;
            sda_out <= 1;
            shift_reg <= 0;
            bit_count <= 0;
            read_mode <= 0;
            cmd_start <= 0;
            cmd_stop <= 0;
            cmd_read <= 0;
            cmd_write <= 0;
            cmd_write_multiple <= 0;
            cmd_valid <= 0;
            data_out <= 0;
            data_valid <= 0;
            data_last <= 0;
            missed_ack_reg <= 0;
            busy_reg <= 0;
            bus_control_reg <= 0;
            bus_active_reg <= 0;
        end else begin
            if (s_axis_cmd_valid && s_axis_cmd_ready) begin
                cmd_start <= s_axis_cmd_start;
                cmd_stop <= s_axis_cmd_stop;
                cmd_read <= s_axis_cmd_read;
                cmd_write <= s_axis_cmd_write;
                cmd_write_multiple <= s_axis_cmd_write_multiple;
                cmd_valid <= 1;
            end

            case (state)
                IDLE: begin
                    if (cmd_start) begin
                        sda_enable <= 1;
                        sda_out <= 0;
                        scl_enable <= 1;
                        scl_out <= 0;
                        state <= START;
                    end
                    busy_reg <= 0;
                end
                START: begin
                    sda_enable <= 0;
                    state <= ADDRESS;
                end
                ADDRESS: begin
                    // Send address + R/W bit
                    if (prescale_counter == prescale) begin
                        prescale_counter <= 0;
                        scl_phase <= ~scl_phase;
                        scl_enable <= ~scl_enable;
                        scl_out <= ~scl_out;
                        if (scl_phase) begin
                            shift_reg <= {s_axis_cmd_address, cmd_read ? 1'b1 : 1'b0};
                            bit_count <= 7;
                            state <= WRITE_DATA;
                        end
                    end else begin
                        prescale_counter <= prescale_counter + 1;
                    end
                end
                WRITE_DATA: begin
                    if (prescale_counter == prescale) begin
                        prescale_counter <= 0;
                        scl_phase <= ~scl_phase;
                        scl_enable <= ~scl_enable;
                        scl_out <= ~scl_out;
                        if (scl_phase) begin
                            if (bit_count == 0) begin
                                if (cmd_write_multiple) begin
                                    state <= WRITE_DATA;
                                end else begin
                                    state <= ACK;
                                end
                            end else begin
                                shift_reg <= {shift_reg[6:0], 1'b0};
                                bit_count <= bit_count - 1;
                            end
                        end
                    end else begin
                        prescale_counter <= prescale_counter + 1;
                    end
                end
                READ_DATA: begin
                    // Read data from slave
                    if (prescale_counter == prescale) begin
                        prescale_counter <= 0;
                        scl_phase <= ~scl_phase;
                        scl_enable <= ~scl_enable;
                        scl_out <= ~scl_out;
                        if (scl_phase) begin
                            if (bit_count == 0) begin
                                data_valid <= 1;
                                data_out <= {shift_reg[6:0], sda_i};
                                data_last <= s_axis_data_tlast;
                                state <= ACK;
                            end else begin
                                shift_reg <= {shift_reg[6:0], sda_i};
                                bit_count <= bit_count - 1;
                            end
                        end
                    end else begin
                        prescale_counter <= prescale_counter + 1;
                    end
                end
                ACK: begin
                    // Check ACK from slave
                    if (prescale_counter == prescale) begin
                        prescale_counter <= 0;
                        scl_phase <= ~scl_phase;
                        scl_enable <= ~scl_enable;
                        scl_out <= ~scl_out;
                        if (scl_phase) begin
                            if (sda_i) missed_ack_reg <= 1;
                            if (cmd_read) begin
                                state <= READ_DATA;
                                bit_count <= 7;
                            end else begin
                                state <= STOP;
                            end
                        end
                    end else begin
                        prescale_counter <= prescale_counter + 1;
                    end
                end
                STOP: begin
                    sda_enable <= 1;
                    sda_out <= 1;
                    if (prescale_counter == prescale) begin
                        prescale_counter <= 0;
                        scl_phase <= ~scl_phase;
                        scl_enable <= ~scl_enable;
                        scl_out <= ~scl_out;
                        if (scl_phase) begin
                            sda_enable <= 1;
                            sda_out <= 1;
                            state <= IDLE;
                            busy_reg <= 0;
                        end
                    end else begin
                        prescale_counter <= prescale_counter + 1;
                    end
                end
                default: state <= IDLE;
            endcase

            // SCL generation
            if (state != IDLE) begin
                if (prescale_counter == prescale) begin
                    prescale_counter <= 0;
                    scl_phase <= ~scl_phase;
                    scl_enable <= ~scl_enable;
                    scl_out <= ~scl_out;
                end else begin
                    prescale_counter <= prescale_counter + 1;
                end
            end else begin
                prescale_counter <= 0;
                scl_phase <= 0;
                scl_enable <= 0;
                scl_out <= 1;
            end
        end
    end

endmodule
