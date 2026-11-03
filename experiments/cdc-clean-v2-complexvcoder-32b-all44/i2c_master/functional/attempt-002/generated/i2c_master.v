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
    reg        scl_reg;
    reg        scl_en;
    reg        sda_reg;
    reg        sda_en;
    reg [2:0]  bit_count;
    reg [2:0]  byte_count;
    reg [5:0]  cmd_reg;
    reg        cmd_valid_reg;
    reg [7:0]  data_reg;
    reg        data_valid_reg;
    reg        data_tlast_reg;
    reg [2:0]  state;
    reg [2:0]  next_state;
    reg        ack;
    reg        start_flag;
    reg        stop_flag;
    reg        read_flag;
    reg        write_flag;
    reg        write_multiple_flag;
    reg [15:0] clk_div;
    reg [15:0] clk_div_cnt;
    reg        busy_reg;
    reg        bus_control_reg;
    reg        bus_active_reg;
    reg        missed_ack_reg;

    // States
    localparam IDLE          = 3'b000;
    localparam START         = 3'b001;
    localparam ADDR          = 3'b010;
    localparam ACK_ADDR      = 3'b011;
    localparam WRITE_DATA    = 3'b100;
    localparam ACK_WRITE     = 3'b101;
    localparam READ_DATA     = 3'b110;
    localparam ACK_READ      = 3'b111;
    localparam STOP          = 3'b110;

    // State machine
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
                if (start_flag) next_state = START;
            end
            START: begin
                next_state = ADDR;
            end
            ADDR: begin
                if (bit_count == 3'b111) next_state = ACK_ADDR;
            end
            ACK_ADDR: begin
                if (ack) begin
                    if (write_flag) next_state = WRITE_DATA;
                    else if (read_flag) next_state = READ_DATA;
                end else begin
                    next_state = STOP;
                end
            end
            WRITE_DATA: begin
                if (bit_count == 3'b111) next_state = ACK_WRITE;
            end
            ACK_WRITE: begin
                if (ack) begin
                    if (write_multiple_flag && !data_tlast_reg) next_state = WRITE_DATA;
                    else next_state = STOP;
                end else begin
                    next_state = STOP;
                end
            end
            READ_DATA: begin
                if (bit_count == 3'b111) next_state = ACK_READ;
            end
            ACK_READ: begin
                if (byte_count < 3'b111) next_state = READ_DATA;
                else next_state = STOP;
            end
            STOP: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Command handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_reg <= 6'b0;
            cmd_valid_reg <= 1'b0;
            start_flag <= 1'b0;
            stop_flag <= 1'b0;
            read_flag <= 1'b0;
            write_flag <= 1'b0;
            write_multiple_flag <= 1'b0;
        end else if (s_axis_cmd_valid && !cmd_valid_reg) begin
            cmd_reg <= {s_axis_cmd_start, s_axis_cmd_read, s_axis_cmd_write, s_axis_cmd_write_multiple, s_axis_cmd_stop};
            cmd_valid_reg <= 1'b1;
            start_flag <= s_axis_cmd_start;
            stop_flag <= s_axis_cmd_stop;
            read_flag <= s_axis_cmd_read;
            write_flag <= s_axis_cmd_write;
            write_multiple_flag <= s_axis_cmd_write_multiple;
        end else if (state == IDLE) begin
            cmd_valid_reg <= 1'b0;
        end
    end

    // Data handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_reg <= 8'b0;
            data_valid_reg <= 1'b0;
            data_tlast_reg <= 1'b0;
        end else if (s_axis_data_tvalid && !data_valid_reg) begin
            data_reg <= s_axis_data_tdata;
            data_valid_reg <= 1'b1;
            data_tlast_reg <= s_axis_data_tlast;
        end else if (state == ACK_WRITE && ack) begin
            data_valid_reg <= 1'b0;
        end
    end

    // Bit and byte counting
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_count <= 3'b0;
            byte_count <= 3'b0;
        end else begin
            case (state)
                ADDR, WRITE_DATA, READ_DATA: begin
                    if (clk_div_cnt == prescale) begin
                        bit_count <= bit_count + 1'b1;
                    end
                end
                ACK_ADDR, ACK_WRITE, ACK_READ: begin
                    if (clk_div_cnt == prescale) begin
                        bit_count <= 3'b0;
                        byte_count <= byte_count + 1'b1;
                    end
                end
                default: begin
                    bit_count <= 3'b0;
                    byte_count <= 3'b0;
                end
            endcase
        end
    end

    // Clock division
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div_cnt <= 16'b0;
        end else begin
            if (clk_div_cnt == prescale) begin
                clk_div_cnt <= 16'b0;
            end else begin
                clk_div_cnt <= clk_div_cnt + 1'b1;
            end
        end
    end

    // SCL and SDA control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            scl_en <= 1'b0;
            sda_en <= 1'b0;
        end else begin
            case (state)
                START: begin
                    if (clk_div_cnt == prescale) begin
                        scl_reg <= 1'b0;
                        sda_reg <= 1'b0;
                        scl_en <= 1'b1;
                        sda_en <= 1'b1;
                    end
                end
                ADDR, WRITE_DATA, READ_DATA: begin
                    if (clk_div_cnt == prescale) begin
                        if (bit_count < 3'b111) begin
                            sda_reg <= (state == ADDR) ? (cmd_reg[5-bit_count]) : (data_reg[7-bit_count]);
                            sda_en <= 1'b1;
                        end else begin
                            sda_reg <= 1'b1;
                            sda_en <= 1'b0;
                        end
                    end
                end
                ACK_ADDR, ACK_WRITE, ACK_READ: begin
                    if (clk_div_cnt == prescale) begin
                        if (bit_count == 3'b0) begin
                            sda_reg <= 1'b1;
                            sda_en <= 1'b0;
                        end else if (bit_count == 3'b1) begin
                            ack <= sda_i;
                        end
                    end
                end
                STOP: begin
                    if (clk_div_cnt == prescale) begin
                        if (bit_count == 3'b0) begin
                            scl_reg <= 1'b0;
                            sda_reg <= 1'b0;
                            scl_en <= 1'b1;
                            sda_en <= 1'b1;
                        end else if (bit_count == 3'b1) begin
                            scl_reg <= 1'b1;
                        end else if (bit_count == 3'b2) begin
                            sda_reg <= 1'b1;
                        end
                    end
                end
                default: begin
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b1;
                    scl_en <= 1'b0;
                    sda_en <= 1'b0;
                end
            endcase
        end
    end

    // Output assignments
    assign s_axis_cmd_ready = !cmd_valid_reg;
    assign s_axis_data_tready = !data_valid_reg;
    assign m_axis_data_tdata = data_reg;
    assign m_axis_data_tvalid = (state == READ_DATA && bit_count == 3'b111);
    assign m_axis_data_tlast = (byte_count == 3'b111);
    assign scl_o = scl_reg;
    assign scl_t = !scl_en;
    assign sda_o = sda_reg;
    assign sda_t = !sda_en;
    assign busy = (state != IDLE);
    assign bus_control = (state == IDLE) ? 1'b0 : 1'b1;
    assign bus_active = (state == IDLE) ? 1'b0 : 1'b1;
    assign missed_ack = (state == STOP) ? missed_ack_reg : 1'b0;

    // Missed ACK detection
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            missed_ack_reg <= 1'b0;
        end else if (state == ACK_ADDR || state == ACK_WRITE || state == ACK_READ) begin
            if (bit_count == 3'b1 && !ack) begin
                missed_ack_reg <= 1'b1;
            end else begin
                missed_ack_reg <= 1'b0;
            end
        end
    end

endmodule
