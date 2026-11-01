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
    localparam S_IDLE            = 4'd0;
    localparam S_START           = 4'd1;
    localparam S_ADDR            = 4'd2;
    localparam S_ADDR_ACK        = 4'd3;
    localparam S_WRITE_DATA      = 4'd4;
    localparam S_WRITE_ACK       = 4'd5;
    localparam S_READ_DATA       = 4'd6;
    localparam S_READ_ACK        = 4'd7;
    localparam S_STOP            = 4'd8;
    localparam S_WAIT            = 4'd9;

    reg [3:0]  state;
    reg [3:0]  bit_cnt;
    reg [7:0]  tx_byte;
    reg [7:0]  rx_byte;
    reg        tx_bit;
    reg        rx_bit;
    reg        ack_bit;
    reg        is_read;
    reg        is_write;
    reg        is_write_multiple;
    reg        need_stop;
    reg        missed_ack_reg;
    reg        scl_drive;
    reg        sda_drive;
    reg        scl_enable;
    reg        sda_enable;
    reg [15:0] prescale_cnt;
    reg        prescale_done;
    reg        scl_high;
    reg        sda_high;
    reg        scl_prev;
    reg        sda_prev;
    reg        start_pending;
    reg        stop_pending;
    reg        addr_valid;
    reg [6:0]  addr_reg;
    reg        read_cmd;
    reg        write_cmd;
    reg        write_multiple_cmd;
    reg        stop_cmd;
    reg        cmd_valid_reg;
    reg        data_valid_reg;
    reg [7:0]  data_reg;
    reg        data_last_reg;
    reg        m_axis_valid;
    reg [7:0]  m_axis_data;
    reg        m_axis_last;
    reg        s_axis_data_ready;
    reg        s_axis_cmd_ready;
    reg        busy_reg;
    reg        bus_control_reg;
    reg        bus_active_reg;

    // Open-drain outputs
    assign scl_o = ~scl_drive;
    assign scl_t = scl_enable;
    assign sda_o = ~sda_drive;
    assign sda_t = sda_enable;

    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;
    assign s_axis_cmd_ready = s_axis_cmd_ready;
    assign s_axis_data_tready = s_axis_data_ready;
    assign m_axis_data_tdata = m_axis_data;
    assign m_axis_data_tvalid = m_axis_valid;
    assign m_axis_data_tlast = m_axis_last;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            bit_cnt <= 4'd0;
            tx_byte <= 8'd0;
            rx_byte <= 8'd0;
            tx_bit <= 1'b0;
            rx_bit <= 1'b0;
            ack_bit <= 1'b0;
            is_read <= 1'b0;
            is_write <= 1'b0;
            is_write_multiple <= 1'b0;
            need_stop <= 1'b0;
            missed_ack_reg <= 1'b0;
            scl_drive <= 1'b1;
            sda_drive <= 1'b1;
            scl_enable <= 1'b0;
            sda_enable <= 1'b0;
            prescale_cnt <= 16'd0;
            prescale_done <= 1'b0;
            scl_high <= 1'b1;
            sda_high <= 1'b1;
            scl_prev <= 1'b1;
            sda_prev <= 1'b1;
            start_pending <= 1'b0;
            stop_pending <= 1'b0;
            addr_valid <= 1'b0;
            addr_reg <= 7'd0;
            read_cmd <= 1'b0;
            write_cmd <= 1'b0;
            write_multiple_cmd <= 1'b0;
            stop_cmd <= 1'b0;
            cmd_valid_reg <= 1'b0;
            data_valid_reg <= 1'b0;
            data_reg <= 8'd0;
            data_last_reg <= 1'b0;
            m_axis_valid <= 1'b0;
            m_axis_data <= 8'd0;
            m_axis_last <= 1'b0;
            s_axis_data_ready <= 1'b0;
            s_axis_cmd_ready <= 1'b1;
            busy_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
        end else begin
            // Default assignments
            prescale_done <= 1'b0;
            s_axis_cmd_ready <= 1'b0;
            s_axis_data_ready <= 1'b0;
            m_axis_valid <= 1'b0;
            m_axis_last <= 1'b0;

            // Prescale counter
            if (state != S_IDLE) begin
                if (prescale_cnt < prescale) begin
                    prescale_cnt <= prescale_cnt + 16'd1;
                end else begin
                    prescale_cnt <= 16'd0;
                    prescale_done <= 1'b1;
                end
            end else begin
                prescale_cnt <= 16'd0;
            end

            // Command acceptance
            if (state == S_IDLE && s_axis_cmd_valid) begin
                s_axis_cmd_ready <= 1'b1;
                addr_reg <= s_axis_cmd_address;
                read_cmd <= s_axis_cmd_read;
                write_cmd <= s_axis_cmd_write;
                write_multiple_cmd <= s_axis_cmd_write_multiple;
                stop_cmd <= s_axis_cmd_stop;
                cmd_valid_reg <= 1'b1;
                is_read <= s_axis_cmd_read;
                is_write <= s_axis_cmd_write;
                is_write_multiple <= s_axis_cmd_write_multiple;
                need_stop <= s_axis_cmd_stop;
                missed_ack_reg <= 1'b0;
                busy_reg <= 1'b1;
                bus_control_reg <= 1'b1;
                bus_active_reg <= 1'b1;
                scl_enable <= 1'b1;
                sda_enable <= 1'b1;
                scl_drive <= 1'b1;
                sda_drive <= 1'b1;
                scl_high <= 1'b1;
                sda_high <= 1'b1;
                scl_prev <= 1'b1;
                sda_prev <= 1'b1;
                start_pending <= 1'b1;
                stop_pending <= 1'b0;
                state <= S_START;
                bit_cnt <= 4'd0;
                prescale_cnt <= 16'd0;
            end

            // Data acceptance for write
            if ((state == S_WRITE_DATA || state == S_WRITE_ACK) && s_axis_data_tvalid) begin
                s_axis_data_ready <= 1'b1;
                data_reg <= s_axis_data_tdata;
                data_last_reg <= s_axis_data_tlast;
                data_valid_reg <= 1'b1;
            end

            // M-axis output
            if (state == S_READ_ACK && prescale_done) begin
                m_axis_valid <= 1'b1;
                m_axis_data <= rx_byte;
                m_axis_last <= data_last_reg;
            end

            if (m_axis_valid && m_axis_data_tready) begin
                m_axis_valid <= 1'b0;
            end

            // State machine
            case (state)
                S_IDLE: begin
                    s_axis_cmd_ready <= 1'b1;
                    busy_reg <= 1'b0;
                    bus_control_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    scl_enable <= 1'b0;
                    sda_enable <= 1'b0;
                    scl_drive <= 1'b1;
                    sda_drive <= 1'b1;
                    scl_high <= 1'b1;
                    sda_high <= 1'b1;
                    scl_prev <= 1'b1;
                    sda_prev <= 1'b1;
                    start_pending <= 1'b0;
                    stop_pending <= 1'b0;
                    if (stop_on_idle) begin
                        // Release bus
                    end
                end

                S_START: begin
                    if (prescale_done) begin
                        // SCL high, SDA high
                        scl_drive <= 1'b1;
                        sda_drive <= 1'b1;
                        scl_high <= 1'b1;
                        sda_high <= 1'b1;
                        scl_prev <= 1'b1;
                        sda_prev <= 1'b1;
                        prescale_cnt <= 16'd0;
                        state <= S_WAIT;
                    end
                end

                S_WAIT: begin
                    if (prescale_done) begin
                        // SDA low while SCL high (START condition)
                        sda_drive <= 1'b0;
                        sda_high <= 1'b0;
                        sda_prev <= 1'b0;
                        prescale_cnt <= 16'd0;
                        state <= S_START;
                        // We'll use a sub-state approach: let's restructure
                        // Actually, let's use a different approach with explicit timing
                    end
                end

                default: begin
                    // Fallback
                end
            endcase

            // Let's restructure with a cleaner state machine
            // Reset and re-implement properly
        end
    end

    // The above is getting complex. Let me rewrite with a cleaner approach.
endmodule
