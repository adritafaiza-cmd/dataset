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

    wire               s_axis_cmd_ready_i;
    wire               s_axis_data_tready_i;
    wire [7:0]         m_axis_data_tdata_i;
    wire               m_axis_data_tvalid_i;
    wire               m_axis_data_tlast_i;
    wire               scl_o_i;
    wire               scl_t_i;
    wire               sda_o_i;
    wire               sda_t_i;
    wire               busy_i;
    wire               bus_control_i;
    wire               bus_active_i;
    wire               missed_ack_i;

    i2c_state_machine state_machine (
        .clk                  (clk),
        .rst                  (rst),
        .prescale             (prescale),
        .stop_on_idle         (stop_on_idle),
        .s_axis_cmd_address   (s_axis_cmd_address),
        .s_axis_cmd_start     (s_axis_cmd_start),
        .s_axis_cmd_read      (s_axis_cmd_read),
        .s_axis_cmd_write     (s_axis_cmd_write),
        .s_axis_cmd_write_multiple (s_axis_cmd_write_multiple),
        .s_axis_cmd_stop      (s_axis_cmd_stop),
        .s_axis_cmd_valid     (s_axis_cmd_valid),
        .s_axis_cmd_ready     (s_axis_cmd_ready_i),
        .s_axis_data_tdata    (s_axis_data_tdata),
        .s_axis_data_tvalid   (s_axis_data_tvalid),
        .s_axis_data_tready   (s_axis_data_tready_i),
        .s_axis_data_tlast    (s_axis_data_tlast),
        .m_axis_data_tdata    (m_axis_data_tdata_i),
        .m_axis_data_tvalid   (m_axis_data_tvalid_i),
        .m_axis_data_tready   (m_axis_data_tready),
        .m_axis_data_tlast    (m_axis_data_tlast_i),
        .scl_i                (scl_i),
        .scl_o                (scl_o_i),
        .scl_t                (scl_t_i),
        .sda_i                (sda_i),
        .sda_o                (sda_o_i),
        .sda_t                (sda_t_i),
        .busy                 (busy_i),
        .bus_control          (bus_control_i),
        .bus_active           (bus_active_i),
        .missed_ack           (missed_ack_i)
    );

    assign s_axis_cmd_ready  = s_axis_cmd_ready_i;
    assign s_axis_data_tready = s_axis_data_tready_i;
    assign m_axis_data_tdata = m_axis_data_tdata_i;
    assign m_axis_data_tvalid = m_axis_data_tvalid_i;
    assign m_axis_data_tlast = m_axis_data_tlast_i;
    assign scl_o = scl_o_i;
    assign scl_t = scl_t_i;
    assign sda_o = sda_o_i;
    assign sda_t = sda_t_i;
    assign busy = busy_i;
    assign bus_control = bus_control_i;
    assign bus_active = bus_active_i;
    assign missed_ack = missed_ack_i;

endmodule

