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
    wire [4:0]         state;
    wire [2:0]         bit_cnt;
    wire [3:0]         byte_cnt;
    wire [5:0]         cmd;
    wire [7:0]         data;
    wire               start;
    wire               stop;
    wire               read;
    wire               write;
    wire               write_multiple;
    wire               ack;
    wire               missed_ack_reg;

    // FSM instance
    i2c_master_fsm fsm (
        .clk(clk),
        .rst(rst),
        .cmd(cmd),
        .data(data),
        .start(start),
        .stop(stop),
        .read(read),
        .write(write),
        .write_multiple(write_multiple),
        .ack(ack),
        .bit_cnt(bit_cnt),
        .byte_cnt(byte_cnt),
        .state(state),
        .busy(busy),
        .bus_control(bus_control),
        .bus_active(bus_active),
        .missed_ack(missed_ack_reg)
    );

    // Bit-bang instance
    i2c_master_bit_bang bit_bang (
        .clk(clk),
        .rst(rst),
        .cmd(cmd),
        .data(data),
        .start(start),
        .stop(stop),
        .read(read),
        .write(write),
        .write_multiple(write_multiple),
        .state(state),
        .bit_cnt(bit_cnt),
        .byte_cnt(byte_cnt),
        .scl_i(scl_i),
        .scl_o(scl_o),
        .scl_t(scl_t),
        .sda_i(sda_i),
        .sda_o(sda_o),
        .sda_t(sda_t),
        .ack(ack),
        .missed_ack(missed_ack)
    );

    // Command buffer instance
    i2c_master_cmd_buffer cmd_buffer (
        .clk(clk),
        .rst(rst),
        .s_axis_cmd_address(s_axis_cmd_address),
        .s_axis_cmd_start(s_axis_cmd_start),
        .s_axis_cmd_read(s_axis_cmd_read),
        .s_axis_cmd_write(s_axis_cmd_write),
        .s_axis_cmd_write_multiple(s_axis_cmd_write_multiple),
        .s_axis_cmd_stop(s_axis_cmd_stop),
        .s_axis_cmd_valid(s_axis_cmd_valid),
        .s_axis_cmd_ready(s_axis_cmd_ready),
        .cmd(cmd),
        .data(data),
        .start(start),
        .stop(stop),
        .read(read),
        .write(write),
        .write_multiple(write_multiple)
    );

    // Data buffer instance
    i2c_master_data_buffer data_buffer (
        .clk(clk),
        .rst(rst),
        .s_axis_data_tdata(s_axis_data_tdata),
        .s_axis_data_tvalid(s_axis_data_tvalid),
        .s_axis_data_tready(s_axis_data_tready),
        .s_axis_data_tlast(s_axis_data_tlast),
        .m_axis_data_tdata(m_axis_data_tdata),
        .m_axis_data_tvalid(m_axis_data_tvalid),
        .m_axis_data_tready(m_axis_data_tready),
        .m_axis_data_tlast(m_axis_data_tlast),
        .data(data)
    );

endmodule

