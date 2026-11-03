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
    reg                bit_start;
    reg                bit_stop;
    reg                bit_data_out;
    wire               bit_data_in;
    reg                bit_valid;
    wire               bit_ready;
    reg  [6:0]         cmd_buffer;
    reg  [7:0]         data_buffer;
    reg  [2:0]         state;
    reg  [2:0]         next_state;
    reg  [3:0]         bit_count;
    reg  [7:0]         byte_count;
    reg                ack_received;
    reg                cmd_ready;
    reg                data_ready;
    reg                data_valid;
    reg                missed_ack_reg;
    reg                busy_reg;
    reg                bus_control_reg;
    reg                bus_active_reg;

    // State definitions
    localparam IDLE             = 3'b000;
    localparam START            = 3'b001;
    localparam ADDR             = 3'b010;
    localparam ADDR_ACK         = 3'b011;
    localparam WRITE_DATA       = 3'b100;
    localparam WRITE_DATA_ACK   = 3'b101;
    localparam READ_DATA        = 3'b110;
    localparam READ_DATA_ACK    = 3'b111;

    // I2C Bit Bang submodule
    i2c_bit_bang bit_bang_inst (
        .clk(clk),
        .rst(rst),
        .prescale(prescale),
        .bit_start(bit_start),
        .bit_stop(bit_stop),
        .bit_data_out(bit_data_out),
        .bit_data_in(bit_data_in),
        .bit_valid(bit_valid),
        .bit_ready(bit_ready),
        .scl_i(scl_i),
        .scl_o(scl_o),
        .scl_t(scl_t),
        .sda_i(sda_i),
        .sda_o(sda_o),
        .sda_t(sda_t)
    );

    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            cmd_buffer <= 7'b0;
            data_buffer <= 8'b0;
            bit_count <= 4'b0;
            byte_count <= 8'b0;
            ack_received <= 1'b0;
            cmd_ready <= 1'b0;
            data_ready <= 1'b0;
            data_valid <= 1'b0;
            missed_ack_reg <= 1'b0;
            busy_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    if (s_axis_cmd_valid && cmd_ready) begin
                        cmd_buffer <= s_axis_cmd_address;
                        if (s_axis_cmd_start) begin
                            next_state <= START;
                        end else begin
                            next_state <= IDLE;
                        end
                    end else begin
                        next_state <= IDLE;
                    end
                end
                START: begin
                    bit_start <= 1'b1;
                    next_state <= ADDR;
                end
                ADDR: begin
                    bit_start <= 1'b0;
                    bit_data_out <= cmd_buffer[6-bit_count];
                    bit_valid <= 1'b1;
                    if (bit_ready) begin
                        bit_valid <= 1'b0;
                        bit_count <= bit_count + 1;
                        if (bit_count == 4'd6) begin
                            bit_count <= 4'b0;
                            next_state <= ADDR_ACK;
                        end
                    end else begin
                        next_state <= ADDR;
                    end
                end
                ADDR_ACK: begin
                    if (bit_ready) begin
                        ack_received <= bit_data_in;
                        if (ack_received) begin
                            if (s_axis_cmd_read) begin
                                next_state <= READ_DATA;
                            end else if (s_axis_cmd_write) begin
                                next_state <= WRITE_DATA;
                            end else begin
                                next_state <= IDLE;
                            end
                        end else begin
                            missed_ack_reg <= 1'b1;
                            next_state <= IDLE;
                        end
                    end else begin
                        next_state <= ADDR_ACK;
                    end
                end
                WRITE_DATA: begin
                    if (s_axis_data_tvalid && data_ready) begin
                        data_buffer <= s_axis_data_tdata;
                        byte_count <= byte_count + 1;
                        if (s_axis_data_tlast) begin
                            next_state <= WRITE_DATA_ACK;
                        end else begin
                            next_state <= WRITE_DATA;
                        end
                    end else begin
                        next_state <= WRITE_DATA;
                    end
                end
                WRITE_DATA_ACK: begin
                    bit_data_out <= data_buffer[7-bit_count];
                    bit_valid <= 1'b1;
                    if (bit_ready) begin
                        bit_valid <= 1'b0;
                        bit_count <= bit_count + 1;
                        if (bit_count == 4'd7) begin
                            bit_count <= 4'b0;
                            if (ack_received) begin
                                if (byte_count == 8'd0) begin
                                    next_state <= IDLE;
                                end else begin
                                    next_state <= WRITE_DATA;
                                end
                            end else begin
                                missed_ack_reg <= 1'b1;
                                next_state <= IDLE;
                            end
                        end
                    end else begin
                        next_state <= WRITE_DATA_ACK;
                    end
                end
                READ_DATA: begin
                    if (bit_ready) begin
                        data_buffer[7-bit_count] <= bit_data_in;
                        bit_count <= bit_count + 1;
                        if (bit_count == 4'd7) begin
                            bit_count <= 4'b0;
                            data_valid <= 1'b1;
                            if (byte_count == 8'd0) begin
                                next_state <= IDLE;
                            end else begin
                                next_state <= READ_DATA_ACK;
                            end
                        end
                    end else begin
                        next_state <= READ_DATA;
                    end
                end
                READ_DATA_ACK: begin
                    bit_data_out <= s_axis_data_tlast ? 1'b1 : 1'b0;
                    bit_valid <= 1'b1;
                    if (bit_ready) begin
                        bit_valid <= 1'b0;
                        byte_count <= byte_count + 1;
                        if (s_axis_data_tlast) begin
                            next_state <= IDLE;
                        end else begin
                            next_state <= READ_DATA;
                        end
                    end else begin
                        next_state <= READ_DATA_ACK;
                    end
                end
                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

    // Command ready logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_ready <= 1'b0;
        end else begin
            if (state == IDLE && s_axis_cmd_valid) begin
                cmd_ready <= 1'b1;
            end else if (state != IDLE) begin
                cmd_ready <= 1'b0;
            end
        end
    end

    // Data ready logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_ready <= 1'b0;
        end else begin
            if (state == WRITE_DATA && s_axis_data_tvalid) begin
                data_ready <= 1'b1;
            end else if (state != WRITE_DATA) begin
                data_ready <= 1'b0;
            end
        end
    end

    // Output assignments
    assign s_axis_cmd_ready = cmd_ready;
    assign s_axis_data_tready = data_ready;
    assign m_axis_data_tdata = data_buffer;
    assign m_axis_data_tvalid = data_valid;
    assign m_axis_data_tlast = (byte_count == 8'd0) ? 1'b1 : 1'b0;
    assign missed_ack = missed_ack_reg;
    assign busy = (state != IDLE);
    assign bus_control = (state != IDLE);
    assign bus_active = (state != IDLE);

    // I2C Bit Bang submodule
    module i2c_bit_bang (
        input  wire        clk,
        input  wire        rst,
        input  wire [15:0] prescale,
        input  wire        bit_start,
        input  wire        bit_stop,
        input  wire        bit_data_out,
        output wire        bit_data_in,
        input  wire        bit_valid,
        output wire        bit_ready,
        input  wire        scl_i,
        output wire        scl_o,
        output wire        scl_t,
        input  wire        sda_i,
        output wire        sda_o,
        output wire        sda_t
    );

        // Internal signals
        reg  [15:0]        prescale_counter;
        reg  [15:0]        prescale_value;
        reg                scl_reg;
        reg                sda_reg;
        reg                scl_o_reg;
        reg                sda_o_reg;
        reg                scl_t_reg;
        reg                sda_t_reg;
        reg                bit_start_reg;
        reg                bit_stop_reg;
        reg                bit_data_out_reg;
        reg  [3:0]         bit_counter;
        reg                bit_valid_reg;
        reg                bit_ready_reg;
        reg                bit_data_in_reg;

        // State definitions
        localparam IDLE             = 3'b000;
        localparam START            = 3'b001;
        localparam DATA             = 3'b010;
        localparam ACK              = 3'b011;
        localparam STOP             = 3'b100;

        reg  [2:0]         state;
        reg  [2:0]         next_state;

        // State machine
        always @(posedge clk or posedge rst) begin
            if (rst) begin
                state <= IDLE;
                prescale_counter <= 16'b0;
                prescale_value <= prescale;
                scl_reg <= 1'b1;
                sda_reg <= 1'b1;
                scl_o_reg <= 1'b1;
                sda_o_reg <= 1'b1;
                scl_t_reg <= 1'b1;
                sda_t_reg <= 1'b1;
                bit_start_reg <= 1'b0;
                bit_stop_reg <= 1'b0;
                bit_data_out_reg <= 1'b0;
                bit_counter <= 4'b0;
                bit_valid_reg <= 1'b0;
                bit_ready_reg <= 1'b0;
                bit_data_in_reg <= 1'b0;
            end else begin
                state <= next_state;
                case (state)
                    IDLE: begin
                        if (bit_start) begin
                            next_state <= START;
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b1;
                            bit_start_reg <= 1'b1;
                            prescale_counter <= 16'b0;
                        end else if (bit_valid) begin
                            bit_valid_reg <= 1'b1;
                            bit_data_out_reg <= bit_data_out;
                            next_state <= DATA;
                            prescale_counter <= 16'b0;
                        end else begin
                            next_state <= IDLE;
                        end
                    end
                    START: begin
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b0;
                        if (prescale_counter == prescale_value) begin
                            prescale_counter <= 16'b0;
                            next_state <= DATA;
                        end else begin
                            prescale_counter <= prescale_counter + 1;
                        end
                    end
                    DATA: begin
                        if (prescale_counter == prescale_value) begin
                            prescale_counter <= 16'b0;
                            if (bit_counter == 4'd7) begin
                                next_state <= ACK;
                            end else begin
                                bit_counter <= bit_counter + 1;
                            end
                        end else begin
                            prescale_counter <= prescale_counter + 1;
                        end
                        scl_reg <= 1'b0;
                        sda_reg <= bit_data_out_reg;
                    end
                    ACK: begin
                        scl_reg <= 1'b0;
                        sda_reg <= 1'b1;
                        if (prescale_counter == prescale_value) begin
                            prescale_counter <= 16'b0;
                            bit_data_in_reg <= sda_i;
                            if (bit_stop) begin
                                next_state <= STOP;
                            end else if (bit_valid_reg) begin
                                next_state <= DATA;
                                bit_data_out_reg <= bit_data_out;
                                bit_counter <= 4'b0;
                            end else begin
                                next_state <= IDLE;
                                bit_ready_reg <= 1'b1;
                            end
                        end else begin
                            prescale_counter <= prescale_counter + 1;
                        end
                    end
                    STOP: begin
                        scl_reg <= 1'b0;
                        sda_reg <= 1'b0;
                        if (prescale_counter == prescale_value) begin
                            prescale_counter <= 16'b0;
                            if (bit_counter == 4'd7) begin
                                next_state <= IDLE;
                                scl_reg <= 1'b1;
                                sda_reg <= 1'b1;
                                bit_stop_reg <= 1'b0;
                                bit_ready_reg <= 1'b1;
                            end else begin
                                bit_counter <= bit_counter + 1;
                            end
                        end else begin
                            prescale_counter <= prescale_counter + 1;
                        end
                    end
                    default: begin
                        next_state <= IDLE;
                    end
                endcase
            end
        end

        // Output assignments
        assign scl_o = scl_reg;
        assign sda_o = sda_reg;
        assign scl_t = scl_t_reg;
        assign sda_t = sda_t_reg;
        assign bit_data_in = bit_data_in_reg;
        assign bit_ready = bit_ready_reg;

    endmodule

endmodule
