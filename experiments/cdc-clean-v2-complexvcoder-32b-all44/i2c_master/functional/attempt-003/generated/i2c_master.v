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
    reg [7:0]  cmd_buffer;
    reg [7:0]  data_buffer;
    reg [2:0]  bit_counter;
    reg [3:0]  state;
    reg [3:0]  next_state;
    reg [15:0] scl_cnt;
    reg        sda_reg;
    reg        scl_reg;
    reg        scl_reg_t;
    reg        sda_reg_t;
    reg        cmd_ready;
    reg        data_ready;
    reg        data_valid;
    reg        data_last;
    reg        bus_busy;
    reg        bus_control_reg;
    reg        bus_active_reg;
    reg        ack_missed;

    // States
    localparam IDLE                = 4'b0000;
    localparam START               = 4'b0001;
    localparam ADDRESS             = 4'b0010;
    localparam ACK_ADDRESS         = 4'b0011;
    localparam WRITE_DATA          = 4'b0100;
    localparam ACK_WRITE           = 4'b0101;
    localparam READ_DATA           = 4'b0110;
    localparam ACK_READ            = 4'b0111;
    localparam STOP                = 4'b1000;

    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (s_axis_cmd_valid && s_axis_cmd_start) begin
                    next_state = START;
                end
            end
            START: begin
                if (scl_cnt == prescale) begin
                    next_state = ADDRESS;
                end
            end
            ADDRESS: begin
                if (scl_cnt == prescale) begin
                    next_state = ACK_ADDRESS;
                end
            end
            ACK_ADDRESS: begin
                if (scl_cnt == prescale) begin
                    if (sda_i) begin
                        next_state = IDLE;
                        ack_missed = 1;
                    end else begin
                        if (s_axis_cmd_read) begin
                            next_state = READ_DATA;
                        end else if (s_axis_cmd_write || s_axis_cmd_write_multiple) begin
                            next_state = WRITE_DATA;
                        end
                    end
                end
            end
            WRITE_DATA: begin
                if (scl_cnt == prescale) begin
                    if (bit_counter == 7) begin
                        next_state = ACK_WRITE;
                    end
                end
            end
            ACK_WRITE: begin
                if (scl_cnt == prescale) begin
                    if (sda_i) begin
                        next_state = IDLE;
                        ack_missed = 1;
                    end else begin
                        if (s_axis_cmd_write_multiple && s_axis_data_tvalid && !s_axis_data_tlast) begin
                            next_state = WRITE_DATA;
                        end else begin
                            next_state = STOP;
                        end
                    end
                end
            end
            READ_DATA: begin
                if (scl_cnt == prescale) begin
                    if (bit_counter == 7) begin
                        next_state = ACK_READ;
                    end
                end
            end
            ACK_READ: begin
                if (scl_cnt == prescale) begin
                    if (s_axis_cmd_read && !s_axis_data_tready) begin
                        next_state = ACK_READ;
                    end else begin
                        if (s_axis_cmd_read) begin
                            next_state = READ_DATA;
                        end else begin
                            next_state = STOP;
                        end
                    end
                end
            end
            STOP: begin
                if (scl_cnt == prescale) begin
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Output logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_cnt <= 16'b0;
            sda_reg <= 1'b1;
            scl_reg <= 1'b1;
            scl_reg_t <= 1'b1;
            sda_reg_t <= 1'b1;
            cmd_ready <= 1'b0;
            data_ready <= 1'b0;
            data_valid <= 1'b0;
            data_last <= 1'b0;
            bus_busy <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            ack_missed <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    scl_cnt <= 16'b0;
                    sda_reg <= 1'b1;
                    scl_reg <= 1'b1;
                    scl_reg_t <= 1'b1;
                    sda_reg_t <= 1'b1;
                    cmd_ready <= 1'b1;
                    data_ready <= 1'b0;
                    data_valid <= 1'b0;
                    data_last <= 1'b0;
                    bus_busy <= 1'b0;
                    bus_control_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    ack_missed <= 1'b0;
                end
                START: begin
                    scl_cnt <= scl_cnt + 1;
                    if (scl_cnt == prescale) begin
                        sda_reg <= 1'b0;
                        scl_cnt <= 16'b0;
                    end
                end
                ADDRESS: begin
                    scl_cnt <= scl_cnt + 1;
                    if (scl_cnt == prescale) begin
                        sda_reg <= cmd_buffer[7 - bit_counter];
                        scl_cnt <= 16'b0;
                        bit_counter <= bit_counter + 1;
                    end
                end
                ACK_ADDRESS: begin
                    scl_cnt <= scl_cnt + 1;
                    if (scl_cnt == prescale) begin
                        scl_cnt <= 16'b0;
                    end
                end
                WRITE_DATA: begin
                    scl_cnt <= scl_cnt + 1;
                    if (scl_cnt == prescale) begin
                        sda_reg <= data_buffer[7 - bit_counter];
                        scl_cnt <= 16'b0;
                        bit_counter <= bit_counter + 1;
                    end
                end
                ACK_WRITE: begin
                    scl_cnt <= scl_cnt + 1;
                    if (scl_cnt == prescale) begin
                        scl_cnt <= 16'b0;
                        bit_counter <= 3'b0;
                    end
                end
                READ_DATA: begin
                    scl_cnt <= scl_cnt + 1;
                    if (scl_cnt == prescale) begin
                        data_buffer[7 - bit_counter] <= sda_i;
                        scl_cnt <= 16'b0;
                        bit_counter <= bit_counter + 1;
                    end
                end
                ACK_READ: begin
                    scl_cnt <= scl_cnt + 1;
                    if (scl_cnt == prescale) begin
                        sda_reg <= bit_counter != 7;
                        scl_cnt <= 16'b0;
                        if (bit_counter == 7) begin
                            data_valid <= 1'b1;
                            data_last <= s_axis_data_tlast;
                            data_ready <= 1'b1;
                        end
                        bit_counter <= bit_counter + 1;
                    end
                end
                STOP: begin
                    scl_cnt <= scl_cnt + 1;
                    if (scl_cnt == prescale) begin
                        sda_reg <= 1'b1;
                        scl_cnt <= 16'b0;
                    end
                end
                default: begin
                    scl_cnt <= 16'b0;
                    sda_reg <= 1'b1;
                    scl_reg <= 1'b1;
                    scl_reg_t <= 1'b1;
                    sda_reg_t <= 1'b1;
                    cmd_ready <= 1'b0;
                    data_ready <= 1'b0;
                    data_valid <= 1'b0;
                    data_last <= 1'b0;
                    bus_busy <= 1'b0;
                    bus_control_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    ack_missed <= 1'b0;
                end
            endcase
        end
    end

    // Command buffer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_buffer <= 8'b0;
        end else if (state == START && s_axis_cmd_valid) begin
            cmd_buffer <= {s_axis_cmd_address, 1'b0}; // Write
            if (s_axis_cmd_read) begin
                cmd_buffer[0] <= 1'b1; // Read
            end
        end
    end

    // Data buffer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_buffer <= 8'b0;
        end else if (state == WRITE_DATA && s_axis_data_tvalid) begin
            data_buffer <= s_axis_data_tdata;
        end
    end

    // Handshake signals
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_cmd_ready <= 1'b0;
            s_axis_data_tready <= 1'b0;
            m_axis_data_tvalid <= 1'b0;
            m_axis_data_tlast <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    s_axis_cmd_ready <= 1'b1;
                    s_axis_data_tready <= 1'b0;
                    m_axis_data_tvalid <= 1'b0;
                    m_axis_data_tlast <= 1'b0;
                end
                ACK_WRITE: begin
                    if (s_axis_cmd_write_multiple && s_axis_data_tvalid && !s_axis_data_tlast) begin
                        s_axis_data_tready <= 1'b1;
                    end else begin
                        s_axis_data_tready <= 1'b0;
                    end
                end
                ACK_READ: begin
                    if (data_valid && m_axis_data_tready) begin
                        data_valid <= 1'b0;
                        data_ready <= 1'b0;
                        m_axis_data_tvalid <= 1'b0;
                        m_axis_data_tlast <= 1'b0;
                    end else begin
                        m_axis_data_tvalid <= data_valid;
                        m_axis_data_tlast <= data_last;
                    end
                end
                default: begin
                    s_axis_cmd_ready <= 1'b0;
                    s_axis_data_tready <= 1'b0;
                    m_axis_data_tvalid <= 1'b0;
                    m_axis_data_tlast <= 1'b0;
                end
            endcase
        end
    end

    // Status signals
    assign busy = (state != IDLE);
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = ack_missed;

    // Open-drain outputs
    assign scl_o = scl_reg;
    assign scl_t = scl_reg_t;
    assign sda_o = sda_reg;
    assign sda_t = sda_reg_t;

    // Data output
    assign m_axis_data_tdata = data_buffer;

endmodule
