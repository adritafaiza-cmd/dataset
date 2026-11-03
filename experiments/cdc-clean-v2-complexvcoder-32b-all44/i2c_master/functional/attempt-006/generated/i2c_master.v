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

    /*
     * Internal signals
     */
    reg [6:0]  cmd_address_reg;
    reg        cmd_start_reg;
    reg        cmd_read_reg;
    reg        cmd_write_reg;
    reg        cmd_write_multiple_reg;
    reg        cmd_stop_reg;
    reg        cmd_valid_reg;
    reg        cmd_ready;
    reg [7:0]  data_tdata_reg;
    reg        data_tvalid_reg;
    reg        data_tready;
    reg        data_tlast_reg;
    reg [7:0]  m_data_tdata;
    reg        m_data_tvalid;
    reg        m_data_tready_reg;
    reg        m_data_tlast;
    reg        scl_o_reg;
    reg        scl_t_reg;
    reg        sda_o_reg;
    reg        sda_t_reg;
    reg        busy_reg;
    reg        bus_control_reg;
    reg        bus_active_reg;
    reg        missed_ack_reg;
    reg [15:0] clock_divider;
    reg [15:0] clock_divider_counter;
    reg [3:0]  bit_counter;
    reg [7:0]  byte_counter;
    reg [2:0]  state;
    reg [2:0]  next_state;
    reg [7:0]  shift_reg;
    reg        ack_bit;
    reg        start_condition;
    reg        stop_condition;
    reg        read_mode;
    reg        write_mode;
    reg        write_multiple_mode;

    /*
     * State definitions
     */
    localparam IDLE = 3'b000;
    localparam START = 3'b001;
    localparam ADDRESS = 3'b010;
    localparam DATA = 3'b011;
    localparam ACK = 3'b100;
    localparam STOP = 3'b101;

    /*
     * State machine
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (cmd_valid_reg) begin
                    next_state = START;
                end
            end
            START: begin
                if (clock_divider_counter == clock_divider) begin
                    next_state = ADDRESS;
                end
            end
            ADDRESS: begin
                if (bit_counter == 4'd7 && clock_divider_counter == clock_divider) begin
                    next_state = ACK;
                end
            end
            ACK: begin
                if (clock_divider_counter == clock_divider) begin
                    if (ack_bit) begin
                        if (write_mode || write_multiple_mode) begin
                            next_state = DATA;
                        end else if (read_mode) begin
                            next_state = DATA;
                        end
                    end else begin
                        next_state = STOP;
                    end
                end
            end
            DATA: begin
                if (bit_counter == 4'd7 && clock_divider_counter == clock_divider) begin
                    next_state = ACK;
                end
            end
            STOP: begin
                if (clock_divider_counter == clock_divider) begin
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    /*
     * Clock divider
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clock_divider_counter <= 16'b0;
        end else if (clock_divider_counter == clock_divider) begin
            clock_divider_counter <= 16'b0;
        end else begin
            clock_divider_counter <= clock_divider_counter + 16'b1;
        end
    end

    /*
     * Bit and byte counters
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_counter <= 4'b0;
            byte_counter <= 8'b0;
        end else begin
            case (state)
                START: begin
                    bit_counter <= 4'b0;
                end
                ADDRESS: begin
                    if (clock_divider_counter == clock_divider) begin
                        bit_counter <= bit_counter + 4'b1;
                    end
                end
                DATA: begin
                    if (clock_divider_counter == clock_divider) begin
                        bit_counter <= bit_counter + 4'b1;
                    end
                end
                ACK: begin
                    bit_counter <= 4'b0;
                end
                STOP: begin
                    bit_counter <= 4'b0;
                end
                default: begin
                    bit_counter <= 4'b0;
                end
            endcase

            if (state == ACK && clock_divider_counter == clock_divider) begin
                if (ack_bit) begin
                    if (write_mode || write_multiple_mode) begin
                        byte_counter <= byte_counter + 8'b1;
                    end else if (read_mode) begin
                        byte_counter <= byte_counter + 8'b1;
                    end
                end
            end
        end
    end

    /*
     * Shift register
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 8'b0;
        end else begin
            case (state)
                START: begin
                    shift_reg <= {cmd_address_reg, read_mode};
                end
                ADDRESS: begin
                    if (clock_divider_counter == clock_divider && bit_counter < 4'd7) begin
                        shift_reg <= {1'b0, shift_reg[7:1]};
                    end
                end
                DATA: begin
                    if (clock_divider_counter == clock_divider && bit_counter < 4'd7) begin
                        if (write_mode || write_multiple_mode) begin
                            shift_reg <= {1'b0, shift_reg[7:1]};
                        end else if (read_mode) begin
                            shift_reg <= {sda_i, shift_reg[7:1]};
                        end
                    end
                end
                ACK: begin
                    if (clock_divider_counter == clock_divider) begin
                        ack_bit <= sda_i;
                    end
                end
                default: begin
                    shift_reg <= 8'b0;
                end
            endcase
        end
    end

    /*
     * Control signals
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            start_condition <= 1'b0;
            stop_condition <= 1'b0;
            read_mode <= 1'b0;
            write_mode <= 1'b0;
            write_multiple_mode <= 1'b0;
            cmd_ready <= 1'b0;
            data_tready <= 1'b0;
            m_data_tvalid <= 1'b0;
            m_data_tlast <= 1'b0;
            scl_o_reg <= 1'b1;
            scl_t_reg <= 1'b1;
            sda_o_reg <= 1'b1;
            sda_t_reg <= 1'b1;
            busy_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            missed_ack_reg <= 1'b0;
            cmd_address_reg <= 7'b0;
            cmd_start_reg <= 1'b0;
            cmd_read_reg <= 1'b0;
            cmd_write_reg <= 1'b0;
            cmd_write_multiple_reg <= 1'b0;
            cmd_stop_reg <= 1'b0;
            cmd_valid_reg <= 1'b0;
            data_tdata_reg <= 8'b0;
            data_tvalid_reg <= 1'b0;
            data_tlast_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    cmd_ready <= 1'b1;
                    if (cmd_valid_reg) begin
                        cmd_address_reg <= s_axis_cmd_address;
                        cmd_start_reg <= s_axis_cmd_start;
                        cmd_read_reg <= s_axis_cmd_read;
                        cmd_write_reg <= s_axis_cmd_write;
                        cmd_write_multiple_reg <= s_axis_cmd_write_multiple;
                        cmd_stop_reg <= s_axis_cmd_stop;
                        cmd_valid_reg <= 1'b0;
                        read_mode <= s_axis_cmd_read;
                        write_mode <= s_axis_cmd_write;
                        write_multiple_mode <= s_axis_cmd_write_multiple;
                    end
                end
                START: begin
                    start_condition <= 1'b1;
                    scl_o_reg <= 1'b0;
                    scl_t_reg <= 1'b0;
                    sda_o_reg <= 1'b0;
                    sda_t_reg <= 1'b0;
                end
                ADDRESS: begin
                    start_condition <= 1'b0;
                    if (clock_divider_counter == clock_divider) begin
                        sda_o_reg <= shift_reg[7];
                        sda_t_reg <= 1'b0;
                    end
                end
                ACK: begin
                    if (clock_divider_counter == clock_divider) begin
                        sda_t_reg <= 1'b1;
                        if (ack_bit) begin
                            if (write_mode || write_multiple_mode) begin
                                if (data_tvalid_reg && data_tready) begin
                                    data_tready <= 1'b0;
                                    data_tvalid_reg <= 1'b0;
                                end
                            end else if (read_mode) begin
                                m_data_tvalid <= 1'b1;
                                m_data_tdata <= shift_reg;
                                if (m_axis_data_tready) begin
                                    m_data_tvalid <= 1'b0;
                                end
                            end
                        end else begin
                            missed_ack_reg <= 1'b1;
                        end
                    end
                end
                DATA: begin
                    if (clock_divider_counter == clock_divider) begin
                        if (write_mode || write_multiple_mode) begin
                            sda_o_reg <= shift_reg[7];
                            sda_t_reg <= 1'b0;
                            if (bit_counter == 4'd7) begin
                                data_tready <= 1'b1;
                                data_tvalid_reg <= 1'b1;
                                data_tdata_reg <= s_axis_data_tdata;
                                data_tlast_reg <= s_axis_data_tlast;
                            end
                        end else if (read_mode) begin
                            sda_t_reg <= 1'b1;
                        end
                    end
                end
                STOP: begin
                    stop_condition <= 1'b1;
                    scl_o_reg <= 1'b0;
                    scl_t_reg <= 1'b0;
                    sda_o_reg <= 1'b0;
                    sda_t_reg <= 1'b0;
                end
                default: begin
                    start_condition <= 1'b0;
                    stop_condition <= 1'b0;
                    scl_o_reg <= 1'b1;
                    scl_t_reg <= 1'b1;
                    sda_o_reg <= 1'b1;
                    sda_t_reg <= 1'b1;
                end
            endcase

            if (state == IDLE) begin
                busy_reg <= 1'b0;
                bus_control_reg <= 1'b0;
                bus_active_reg <= 1'b0;
                missed_ack_reg <= 1'b0;
            end else begin
                busy_reg <= 1'b1;
                bus_control_reg <= 1'b1;
                bus_active_reg <= 1'b1;
            end

            if (state == STOP && clock_divider_counter == clock_divider) begin
                start_condition <= 1'b0;
                stop_condition <= 1'b0;
                scl_o_reg <= 1'b1;
                scl_t_reg <= 1'b1;
                sda_o_reg <= 1'b1;
                sda_t_reg <= 1'b1;
            end
        end
    end

    /*
     * Output assignments
     */
    assign s_axis_cmd_ready = cmd_ready;
    assign s_axis_data_tready = data_tready;
    assign m_axis_data_tdata = m_data_tdata;
    assign m_axis_data_tvalid = m_data_tvalid;
    assign m_axis_data_tlast = m_data_tlast;
    assign scl_o = scl_o_reg;
    assign scl_t = scl_t_reg;
    assign sda_o = sda_o_reg;
    assign sda_t = sda_t_reg;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;

endmodule
