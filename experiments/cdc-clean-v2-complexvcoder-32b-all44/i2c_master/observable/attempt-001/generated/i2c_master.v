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

    wire               fsm_scl_o;
    wire               fsm_scl_t;
    wire               fsm_sda_o;
    wire               fsm_sda_t;

    i2c_master_fsm u_i2c_master_fsm (
        .clk                    (clk),
        .rst                    (rst),
        .s_axis_cmd_address     (s_axis_cmd_address),
        .s_axis_cmd_start       (s_axis_cmd_start),
        .s_axis_cmd_read        (s_axis_cmd_read),
        .s_axis_cmd_write       (s_axis_cmd_write),
        .s_axis_cmd_write_multiple (s_axis_cmd_write_multiple),
        .s_axis_cmd_stop        (s_axis_cmd_stop),
        .s_axis_cmd_valid       (s_axis_cmd_valid),
        .s_axis_cmd_ready       (s_axis_cmd_ready),
        .s_axis_data_tdata      (s_axis_data_tdata),
        .s_axis_data_tvalid     (s_axis_data_tvalid),
        .s_axis_data_tready     (s_axis_data_tready),
        .s_axis_data_tlast      (s_axis_data_tlast),
        .m_axis_data_tdata      (m_axis_data_tdata),
        .m_axis_data_tvalid     (m_axis_data_tvalid),
        .m_axis_data_tready     (m_axis_data_tready),
        .m_axis_data_tlast      (m_axis_data_tlast),
        .scl_o                  (fsm_scl_o),
        .scl_t                  (fsm_scl_t),
        .sda_o                  (fsm_sda_o),
        .sda_t                  (fsm_sda_t),
        .busy                   (busy),
        .bus_control            (bus_control),
        .bus_active             (bus_active),
        .missed_ack             (missed_ack),
        .stop_on_idle           (stop_on_idle),
        .prescale               (prescale)
    );

    i2c_master_bit_banger u_i2c_master_bit_banger (
        .clk                    (clk),
        .rst                    (rst),
        .scl_o                  (fsm_scl_o),
        .scl_t                  (fsm_scl_t),
        .scl_i                  (scl_i),
        .sda_o                  (fsm_sda_o),
        .sda_t                  (fsm_sda_t),
        .sda_i                  (sda_i)
    );

    assign scl_o = u_i2c_master_bit_banger.scl_o;
    assign scl_t = u_i2c_master_bit_banger.scl_t;
    assign sda_o = u_i2c_master_bit_banger.sda_o;
    assign sda_t = u_i2c_master_bit_banger.sda_t;

endmodule