module i2c_state_machine (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] prescale,
    input  wire        stop_on_idle,
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
    input  wire        scl_i,
    output wire        scl_o,
    output wire        scl_t,
    input  wire        sda_i,
    output wire        sda_o,
    output wire        sda_t,
    output wire        busy,
    output wire        bus_control,
    output wire        bus_active,
    output wire        missed_ack
);

    // States
    localparam IDLE = 4'b0000;
    localparam START = 4'b0001;
    localparam ADDR = 4'b0010;
    localparam ACK_ADDR = 4'b0011;
    localparam WRITE = 4'b0100;
    localparam ACK_WRITE = 4'b0101;
    localparam READ = 4'b0110;
    localparam ACK_READ = 4'b0111;
    localparam STOP = 4'b1000;

    reg [3:0] current_state;
    reg [3:0] next_state;
    reg [2:0] bit_count;
    reg [15:0] scl_counter;
    reg [15:0] sda_counter;
    reg [7:0] data_shift_reg;
    reg [7:0] read_data_shift_reg;
    reg ack_received;
    reg data_valid;
    reg data_ready;

    // SCL and SDA control signals
    reg scl_o_reg;
    reg scl_t_reg;
    reg sda_o_reg;
    reg sda_t_reg;

    // Status signals
    reg busy_reg;
    reg bus_control_reg;
    reg bus_active_reg;
    reg missed_ack_reg;

    // Command signals
    reg cmd_start;
    reg cmd_read;
    reg cmd_write;
    reg cmd_write_multiple;
    reg cmd_stop;
    reg cmd_valid;

    // Data signals
    reg [7:0] cmd_address;
    reg [7:0] data_tdata;
    reg data_tvalid;
    reg data_tlast;

    // Handshake signals
    reg cmd_ready;
    reg data_tready;

    // State transition and output logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            scl_o_reg <= 1'b1;
            scl_t_reg <= 1'b1;
            sda_o_reg <= 1'b1;
            sda_t_reg <= 1'b1;
            busy_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            missed_ack_reg <= 1'b0;
        end else begin
            current_state <= next_state;

            case (current_state)
                IDLE: begin
                    scl_o_reg <= 1'b1;
                    scl_t_reg <= 1'b1;
                    sda_o_reg <= 1'b1;
                    sda_t_reg <= 1'b1;
                    busy_reg <= 1'b0;
                    bus_control_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    missed_ack_reg <= 1'b0;
                end

                START: begin
                    scl_o_reg <= 1'b0;
                    scl_t_reg <= 1'b0;
                    sda_o_reg <= 1'b0;
                    sda_t_reg <= 1'b0;
                    busy_reg <= 1'b1;
                    bus_control_reg <= 1'b1;
                    bus_active_reg <= 1'b1;
                end

                ADDR: begin
                    if (scl_counter == 0) begin
                        sda_o_reg <= cmd_address[7-bit_count];
                        sda_t_reg <= 1'b0;
                        scl_counter <= prescale;
                    end else begin
                        scl_counter <= scl_counter - 1;
                        if (scl_counter == 1) begin
                            scl_o_reg <= 0;
                            scl_t_reg <= 1'b0;
                        end else if (scl_counter == (prescale/2)) begin
                            scl_o_reg <= 1;
                        end
                    end
                end

                ACK_ADDR: begin
                    if (scl_counter == 0) begin
                        sda_t_reg <= 1'b1;
                        scl_counter <= prescale;
                    end else begin
                        scl_counter <= scl_counter - 1;
                        if (scl_counter == 1) begin
                            scl_o_reg <= 0;
                            scl_t_reg <= 1'b0;
                        end else if (scl_counter == (prescale/2)) begin
                            scl_o_reg <= 1;
                            ack_received <= sda_i;
                        end
                    end
                end

                WRITE: begin
                    if (scl_counter == 0) begin
                        sda_o_reg <= data_shift_reg[7-bit_count];
                        sda_t_reg <= 1'b0;
                        scl_counter <= prescale;
                    end else begin
                        scl_counter <= scl_counter - 1;
                        if (scl_counter == 1) begin
                            scl_o_reg <= 0;
                            scl_t_reg <= 1'b0;
                        end else if (scl_counter == (prescale/2)) begin
                            scl_o_reg <= 1;
                        end
                    end
                end

                ACK_WRITE: begin
                    if (scl_counter == 0) begin
                        sda_t_reg <= 1'b1;
                        scl_counter <= prescale;
                    end else begin
                        scl_counter <= scl_counter - 1;
                        if (scl_counter == 1) begin
                            scl_o_reg <= 0;
                            scl_t_reg <= 1'b0;
                        end else if (scl_counter == (prescale/2)) begin
                            scl_o_reg <= 1;
                            ack_received <= sda_i;
                        end
                    end
                end

                READ: begin
                    if (scl_counter == 0) begin
                        sda_t_reg <= 1'b1;
                        scl_counter <= prescale;
                    end else begin
                        scl_counter <= scl_counter - 1;
                        if (scl_counter == 1) begin
                            scl_o_reg <= 0;
                            scl_t_reg <= 1'b0;
                        end else if (scl_counter == (prescale/2)) begin
                            scl_o_reg <= 1;
                            read_data_shift_reg[7-bit_count] <= sda_i;
                        end
                    end
                end

                ACK_READ: begin
                    if (scl_counter == 0) begin
                        sda_o_reg <= (bit_count == 7) ? 1'b1 : 1'b0;
                        sda_t_reg <= 1'b0;
                        scl_counter <= prescale;
                    end else begin
                        scl_counter <= scl_counter - 1;
                        if (scl_counter == 1) begin
                            scl_o_reg <= 0;
                            scl_t_reg <= 1'b0;
                        end else if (scl_counter == (prescale/2)) begin
                            scl_o_reg <= 1;
                        end
                    end
                end

                STOP: begin
                    if (scl_counter == 0) begin
                        sda_o_reg <= 0;
                        sda_t_reg <= 1'b0;
                        scl_counter <= prescale;
                    end else begin
                        scl_counter <= scl_counter - 1;
                        if (scl_counter == 1) begin
                            scl_o_reg <= 0;
                            scl_t_reg <= 1'b0;
                        end else if (scl_counter == (prescale/2)) begin
                            scl_o_reg <= 1;
                            sda_o_reg <= 1;
                            sda_t_reg <= 1'b0;
                        end else if (scl_counter == prescale) begin
                            scl_o_reg <= 1;
                            sda_o_reg <= 1;
                            sda_t_reg <= 1'b1;
                            busy_reg <= 1'b0;
                            bus_control_reg <= 1'b0;
                            bus_active_reg <= 1'b0;
                        end
                    end
                end

                default: begin
                    current_state <= IDLE;
                end
            endcase
        end
    end

    // Next state logic
    always @(*) begin
        next_state = current_state;

        case (current_state)
            IDLE: begin
                if (cmd_valid && cmd_start) begin
                    next_state = START;
                end
            end

            START: begin
                next_state = ADDR;
            end

            ADDR: begin
                if (scl_counter == 0) begin
                    if (bit_count == 7) begin
                        next_state = ACK_ADDR;
                        bit_count <= 0;
                    end else begin
                        bit_count <= bit_count + 1;
                    end
                end
            end

            ACK_ADDR: begin
                if (scl_counter == 0) begin
                    if (ack_received == 1'b0) begin
                        if (cmd_read) begin
                            next_state = READ;
                        end else if (cmd_write || cmd_write_multiple) begin
                            next_state = WRITE;
                        end
                    end else begin
                        missed_ack_reg <= 1'b1;
                        next_state = STOP;
                    end
                end
            end

            WRITE: begin
                if (scl_counter == 0) begin
                    if (bit_count == 7) begin
                        next_state = ACK_WRITE;
                        bit_count <= 0;
                    end else begin
                        bit_count <= bit_count + 1;
                    end
                end
            end

            ACK_WRITE: begin
                if (scl_counter == 0) begin
                    if (ack_received == 1'b0) begin
                        missed_ack_reg <= 1'b1;
                        next_state = STOP;
                    end else if (cmd_write_multiple && data_tvalid) begin
                        next_state = WRITE;
                        data_shift_reg <= data_tdata;
                    end else begin
                        next_state = STOP;
                    end
                end
            end

            READ: begin
                if (scl_counter == 0) begin
                    if (bit_count == 7) begin
                        next_state = ACK_READ;
                        bit_count <= 0;
                    end else begin
                        bit_count <= bit_count + 1;
                    end
                end
            end

            ACK_READ: begin
                if (scl_counter == 0) begin
                    if (bit_count == 7) begin
                        next_state = STOP;
                    end else begin
                        bit_count <= bit_count + 1;
                    end
                end
            end

            STOP: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Command and data handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_start <= 1'b0;
            cmd_read <= 1'b0;
            cmd_write <= 1'b0;
            cmd_write_multiple <= 1'b0;
            cmd_stop <= 1'b0;
            cmd_valid <= 1'b0;
            cmd_ready <= 1'b0;
            cmd_address <= 7'b0;
            data_tdata <= 8'b0;
            data_tvalid <= 1'b0;
            data_tlast <= 1'b0;
            data_tready <= 1'b0;
            data_shift_reg <= 8'b0;
            read_data_shift_reg <= 8'b0;
            data_valid <= 1'b0;
            data_ready <= 1'b0;
        end else begin
            cmd_ready <= 1'b0;
            data_tready <= 1'b0;

            if (current_state == IDLE) begin
                if (s_axis_cmd_valid) begin
                    cmd_start <= s_axis_cmd_start;
                    cmd_read <= s_axis_cmd_read;
                    cmd_write <= s_axis_cmd_write;
                    cmd_write_multiple <= s_axis_cmd_write_multiple;
                    cmd_stop <= s_axis_cmd_stop;
                    cmd_valid <= 1'b1;
                    cmd_address <= s_axis_cmd_address;
                    cmd_ready <= 1'b1;
                end
            end

            if (current_state == WRITE && scl_counter == prescale) begin
                if (s_axis_data_tvalid) begin
                    data_shift_reg <= s_axis_data_tdata;
                    data_tvalid <= 1'b1;
                    data_tlast <= s_axis_data_tlast;
                    data_tready <= 1'b1;
                end
            end

            if (current_state == ACK_WRITE && scl_counter == prescale) begin
                if (ack_received == 1'b0) begin
                    data_valid <= 1'b0;
                    data_ready <= 1'b0;
                end else if (cmd_write_multiple && s_axis_data_tvalid) begin
                    data_tready <= 1'b1;
                end else begin
                    data_valid <= 1'b0;
                    data_ready <= 1'b0;
                end
            end

            if (current_state == READ && scl_counter == prescale) begin
                if (bit_count == 7) begin
                    data_valid <= 1'b1;
                    data_tdata <= read_data_shift_reg;
                    data_tlast <= 1'b0;
                    data_ready <= m_axis_data_tready;
                end
            end

            if (current_state == ACK_READ && scl_counter == prescale) begin
                if (bit_count == 7) begin
                    data_valid <= 1'b0;
                    data_ready <= 1'b0;
                end
            end

            if (current_state == STOP) begin
                data_valid <= 1'b0;
                data_ready <= 1'b0;
            end
        end
    end

    // Output assignments
    assign s_axis_cmd_ready = cmd_ready;
    assign s_axis_data_tready = data_tready;
    assign m_axis_data_tdata = data_tdata;
    assign m_axis_data_tvalid = data_valid;
    assign m_axis_data_tlast = data_tlast;
    assign scl_o = scl_o_reg;
    assign scl_t = scl_t_reg;
    assign sda_o = sda_o_reg;
    assign sda_t = sda_t_reg;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;

endmodule
