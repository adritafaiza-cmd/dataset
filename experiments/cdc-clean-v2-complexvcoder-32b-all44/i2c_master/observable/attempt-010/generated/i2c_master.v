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
    reg                cmd_start;
    reg                cmd_read;
    reg                cmd_write;
    reg                cmd_write_multiple;
    reg                cmd_stop;
    reg [7:0]          write_data;
    wire [7:0]         read_data;
    wire               ack_received;

    /*
     * Instantiate the i2c_bit_bang submodule
     */
    i2c_bit_bang bit_bang (
        .clk(clk),
        .rst(rst),
        .scl_i(scl_i),
        .scl_o(scl_o),
        .scl_t(scl_t),
        .sda_i(sda_i),
        .sda_o(sda_o),
        .sda_t(sda_t),
        .prescale(prescale),
        .cmd_start(cmd_start),
        .cmd_read(cmd_read),
        .cmd_write(cmd_write),
        .cmd_write_multiple(cmd_write_multiple),
        .cmd_stop(cmd_stop),
        .write_data(write_data),
        .read_data(read_data),
        .ack_received(ack_received),
        .busy(busy),
        .bus_control(bus_control),
        .bus_active(bus_active),
        .missed_ack(missed_ack)
    );

    /*
     * Command handling logic
     */
    reg                cmd_valid;
    reg                cmd_ready;
    reg                data_ready;
    reg [7:0]          data_buffer;
    reg                data_valid;
    reg                data_last;
    reg [7:0]          cmd_address;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_valid <= 0;
            cmd_ready <= 1;
            data_ready <= 0;
            data_valid <= 0;
            data_last <= 0;
            cmd_address <= 0;
        end else begin
            cmd_ready <= 1;

            if (s_axis_cmd_valid && cmd_ready) begin
                cmd_valid <= 1;
                cmd_address <= s_axis_cmd_address;
                cmd_start <= s_axis_cmd_start;
                cmd_read <= s_axis_cmd_read;
                cmd_write <= s_axis_cmd_write;
                cmd_write_multiple <= s_axis_cmd_write_multiple;
                cmd_stop <= s_axis_cmd_stop;
                cmd_ready <= 0;
            end else if (ack_received) begin
                cmd_valid <= 0;
            end

            if (s_axis_data_tvalid && data_ready) begin
                data_buffer <= s_axis_data_tdata;
                data_valid <= 1;
                data_last <= s_axis_data_tlast;
                data_ready <= 0;
            end else if (ack_received) begin
                data_valid <= 0;
            end

            if (read_data && !data_valid) begin
                data_ready <= 1;
            end

            if (read_data && data_ready) begin
                m_axis_data_tdata <= read_data;
                m_axis_data_tvalid <= 1;
                m_axis_data_tlast <= data_last;
            end else begin
                m_axis_data_tvalid <= 0;
            end
        end
    end

    assign s_axis_cmd_ready = cmd_ready;
    assign s_axis_data_tready = data_ready;

endmodule

