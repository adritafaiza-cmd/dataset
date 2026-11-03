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
    reg [2:0] cmd_state;
    reg [2:0] data_state;
    reg [6:0] cmd_address_reg;
    reg       cmd_start_reg;
    reg       cmd_read_reg;
    reg       cmd_write_reg;
    reg       cmd_write_multiple_reg;
    reg       cmd_stop_reg;
    reg       cmd_valid_reg;
    reg       cmd_ready_reg;
    reg [7:0] data_tdata_reg;
    reg       data_tvalid_reg;
    reg       data_tready_reg;
    reg       data_tlast_reg;
    reg [7:0] m_data_tdata_reg;
    reg       m_data_tvalid_reg;
    reg       m_data_tlast_reg;
    reg       bit_bang_start;
    reg       bit_bang_stop;
    reg       bit_bang_read;
    reg       bit_bang_write;
    reg [7:0] bit_bang_data;
    wire      bit_bang_ack;
    wire      bit_bang_busy;

    // States for command processing
    localparam CMD_IDLE = 3'b000;
    localparam CMD_START = 3'b001;
    localparam CMD_ADDR = 3'b010;
    localparam CMD_WRITE = 3'b011;
    localparam CMD_READ = 3'b100;
    localparam CMD_STOP = 3'b101;

    // States for data processing
    localparam DATA_IDLE = 3'b000;
    localparam DATA_WRITE = 3'b001;
    localparam DATA_READ = 3'b010;
    localparam DATA_WAIT = 3'b011;

    // Command processing state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_state <= CMD_IDLE;
            cmd_ready_reg <= 1'b0;
            cmd_valid_reg <= 1'b0;
            cmd_address_reg <= 7'b0;
            cmd_start_reg <= 1'b0;
            cmd_read_reg <= 1'b0;
            cmd_write_reg <= 1'b0;
            cmd_write_multiple_reg <= 1'b0;
            cmd_stop_reg <= 1'b0;
            bit_bang_start <= 1'b0;
            bit_bang_stop <= 1'b0;
            bit_bang_read <= 1'b0;
            bit_bang_write <= 1'b0;
            bit_bang_data <= 8'b0;
        end else begin
            case (cmd_state)
                CMD_IDLE: begin
                    if (s_axis_cmd_valid) begin
                        cmd_ready_reg <= 1'b1;
                        cmd_valid_reg <= 1'b1;
                        cmd_address_reg <= s_axis_cmd_address;
                        cmd_start_reg <= s_axis_cmd_start;
                        cmd_read_reg <= s_axis_cmd_read;
                        cmd_write_reg <= s_axis_cmd_write;
                        cmd_write_multiple_reg <= s_axis_cmd_write_multiple;
                        cmd_stop_reg <= s_axis_cmd_stop;
                        bit_bang_start <= s_axis_cmd_start;
                        bit_bang_stop <= s_axis_cmd_stop;
                        cmd_state <= CMD_START;
                    end else begin
                        cmd_ready_reg <= 1'b1;
                    end
                end
                CMD_START: begin
                    if (!bit_bang_busy) begin
                        cmd_state <= CMD_ADDR;
                    end
                end
                CMD_ADDR: begin
                    if (!bit_bang_busy) begin
                        bit_bang_write <= 1'b1;
                        bit_bang_data <= {cmd_address_reg, 1'b0};
                        cmd_state <= CMD_WRITE;
                    end
                end
                CMD_WRITE: begin
                    if (!bit_bang_busy) begin
                        if (cmd_write_reg || cmd_write_multiple_reg) begin
                            bit_bang_write <= 1'b1;
                            bit_bang_data <= s_axis_data_tdata;
                            cmd_state <= CMD_WRITE;
                            if (s_axis_data_tlast) begin
                                cmd_state <= CMD_STOP;
                            end
                        end else if (cmd_read_reg) begin
                            bit_bang_read <= 1'b1;
                            cmd_state <= CMD_READ;
                        end else begin
                            cmd_state <= CMD_STOP;
                        end
                    end
                end
                CMD_READ: begin
                    if (!bit_bang_busy) begin
                        bit_bang_read <= 1'b1;
                        cmd_state <= CMD_WAIT;
                    end
                end
                CMD_WAIT: begin
                    if (!bit_bang_busy) begin
                        m_data_tdata_reg <= bit_bang_data;
                        m_data_tvalid_reg <= 1'b1;
                        m_data_tlast_reg <= s_axis_data_tlast;
                        if (s_axis_data_tlast) begin
                            cmd_state <= CMD_STOP;
                        end else begin
                            cmd_state <= CMD_READ;
                        end
                    end
                end
                CMD_STOP: begin
                    if (!bit_bang_busy) begin
                        bit_bang_stop <= 1'b1;
                        cmd_state <= CMD_IDLE;
                    end
                end
                default: cmd_state <= CMD_IDLE;
            endcase
        end
    end

    // Data processing state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_state <= DATA_IDLE;
            data_tready_reg <= 1'b0;
        end else begin
            case (data_state)
                DATA_IDLE: begin
                    if (s_axis_data_tvalid) begin
                        data_tready_reg <= 1'b1;
                        data_tdata_reg <= s_axis_data_tdata;
                        data_tlast_reg <= s_axis_data_tlast;
                        data_state <= DATA_WRITE;
                    end else begin
                        data_tready_reg <= 1'b0;
                    end
                end
                DATA_WRITE: begin
                    if (!bit_bang_busy) begin
                        bit_bang_write <= 1'b1;
                        bit_bang_data <= data_tdata_reg;
                        data_state <= DATA_IDLE;
                    end
                end
                default: data_state <= DATA_IDLE;
            endcase
        end
    end

    // Bit-bang I2C interface
    i2c_bit_bang bit_bang (
        .clk(clk),
        .rst(rst),
        .scl_i(scl_i),
        .scl_o(scl_o),
        .scl_t(scl_t),
        .sda_i(sda_i),
        .sda_o(sda_o),
        .sda_t(sda_t),
        .start(bit_bang_start),
        .stop(bit_bang_stop),
        .read(bit_bang_read),
        .write(bit_bang_write),
        .data(bit_bang_data),
        .ack(bit_bang_ack),
        .busy(bit_bang_busy)
    );

    // Output assignments
    assign s_axis_cmd_ready = cmd_ready_reg;
    assign s_axis_data_tready = data_tready_reg;
    assign m_axis_data_tdata = m_data_tdata_reg;
    assign m_axis_data_tvalid = m_data_tvalid_reg;
    assign m_axis_data_tlast = m_data_tlast_reg;
    assign busy = bit_bang_busy;
    assign bus_control = bit_bang_start | bit_bang_stop | bit_bang_read | bit_bang_write;
    assign bus_active = bit_bang_busy;
    assign missed_ack = !bit_bang_ack;

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
    input  wire        start,
    input  wire        stop,
    input  wire        read,
    input  wire        write,
    inout  wire [7:0]  data,
    output wire        ack,
    output wire        busy
);

    // Internal signals
    reg [15:0] prescale_counter;
    reg [3:0] bit_count;
    reg [2:0] state;
    reg [7:0] data_reg;
    reg scl_reg;
    reg sda_reg;
    reg scl_t_reg;
    reg sda_t_reg;
    reg ack_reg;
    reg busy_reg;

    // States for bit-banging
    localparam IDLE = 3'b000;
    localparam START = 3'b001;
    localparam STOP = 3'b010;
    localparam WRITE = 3'b011;
    localparam READ = 3'b100;
    localparam ACK = 3'b101;

    // Bit-banging state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prescale_counter <= 16'h0000;
            bit_count <= 4'b0;
            state <= IDLE;
            data_reg <= 8'b0;
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            scl_t_reg <= 1'b1;
            sda_t_reg <= 1'b1;
            ack_reg <= 1'b0;
            busy_reg <= 1'b0;
        end else begin
            if (prescale_counter < prescale) begin
                prescale_counter <= prescale_counter + 1;
            end else begin
                prescale_counter <= 16'h0000;
                case (state)
                    IDLE: begin
                        if (start) begin
                            state <= START;
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b0;
                            scl_t_reg <= 1'b0;
                            sda_t_reg <= 1'b0;
                            busy_reg <= 1'b1;
                        end else if (stop) begin
                            state <= STOP;
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b0;
                            scl_t_reg <= 1'b0;
                            sda_t_reg <= 1'b0;
                            busy_reg <= 1'b1;
                        end else if (write) begin
                            state <= WRITE;
                            data_reg <= data;
                            bit_count <= 4'b0;
                            scl_reg <= 1'b0;
                            sda_reg <= data_reg[7];
                            scl_t_reg <= 1'b0;
                            sda_t_reg <= 1'b0;
                            busy_reg <= 1'b1;
                        end else if (read) begin
                            state <= READ;
                            bit_count <= 4'b0;
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            sda_t_reg <= 1'b1;
                            busy_reg <= 1'b1;
                        end
                    end
                    START: begin
                        scl_reg <= 1'b1;
                        state <= IDLE;
                    end
                    STOP: begin
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b1;
                        state <= IDLE;
                        busy_reg <= 1'b0;
                    end
                    WRITE: begin
                        if (bit_count < 8) begin
                            scl_reg <= 1'b0;
                            sda_reg <= data_reg[7-bit_count];
                            scl_t_reg <= 1'b0;
                            sda_t_reg <= 1'b0;
                            bit_count <= bit_count + 1;
                        end else begin
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            sda_t_reg <= 1'b1;
                            state <= ACK;
                        end
                    end
                    READ: begin
                        if (bit_count < 8) begin
                            scl_reg <= 1'b0;
                            scl_t_reg <= 1'b0;
                            sda_t_reg <= 1'b1;
                            bit_count <= bit_count + 1;
                        end else begin
                            scl_reg <= 1'b0;
                            scl_t_reg <= 1'b0;
                            sda_t_reg <= 1'b1;
                            state <= ACK;
                        end
                    end
                    ACK: begin
                        scl_reg <= 1'b1;
                        if (read) begin
                            data[7-bit_count] <= sda_i;
                        end
                        ack_reg <= sda_i;
                        state <= IDLE;
                        busy_reg <= 1'b0;
                    end
                    default: state <= IDLE;
                endcase
            end
        end
    end

    // Output assignments
    assign scl_o = scl_reg;
    assign scl_t = scl_t_reg;
    assign sda_o = sda_reg;
    assign sda_t = sda_t_reg;
    assign ack = ack_reg;
    assign busy = busy_reg;

endmodule
