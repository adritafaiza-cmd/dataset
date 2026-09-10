module i2c_master (
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
    input  wire        scl_i,
    output wire        scl_o,
    output wire        scl_t,
    input  wire        sda_i,
    output wire        sda_o,
    output wire        sda_t,
    output wire        busy,
    output wire        bus_control,
    output wire        bus_active,
    output wire        missed_ack,
    input  wire [15:0] prescale,
    input  wire        stop_on_idle
);

    reg [2:0] state;
    reg [2:0] next_state;
    reg [15:0] prescale_counter;
    reg [7:0] address;
    reg [7:0] data;
    reg start;
    reg read;
    reg write;
    reg write_multiple;
    reg stop;
    reg valid;
    reg cmd_ready;
    reg data_ready;
    reg scl_out;
    reg scl_tristate;
    reg sda_out;
    reg sda_tristate;
    reg busy_reg;
    reg bus_control_reg;
    reg bus_active_reg;
    reg missed_ack_reg;
    reg [7:0] m_axis_data;
    reg m_axis_data_valid;
    reg m_axis_data_last;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            prescale_counter <= 0;
            address <= 0;
            data <= 0;
            start <= 0;
            read <= 0;
            write <= 0;
            write_multiple <= 0;
            stop <= 0;
            valid <= 0;
            cmd_ready <= 0;
            data_ready <= 0;
            scl_out <= 1;
            scl_tristate <= 1;
            sda_out <= 1;
            sda_tristate <= 1;
            busy_reg <= 0;
            bus_control_reg <= 0;
            bus_active_reg <= 0;
            missed_ack_reg <= 0;
            m_axis_data <= 0;
            m_axis_data_valid <= 0;
            m_axis_data_last <= 0;
        end else begin
            state <= next_state;
            prescale_counter <= prescale_counter + 1;
            address <= address;
            data <= data;
            start <= start;
            read <= read;
            write <= write;
            write_multiple <= write_multiple;
            stop <= stop;
            valid <= valid;
            cmd_ready <= cmd_ready;
            data_ready <= data_ready;
            scl_out <= scl_out;
            scl_tristate <= scl_tristate;
            sda_out <= sda_out;
            sda_tristate <= sda_tristate;
            busy_reg <= busy_reg;
            bus_control_reg <= bus_control_reg;
            bus_active_reg <= bus_active_reg;
            missed_ack_reg <= missed_ack_reg;
            m_axis_data <= m_axis_data;
            m_axis_data_valid <= m_axis_data_valid;
            m_axis_data_last <= m_axis_data_last;

            case (state)
                0: begin // IDLE
                    if (s_axis_cmd_valid) begin
                        address <= s_axis_cmd_address;
                        start <= s_axis_cmd_start;
                        read <= s_axis_cmd_read;
                        write <= s_axis_cmd_write;
                        write_multiple <= s_axis_cmd_write_multiple;
                        stop <= s_axis_cmd_stop;
                        valid <= 1;
                        next_state <= 1;
                    end else begin
                        next_state <= 0;
                    end
                end
                1: begin // START
                    if (prescale_counter >= prescale) begin
                        prescale_counter <= 0;
                        scl_out <= 0;
                        scl_tristate <= 0;
                        sda_out <= 0;
                        sda_tristate <= 0;
                        next_state <= 2;
                    end else begin
                        next_state <= 1;
                    end
                end
                2: begin // ADDRESS
                    if (prescale_counter >= prescale) begin
                        prescale_counter <= 0;
                        scl_out <= 1;
                        scl_tristate <= 0;
                        sda_out <= address[7];
                        sda_tristate <= 0;
                        address <= address << 1;
                        next_state <= 3;
                    end else begin
                        next_state <= 2;
                    end
                end
                3: begin // ACK
                    if (prescale_counter >= prescale) begin
                        prescale_counter <= 0;
                        scl_out <= 0;
                        scl_tristate <= 0;
                        sda_out <= 1;
                        sda_tristate <= 1;
                        if (sda_i) begin
                            missed_ack_reg <= 1;
                        end
                        next_state <= 4;
                    end else begin
                        next_state <= 3;
                    end
                end
                4: begin // WRITE
                    if (write) begin
                        if (prescale_counter >= prescale) begin
                            prescale_counter <= 0;
                            scl_out <= 1;
                            scl_tristate <= 0;
                            sda_out <= data[7];
                            sda_tristate <= 0;
                            data <= data << 1;
                            next_state <= 5;
                        end else begin
                            next_state <= 4;
                        end
                    end else if (read) begin
                        if (prescale_counter >= prescale) begin
                            prescale_counter <= 0;
                            scl_out <= 1;
                            scl_tristate <= 0;
                            sda_out <= 1;
                            sda_tristate <= 1;
                            next_state <= 6;
                        end else begin
                            next_state <= 4;
                        end
                    end else begin
                        next_state <= 0;
                    end
                end
                5: begin // WRITE ACK
                    if (prescale_counter >= prescale) begin
                        prescale_counter <= 0;
                        scl_out <= 0;
                        scl_tristate <= 0;
                        sda_out <= 1;
                        sda_tristate <= 1;
                        if (sda_i) begin
                            missed_ack_reg <= 1;
                        end
                        next_state <= 4;
                    end else begin
                        next_state <= 5;
                    end
                end
                6: begin // READ
                    if (prescale_counter >= prescale) begin
                        prescale_counter <= 0;
                        scl_out <= 1;
                        scl_tristate <= 0;
                        sda_out <= 1;
                        sda_tristate <= 1;
                        m_axis_data <= sda_i;
                        m_axis_data_valid <= 1;
                        m_axis_data_last <= 1;
                        next_state <= 7;
                    end else begin
                        next_state <= 6;
                    end
                end
                7: begin // STOP
                    if (prescale_counter >= prescale) begin
                        prescale_counter <= 0;
                        scl_out <= 1;
                        scl_tristate <= 1;
                        sda_out <= 1;
                        sda_tristate <= 1;
                        next_state <= 0;
                    end else begin
                        next_state <= 7;
                    end
                end
                default: begin
                    next_state <= 0;
                end
            endcase
        end
    end

    assign s_axis_cmd_ready = cmd_ready;
    assign s_axis_data_tready = data_ready;
    assign scl_o = scl_out;
    assign scl_t = scl_tristate;
    assign sda_o = sda_out;
    assign sda_t = sda_tristate;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;
    assign m_axis_data_tdata = m_axis_data;
    assign m_axis_data_tvalid = m_axis_data_valid;
    assign m_axis_data_tlast = m_axis_data_last;

endmodule