module i2c_bit_bang (
    input  wire        clk,
    input  wire        rst,
    input  wire        scl_i,
    output wire        scl_o,
    output wire        scl_t,
    input  wire        sda_i,
    output wire        sda_o,
    output wire        sda_t,
    input  wire [15:0] prescale,
    input  wire        cmd_start,
    input  wire        cmd_read,
    input  wire        cmd_write,
    input  wire        cmd_write_multiple,
    input  wire        cmd_stop,
    input  wire [7:0]  write_data,
    output wire [7:0]  read_data,
    output wire        ack_received,
    output wire        busy,
    output wire        bus_control,
    output wire        bus_active,
    output wire        missed_ack
);

    /*
     * Internal signals
     */
    reg [15:0]         timer;
    reg [2:0]          bit_counter;
    reg [2:0]          byte_counter;
    reg [7:0]          current_byte;
    reg [3:0]          current_state;
    reg [3:0]          next_state;
    reg                scl_reg;
    reg                sda_reg;
    reg                scl_t_reg;
    reg                sda_t_reg;
    reg [7:0]          read_data_reg;
    reg                ack_received_reg;
    reg                busy_reg;
    reg                bus_control_reg;
    reg                bus_active_reg;
    reg                missed_ack_reg;

    /*
     * State definitions
     */
    localparam IDLE = 4'd0;
    localparam START = 4'd1;
    localparam ADDR = 4'd2;
    localparam ACK_ADDR = 4'd3;
    localparam WRITE = 4'd4;
    localparam ACK_WRITE = 4'd5;
    localparam READ = 4'd6;
    localparam ACK_READ = 4'd7;
    localparam STOP = 4'd8;

    /*
     * State transition logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (cmd_start) begin
                    next_state = START;
                end
            end
            START: begin
                if (timer == 0) begin
                    next_state = ADDR;
                end
            end
            ADDR: begin
                if (bit_counter == 3'd7) begin
                    next_state = ACK_ADDR;
                end
            end
            ACK_ADDR: begin
                if (timer == 0) begin
                    if (cmd_read) begin
                        next_state = READ;
                    end else if (cmd_write || cmd_write_multiple) begin
                        next_state = WRITE;
                    end
                end
            end
            WRITE: begin
                if (bit_counter == 3'd7) begin
                    next_state = ACK_WRITE;
                end
            end
            ACK_WRITE: begin
                if (timer == 0) begin
                    if (cmd_write_multiple && !cmd_stop) begin
                        next_state = WRITE;
                    end else begin
                        next_state = STOP;
                    end
                end
            end
            READ: begin
                if (bit_counter == 3'd7) begin
                    next_state = ACK_READ;
                end
            end
            ACK_READ: begin
                if (timer == 0) begin
                    if (cmd_stop) begin
                        next_state = STOP;
                    end else begin
                        next_state = READ;
                    end
                end
            end
            STOP: begin
                if (timer == 0) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    /*
     * Bit-banging logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            timer <= prescale;
            bit_counter <= 0;
            byte_counter <= 0;
            scl_reg <= 1;
            sda_reg <= 1;
            scl_t_reg <= 1;
            sda_t_reg <= 1;
            read_data_reg <= 0;
            ack_received_reg <= 0;
            busy_reg <= 0;
            bus_control_reg <= 0;
            bus_active_reg <= 0;
            missed_ack_reg <= 0;
        end else begin
            timer <= (timer == 0) ? prescale : timer - 1;

            case (current_state)
                IDLE: begin
                    scl_reg <= 1;
                    sda_reg <= 1;
                    scl_t_reg <= 1;
                    sda_t_reg <= 1;
                    read_data_reg <= 0;
                    ack_received_reg <= 0;
                    busy_reg <= 0;
                    bus_control_reg <= 0;
                    bus_active_reg <= 0;
                    missed_ack_reg <= 0;
                end
                START: begin
                    if (timer == prescale) begin
                        sda_reg <= 0;
                        scl_reg <= 1;
                        scl_t_reg <= 0;
                        sda_t_reg <= 0;
                        busy_reg <= 1;
                        bus_control_reg <= 1;
                        bus_active_reg <= 1;
                    end
                end
                ADDR: begin
                    if (timer == 0) begin
                        sda_reg <= (byte_counter == 3'd0) ? cmd_start : write_data[7 - bit_counter];
                        scl_reg <= (bit_counter == 3'd0) ? 0 : 1;
                        scl_t_reg <= 0;
                        sda_t_reg <= 0;
                        bit_counter <= (bit_counter == 3'd7) ? 0 : bit_counter + 1;
                        byte_counter <= (bit_counter == 3'd7) ? byte_counter + 1 : byte_counter;
                    end
                end
                ACK_ADDR: begin
                    if (timer == 0) begin
                        scl_reg <= 1;
                        scl_t_reg <= 0;
                        sda_reg <= 1;
                        sda_t_reg <= 1;
                        if (sda_i) begin
                            missed_ack_reg <= 1;
                        end else begin
                            ack_received_reg <= 1;
                        end
                    end
                end
                WRITE: begin
                    if (timer == 0) begin
                        sda_reg <= write_data[7 - bit_counter];
                        scl_reg <= (bit_counter == 3'd0) ? 0 : 1;
                        scl_t_reg <= 0;
                        sda_t_reg <= 0;
                        bit_counter <= (bit_counter == 3'd7) ? 0 : bit_counter + 1;
                    end
                end
                ACK_WRITE: begin
                    if (timer == 0) begin
                        scl_reg <= 1;
                        scl_t_reg <= 0;
                        sda_reg <= 1;
                        sda_t_reg <= 1;
                        if (sda_i) begin
                            missed_ack_reg <= 1;
                        end else begin
                            ack_received_reg <= 1;
                        end
                    end
                end
                READ: begin
                    if (timer == 0) begin
                        scl_reg <= 1;
                        scl_t_reg <= 0;
                        sda_reg <= 1;
                        sda_t_reg <= 1;
                        read_data_reg[7 - bit_counter] <= sda_i;
                        bit_counter <= (bit_counter == 3'd7) ? 0 : bit_counter + 1;
                    end
                end
                ACK_READ: begin
                    if (timer == 0) begin
                        sda_reg <= (cmd_stop) ? 1 : 0;
                        scl_reg <= 0;
                        scl_t_reg <= 0;
                        sda_t_reg <= 0;
                        ack_received_reg <= 1;
                    end
                end
                STOP: begin
                    if (timer == 0) begin
                        sda_reg <= 0;
                        scl_reg <= 0;
                        scl_t_reg <= 0;
                        sda_t_reg <= 0;
                    end else if (timer == prescale / 2) begin
                        scl_reg <= 1;
                    end else if (timer == prescale) begin
                        sda_reg <= 1;
                        scl_t_reg <= 1;
                        sda_t_reg <= 1;
                        busy_reg <= 0;
                        bus_control_reg <= 0;
                        bus_active_reg <= 0;
                    end
                end
            endcase
        end
    end

    assign scl_o = scl_reg;
    assign sda_o = sda_reg;
    assign scl_t = scl_t_reg;
    assign sda_t = sda_t_reg;
    assign read_data = read_data_reg;
    assign ack_received = ack_received_reg;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;

endmodule
