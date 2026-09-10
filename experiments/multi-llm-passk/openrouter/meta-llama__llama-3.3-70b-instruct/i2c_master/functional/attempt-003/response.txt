```verilog
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

    reg [6:0]  address;
    reg [7:0]  data;
    reg [2:0]  state;
    reg [15:0] scl_count;
    reg [15:0] scl_prescale;
    reg        scl_high;
    reg        scl_low;
    reg        sda_high;
    reg        sda_low;
    reg        ack;
    reg        start;
    reg        stop;
    reg        read;
    reg        write;
    reg        write_multiple;
    reg        cmd_valid;
    reg        data_valid;
    reg        data_last;
    reg        busy_reg;
    reg        bus_control_reg;
    reg        bus_active_reg;
    reg        missed_ack_reg;

    assign scl_o = scl_high ? 1'b1 : 1'b0;
    assign scl_t = scl_low ? 1'b0 : 1'bz;
    assign sda_o = sda_high ? 1'b1 : 1'b0;
    assign sda_t = sda_low ? 1'b0 : 1'bz;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;

    always @(posedge clk) begin
        if (rst) begin
            state <= 0;
            scl_count <= 0;
            scl_prescale <= prescale;
            scl_high <= 1'b1;
            scl_low <= 1'b0;
            sda_high <= 1'b1;
            sda_low <= 1'b0;
            ack <= 1'b1;
            start <= 1'b0;
            stop <= 1'b0;
            read <= 1'b0;
            write <= 1'b0;
            write_multiple <= 1'b0;
            cmd_valid <= 1'b0;
            data_valid <= 1'b0;
            data_last <= 1'b0;
            busy_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            missed_ack_reg <= 1'b0;
            s_axis_cmd_ready <= 1'b0;
            s_axis_data_tready <= 1'b0;
            m_axis_data_tvalid <= 1'b0;
            m_axis_data_tlast <= 1'b0;
        end else begin
            case (state)
                0: begin
                    if (s_axis_cmd_valid) begin
                        address <= s_axis_cmd_address;
                        start <= s_axis_cmd_start;
                        read <= s_axis_cmd_read;
                        write <= s_axis_cmd_write;
                        write_multiple <= s_axis_cmd_write_multiple;
                        stop <= s_axis_cmd_stop;
                        cmd_valid <= 1'b1;
                        state <= 1;
                        s_axis_cmd_ready <= 1'b1;
                    end else begin
                        s_axis_cmd_ready <= 1'b0;
                    end
                end
                1: begin
                    if (start) begin
                        scl_high <= 1'b0;
                        scl_low <= 1'b1;
                        sda_high <= 1'b0;
                        sda_low <= 1'b1;
                        state <= 2;
                    end else if (read) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 3;
                    end else if (write) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 4;
                    end else if (stop) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 5;
                    end
                end
                2: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        state <= 3;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                3: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b0;
                        scl_low <= 1'b1;
                        state <= 4;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                4: begin
                    if (s_axis_data_tvalid) begin
                        data <= s_axis_data_tdata;
                        data_valid <= 1'b1;
                        data_last <= s_axis_data_tlast;
                        s_axis_data_tready <= 1'b1;
                        state <= 5;
                    end else begin
                        s_axis_data_tready <= 1'b0;
                    end
                end
                5: begin
                    if (ack) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 6;
                    end else begin
                        missed_ack_reg <= 1'b1;
                        state <= 0;
                    end
                end
                6: begin
                    if (stop) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 7;
                    end else if (read) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 8;
                    end else if (write) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 9;
                    end
                end
                7: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        state <= 0;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                8: begin
                    if (m_axis_data_tready) begin
                        m_axis_data_tdata <= data;
                        m_axis_data_tvalid <= 1'b1;
                        m_axis_data_tlast <= data_last;
                        state <= 0;
                    end else begin
                        m_axis_data_tvalid <= 1'b0;
                        m_axis_data_tlast <= 1'b0;
                    end
                end
                9: begin
                    if (s_axis_data_tvalid) begin
                        data <= s_axis_data_tdata;
                        data_valid <= 1'b1;
                        data_last <= s_axis_data_tlast;
                        s_axis_data_tready <= 1'b1;
                        state <= 10;
                    end else begin
                        s_axis_data_tready <= 1'b0;
                    end
                end
                10: begin
                    if (ack) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 11;
                    end else begin
                        missed_ack_reg <= 1'b1;
                        state <= 0;
                    end
                end
                11: begin
                    if (stop) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 12;
                    end else if (read) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 13;
                    end else if (write) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 14;
                    end
                end
                12: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        state <= 0;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                13: begin
                    if (m_axis_data_tready) begin
                        m_axis_data_tdata <= data;
                        m_axis_data_tvalid <= 1'b1;
                        m_axis_data_tlast <= data_last;
                        state <= 0;
                    end else begin
                        m_axis_data_tvalid <= 1'b0;
                        m_axis_data_tlast <= 1'b0;
                    end
                end
                14: begin
                    if (s_axis_data_tvalid) begin
                        data <= s_axis_data_tdata;
                        data_valid <= 1'b1;
                        data_last <= s_axis_data_tlast;
                        s_axis_data_tready <= 1'b1;
                        state <= 15;
                    end else begin
                        s_axis_data_tready <= 1'b0;
                    end
                end
                15: begin
                    if (ack) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 16;
                    end else begin
                        missed_ack_reg <= 1'b1;
                        state <= 0;
                    end
                end
                16: begin
                    if (stop) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 17;
                    end else if (read) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 18;
                    end else if (write) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 19;
                    end
                end
                17: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        state <= 0;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                18: begin
                    if (m_axis_data_tready) begin
                        m_axis_data_tdata <= data;
                        m_axis_data_tvalid <= 1'b1;
                        m_axis_data_tlast <= data_last;
                        state <= 0;
                    end else begin
                        m_axis_data_tvalid <= 1'b0;
                        m_axis_data_tlast <= 1'b0;
                    end
                end
                19: begin
                    if (s_axis_data_tvalid) begin
                        data <= s_axis_data_tdata;
                        data_valid <= 1'b1;
                        data_last <= s_axis_data_tlast;
                        s_axis_data_tready <= 1'b1;
                        state <= 20;
                    end else begin
                        s_axis_data_tready <= 1'b0;
                    end
                end
                20: begin
                    if (ack) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 21;
                    end else begin
                        missed_ack_reg <= 1'b1;
                        state <= 0;
                    end
                end
                21: begin
                    if (stop) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 22;
                    end else if (read) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 23;
                    end else if (write) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 24;
                    end
                end
                22: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        state <= 0;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                23: begin
                    if (m_axis_data_tready) begin
                        m_axis_data_tdata <= data;
                        m_axis_data_tvalid <= 1'b1;
                        m_axis_data_tlast <= data_last;
                        state <= 0;
                    end else begin
                        m_axis_data_tvalid <= 1'b0;
                        m_axis_data_tlast <= 1'b0;
                    end
                end
                24: begin
                    if (s_axis_data_tvalid) begin
                        data <= s_axis_data_tdata;
                        data_valid <= 1'b1;
                        data_last <= s_axis_data_tlast;
                        s_axis_data_tready <= 1'b1;
                        state <= 25;
                    end else begin
                        s_axis_data_tready <= 1'b0;
                    end
                end
                25: begin
                    if (ack) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 26;
                    end else begin
                        missed_ack_reg <= 1'b1;
                        state <= 0;
                    end
                end
                26: begin
                    if (stop) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 27;
                    end else if (read) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 28;
                    end else if (write) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 29;
                    end
                end
                27: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        state <= 0;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                28: begin
                    if (m_axis_data_tready) begin
                        m_axis_data_tdata <= data;
                        m_axis_data_tvalid <= 1'b1;
                        m_axis_data_tlast <= data_last;
                        state <= 0;
                    end else begin
                        m_axis_data_tvalid <= 1'b0;
                        m_axis_data_tlast <= 1'b0;
                    end
                end
                29: begin
                    if (s_axis_data_tvalid) begin
                        data <= s_axis_data_tdata;
                        data_valid <= 1'b1;
                        data_last <= s_axis_data_tlast;
                        s_axis_data_tready <= 1'b1;
                        state <= 30;
                    end else begin
                        s_axis_data_tready <= 1'b0;
                    end
                end
                30: begin
                    if (ack) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 31;
                    end else begin
                        missed_ack_reg <= 1'b1;
                        state <= 0;
                    end
                end
                31: begin
                    if (stop) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 32;
                    end else if (read) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 33;
                    end else if (write) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 34;
                    end
                end
                32: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        state <= 0;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                33: begin
                    if (m_axis_data_tready) begin
                        m_axis_data_tdata <= data;
                        m_axis_data_tvalid <= 1'b1;
                        m_axis_data_tlast <= data_last;
                        state <= 0;
                    end else begin
                        m_axis_data_tvalid <= 1'b0;
                        m_axis_data_tlast <= 1'b0;
                    end
                end
                34: begin
                    if (s_axis_data_tvalid) begin
                        data <= s_axis_data_tdata;
                        data_valid <= 1'b1;
                        data_last <= s_axis_data_tlast;
                        s_axis_data_tready <= 1'b1;
                        state <= 35;
                    end else begin
                        s_axis_data_tready <= 1'b0;
                    end
                end
                35: begin
                    if (ack) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 36;
                    end else begin
                        missed_ack_reg <= 1'b1;
                        state <= 0;
                    end
                end
                36: begin
                    if (stop) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 37;
                    end else if (read) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 38;
                    end else if (write) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 39;
                    end
                end
                37: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        state <= 0;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                38: begin
                    if (m_axis_data_tready) begin
                        m_axis_data_tdata <= data;
                        m_axis_data_tvalid <= 1'b1;
                        m_axis_data_tlast <= data_last;
                        state <= 0;
                    end else begin
                        m_axis_data_tvalid <= 1'b0;
                        m_axis_data_tlast <= 1'b0;
                    end
                end
                39: begin
                    if (s_axis_data_tvalid) begin
                        data <= s_axis_data_tdata;
                        data_valid <= 1'b1;
                        data_last <= s_axis_data_tlast;
                        s_axis_data_tready <= 1'b1;
                        state <= 40;
                    end else begin
                        s_axis_data_tready <= 1'b0;
                    end
                end
                40: begin
                    if (ack) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 41;
                    end else begin
                        missed_ack_reg <= 1'b1;
                        state <= 0;
                    end
                end
                41: begin
                    if (stop) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 42;
                    end else if (read) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 43;
                    end else if (write) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 44;
                    end
                end
                42: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        state <= 0;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                43: begin
                    if (m_axis_data_tready) begin
                        m_axis_data_tdata <= data;
                        m_axis_data_tvalid <= 1'b1;
                        m_axis_data_tlast <= data_last;
                        state <= 0;
                    end else begin
                        m_axis_data_tvalid <= 1'b0;
                        m_axis_data_tlast <= 1'b0;
                    end
                end
                44: begin
                    if (s_axis_data_tvalid) begin
                        data <= s_axis_data_tdata;
                        data_valid <= 1'b1;
                        data_last <= s_axis_data_tlast;
                        s_axis_data_tready <= 1'b1;
                        state <= 45;
                    end else begin
                        s_axis_data_tready <= 1'b0;
                    end
                end
                45: begin
                    if (ack) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 46;
                    end else begin
                        missed_ack_reg <= 1'b1;
                        state <= 0;
                    end
                end
                46: begin
                    if (stop) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 47;
                    end else if (read) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 48;
                    end else if (write) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 49;
                    end
                end
                47: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        state <= 0;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                48: begin
                    if (m_axis_data_tready) begin
                        m_axis_data_tdata <= data;
                        m_axis_data_tvalid <= 1'b1;
                        m_axis_data_tlast <= data_last;
                        state <= 0;
                    end else begin
                        m_axis_data_tvalid <= 1'b0;
                        m_axis_data_tlast <= 1'b0;
                    end
                end
                49: begin
                    if (s_axis_data_tvalid) begin
                        data <= s_axis_data_tdata;
                        data_valid <= 1'b1;
                        data_last <= s_axis_data_tlast;
                        s_axis_data_tready <= 1'b1;
                        state <= 50;
                    end else begin
                        s_axis_data_tready <= 1'b0;
                    end
                end
                50: begin
                    if (ack) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 51;
                    end else begin
                        missed_ack_reg <= 1'b1;
                        state <= 0;
                    end
                end
                51: begin
                    if (stop) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 52;
                    end else if (read) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 53;
                    end else if (write) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 54;
                    end
                end
                52: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        state <= 0;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                53: begin
                    if (m_axis_data_tready) begin
                        m_axis_data_tdata <= data;
                        m_axis_data_tvalid <= 1'b1;
                        m_axis_data_tlast <= data_last;
                        state <= 0;
                    end else begin
                        m_axis_data_tvalid <= 1'b0;
                        m_axis_data_tlast <= 1'b0;
                    end
                end
                54: begin
                    if (s_axis_data_tvalid) begin
                        data <= s_axis_data_tdata;
                        data_valid <= 1'b1;
                        data_last <= s_axis_data_tlast;
                        s_axis_data_tready <= 1'b1;
                        state <= 55;
                    end else begin
                        s_axis_data_tready <= 1'b0;
                    end
                end
                55: begin
                    if (ack) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 56;
                    end else begin
                        missed_ack_reg <= 1'b1;
                        state <= 0;
                    end
                end
                56: begin
                    if (stop) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 57;
                    end else if (read) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 58;
                    end else if (write) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 59;
                    end
                end
                57: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        state <= 0;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                58: begin
                    if (m_axis_data_tready) begin
                        m_axis_data_tdata <= data;
                        m_axis_data_tvalid <= 1'b1;
                        m_axis_data_tlast <= data_last;
                        state <= 0;
                    end else begin
                        m_axis_data_tvalid <= 1'b0;
                        m_axis_data_tlast <= 1'b0;
                    end
                end
                59: begin
                    if (s_axis_data_tvalid) begin
                        data <= s_axis_data_tdata;
                        data_valid <= 1'b1;
                        data_last <= s_axis_data_tlast;
                        s_axis_data_tready <= 1'b1;
                        state <= 60;
                    end else begin
                        s_axis_data_tready <= 1'b0;
                    end
                end
                60: begin
                    if (ack) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 61;
                    end else begin
                        missed_ack_reg <= 1'b1;
                        state <= 0;
                    end
                end
                61: begin
                    if (stop) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 62;
                    end else if (read) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 63;
                    end else if (write) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 64;
                    end
                end
                62: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        state <= 0;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                63: begin
                    if (m_axis_data_tready) begin
                        m_axis_data_tdata <= data;
                        m_axis_data_tvalid <= 1'b1;
                        m_axis_data_tlast <= data_last;
                        state <= 0;
                    end else begin
                        m_axis_data_tvalid <= 1'b0;
                        m_axis_data_tlast <= 1'b0;
                    end
                end
                64: begin
                    if (s_axis_data_tvalid) begin
                        data <= s_axis_data_tdata;
                        data_valid <= 1'b1;
                        data_last <= s_axis_data_tlast;
                        s_axis_data_tready <= 1'b1;
                        state <= 65;
                    end else begin
                        s_axis_data_tready <= 1'b0;
                    end
                end
                65: begin
                    if (ack) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 66;
                    end else begin
                        missed_ack_reg <= 1'b1;
                        state <= 0;
                    end
                end
                66: begin
                    if (stop) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 67;
                    end else if (read) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 68;
                    end else if (write) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 69;
                    end
                end
                67: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        state <= 0;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                68: begin
                    if (m_axis_data_tready) begin
                        m_axis_data_tdata <= data;
                        m_axis_data_tvalid <= 1'b1;
                        m_axis_data_tlast <= data_last;
                        state <= 0;
                    end else begin
                        m_axis_data_tvalid <= 1'b0;
                        m_axis_data_tlast <= 1'b0;
                    end
                end
                69: begin
                    if (s_axis_data_tvalid) begin
                        data <= s_axis_data_tdata;
                        data_valid <= 1'b1;
                        data_last <= s_axis_data_tlast;
                        s_axis_data_tready <= 1'b1;
                        state <= 70;
                    end else begin
                        s_axis_data_tready <= 1'b0;
                    end
                end
                70: begin
                    if (ack) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 71;
                    end else begin
                        missed_ack_reg <= 1'b1;
                        state <= 0;
                    end
                end
                71: begin
                    if (stop) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 72;
                    end else if (read) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 73;
                    end else if (write) begin
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        sda_high <= 1'b1;
                        sda_low <= 1'b0;
                        state <= 74;
                    end
                end
                72: begin
                    if (scl_count == scl_prescale) begin
                        scl_count <= 0;
                        scl_high <= 1'b1;
                        scl_low <= 1'b0;
                        state <= 0;
                    end else begin
                        scl_count <= scl_count + 1;
                    end
                end
                73: begin
                    if
