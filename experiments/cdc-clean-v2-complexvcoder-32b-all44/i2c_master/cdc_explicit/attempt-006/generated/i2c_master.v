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
     * Internal Registers
     */
    reg [6:0]  cmd_address_reg;
    reg        cmd_start_reg;
    reg        cmd_read_reg;
    reg        cmd_write_reg;
    reg        cmd_write_multiple_reg;
    reg        cmd_stop_reg;
    reg        cmd_valid_reg;
    reg [7:0]  data_reg;
    reg        data_valid_reg;
    reg        data_tlast_reg;
    reg        scl_reg;
    reg        scl_t_reg;
    reg        sda_reg;
    reg        sda_t_reg;
    reg        busy_reg;
    reg        bus_control_reg;
    reg        bus_active_reg;
    reg        missed_ack_reg;
    reg [2:0]  bit_cnt;
    reg [7:0]  byte_cnt;
    reg [2:0]  state;
    reg [15:0] prescale_cnt;

    /*
     * State Definitions
     */
    localparam IDLE          = 3'b000;
    localparam START         = 3'b001;
    localparam ADDR          = 3'b010;
    localparam R_W           = 3'b011;
    localparam WRITE_DATA    = 3'b100;
    localparam READ_DATA     = 3'b101;
    localparam STOP          = 3'b110;

    /*
     * Command Ready
     */
    assign s_axis_cmd_ready = ~busy_reg;

    /*
     * Data Ready
     */
    assign s_axis_data_tready = (state == WRITE_DATA) & data_tlast_reg;

    /*
     * Output Assignments
     */
    assign m_axis_data_tdata  = data_reg;
    assign m_axis_data_tvalid = (state == READ_DATA);
    assign m_axis_data_tlast  = (state == READ_DATA) & (byte_cnt == 8'd1);
    assign scl_o              = scl_reg;
    assign scl_t              = scl_t_reg;
    assign sda_o              = sda_reg;
    assign sda_t              = sda_t_reg;
    assign busy               = busy_reg;
    assign bus_control        = bus_control_reg;
    assign bus_active         = bus_active_reg;
    assign missed_ack         = missed_ack_reg;

    /*
     * State Machine
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state          <= IDLE;
            busy_reg       <= 1'b0;
            bus_control_reg<= 1'b0;
            bus_active_reg <= 1'b0;
            missed_ack_reg <= 1'b0;
            bit_cnt        <= 3'b000;
            byte_cnt       <= 8'd0;
            prescale_cnt   <= 16'd0;
            scl_reg        <= 1'b1;
            scl_t_reg      <= 1'b1;
            sda_reg        <= 1'b1;
            sda_t_reg      <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    busy_reg       <= 1'b0;
                    bus_control_reg<= 1'b0;
                    bus_active_reg <= 1'b0;
                    missed_ack_reg <= 1'b0;
                    bit_cnt        <= 3'b000;
                    byte_cnt       <= 8'd0;
                    prescale_cnt   <= 16'd0;
                    scl_reg        <= 1'b1;
                    scl_t_reg      <= 1'b1;
                    sda_reg        <= 1'b1;
                    sda_t_reg      <= 1'b1;
                    if (cmd_valid_reg) begin
                        cmd_address_reg        <= s_axis_cmd_address;
                        cmd_start_reg          <= s_axis_cmd_start;
                        cmd_read_reg           <= s_axis_cmd_read;
                        cmd_write_reg          <= s_axis_cmd_write;
                        cmd_write_multiple_reg <= s_axis_cmd_write_multiple;
                        cmd_stop_reg           <= s_axis_cmd_stop;
                        cmd_valid_reg          <= 1'b0;
                        if (cmd_start_reg) begin
                            state              <= START;
                            busy_reg           <= 1'b1;
                            bus_control_reg    <= 1'b1;
                        end
                    end
                end

                START: begin
                    if (prescale_cnt == prescale) begin
                        prescale_cnt <= 16'd0;
                        scl_reg      <= 1'b0;
                        scl_t_reg      <= 1'b0;
                        sda_reg      <= 1'b0;
                        sda_t_reg      <= 1'b0;
                        state        <= ADDR;
                    end else begin
                        prescale_cnt <= prescale_cnt + 1'b1;
                    end
                end

                ADDR: begin
                    if (prescale_cnt == prescale) begin
                        prescale_cnt <= 16'd0;
                        if (bit_cnt < 3'd8) begin
                            scl_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            sda_reg <= cmd_address_reg[6-bit_cnt];
                            sda_t_reg <= 1'b0;
                            bit_cnt <= bit_cnt + 1'b1;
                        end else begin
                            scl_reg <= 1'b0;
                            scl_t_reg <= 1'b0;
                            sda_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_cnt <= 3'b000;
                            state <= R_W;
                        end
                    end else begin
                        prescale_cnt <= prescale_cnt + 1'b1;
                    end
                end

                R_W: begin
                    if (prescale_cnt == prescale) begin
                        prescale_cnt <= 16'd0;
                        scl_reg <= 1'b1;
                        scl_t_reg <= 1'b0;
                        sda_reg <= cmd_read_reg;
                        sda_t_reg <= 1'b0;
                        if (cmd_read_reg) begin
                            state <= READ_DATA;
                        end else begin
                            state <= WRITE_DATA;
                        end
                    end else begin
                        prescale_cnt <= prescale_cnt + 1'b1;
                    end
                end

                WRITE_DATA: begin
                    if (prescale_cnt == prescale) begin
                        prescale_cnt <= 16'd0;
                        if (bit_cnt < 3'd8) begin
                            scl_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            sda_reg <= data_reg[7-bit_cnt];
                            sda_t_reg <= 1'b0;
                            bit_cnt <= bit_cnt + 1'b1;
                        end else begin
                            scl_reg <= 1'b0;
                            scl_t_reg <= 1'b0;
                            sda_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_cnt <= 3'b000;
                            state <= STOP;
                            byte_cnt <= byte_cnt + 1'b1;
                            if (data_tlast_reg) begin
                                state <= STOP;
                            end else begin
                                state <= WRITE_DATA;
                            end
                        end
                    end else begin
                        prescale_cnt <= prescale_cnt + 1'b1;
                    end
                end

                READ_DATA: begin
                    if (prescale_cnt == prescale) begin
                        prescale_cnt <= 16'd0;
                        if (bit_cnt < 3'd8) begin
                            scl_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            sda_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_cnt <= bit_cnt + 1'b1;
                        end else begin
                            scl_reg <= 1'b0;
                            scl_t_reg <= 1'b0;
                            sda_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            bit_cnt <= 3'b000;
                            state <= STOP;
                            byte_cnt <= byte_cnt + 1'b1;
                            if (data_tlast_reg) begin
                                state <= STOP;
                            end else begin
                                state <= READ_DATA;
                            end
                        end
                    end else begin
                        prescale_cnt <= prescale_cnt + 1'b1;
                    end
                end

                STOP: begin
                    if (prescale_cnt == prescale) begin
                        prescale_cnt <= 16'd0;
                        scl_reg <= 1'b1;
                        scl_t_reg <= 1'b0;
                        sda_reg <= 1'b0;
                        sda_t_reg <= 1'b0;
                        state <= IDLE;
                    end else begin
                        prescale_cnt <= prescale_cnt + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    /*
     * Command Register
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_valid_reg <= 1'b0;
        end else begin
            if (s_axis_cmd_valid && ~cmd_valid_reg) begin
                cmd_valid_reg <= 1'b1;
            end else if (state == IDLE) begin
                cmd_valid_reg <= 1'b0;
            end
        end
    end

    /*
     * Data Register
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_reg <= 8'd0;
            data_valid_reg <= 1'b0;
            data_tlast_reg <= 1'b0;
        end else begin
            if (s_axis_data_tvalid && ~data_valid_reg) begin
                data_reg <= s_axis_data_tdata;
                data_valid_reg <= 1'b1;
                data_tlast_reg <= s_axis_data_tlast;
            end else if (state == WRITE_DATA && bit_cnt == 3'd8) begin
                data_valid_reg <= 1'b0;
            end
        end
    end

endmodule
