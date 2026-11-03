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

    wire cmd_valid;
    wire [1:0] cmd_type;
    wire [6:0] cmd_address;
    wire cmd_start;
    wire cmd_read;
    wire cmd_write;
    wire cmd_stop;

    wire data_out;
    wire [7:0] data_in;
    wire data_valid;
    wire data_ready;
    wire data_last;

    i2c_master_cmd_parser cmd_parser_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_cmd_address(s_axis_cmd_address),
        .s_axis_cmd_start(s_axis_cmd_start),
        .s_axis_cmd_read(s_axis_cmd_read),
        .s_axis_cmd_write(s_axis_cmd_write),
        .s_axis_cmd_write_multiple(s_axis_cmd_write_multiple),
        .s_axis_cmd_stop(s_axis_cmd_stop),
        .s_axis_cmd_valid(s_axis_cmd_valid),
        .s_axis_cmd_ready(s_axis_cmd_ready),
        .cmd_valid(cmd_valid),
        .cmd_type(cmd_type),
        .cmd_address(cmd_address),
        .cmd_start(cmd_start),
        .cmd_read(cmd_read),
        .cmd_write(cmd_write),
        .cmd_stop(cmd_stop)
    );

    i2c_master_data_handler data_handler_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_data_tdata(s_axis_data_tdata),
        .s_axis_data_tvalid(s_axis_data_tvalid),
        .s_axis_data_tready(s_axis_data_tready),
        .s_axis_data_tlast(s_axis_data_tlast),
        .m_axis_data_tdata(m_axis_data_tdata),
        .m_axis_data_tvalid(m_axis_data_tvalid),
        .m_axis_data_tready(m_axis_data_tready),
        .m_axis_data_tlast(m_axis_data_tlast),
        .cmd_valid(cmd_valid),
        .cmd_type(cmd_type),
        .cmd_address(cmd_address),
        .cmd_start(cmd_start),
        .cmd_read(cmd_read),
        .cmd_write(cmd_write),
        .cmd_stop(cmd_stop),
        .data_out(data_out),
        .data_in(data_in),
        .data_valid(data_valid),
        .data_ready(data_ready),
        .data_last(data_last),
        .busy(busy),
        .bus_control(bus_control),
        .bus_active(bus_active),
        .missed_ack(missed_ack)
    );

    i2c_master_bit_bang bit_bang_inst (
        .clk(clk),
        .rst(rst),
        .prescale(prescale),
        .stop_on_idle(stop_on_idle),
        .scl_i(scl_i),
        .scl_o(scl_o),
        .scl_t(scl_t),
        .sda_i(sda_i),
        .sda_o(sda_o),
        .sda_t(sda_t),
        .data_out(data_out),
        .data_in(data_in),
        .data_valid(data_valid),
        .data_ready(data_ready),
        .data_last(data_last)
    );

endmodule

module i2c_master_cmd_parser (
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
    output wire        cmd_valid,
    output wire [1:0]  cmd_type,
    output wire [6:0]  cmd_address,
    output wire        cmd_start,
    output wire        cmd_read,
    output wire        cmd_write,
    output wire        cmd_stop
);

    reg s_axis_cmd_ready_reg;
    reg cmd_valid_reg;
    reg [1:0] cmd_type_reg;
    reg [6:0] cmd_address_reg;
    reg cmd_start_reg;
    reg cmd_read_reg;
    reg cmd_write_reg;
    reg cmd_stop_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_cmd_ready_reg <= 0;
            cmd_valid_reg <= 0;
            cmd_type_reg <= 0;
            cmd_address_reg <= 0;
            cmd_start_reg <= 0;
            cmd_read_reg <= 0;
            cmd_write_reg <= 0;
            cmd_stop_reg <= 0;
        end else begin
            s_axis_cmd_ready_reg <= ~cmd_valid_reg;
            if (s_axis_cmd_valid && ~cmd_valid_reg) begin
                cmd_valid_reg <= 1;
                cmd_type_reg <= {s_axis_cmd_read, s_axis_cmd_write};
                cmd_address_reg <= s_axis_cmd_address;
                cmd_start_reg <= s_axis_cmd_start;
                cmd_read_reg <= s_axis_cmd_read;
                cmd_write_reg <= s_axis_cmd_write;
                cmd_stop_reg <= s_axis_cmd_stop;
            end else if (cmd_valid_reg) begin
                cmd_valid_reg <= 0;
            end
        end
    end

    assign s_axis_cmd_ready = s_axis_cmd_ready_reg;
    assign cmd_valid = cmd_valid_reg;
    assign cmd_type = cmd_type_reg;
    assign cmd_address = cmd_address_reg;
    assign cmd_start = cmd_start_reg;
    assign cmd_read = cmd_read_reg;
    assign cmd_write = cmd_write_reg;
    assign cmd_stop = cmd_stop_reg;