module i2c_master_fsm (
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
    input  wire [7:0]  s_axis_data_tdata,
    input  wire        s_axis_data_tvalid,
    output wire        s_axis_data_tready,
    input  wire        s_axis_data_tlast,
    output wire [7:0]  m_axis_data_tdata,
    output wire        m_axis_data_tvalid,
    input  wire        m_axis_data_tready,
    output wire        m_axis_data_tlast,
    output wire        scl_o,
    output wire        scl_t,
    output wire        sda_o,
    output wire        sda_t,
    output wire        busy,
    output wire        bus_control,
    output wire        bus_active,
    output wire        missed_ack,
    input  wire        stop_on_idle,
    input  wire [15:0] prescale
);

    localparam IDLE             = 4'b0000;
    localparam START            = 4'b0001;
    localparam SEND_ADDR        = 4'b0010;
    localparam WAIT_ACK_ADDR    = 4'b0011;
    localparam SEND_DATA        = 4'b0100;
    localparam WAIT_ACK_DATA    = 4'b0101;
    localparam READ_DATA        = 4'b0110;
    localparam SEND_ACK         = 4'b0111;
    localparam STOP             = 4'b1000;

    reg [3:0]          current_state;
    reg [3:0]          next_state;
    reg [2:0]          bit_count;
    reg [7:0]          byte_count;
    reg [7:0]          data_shift_register;
    reg                ack_received;
    reg                scl_o_reg;
    reg                scl_t_reg;
    reg                sda_o_reg;
    reg                sda_t_reg;
    reg                busy_reg;
    reg                bus_control_reg;
    reg                bus_active_reg;
    reg                missed_ack_reg;
    reg [15:0]         clock_divider;
    reg [7:0]          read_data_buffer;

    assign s_axis_cmd_ready = (current_state == IDLE);
    assign s_axis_data_tready = (current_state == SEND_DATA);
    assign m_axis_data_tdata = read_data_buffer;
    assign m_axis_data_tvalid = (current_state == READ_DATA);
    assign m_axis_data_tlast = (byte_count == 0);
    assign scl_o = scl_o_reg;
    assign scl_t = scl_t_reg;
    assign sda_o = sda_o_reg;
    assign sda_t = sda_t_reg;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            bit_count <= 3'b000;
            byte_count <= 8'b00000000;
            data_shift_register <= 8'b00000000;
            ack_received <= 1'b0;
            scl_o_reg <= 1'b1;
            scl_t_reg <= 1'b1;
            sda_o_reg <= 1'b1;
            sda_t_reg <= 1'b1;
            busy_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            missed_ack_reg <= 1'b0;
            clock_divider <= 16'b0000000000000000;
            read_data_buffer <= 8'b00000000;
        end else begin
            current_state <= next_state;
            if (clock_divider != 0) begin
                clock_divider <= clock_divider - 1;
            end else begin
                case (current_state)
                    IDLE: begin
                        if (s_axis_cmd_valid) begin
                            next_state <= START;
                            busy_reg <= 1'b1;
                            bus_control_reg <= 1'b1;
                            bus_active_reg <= 1'b1;
                            data_shift_register <= {s_axis_cmd_read, s_axis_cmd_address};
                            byte_count <= s_axis_cmd_write_multiple ? 8'd1 : 8'd0;
                        end else begin
                            next_state <= IDLE;
                        end
                    end
                    START: begin
                        scl_o_reg <= 1'b1;
                        sda_o_reg <= 1'b1;
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b0;
                        clock_divider <= prescale;
                        next_state <= SEND_ADDR;
                    end
                    SEND_ADDR: begin
                        if (bit_count < 3'd7) begin
                            scl_o_reg <= 1'b0;
                            sda_o_reg <= data_shift_register[7];
                            sda_t_reg <= 1'b0;
                            clock_divider <= prescale;
                            bit_count <= bit_count + 1;
                            next_state <= SEND_ADDR;
                        end else begin
                            scl_o_reg <= 1'b0;
                            sda_o_reg <= data_shift_register[7];
                            sda_t_reg <= 1'b0;
                            clock_divider <= prescale;
                            next_state <= WAIT_ACK_ADDR;
                        end
                    end
                    WAIT_ACK_ADDR: begin
                        scl_o_reg <= 1'b1;
                        sda_t_reg <= 1'b1;
                        clock_divider <= prescale;
                        if (sda_i) begin
                            missed_ack_reg <= 1'b1;
                            next_state <= STOP;
                        end else begin
                            ack_received <= 1'b1;
                            next_state <= s_axis_cmd_read ? READ_DATA : IDLE;
                        end
                    end
                    SEND_DATA: begin
                        if (s_axis_data_tvalid && !s_axis_data_tready) begin
                            data_shift_register <= s_axis_data_tdata;
                            byte_count <= byte_count - 1;
                            next_state <= SEND_DATA;
                        end else if (byte_count > 0) begin
                            if (bit_count < 3'd7) begin
                                scl_o_reg <= 1'b0;
                                sda_o_reg <= data_shift_register[7];
                                sda_t_reg <= 1'b0;
                                clock_divider <= prescale;
                                bit_count <= bit_count + 1;
                                next_state <= SEND_DATA;
                            end else begin
                                scl_o_reg <= 1'b0;
                                sda_o_reg <= data_shift_register[7];
                                sda_t_reg <= 1'b0;
                                clock_divider <= prescale;
                                next_state <= WAIT_ACK_DATA;
                            end
                        end else begin
                            next_state <= IDLE;
                        end
                    end
                    WAIT_ACK_DATA: begin
                        scl_o_reg <= 1'b1;
                        sda_t_reg <= 1'b1;
                        clock_divider <= prescale;
                        if (sda_i) begin
                            missed_ack_reg <= 1'b1;
                            next_state <= STOP;
                        end else begin
                            ack_received <= 1'b1;
                            next_state <= s_axis_cmd_write_multiple ? SEND_DATA : IDLE;
                        end
                    end
                    READ_DATA: begin
                        if (bit_count < 3'd7) begin
                            scl_o_reg <= 1'b0;
                            sda_t_reg <= 1'b1;
                            clock_divider <= prescale;
                            bit_count <= bit_count + 1;
                            read_data_buffer[7-bit_count] <= sda_i;
                            next_state <= READ_DATA;
                        end else begin
                            scl_o_reg <= 1'b0;
                            sda_t_reg <= 1'b1;
                            clock_divider <= prescale;
                            read_data_buffer[0] <= sda_i;
                            next_state <= SEND_ACK;
                        end
                    end
                    SEND_ACK: begin
                        scl_o_reg <= 1'b1;
                        sda_o_reg <= s_axis_data_tlast ? 1'b1 : 1'b0;
                        sda_t_reg <= 1'b0;
                        clock_divider <= prescale;
                        next_state <= STOP;
                    end
                    STOP: begin
                        scl_o_reg <= 1'b0;
                        sda_o_reg <= 1'b0;
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b0;
                        clock_divider <= prescale;
                        next_state <= STOP2;
                    end
                    STOP2: begin
                        scl_o_reg <= 1'b1;
                        sda_o_reg <= 1'b1;
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b0;
                        clock_divider <= prescale;
                        next_state <= IDLE;
                        busy_reg <= 1'b0;
                        bus_control_reg <= 1'b0;
                        bus_active_reg <= 1'b0;
                    end
                    default: begin
                        next_state <= IDLE;
                    end
                endcase
            end
        end
    end

endmodule

module i2c_master_bit_banger (
    input  wire        clk,
    input  wire        rst,
    input  wire        scl_o,
    input  wire        scl_t,
    input  wire        scl_i,
    input  wire        sda_o,
    input  wire        sda_t,
    input  wire        sda_i,
    output wire        scl_o_reg,
    output wire        scl_t_reg,
    output wire        sda_o_reg,
    output wire        sda_t_reg
);

    reg [15:0]         clock_divider;
    reg [2:0]          bit_count;
    reg                scl_o_reg;
    reg                scl_t_reg;
    reg                sda_o_reg;
    reg                sda_t_reg;

    assign scl_o_reg = scl_o;
    assign scl_t_reg = scl_t;
    assign sda_o_reg = sda_o;
    assign sda_t_reg = sda_t;

endmodule
