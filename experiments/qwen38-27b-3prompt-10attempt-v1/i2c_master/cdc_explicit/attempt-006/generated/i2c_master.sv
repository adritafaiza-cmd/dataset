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

    // State machine states
    localparam S_IDLE = 4'd0;
    localparam S_START = 4'd1;
    localparam S_ADDR = 4'd2;
    localparam S_DATA = 4'd3;
    localparam S_ACK = 4'd4;
    localparam S_STOP = 4'd5;
    localparam S_WAIT = 4'd6;

    reg [3:0] state, state_next;
    reg [7:0] data_reg;
    reg [7:0] data_next;
    reg [2:0] bit_cnt;
    reg [2:0] bit_cnt_next;
    reg       scl_reg;
    reg       sda_reg;
    reg       scl_next;
    reg       sda_next;
    reg       scl_t_reg;
    reg       sda_t_reg;
    reg       scl_t_next;
    reg       sda_t_next;
    reg       busy_reg;
    reg       missed_ack_reg;
    reg       bus_control_reg;
    reg       bus_active_reg;
    reg       cmd_start_reg;
    reg       cmd_read_reg;
    reg       cmd_write_reg;
    reg       cmd_write_multiple_reg;
    reg       cmd_stop_reg;
    reg [6:0] addr_reg;
    reg       ack_reg;
    reg       ack_next;
    reg       data_valid_reg;
    reg       data_valid_next;
    reg       data_last_reg;
    reg       data_last_next;
    reg [7:0] data_out_reg;
    reg [7:0] data_out_next;
    reg       data_ready_reg;
    reg       data_ready_next;
    reg       cmd_ready_reg;
    reg       cmd_ready_next;
    reg       scl_i_reg;
    reg       sda_i_reg;
    reg [15:0] prescale_reg;
    reg       stop_on_idle_reg;
    reg [15:0] prescale_cnt;
    reg [15:0] prescale_cnt_next;
    reg       prescale_done;
    reg       prescale_done_next;

    // Synchronize inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_i_reg <= 1'b1;
            sda_i_reg <= 1'b1;
            prescale_reg <= 16'd0;
            stop_on_idle_reg <= 1'b0;
        end else begin
            scl_i_reg <= scl_i;
            sda_i_reg <= sda_i;
            prescale_reg <= prescale;
            stop_on_idle_reg <= stop_on_idle;
        end
    end

    // Synchronize command inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_start_reg <= 1'b0;
            cmd_read_reg <= 1'b0;
            cmd_write_reg <= 1'b0;
            cmd_write_multiple_reg <= 1'b0;
            cmd_stop_reg <= 1'b0;
            addr_reg <= 7'd0;
        end else begin
            if (s_axis_cmd_valid && s_axis_cmd_ready) begin
                cmd_start_reg <= s_axis_cmd_start;
                cmd_read_reg <= s_axis_cmd_read;
                cmd_write_reg <= s_axis_cmd_write;
                cmd_write_multiple_reg <= s_axis_cmd_write_multiple;
                cmd_stop_reg <= s_axis_cmd_stop;
                addr_reg <= s_axis_cmd_address;
            end
        end
    end

    // Synchronize data inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_reg <= 8'd0;
            data_valid_reg <= 1'b0;
            data_last_reg <= 1'b0;
        end else begin
            if (s_axis_data_tvalid && s_axis_data_tready) begin
                data_reg <= s_axis_data_tdata;
                data_valid_reg <= 1'b1;
                data_last_reg <= s_axis_data_tlast;
            end else if (state == S_DATA && bit_cnt == 3'd0) begin
                data_valid_reg <= 1'b0;
            end
        end
    end

    // Synchronize output ready
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_ready_reg <= 1'b0;
        end else begin
            data_ready_reg <= m_axis_data_tready;
        end
    end

    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            bit_cnt <= 3'd0;
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            scl_t_reg <= 1'b1;
            sda_t_reg <= 1'b1;
            busy_reg <= 1'b0;
            missed_ack_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            ack_reg <= 1'b0;
            data_out_reg <= 8'd0;
            prescale_cnt <= 16'd0;
            prescale_done <= 1'b0;
        end else begin
            state <= state_next;
            bit_cnt <= bit_cnt_next;
            scl_reg <= scl_next;
            sda_reg <= sda_next;
            scl_t_reg <= scl_t_next;
            sda_t_reg <= sda_t_next;
            busy_reg <= busy_reg;
            missed_ack_reg <= missed_ack_reg;
            bus_control_reg <= bus_control_reg;
            bus_active_reg <= bus_active_reg;
            ack_reg <= ack_next;
            data_out_reg <= data_out_next;
            prescale_cnt <= prescale_cnt_next;
            prescale_done <= prescale_done_next;
        end
    end

    // Next state logic
    always @(*) begin
        state_next = state;
        bit_cnt_next = bit_cnt;
        scl_next = scl_reg;
        sda_next = sda_reg;
        scl_t_next = scl_t_reg;
        sda_t_next = sda_t_reg;
        ack_next = ack_reg;
        data_out_next = data_out_reg;
        prescale_cnt_next = prescale_cnt;
        prescale_done_next = prescale_done;

        case (state)
            S_IDLE: begin
                if (s_axis_cmd_valid && s_axis_cmd_ready) begin
                    if (s_axis_cmd_start) begin
                        state_next = S_START;
                        busy_reg = 1'b1;
                        bus_control_reg = 1'b1;
                        bus_active_reg = 1'b1;
                        missed_ack_reg = 1'b0;
                        bit_cnt_next = 3'd0;
                        scl_next = 1'b1;
                        sda_next = 1'b1;
                        scl_t_next = 1'b0;
                        sda_t_next = 1'b0;
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end else if (s_axis_cmd_stop) begin
                        state_next = S_STOP;
                        busy_reg = 1'b1;
                        bus_control_reg = 1'b1;
                        bus_active_reg = 1'b1;
                        missed_ack_reg = 1'b0;
                        bit_cnt_next = 3'd0;
                        scl_next = 1'b1;
                        sda_next = 1'b0;
                        scl_t_next = 1'b0;
                        sda_t_next = 1'b0;
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end
                end
            end

            S_START: begin
                if (prescale_done) begin
                    if (bit_cnt == 3'd0) begin
                        // SDA high to low while SCL high
                        sda_next = 1'b0;
                        sda_t_next = 1'b0;
                        bit_cnt_next = 3'd1;
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end else if (bit_cnt == 3'd1) begin
                        // SCL low
                        scl_next = 1'b0;
                        scl_t_next = 1'b0;
                        bit_cnt_next = 3'd2;
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end else if (bit_cnt == 3'd2) begin
                        // SDA low, SCL low
                        sda_next = 1'b0;
                        sda_t_next = 1'b0;
                        bit_cnt_next = 3'd3;
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end else if (bit_cnt == 3'd3) begin
                        // SCL high
                        scl_next = 1'b1;
                        scl_t_next = 1'b0;
                        bit_cnt_next = 3'd0;
                        state_next = S_ADDR;
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end
                end
            end

            S_ADDR: begin
                if (prescale_done) begin
                    if (bit_cnt < 3'd7) begin
                        // Drive address bit
                        if (cmd_read_reg) begin
                            sda_next = ~addr_reg[6-bit_cnt];
                        end else begin
                            sda_next = ~addr_reg[6-bit_cnt];
                        end
                        sda_t_next = 1'b0;
                        bit_cnt_next = bit_cnt + 3'd1;
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end else if (bit_cnt == 3'd7) begin
                        // Drive R/W bit
                        sda_next = cmd_read_reg;
                        sda_t_next = 1'b0;
                        bit_cnt_next = 3'd0;
                        state_next = S_ACK;
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end
                end
            end

            S_ACK: begin
                if (prescale_done) begin
                    if (bit_cnt == 3'd0) begin
                        // Release SDA to read ACK
                        sda_t_next = 1'b1;
                        sda_next = 1'b1;
                        bit_cnt_next = 3'd1;
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end else if (bit_cnt == 3'd1) begin
                        // SCL high to sample ACK
                        scl_next = 1'b1;
                        scl_t_next = 1'b0;
                        bit_cnt_next = 3'd2;
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end else if (bit_cnt == 3'd2) begin
                        // Sample ACK
                        ack_next = ~sda_i_reg;
                        if (sda_i_reg) begin
                            missed_ack_reg = 1'b1;
                        end
                        bit_cnt_next = 3'd3;
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end else if (bit_cnt == 3'd3) begin
                        // SCL low
                        scl_next = 1'b0;
                        scl_t_next = 1'b0;
                        bit_cnt_next = 3'd0;
                        if (cmd_read_reg) begin
                            state_next = S_DATA;
                        end else begin
                            if (cmd_write_multiple_reg) begin
                                state_next = S_DATA;
                            end else begin
                                state_next = S_STOP;
                            end
                        end
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end
                end
            end

            S_DATA: begin
                if (prescale_done) begin
                    if (cmd_read_reg) begin
                        // Read data
                        if (bit_cnt < 3'd7) begin
                            // SCL high to sample data
                            scl_next = 1'b1;
                            scl_t_next = 1'b0;
                            bit_cnt_next = bit_cnt + 3'd1;
                            prescale_cnt_next = 16'd0;
                            prescale_done_next = 1'b0;
                        end else if (bit_cnt == 3'd7) begin
                            // Sample last bit
                            data_out_next = {sda_i_reg, data_out_reg[7:1]};
                            bit_cnt_next = 3'd0;
                            state_next = S_ACK;
                            prescale_cnt_next = 16'd0;
                            prescale_done_next = 1'b0;
                        end
                    end else begin
                        // Write data
                        if (bit_cnt < 3'd7) begin
                            // Drive data bit
                            sda_next = ~data_reg[7-bit_cnt];
                            sda_t_next = 1'b0;
                            bit_cnt_next = bit_cnt + 3'd1;
                            prescale_cnt_next = 16'd0;
                            prescale_done_next = 1'b0;
                        end else if (bit_cnt == 3'd7) begin
                            // Drive last bit
                            sda_next = ~data_reg[0];
                            sda_t_next = 1'b0;
                            bit_cnt_next = 3'd0;
                            state_next = S_ACK;
                            prescale_cnt_next = 16'd0;
                            prescale_done_next = 1'b0;
                        end
                    end
                end
            end

            S_STOP: begin
                if (prescale_done) begin
                    if (bit_cnt == 3'd0) begin
                        // SDA low
                        sda_next = 1'b0;
                        sda_t_next = 1'b0;
                        bit_cnt_next = 3'd1;
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end else if (bit_cnt == 3'd1) begin
                        // SCL high
                        scl_next = 1'b1;
                        scl_t_next = 1'b0;
                        bit_cnt_next = 3'd2;
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end else if (bit_cnt == 3'd2) begin
                        // SDA high
                        sda_next = 1'b1;
                        sda_t_next = 1'b0;
                        bit_cnt_next = 3'd3;
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end else if (bit_cnt == 3'd3) begin
                        // Release bus
                        scl_next = 1'b1;
                        sda_next = 1'b1;
                        scl_t_next = 1'b1;
                        sda_t_next = 1'b1;
                        bit_cnt_next = 3'd0;
                        state_next = S_IDLE;
                        busy_reg = 1'b0;
                        bus_control_reg = 1'b0;
                        bus_active_reg = 1'b0;
                        prescale_cnt_next = 16'd0;
                        prescale_done_next = 1'b0;
                    end
                end
            end

            default: begin
                state_next = S_IDLE;
            end
        endcase

        // Prescale counter
        if (state != S_IDLE) begin
            if (prescale_cnt < prescale_reg) begin
                prescale_cnt_next = prescale_cnt + 16'd1;
                prescale_done_next = 1'b0;
            end else begin
                prescale_cnt_next = prescale_cnt;
                prescale_done_next = 1'b1;
            end
        end else begin
            prescale_cnt_next = 16'd0;
            prescale_done_next = 1'b0;
        end
    end

    // Output assignments
    assign scl_o = ~scl_t_reg;
    assign scl_t = scl_t_reg;
    assign sda_o = ~sda_t_reg;
    assign sda_t = sda_t_reg;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;
    assign s_axis_cmd_ready = (state == S_IDLE);
    assign s_axis_data_tready = (state == S_DATA) && (bit_cnt == 3'd0) && !cmd_read_reg;
    assign m_axis_data_tdata = data_out_reg;
    assign m_axis_data_tvalid = (state == S_ACK) && cmd_read_reg && (bit_cnt == 3'd2);
    assign m_axis_data_tlast = data_last_reg;

endmodule