endmodule

module i2c_master_data_handler (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  s_axis_data_tdata,
    input  wire        s_axis_data_tvalid,
    output wire        s_axis_data_tready,
    input  wire        s_axis_data_tlast,
    output wire [7:0]  m_axis_data_tdata,
    output wire        m_axis_data_tvalid,
    input  wire        m_axis_data_tready,
    output wire        m_axis_data_tlast,
    input  wire        cmd_valid,
    input  wire [1:0]  cmd_type,
    input  wire [6:0]  cmd_address,
    input  wire        cmd_start,
    input  wire        cmd_read,
    input  wire        cmd_write,
    input  wire        cmd_stop,
    output wire        data_out,
    input  wire [7:0]  data_in,
    input  wire        data_valid,
    output wire        data_ready,
    input  wire        data_last,
    output wire        busy,
    output wire        bus_control,
    output wire        bus_active,
    output wire        missed_ack
);

    reg s_axis_data_tready_reg;
    reg m_axis_data_tvalid_reg;
    reg m_axis_data_tlast_reg;
    reg [7:0] m_axis_data_tdata_reg;
    reg data_ready_reg;
    reg busy_reg;
    reg bus_control_reg;
    reg bus_active_reg;
    reg missed_ack_reg;

    reg [7:0] data_buffer [0:31];
    reg [4:0] data_count;
    reg [7:0] read_data;
    reg read_data_valid;
    reg read_data_last;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_data_tready_reg <= 0;
            m_axis_data_tvalid_reg <= 0;
            m_axis_data_tlast_reg <= 0;
            data_ready_reg <= 0;
            busy_reg <= 0;
            bus_control_reg <= 0;
            bus_active_reg <= 0;
            missed_ack_reg <= 0;
            data_count <= 0;
            read_data_valid <= 0;
            read_data_last <= 0;
        end else begin
            s_axis_data_tready_reg <= ~busy_reg;
            if (cmd_valid && ~busy_reg) begin
                busy_reg <= 1;
                bus_control_reg <= 1;
                if (cmd_write) begin
                    data_buffer[data_count] <= s_axis_data_tdata;
                    data_count <= data_count + 1;
                    if (s_axis_data_tlast) begin
                        bus_active_reg <= 1;
                    end
                end else if (cmd_read) begin
                    bus_active_reg <= 1;
                end
            end else if (data_valid) begin
                if (cmd_write) begin
                    if (data_last) begin
                        busy_reg <= 0;
                        bus_control_reg <= 0;
                        bus_active_reg <= 0;
                    end
                end else if (cmd_read) begin
                    read_data <= data_in;
                    read_data_valid <= 1;
                    read_data_last <= data_last;
                    if (data_last) begin
                        busy_reg <= 0;
                        bus_control_reg <= 0;
                        bus_active_reg <= 0;
                    end
                end
            end

            if (read_data_valid && m_axis_data_tready) begin
                m_axis_data_tvalid_reg <= 1;
                m_axis_data_tdata_reg <= read_data;
                m_axis_data_tlast_reg <= read_data_last;
                read_data_valid <= 0;
            end else if (m_axis_data_tvalid) begin
                m_axis_data_tvalid_reg <= 0;
            end

            data_ready_reg <= data_valid;

            if (data_last && missed_ack_reg) begin
                missed_ack_reg <= 0;
            end
        end
    end

    assign s_axis_data_tready = s_axis_data_tready_reg;
    assign m_axis_data_tvalid = m_axis_data_tvalid_reg;
    assign m_axis_data_tlast = m_axis_data_tlast_reg;
    assign m_axis_data_tdata = m_axis_data_tdata_reg;
    assign data_ready = data_ready_reg;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;
    assign data_out = cmd_write ? data_buffer[data_count - 1] : 1'b0;

