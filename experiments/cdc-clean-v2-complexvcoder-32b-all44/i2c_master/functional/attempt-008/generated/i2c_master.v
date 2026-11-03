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

    // Internal signals
    reg [3:0]          state, next_state;
    reg [2:0]          bit_count;
    reg [3:0]          byte_count;
    reg [15:0]         scl_cnt, sda_cnt;
    reg [7:0]          shift_reg;
    reg [7:0]          data_in, data_out;
    reg                cmd_start, cmd_read, cmd_write, cmd_write_multiple, cmd_stop, cmd_valid;
    reg                data_valid, data_last, data_ready;
    reg                scl, sda;
    reg                scl_o_int, scl_t_int, sda_o_int, sda_t_int;
    reg                busy_int, bus_control_int, bus_active_int, missed_ack_int;

    // State definitions
    localparam IDLE = 4'b0000;
    localparam START = 4'b0001;
    localparam ADDR = 4'b0010;
    localparam R_W = 4'b0011;
    localparam DATA_W = 4'b0100;
    localparam DATA_R = 4'b0101;
    localparam STOP = 4'b0110;
    localparam ACK = 4'b0111;
    localparam WAIT = 4'b1000;

    // State transition logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (cmd_start && cmd_valid)
                    next_state = START;
            end
            START: begin
                if (scl_cnt == prescale - 1)
                    next_state = ADDR;
            end
            ADDR: begin
                if (bit_count == 3'b111)
                    next_state = R_W;
            end
            R_W: begin
                if (scl_cnt == prescale - 1)
                    next_state = cmd_write ? DATA_W : DATA_R;
            end
            DATA_W: begin
                if (bit_count == 3'b111 && sda_cnt == prescale - 1)
                    next_state = ACK;
            end
            DATA_R: begin
                if (bit_count == 3'b111 && scl_cnt == prescale - 1)
                    next_state = cmd_stop ? STOP : DATA_R;
            end
            ACK: begin
                if (scl_cnt == prescale - 1)
                    next_state = cmd_stop ? STOP : WAIT;
            end
            STOP: begin
                if (scl_cnt == prescale - 1)
                    next_state = IDLE;
            end
            WAIT: begin
                if (scl_cnt == prescale - 1)
                    next_state = cmd_write ? DATA_W : DATA_R;
            end
        endcase
    end

    // Output logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_o_int <= 1'b1;
            scl_t_int <= 1'b1;
            sda_o_int <= 1'b1;
            sda_t_int <= 1'b1;
            busy_int <= 1'b0;
            bus_control_int <= 1'b0;
            bus_active_int <= 1'b0;
            missed_ack_int <= 1'b0;
            bit_count <= 3'b000;
            byte_count <= 4'b0000;
            scl_cnt <= 16'b0000;
            sda_cnt <= 16'b0000;
            shift_reg <= 8'b00000000;
            data_in <= 8'b00000000;
            data_out <= 8'b00000000;
            cmd_start <= 1'b0;
            cmd_read <= 1'b0;
            cmd_write <= 1'b0;
            cmd_write_multiple <= 1'b0;
            cmd_stop <= 1'b0;
            cmd_valid <= 1'b0;
            data_valid <= 1'b0;
            data_last <= 1'b0;
            data_ready <= 1'b0;
            scl <= 1'b1;
            sda <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    busy_int <= 1'b0;
                    bus_control_int <= 1'b0;
                    bus_active_int <= 1'b0;
                    missed_ack_int <= 1'b0;
                    scl_o_int <= 1'b1;
                    scl_t_int <= 1'b1;
                    sda_o_int <= 1'b1;
                    sda_t_int <= 1'b1;
                    cmd_start <= s_axis_cmd_start;
                    cmd_read <= s_axis_cmd_read;
                    cmd_write <= s_axis_cmd_write;
                    cmd_write_multiple <= s_axis_cmd_write_multiple;
                    cmd_stop <= s_axis_cmd_stop;
                    cmd_valid <= s_axis_cmd_valid;
                    if (cmd_valid) begin
                        s_axis_cmd_ready <= 1'b1;
                    end else begin
                        s_axis_cmd_ready <= 1'b0;
                    end
                end
                START: begin
                    busy_int <= 1'b1;
                    bus_control_int <= 1'b1;
                    bus_active_int <= 1'b1;
                    scl_o_int <= (scl_cnt < prescale) ? 1'b1 : 1'b0;
                    scl_t_int <= 1'b0;
                    sda_o_int <= (scl_cnt < prescale) ? 1'b1 : 1'b0;
                    sda_t_int <= 1'b0;
                    if (scl_cnt < prescale) begin
                        scl_cnt <= scl_cnt + 1'b1;
                    end else begin
                        scl_cnt <= 16'b0000;
                    end
                end
                ADDR: begin
                    scl_o_int <= (scl_cnt < prescale) ? 1'b0 : 1'b1;
                    scl_t_int <= 1'b0;
                    sda_o_int <= (scl_cnt < prescale) ? (shift_reg[7-bit_count]) : 1'bZ;
                    sda_t_int <= (scl_cnt < prescale) ? 1'b0 : 1'b1;
                    if (scl_cnt < prescale) begin
                        scl_cnt <= scl_cnt + 1'b1;
                    end else begin
                        scl_cnt <= 16'b0000;
                        bit_count <= bit_count + 1'b1;
                    end
                end
                R_W: begin
                    scl_o_int <= (scl_cnt < prescale) ? 1'b0 : 1'b1;
                    scl_t_int <= 1'b0;
                    sda_o_int <= (scl_cnt < prescale) ? cmd_read : 1'bZ;
                    sda_t_int <= (scl_cnt < prescale) ? 1'b0 : 1'b1;
                    if (scl_cnt < prescale) begin
                        scl_cnt <= scl_cnt + 1'b1;
                    end else begin
                        scl_cnt <= 16'b0000;
                        if (cmd_read) begin
                            shift_reg[7] <= sda_i;
                        end
                        bit_count <= 3'b000;
                        byte_count <= byte_count + 1'b1;
                    end
                end
                DATA_W: begin
                    scl_o_int <= (scl_cnt < prescale) ? 1'b0 : 1'b1;
                    scl_t_int <= 1'b0;
                    sda_o_int <= (scl_cnt < prescale) ? (shift_reg[7-bit_count]) : 1'bZ;
                    sda_t_int <= (scl_cnt < prescale) ? 1'b0 : 1'b1;
                    if (scl_cnt < prescale) begin
                        scl_cnt <= scl_cnt + 1'b1;
                    end else begin
                        scl_cnt <= 16'b0000;
                        bit_count <= bit_count + 1'b1;
                        if (bit_count == 3'b111) begin
                            sda_cnt <= 16'b0000;
                        end else begin
                            sda_cnt <= sda_cnt + 1'b1;
                        end
                    end
                end
                DATA_R: begin
                    scl_o_int <= (scl_cnt < prescale) ? 1'b0 : 1'b1;
                    scl_t_int <= 1'b0;
                    sda_o_int <= (scl_cnt < prescale) ? 1'b1 : 1'bZ;
                    sda_t_int <= (scl_cnt < prescale) ? 1'b0 : 1'b1;
                    if (scl_cnt < prescale) begin
                        scl_cnt <= scl_cnt + 1'b1;
                    end else begin
                        scl_cnt <= 16'b0000;
                        if (bit_count == 3'b111) begin
                            shift_reg[7] <= sda_i;
                            bit_count <= 3'b000;
                            byte_count <= byte_count + 1'b1;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end
                ACK: begin
                    scl_o_int <= (scl_cnt < prescale) ? 1'b0 : 1'b1;
                    scl_t_int <= 1'b0;
                    sda_o_int <= (scl_cnt < prescale) ? 1'b1 : 1'bZ;
                    sda_t_int <= (scl_cnt < prescale) ? 1'b0 : 1'b1;
                    if (scl_cnt < prescale) begin
                        scl_cnt <= scl_cnt + 1'b1;
                    end else begin
                        scl_cnt <= 16'b0000;
                        if (sda_i) begin
                            missed_ack_int <= 1'b1;
                        end else begin
                            missed_ack_int <= 1'b0;
                        end
                    end
                end
                STOP: begin
                    scl_o_int <= (scl_cnt < prescale) ? 1'b0 : 1'b1;
                    scl_t_int <= 1'b0;
                    sda_o_int <= (scl_cnt < prescale) ? 1'b0 : 1'b1;
                    sda_t_int <= 1'b0;
                    if (scl_cnt < prescale) begin
                        scl_cnt <= scl_cnt + 1'b1;
                    end else begin
                        scl_cnt <= 16'b0000;
                    end
                end
                WAIT: begin
                    scl_o_int <= 1'b1;
                    scl_t_int <= 1'b1;
                    sda_o_int <= 1'b1;
                    sda_t_int <= 1'b1;
                    if (scl_cnt < prescale) begin
                        scl_cnt <= scl_cnt + 1'b1;
                    end else begin
                        scl_cnt <= 16'b0000;
                    end
                end
            endcase
        end
    end

    // Command and data handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 8'b00000000;
            data_in <= 8'b00000000;
            data_out <= 8'b00000000;
            data_valid <= 1'b0;
            data_last <= 1'b0;
            data_ready <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (cmd_valid) begin
                        shift_reg <= {s_axis_cmd_address, cmd_read};
                    end
                end
                DATA_W: begin
                    if (bit_count == 3'b111 && sda_cnt == prescale - 1) begin
                        if (s_axis_data_tvalid) begin
                            shift_reg <= s_axis_data_tdata;
                            data_ready <= 1'b1;
                        end else begin
                            data_ready <= 1'b0;
                        end
                    end
                end
                DATA_R: begin
                    if (bit_count == 3'b111 && scl_cnt == prescale - 1) begin
                        if (byte_count == 4'b1000) begin
                            data_valid <= 1'b0;
                            data_last <= 1'b1;
                        end else begin
                            data_valid <= 1'b1;
                            data_last <= 1'b0;
                            data_out <= shift_reg;
                        end
                    end
                end
                WAIT: begin
                    data_ready <= 1'b0;
                end
                default: begin
                    data_ready <= 1'b0;
                end
            endcase
        end
    end

    // Handshake signals
    assign s_axis_cmd_ready = (state == IDLE) && cmd_valid;
    assign s_axis_data_tready = data_ready;
    assign m_axis_data_tdata = data_out;
    assign m_axis_data_tvalid = data_valid;
    assign m_axis_data_tlast = data_last;

    // I2C signals
    assign scl_o = scl_o_int;
    assign scl_t = scl_t_int;
    assign sda_o = sda_o_int;
    assign sda_t = sda_t_int;

    // Status signals
    assign busy = busy_int;
    assign bus_control = bus_control_int;
    assign bus_active = bus_active_int;
    assign missed_ack = missed_ack_int;

endmodule