module i2c_master_fsm (
    input  wire        clk,
    input  wire        rst,
    input  wire [5:0]  cmd,
    input  wire [7:0]  data,
    input  wire        start,
    input  wire        stop,
    input  wire        read,
    input  wire        write,
    input  wire        write_multiple,
    input  wire        ack,
    output wire [2:0]  bit_cnt,
    output wire [3:0]  byte_cnt,
    output wire [4:0]  state,
    output wire        busy,
    output wire        bus_control,
    output wire        bus_active,
    output wire        missed_ack
);

    // States
    localparam IDLE = 5'b00000;
    localparam START = 5'b00001;
    localparam ADDRESS = 5'b00010;
    localparam ACK_ADDRESS = 5'b00011;
    localparam DATA_WRITE = 5'b00100;
    localparam ACK_DATA_WRITE = 5'b00101;
    localparam DATA_READ = 5'b00110;
    localparam ACK_DATA_READ = 5'b00111;
    localparam STOP = 5'b01000;
    localparam ERROR = 5'b01001;

    // Internal registers
    reg [4:0]          current_state;
    reg [4:0]          next_state;
    reg [2:0]          bit_cnt_reg;
    reg [3:0]          byte_cnt_reg;
    reg                busy_reg;
    reg                bus_control_reg;
    reg                bus_active_reg;
    reg                missed_ack_reg;

    // State register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // State transition logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (start)
                    next_state = START;
                else
                    next_state = IDLE;
            end
            START: begin
                next_state = ADDRESS;
            end
            ADDRESS: begin
                if (ack)
                    next_state = ACK_ADDRESS;
                else
                    next_state = ERROR;
            end
            ACK_ADDRESS: begin
                if (write)
                    next_state = DATA_WRITE;
                else if (read)
                    next_state = DATA_READ;
                else if (stop)
                    next_state = STOP;
                else
                    next_state = ACK_ADDRESS;
            end
            DATA_WRITE: begin
                if (ack)
                    next_state = ACK_DATA_WRITE;
                else
                    next_state = ERROR;
            end
            ACK_DATA_WRITE: begin
                if (write_multiple)
                    next_state = DATA_WRITE;
                else if (stop)
                    next_state = STOP;
                else
                    next_state = ACK_DATA_WRITE;
            end
            DATA_READ: begin
                next_state = ACK_DATA_READ;
            end
            ACK_DATA_READ: begin
                if (read)
                    next_state = DATA_READ;
                else if (stop)
                    next_state = STOP;
                else
                    next_state = ACK_DATA_READ;
            end
            STOP: begin
                next_state = IDLE;
            end
            ERROR: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Bit count logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_cnt_reg <= 3'b000;
        end else if (current_state == ADDRESS || current_state == DATA_WRITE || current_state == DATA_READ) begin
            if (bit_cnt_reg == 3'b111) begin
                bit_cnt_reg <= 3'b000;
            end else if (current_state == DATA_READ && bit_cnt_reg == 3'b110) begin
                bit_cnt_reg <= 3'b000;
            end else begin
                bit_cnt_reg <= bit_cnt_reg + 1;
            end
        end
    end

    // Byte count logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            byte_cnt_reg <= 4'b0000;
        end else if (current_state == ACK_ADDRESS) begin
            if (write)
                byte_cnt_reg <= 4'b0001;
            else if (read)
                byte_cnt_reg <= 4'b0001;
        end else if (current_state == ACK_DATA_WRITE) begin
            if (write_multiple) begin
                if (byte_cnt_reg == 4'b1111) begin
                    byte_cnt_reg <= 4'b0000;
                end else begin
                    byte_cnt_reg <= byte_cnt_reg + 1;
                end
            end else begin
                byte_cnt_reg <= 4'b0000;
            end
        end else if (current_state == ACK_DATA_READ) begin
            if (read) begin
                if (byte_cnt_reg == 4'b1111) begin
                    byte_cnt_reg <= 4'b0000;
                end else begin
                    byte_cnt_reg <= byte_cnt_reg + 1;
                end
            end else begin
                byte_cnt_reg <= 4'b0000;
            end
        end
    end

    // Busy flag logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            busy_reg <= 1'b0;
        end else if (current_state == IDLE) begin
            busy_reg <= 1'b0;
        end else begin
            busy_reg <= 1'b1;
        end
    end

    // Bus control flag logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bus_control_reg <= 1'b0;
        end else if (current_state == START) begin
            bus_control_reg <= 1'b1;
        end else if (current_state == STOP) begin
            bus_control_reg <= 1'b0;
        end
    end

    // Bus active flag logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bus_active_reg <= 1'b0;
        end else if (current_state == START) begin
            bus_active_reg <= 1'b1;
        end else if (current_state == STOP) begin
            bus_active_reg <= 1'b0;
        end
    end

    // Missed ACK flag logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            missed_ack_reg <= 1'b0;
        end else if (current_state == ACK_ADDRESS || current_state == ACK_DATA_WRITE) begin
            if (!ack)
                missed_ack_reg <= 1'b1;
            else
                missed_ack_reg <= 1'b0;
        end
    end

    // Assign outputs
    assign bit_cnt = bit_cnt_reg;
    assign byte_cnt = byte_cnt_reg;
    assign state = current_state;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;

endmodule

module i2c_master_bit_bang (
    input  wire        clk,
    input  wire        rst,
    input  wire [5:0]  cmd,
    input  wire [7:0]  data,
    input  wire        start,
    input  wire        stop,
    input  wire        read,
    input  wire        write,
    input  wire        write_multiple,
    input  wire [4:0]  state,
    input  wire [2:0]  bit_cnt,
    input  wire [3:0]  byte_cnt,
    input  wire        scl_i,
    output wire        scl_o,
    output wire        scl_t,
    input  wire        sda_i,
    output wire        sda_o,
    output wire        sda_t,
    output wire        ack,
    output wire        missed_ack
);

    // Internal registers
    reg                scl_reg;
    reg                sda_reg;
    reg                scl_t_reg;
    reg                sda_t_reg;
    reg                ack_reg;
    reg                missed_ack_reg;
    reg [2:0]          bit_cnt_reg;
    reg [3:0]          byte_cnt_reg;
    reg [7:0]          data_reg;
    reg [7:0]          shift_reg;

    // State processing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            scl_t_reg <= 1'b1;
            sda_t_reg <= 1'b1;
            ack_reg <= 1'b0;
            missed_ack_reg <= 1'b0;
            bit_cnt_reg <= 3'b000;
            byte_cnt_reg <= 4'b0000;
            data_reg <= 8'b00000000;
            shift_reg <= 8'b00000000;
        end else begin
            case (state)
                5'b00001: begin // START
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b0;
                    sda_reg <= 1'b0;
                end
                5'b00010: begin // ADDRESS
                    if (bit_cnt_reg == 3'b000) begin
                        shift_reg <= {cmd[5:0], read};
                        data_reg <= data;
                    end
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b0;
                    sda_reg <= shift_reg[7];
                    shift_reg <= shift_reg << 1;
                    bit_cnt_reg <= bit_cnt_reg + 1;
                end
                5'b00011: begin // ACK_ADDRESS
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b1;
                    if (bit_cnt_reg == 3'b000) begin
                        ack_reg <= sda_i;
                        if (!ack_reg)
                            missed_ack_reg <= 1'b0;
                        else
                            missed_ack_reg <= 1'b1;
                    end
                    bit_cnt_reg <= bit_cnt_reg + 1;
                end
                5'b00100: begin // DATA_WRITE
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b0;
                    sda_reg <= data_reg[7];
                    data_reg <= data_reg << 1;
                    bit_cnt_reg <= bit_cnt_reg + 1;
                end
                5'b00101: begin // ACK_DATA_WRITE
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b1;
                    if (bit_cnt_reg == 3'b000) begin
                        ack_reg <= sda_i;
                        if (!ack_reg)
                            missed_ack_reg <= 1'b0;
                        else
                            missed_ack_reg <= 1'b1;
                    end
                    bit_cnt_reg <= bit_cnt_reg + 1;
                end
                5'b00110: begin // DATA_READ
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b1;
                    if (bit_cnt_reg == 3'b000) begin
                        shift_reg <= 8'b00000000;
                    end
                    shift_reg <= {shift_reg[6:0], sda_i};
                    bit_cnt_reg <= bit_cnt_reg + 1;
                end
                5'b00111: begin // ACK_DATA_READ
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b0;
                    if (bit_cnt_reg == 3'b000) begin
                        sda_reg <= 1'b0;
                    end else begin
                        sda_reg <= 1'b1;
                    end
                    bit_cnt_reg <= bit_cnt_reg + 1;
                end
                5'b01000: begin // STOP
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b0;
                    sda_reg <= 1'b0;
                    scl_reg <= 1'b0;
                    if (bit_cnt_reg == 3'b000) begin
                        scl_reg <= 1'b1;
                    end else if (bit_cnt_reg == 3'b001) begin
                        sda_reg <= 1'b1;
                    end
                    bit_cnt_reg <= bit_cnt_reg + 1;
                end
                default: begin
                    scl_t_reg <= 1'b1;
                    sda_t_reg <= 1'b1;
                end
            endcase
        end
    end

    // Assign outputs
    assign scl_o = scl_reg;
    assign sda_o = sda_reg;
    assign scl_t = scl_t_reg;
    assign sda_t = sda_t_reg;
    assign ack = ack_reg;
    assign missed_ack = missed_ack_reg;

endmodule

module i2c_master_cmd_buffer (
    input  wire        clk,
    input  wire        rst,
    input  wire [6:0]  s_axis_cmd_address,
    input  wire        s_axis_cmd_start,
    input  wire        s_axis_cmd_read,
    input  wire        s_axis_cmd_write,
    input  wire        s_axis_cmd_write_multiple,
    input  wire        s_axis_cmd_stop,
    input  wire        s_axis_cmd_valid,
    output wire        s_axis_cmd_ready,
    output wire [5:0]  cmd,
    output wire [7:0]  data,
    output wire        start,
    output wire        stop,
    output wire        read,
    output wire        write,
    output wire        write_multiple
);

    // Internal registers
    reg [6:0]          cmd_address_reg;
    reg [5:0]          cmd_reg;
    reg [7:0]          data_reg;
    reg                start_reg;
    reg                stop_reg;
    reg                read_reg;
    reg                write_reg;
    reg                write_multiple_reg;
    reg                cmd_valid_reg;
    reg                cmd_ready_reg;

    // Command buffer logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_address_reg <= 7'b0000000;
            cmd_reg <= 6'b000000;
            start_reg <= 1'b0;
            stop_reg <= 1'b0;
            read_reg <= 1'b0;
            write_reg <= 1'b0;
            write_multiple_reg <= 1'b0;
            cmd_valid_reg <= 1'b0;
            cmd_ready_reg <= 1'b0;
        end else begin
            if (s_axis_cmd_valid && cmd_ready_reg) begin
                cmd_address_reg <= s_axis_cmd_address;
                start_reg <= s_axis_cmd_start;
                stop_reg <= s_axis_cmd_stop;
                read_reg <= s_axis_cmd_read;
                write_reg <= s_axis_cmd_write;
                write_multiple_reg <= s_axis_cmd_write_multiple;
                cmd_valid_reg <= 1'b1;
                cmd_ready_reg <= 1'b0;
            end else if (!cmd_valid_reg) begin
                cmd_ready_reg <= 1'b1;
            end
        end
    end

    // Command encoding
    always @(*) begin
        case ({start_reg, stop_reg, read_reg, write_reg, write_multiple_reg})
            5'b10000: cmd_reg = {1'b0, cmd_address_reg[6:0], 1'b0}; // START
            5'b01000: cmd_reg = {1'b1, cmd_address_reg[6:0], 1'b0}; // STOP
            5'b00100: cmd_reg = {1'b0, cmd_address_reg[6:0], 1'b1}; // READ
            5'b00010: cmd_reg = {1'b0, cmd_address_reg[6:0], 1'b0}; // WRITE
            5'b00001: cmd_reg = {1'b0, cmd_address_reg[6:0], 1'b0}; // WRITE_MULTIPLE
            default: cmd_reg = 6'b000000;
        endcase
    end

    // Assign outputs
    assign s_axis_cmd_ready = cmd_ready_reg;
    assign cmd = cmd_reg;
    assign data = data_reg;
    assign start = start_reg;
    assign stop = stop_reg;
    assign read = read_reg;
    assign write = write_reg;
    assign write_multiple = write_multiple_reg;

endmodule

module i2c_master_data_buffer (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  s_axis_data_tdata,
    input  wire        s_axis_data_tvalid,
    output wire        s_axis_data_tready,
    input  wire        s_axis_data_tlast,
    output wire [7:0]  m_axis_data_tdata,
    output wire        m_axis_data_tvalid,
    input  wire        m_axis_data_tready,
    output wire        m_axis_data_tlast,
    output wire [7:0]  data
);

    // Internal registers
    reg [7:0]          data_reg;
    reg                data_valid_reg;
    reg                data_last_reg;
    reg                data_ready_reg;

    // Data buffer logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_reg <= 8'b00000000;
            data_valid_reg <= 1'b0;
            data_last_reg <= 1'b0;
            data_ready_reg <= 1'b0;
        end else begin
            if (s_axis_data_tvalid && data_ready_reg) begin
                data_reg <= s_axis_data_tdata;
                data_valid_reg <= 1'b1;
                data_last_reg <= s_axis_data_tlast;
                data_ready_reg <= 1'b0;
            end else if (!data_valid_reg) begin
                data_ready_reg <= 1'b1;
            end

            if (m_axis_data_tready && data_valid_reg) begin
                data_valid_reg <= 1'b0;
                data_last_reg <= 1'b0;
            end
        end
    end

    // Assign outputs
    assign s_axis_data_tready = data_ready_reg;
    assign m_axis_data_tdata = data_reg;
    assign m_axis_data_tvalid = data_valid_reg;
    assign m_axis_data_tlast = data_last_reg;
    assign data = data_reg;

endmodule