endmodule

module i2c_master_bit_bang (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] prescale,
    input  wire        stop_on_idle,
    input  wire        scl_i,
    output wire        scl_o,
    output wire        scl_t,
    input  wire        sda_i,
    output wire        sda_o,
    output wire        sda_t,
    input  wire        data_out,
    output wire [7:0]  data_in,
    input  wire        data_valid,
    output wire        data_ready,
    input  wire        data_last
);

    reg scl_o_reg;
    reg sda_o_reg;
    reg scl_t_reg;
    reg sda_t_reg;
    reg [3:0] bit_count;
    reg [7:0] shift_reg;
    reg [15:0] prescale_counter;
    reg [15:0] prescale_value;
    reg start_condition;
    reg stop_condition;
    reg shift_out;
    reg shift_in;
    reg busy;
    reg missed_ack;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_o_reg <= 1;
            sda_o_reg <= 1;
            scl_t_reg <= 1;
            sda_t_reg <= 1;
            bit_count <= 0;
            shift_reg <= 0;
            prescale_counter <= 0;
            prescale_value <= prescale;
            start_condition <= 0;
            stop_condition <= 0;
            shift_out <= 0;
            shift_in <= 0;
            busy <= 0;
            missed_ack <= 0;
        end else begin
            prescale_counter <= prescale_counter + 1;
            if (prescale_counter >= prescale_value) begin
                prescale_counter <= 0;

                if (data_valid && ~busy) begin
                    busy <= 1;
                    start_condition <= 1;
                    shift_reg <= {data_out, 1'b1}; // Append stop bit
                    bit_count <= 8;
                end else if (busy) begin
                    if (start_condition) begin
                        scl_o_reg <= 0;
                        sda_o_reg <= 0;
                        scl_t_reg <= 0;
                        sda_t_reg <= 0;
                        start_condition <= 0;
                        shift_out <= 1;
                    end else if (shift_out) begin
                        if (bit_count > 0) begin
                            bit_count <= bit_count - 1;
                            sda_o_reg <= shift_reg[7];
                            shift_reg <= {shift_reg[6:0], 1'b0};
                        end else begin
                            shift_out <= 0;
                            shift_in <= 1;
                        end
                    end else if (shift_in) begin
                        if (bit_count < 8) begin
                            bit_count <= bit_count + 1;
                            shift_reg <= {shift_reg[6:0], sda_i};
                        end else begin
                            shift_in <= 0;
                            if (sda_i) begin
                                missed_ack <= 1;
                            end
                            if (data_last) begin
                                stop_condition <= 1;
                            end else begin
                                busy <= 0;
                            end
                        end
                    end else if (stop_condition) begin
                        scl_o_reg <= 0;
                        sda_o_reg <= 0;
                        scl_t_reg <= 0;
                        sda_t_reg <= 0;
                        sda_o_reg <= 1;
                        stop_condition <= 0;
                        busy <= 0;
                    end
                end
            end
        end
    end

    assign scl_o = scl_o_reg;
    assign sda_o = sda_o_reg;
    assign scl_t = scl_t_reg;
    assign sda_t = sda_t_reg;
    assign data_in = shift_reg;
    assign data_ready = ~busy;
    assign data_last = data_last;

endmodule
