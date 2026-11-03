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
    reg [6:0]          cmd_reg;
    reg                cmd_start_reg;
    reg                cmd_read_reg;
    reg                cmd_write_reg;
    reg                cmd_write_multiple_reg;
    reg                cmd_stop_reg;
    reg                cmd_valid_reg;
    reg [7:0]          data_reg;
    reg                data_valid_reg;
    reg                data_tlast_reg;
    reg [3:0]          state;
    reg [2:0]          bit_cnt;
    reg                scl_reg;
    reg                sda_reg;
    reg                scl_o_reg;
    reg                sda_o_reg;
    reg                scl_t_reg;
    reg                sda_t_reg;
    reg                busy_reg;
    reg                bus_control_reg;
    reg                bus_active_reg;
    reg                missed_ack_reg;
    reg [15:0]         prescale_reg;
    reg [15:0]         prescale_cnt;

    /*
     * State definitions
     */
    localparam IDLE          = 4'b0000;
    localparam START         = 4'b0001;
    localparam ADDR          = 4'b0010;
    localparam ADDR_ACK      = 4'b0011;
    localparam WRITE         = 4'b0100;
    localparam WRITE_ACK     = 4'b0101;
    localparam READ          = 4'b0110;
    localparam READ_ACK      = 4'b0111;
    localparam STOP          = 4'b1000;
    localparam STOP_IDLE     = 4'b1001;

    /*
     * Register inputs
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_reg <= 7'b0;
            cmd_start_reg <= 1'b0;
            cmd_read_reg <= 1'b0;
            cmd_write_reg <= 1'b0;
            cmd_write_multiple_reg <= 1'b0;
            cmd_stop_reg <= 1'b0;
            cmd_valid_reg <= 1'b0;
            data_reg <= 8'b0;
            data_valid_reg <= 1'b0;
            data_tlast_reg <= 1'b0;
            state <= IDLE;
            bit_cnt <= 3'b0;
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            scl_o_reg <= 1'b1;
            sda_o_reg <= 1'b1;
            scl_t_reg <= 1'b1;
            sda_t_reg <= 1'b1;
            busy_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            missed_ack_reg <= 1'b0;
            prescale_reg <= 16'b0;
            prescale_cnt <= 16'b0;
        end else begin
            if (cmd_valid_reg && s_axis_cmd_ready) begin
                cmd_reg <= s_axis_cmd_address;
                cmd_start_reg <= s_axis_cmd_start;
                cmd_read_reg <= s_axis_cmd_read;
                cmd_write_reg <= s_axis_cmd_write;
                cmd_write_multiple_reg <= s_axis_cmd_write_multiple;
                cmd_stop_reg <= s_axis_cmd_stop;
                cmd_valid_reg <= 1'b0;
            end

            if (s_axis_data_tvalid && s_axis_data_tready) begin
                data_reg <= s_axis_data_tdata;
                data_valid_reg <= 1'b1;
                data_tlast_reg <= s_axis_data_tlast;
            end

            if (prescale_cnt == prescale_reg) begin
                prescale_cnt <= 16'b0;
            end else begin
                prescale_cnt <= prescale_cnt + 1'b1;
            end

            case (state)
                IDLE: begin
                    s_axis_cmd_ready <= 1'b1;
                    s_axis_data_tready <= 1'b0;
                    m_axis_data_tvalid <= 1'b0;
                    m_axis_data_tlast <= 1'b0;
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b1;
                    scl_o_reg <= 1'b1;
                    sda_o_reg <= 1'b1;
                    scl_t_reg <= 1'b1;
                    sda_t_reg <= 1'b1;
                    busy_reg <= 1'b0;
                    bus_control_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    missed_ack_reg <= 1'b0;
                    if (cmd_valid_reg && s_axis_cmd_ready) begin
                        state <= START;
                        busy_reg <= 1'b1;
                        bus_control_reg <= 1'b1;
                        bus_active_reg <= 1'b1;
                        prescale_cnt <= 16'b0;
                    end
                end

                START: begin
                    s_axis_cmd_ready <= 1'b0;
                    s_axis_data_tready <= 1'b0;
                    m_axis_data_tvalid <= 1'b0;
                    m_axis_data_tlast <= 1'b0;
                    scl_reg <= (prescale_cnt == prescale_reg / 2) ? 1'b0 : scl_reg;
                    sda_reg <= (prescale_cnt == prescale_reg / 4) ? 1'b0 : sda_reg;
                    scl_o_reg <= scl_reg;
                    sda_o_reg <= sda_reg;
                    scl_t_reg <= ~scl_reg;
                    sda_t_reg <= ~sda_reg;
                    if (prescale_cnt == prescale_reg) begin
                        state <= ADDR;
                    end
                end

                ADDR: begin
                    s_axis_cmd_ready <= 1'b0;
                    s_axis_data_tready <= 1'b0;
                    m_axis_data_tvalid <= 1'b0;
                    m_axis_data_tlast <= 1'b0;
                    scl_reg <= (prescale_cnt == prescale_reg / 2) ? ~scl_reg : scl_reg;
                    sda_reg <= (prescale_cnt == prescale_reg / 2) ? (bit_cnt == 3'b0 ? cmd_reg[6] : sda_reg) : sda_reg;
                    scl_o_reg <= scl_reg;
                    sda_o_reg <= sda_reg;
                    scl_t_reg <= ~scl_reg;
                    sda_t_reg <= ~sda_reg;
                    if (prescale_cnt == prescale_reg) begin
                        if (bit_cnt == 3'b111) begin
                            state <= ADDR_ACK;
                            bit_cnt <= 3'b0;
                        end else begin
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end
                end

                ADDR_ACK: begin
                    s_axis_cmd_ready <= 1'b0;
                    s_axis_data_tready <= 1'b0;
                    m_axis_data_tvalid <= 1'b0;
                    m_axis_data_tlast <= 1'b0;
                    scl_reg <= (prescale_cnt == prescale_reg / 2) ? ~scl_reg : scl_reg;
                    sda_reg <= 1'b1;
                    scl_o_reg <= scl_reg;
                    sda_o_reg <= sda_reg;
                    scl_t_reg <= ~scl_reg;
                    sda_t_reg <= ~sda_reg;
                    if (prescale_cnt == prescale_reg) begin
                        if (sda_i == 1'b1) begin
                            missed_ack_reg <= 1'b1;
                        end
                        if (cmd_read_reg) begin
                            state <= READ;
                        end else begin
                            state <= WRITE;
                        end
                    end
                end

                WRITE: begin
                    s_axis_cmd_ready <= 1'b0;
                    s_axis_data_tready <= 1'b1;
                    m_axis_data_tvalid <= 1'b0;
                    m_axis_data_tlast <= 1'b0;
                    scl_reg <= (prescale_cnt == prescale_reg / 2) ? ~scl_reg : scl_reg;
                    sda_reg <= (prescale_cnt == prescale_reg / 2) ? (bit_cnt == 3'b0 ? data_reg[7] : sda_reg) : sda_reg;
                    scl_o_reg <= scl_reg;
                    sda_o_reg <= sda_reg;
                    scl_t_reg <= ~scl_reg;
                    sda_t_reg <= ~sda_reg;
                    if (prescale_cnt == prescale_reg) begin
                        if (bit_cnt == 3'b111) begin
                            state <= WRITE_ACK;
                            bit_cnt <= 3'b0;
                        end else begin
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end
                end

                WRITE_ACK: begin
                    s_axis_cmd_ready <= 1'b0;
                    s_axis_data_tready <= 1'b0;
                    m_axis_data_tvalid <= 1'b0;
                    m_axis_data_tlast <= 1'b0;
                    scl_reg <= (prescale_cnt == prescale_reg / 2) ? ~scl_reg : scl_reg;
                    sda_reg <= 1'b1;
                    scl_o_reg <= scl_reg;
                    sda_o_reg <= sda_reg;
                    scl_t_reg <= ~scl_reg;
                    sda_t_reg <= ~sda_reg;
                    if (prescale_cnt == prescale_reg) begin
                        if (sda_i == 1'b1) begin
                            missed_ack_reg <= 1'b1;
                        end
                        if (data_tlast_reg) begin
                            if (cmd_stop_reg) begin
                                state <= STOP;
                            end else if (cmd_write_multiple_reg) begin
                                state <= WRITE;
                            end else begin
                                state <= IDLE;
                            end
                        end else begin
                            state <= WRITE;
                        end
                    end
                end

                READ: begin
                    s_axis_cmd_ready <= 1'b0;
                    s_axis_data_tready <= 1'b0;
                    m_axis_data_tvalid <= 1'b1;
                    m_axis_data_tlast <= (bit_cnt == 3'b111) ? 1'b1 : 1'b0;
                    scl_reg <= (prescale_cnt == prescale_reg / 2) ? ~scl_reg : scl_reg;
                    sda_reg <= 1'b1;
                    scl_o_reg <= scl_reg;
                    sda_o_reg <= sda_reg;
                    scl_t_reg <= ~scl_reg;
                    sda_t_reg <= ~scl_reg;
                    if (prescale_cnt == prescale_reg) begin
                        if (bit_cnt == 3'b111) begin
                            state <= READ_ACK;
                            bit_cnt <= 3'b0;
                        end else begin
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end
                end

                READ_ACK: begin
                    s_axis_cmd_ready <= 1'b0;
                    s_axis_data_tready <= 1'b0;
                    m_axis_data_tvalid <= 1'b0;
                    m_axis_data_tlast <= 1'b0;
                    scl_reg <= (prescale_cnt == prescale_reg / 2) ? ~scl_reg : scl_reg;
                    sda_reg <= (bit_cnt == 3'b0) ? 1'b0 : sda_reg;
                    scl_o_reg <= scl_reg;
                    sda_o_reg <= sda_reg;
                    scl_t_reg <= ~scl_reg;
                    sda_t_reg <= ~scl_reg;
                    if (prescale_cnt == prescale_reg) begin
                        if (bit_cnt == 3'b111) begin
                            if (cmd_stop_reg) begin
                                state <= STOP;
                            end else begin
                                state <= READ;
                            end
                        end else begin
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end
                end

                STOP: begin
                    s_axis_cmd_ready <= 1'b0;
                    s_axis_data_tready <= 1'b0;
                    m_axis_data_tvalid <= 1'b0;
                    m_axis_data_tlast <= 1'b0;
                    scl_reg <= (prescale_cnt == prescale_reg / 2) ? ~scl_reg : scl_reg;
                    sda_reg <= (prescale_cnt == prescale_reg / 4) ? 1'b1 : sda_reg;
                    scl_o_reg <= scl_reg;
                    sda_o_reg <= sda_reg;
                    scl_t_reg <= ~scl_reg;
                    sda_t_reg <= ~sda_reg;
                    if (prescale_cnt == prescale_reg) begin
                        if (scl_reg == 1'b1) begin
                            state <= IDLE;
                            busy_reg <= 1'b0;
                            bus_control_reg <= 1'b0;
                            bus_active_reg <= 1'b0;
                            prescale_cnt <= 16'b0;
                        end
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    /*
     * Output assignments
     */
    assign s_axis_cmd_ready = cmd_valid_reg ? s_axis_cmd_ready : 1'b0;
    assign s_axis_data_tready = data_valid_reg ? s_axis_data_tready : 1'b0;
    assign m_axis_data_tdata = data_reg;
    assign m_axis_data_tvalid = state == READ && bit_cnt == 3'b111;
    assign m_axis_data_tlast = data_tlast_reg;
    assign scl_o = scl_o_reg;
    assign scl_t = scl_t_reg;
    assign sda_o = sda_o_reg;
    assign sda_t = sda_t_reg;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;
endmodule
