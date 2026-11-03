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
    reg        sda_reg;
    reg        scl_t_reg;
    reg        sda_t_reg;
    reg [2:0]  bit_count;
    reg [7:0]  byte_count;
    reg [6:0]  current_address;
    reg [7:0]  current_data;
    reg        read_mode;
    reg        write_mode;
    reg        write_multiple_mode;
    reg        stop_mode;
    reg        cmd_ready;
    reg        data_ready;
    reg        data_valid;
    reg        data_tlast;
    reg        start_condition;
    reg        stop_condition;
    reg        ack_received;
    reg [3:0]  state;
    reg [3:0]  next_state;

    // States
    localparam IDLE = 4'b0000;
    localparam START = 4'b0001;
    localparam SEND_ADDRESS = 4'b0010;
    localparam WAIT_ACK_ADDR = 4'b0011;
    localparam SEND_DATA = 4'b0100;
    localparam WAIT_ACK_DATA = 4'b0101;
    localparam RECEIVE_DATA = 4'b0110;
    localparam SEND_ACK = 4'b0111;
    localparam STOP = 4'b1000;

    // Handshakes
    assign s_axis_cmd_ready = (state == IDLE);
    assign s_axis_data_tready = (write_mode || write_multiple_mode) && (state == SEND_DATA || state == WAIT_ACK_DATA);
    assign m_axis_data_tvalid = read_mode && (state == RECEIVE_DATA);
    assign m_axis_data_tlast = read_mode && (state == RECEIVE_DATA) && (byte_count == 0);

    // I2C outputs
    assign scl_o = scl_reg;
    assign scl_t = scl_t_reg;
    assign sda_o = sda_reg;
    assign sda_t = sda_t_reg;

    // Status outputs
    assign busy = (state != IDLE);
    assign bus_control = (state != IDLE);
    assign bus_active = (state != IDLE);
    assign missed_ack = (state == WAIT_ACK_ADDR || state == WAIT_ACK_DATA) && !ack_received;

    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            scl_t_reg <= 1'b1;
            sda_t_reg <= 1'b1;
            bit_count <= 3'b0;
            byte_count <= 8'b0;
            current_address <= 7'b0;
            current_data <= 8'b0;
            read_mode <= 1'b0;
            write_mode <= 1'b0;
            write_multiple_mode <= 1'b0;
            stop_mode <= 1'b0;
            cmd_ready <= 1'b0;
            data_ready <= 1'b0;
            data_valid <= 1'b0;
            data_tlast <= 1'b0;
            start_condition <= 1'b0;
            stop_condition <= 1'b0;
            ack_received <= 1'b0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b1;
                    scl_t_reg <= 1'b1;
                    sda_t_reg <= 1'b1;
                    bit_count <= 3'b0;
                    byte_count <= 8'b0;
                    current_address <= 7'b0;
                    current_data <= 8'b0;
                    read_mode <= 1'b0;
                    write_mode <= 1'b0;
                    write_multiple_mode <= 1'b0;
                    stop_mode <= 1'b0;
                    cmd_ready <= 1'b0;
                    data_ready <= 1'b0;
                    data_valid <= 1'b0;
                    data_tlast <= 1'b0;
                    start_condition <= 1'b0;
                    stop_condition <= 1'b0;
                    ack_received <= 1'b0;

                    if (s_axis_cmd_valid) begin
                        cmd_ready <= 1'b1;
                        current_address <= s_axis_cmd_address;
                        read_mode <= s_axis_cmd_read;
                        write_mode <= s_axis_cmd_write;
                        write_multiple_mode <= s_axis_cmd_write_multiple;
                        stop_mode <= s_axis_cmd_stop;
                        next_state <= START;
                    end
                end

                START: begin
                    start_condition <= 1'b1;
                    scl_reg <= 1'b0;
                    sda_reg <= 1'b0;
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b0;
                    next_state <= SEND_ADDRESS;
                end

                SEND_ADDRESS: begin
                    start_condition <= 1'b0;
                    if (bit_count < 3'd7) begin
                        bit_count <= bit_count + 1'b1;
                        sda_reg <= current_address[6-bit_count];
                        scl_reg <= (bit_count == 3'd6) ? 1'b1 : scl_reg;
                    end else begin
                        sda_reg <= read_mode;
                        scl_reg <= 1'b1;
                        next_state <= WAIT_ACK_ADDR;
                    end
                end

                WAIT_ACK_ADDR: begin
                    scl_reg <= 1'b0;
                    sda_reg <= 1'b1;
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b1;
                    if (scl_i) begin
                        ack_received <= ~sda_i;
                        scl_reg <= 1'b1;
                        if (ack_received) begin
                            if (read_mode) begin
                                next_state <= RECEIVE_DATA;
                            end else if (write_mode || write_multiple_mode) begin
                                next_state <= SEND_DATA;
                            end
                        end else begin
                            next_state <= STOP;
                        end
                    end
                end

                SEND_DATA: begin
                    if (bit_count < 3'd7) begin
                        bit_count <= bit_count + 1'b1;
                        sda_reg <= current_data[7-bit_count];
                        scl_reg <= (bit_count == 3'd6) ? 1'b1 : scl_reg;
                    end else begin
                        sda_reg <= 1'b1;
                        scl_reg <= 1'b1;
                        next_state <= WAIT_ACK_DATA;
                    end
                end

                WAIT_ACK_DATA: begin
                    scl_reg <= 1'b0;
                    sda_reg <= 1'b1;
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b1;
                    if (scl_i) begin
                        ack_received <= ~sda_i;
                        scl_reg <= 1'b1;
                        if (ack_received) begin
                            if (write_multiple_mode && !s_axis_data_tlast) begin
                                next_state <= SEND_DATA;
                            end else begin
                                next_state <= STOP;
                            end
                        end else begin
                            next_state <= STOP;
                        end
                    end
                end

                RECEIVE_DATA: begin
                    scl_reg <= 1'b0;
                    sda_reg <= 1'b1;
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b1;
                    if (scl_i) begin
                        if (bit_count < 3'd7) begin
                            bit_count <= bit_count + 1'b1;
                            current_data[7-bit_count] <= sda_i;
                            scl_reg <= (bit_count == 3'd6) ? 1'b1 : scl_reg;
                        end else begin
                            scl_reg <= 1'b1;
                            m_axis_data_tdata <= current_data;
                            m_axis_data_tlast <= (byte_count == 8'd1);
                            byte_count <= byte_count - 1'b1;
                            if (byte_count == 8'd1) begin
                                next_state <= STOP;
                            end else begin
                                next_state <= SEND_ACK;
                            end
                        end
                    end
                end

                SEND_ACK: begin
                    scl_reg <= 1'b0;
                    sda_reg <= 1'b0;
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b0;
                    scl_reg <= 1'b1;
                    next_state <= RECEIVE_DATA;
                end

                STOP: begin
                    stop_condition <= 1'b1;
                    scl_reg <= 1'b0;
                    sda_reg <= 1'b0;
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b0;
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b1;
                    next_state <= IDLE;
                end

                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

    // Data handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_data <= 8'b0;
            byte_count <= 8'b0;
        end else begin
            if (s_axis_cmd_valid && (state == IDLE)) begin
                if (write_mode || write_multiple_mode) begin
                    current_data <= s_axis_data_tdata;
                    byte_count <= 8'd1;
                end
            end else if (s_axis_data_tvalid && (state == SEND_DATA || state == WAIT_ACK_DATA)) begin
                current_data <= s_axis_data_tdata;
                byte_count <= byte_count + 1'b1;
            end else if (m_axis_data_tready && (state == RECEIVE_DATA)) begin
                byte_count <= byte_count - 1'b1;
            end
        end
    end

endmodule
