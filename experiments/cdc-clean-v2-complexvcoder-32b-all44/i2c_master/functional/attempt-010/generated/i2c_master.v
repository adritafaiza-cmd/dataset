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
    reg [3:0]          state;
    reg [3:0]          next_state;
    reg [2:0]          bit_count;
    reg [2:0]          byte_count;
    reg [7:0]          shift_reg;
    reg                ack;
    reg                scl_reg;
    reg                sda_reg;
    reg                scl_t_reg;
    reg                sda_t_reg;
    reg                s_axis_cmd_ready_reg;
    reg                s_axis_data_tready_reg;
    reg                m_axis_data_tvalid_reg;
    reg                m_axis_data_tlast_reg;
    reg [7:0]          m_axis_data_tdata_reg;
    reg                busy_reg;
    reg                bus_control_reg;
    reg                bus_active_reg;
    reg                missed_ack_reg;
    reg [15:0]         timer;

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

    /*
     * State machine
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            bit_count <= 3'b000;
            byte_count <= 3'b000;
            shift_reg <= 8'b0;
            ack <= 1'b0;
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            scl_t_reg <= 1'b1;
            sda_t_reg <= 1'b1;
            s_axis_cmd_ready_reg <= 1'b0;
            s_axis_data_tready_reg <= 1'b0;
            m_axis_data_tvalid_reg <= 1'b0;
            m_axis_data_tlast_reg <= 1'b0;
            m_axis_data_tdata_reg <= 8'b0;
            busy_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            missed_ack_reg <= 1'b0;
            timer <= 16'b0;
        end else begin
            state <= next_state;
            timer <= (timer == prescale) ? 16'b0 : timer + 1;
            case (state)
                IDLE: begin
                    busy_reg <= 1'b0;
                    bus_control_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    missed_ack_reg <= 1'b0;
                    if (s_axis_cmd_valid && s_axis_cmd_start) begin
                        next_state <= START;
                        busy_reg <= 1'b1;
                        bus_control_reg <= 1'b1;
                        bus_active_reg <= 1'b1;
                        s_axis_cmd_ready_reg <= 1'b1;
                    end else begin
                        next_state <= IDLE;
                        s_axis_cmd_ready_reg <= 1'b0;
                    end
                end
                START: begin
                    if (timer == prescale) begin
                        scl_reg <= 1'b0;
                        sda_reg <= 1'b0;
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b0;
                        next_state <= ADDR;
                        bit_count <= 3'b000;
                        shift_reg <= {s_axis_cmd_address, s_axis_cmd_read};
                    end else begin
                        next_state <= START;
                    end
                end
                ADDR: begin
                    if (timer == prescale) begin
                        scl_reg <= 1'b0;
                        sda_reg <= shift_reg[7-bit_count];
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b0;
                        if (bit_count == 3'b111) begin
                            next_state <= ADDR_ACK;
                            bit_count <= 3'b000;
                        end else begin
                            next_state <= ADDR;
                            bit_count <= bit_count + 1;
                        end
                    end else begin
                        next_state <= ADDR;
                    end
                end
                ADDR_ACK: begin
                    if (timer == prescale) begin
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b1;
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b1;
                        ack <= sda_i;
                        next_state <= (ack) ? (s_axis_cmd_read) ? READ : WRITE : STOP;
                        missed_ack_reg <= ~ack;
                    end else begin
                        next_state <= ADDR_ACK;
                    end
                end
                WRITE: begin
                    if (timer == prescale) begin
                        scl_reg <= 1'b0;
                        sda_reg <= shift_reg[7-bit_count];
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b0;
                        if (bit_count == 3'b111) begin
                            next_state <= WRITE_ACK;
                            bit_count <= 3'b000;
                        end else begin
                            next_state <= WRITE;
                            bit_count <= bit_count + 1;
                        end
                    end else begin
                        next_state <= WRITE;
                    end
                end
                WRITE_ACK: begin
                    if (timer == prescale) begin
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b1;
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b1;
                        ack <= sda_i;
                        missed_ack_reg <= ~ack;
                        if (ack) begin
                            if (s_axis_cmd_write_multiple && !s_axis_data_tlast) begin
                                next_state <= WRITE;
                                shift_reg <= s_axis_data_tdata;
                                s_axis_data_tready_reg <= 1'b1;
                            end else begin
                                next_state <= STOP;
                            end
                        end else begin
                            next_state <= STOP;
                        end
                    end else begin
                        next_state <= WRITE_ACK;
                    end
                end
                READ: begin
                    if (timer == prescale) begin
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b1;
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b1;
                        shift_reg[7-bit_count] <= sda_i;
                        if (bit_count == 3'b111) begin
                            next_state <= READ_ACK;
                            bit_count <= 3'b000;
                        end else begin
                            next_state <= READ;
                            bit_count <= bit_count + 1;
                        end
                    end else begin
                        next_state <= READ;
                    end
                end
                READ_ACK: begin
                    if (timer == prescale) begin
                        scl_reg <= 1'b0;
                        sda_reg <= (byte_count == 3'b000 && s_axis_data_tready) ? 1'b1 : 1'b0;
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= (byte_count == 3'b000 && s_axis_data_tready) ? 1'b1 : 1'b0;
                        m_axis_data_tdata_reg <= shift_reg;
                        m_axis_data_tvalid_reg <= 1'b1;
                        m_axis_data_tlast_reg <= (byte_count == 3'b000);
                        if (byte_count == 3'b000 && s_axis_data_tready) begin
                            byte_count <= 3'b111;
                        end else begin
                            byte_count <= byte_count - 1;
                        end
                        if (byte_count == 3'b000 && s_axis_data_tready) begin
                            if (s_axis_cmd_write_multiple && !s_axis_cmd_stop) begin
                                next_state <= ADDR;
                                shift_reg <= {s_axis_cmd_address, s_axis_cmd_read};
                            end else begin
                                next_state <= STOP;
                            end
                        end else begin
                            next_state <= READ;
                        end
                    end else begin
                        next_state <= READ_ACK;
                    end
                end
                STOP: begin
                    if (timer == prescale) begin
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b0;
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b0;
                        next_state <= IDLE;
                        s_axis_cmd_ready_reg <= 1'b0;
                        s_axis_data_tready_reg <= 1'b0;
                        m_axis_data_tvalid_reg <= 1'b0;
                        m_axis_data_tlast_reg <= 1'b0;
                    end else begin
                        next_state <= STOP;
                    end
                end
                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

    /*
     * Output assignments
     */
    assign s_axis_cmd_ready = s_axis_cmd_ready_reg;
    assign s_axis_data_tready = s_axis_data_tready_reg;
    assign m_axis_data_tdata = m_axis_data_tdata_reg;
    assign m_axis_data_tvalid = m_axis_data_tvalid_reg;
    assign m_axis_data_tlast = m_axis_data_tlast_reg;
    assign scl_o = scl_reg;
    assign scl_t = scl_t_reg;
    assign sda_o = sda_reg;
    assign sda_t = sda_t_reg;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;

endmodule
