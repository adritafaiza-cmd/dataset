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
    localparam S_ADDR_BIT        = 4'd2;
    localparam S_ADDR_ACK        = 4'd3;
    localparam S_DATA_BIT        = 4'd4;
    localparam S_DATA_ACK        = 4'd5;
    localparam S_READ_BIT        = 4'd6;
    localparam S_READ_ACK        = 4'd7;
    localparam S_STOP            = 4'd8;
    localparam S_WAIT_DATA       = 4'd9;
    localparam S_WAIT_CMD        = 4'd10;

    reg [3:0]  state;
    reg [3:0]  bit_cnt;
    reg [7:0]  tx_data;
    reg [7:0]  rx_data;
    reg        tx_bit;
    reg        rx_bit;
    reg        ack_bit;
    reg        is_read;
    reg        is_write;
    reg        is_write_multiple;
    reg        need_stop;
    reg        missed_ack_reg;
    reg        scl_reg;
    reg        sda_reg;
    reg [15:0] prescale_cnt;
    reg        prescale_done;
    reg        scl_high;
    reg        sda_high;
    reg        scl_prev;
    reg        sda_prev;
    reg        start_cond;
    reg        stop_cond;
    reg        bit_start;
    reg        bit_end;
    reg        ack_phase;
    reg        data_phase;
    reg        addr_phase;
    reg        read_phase;
    reg        write_phase;
    reg        write_multiple_phase;
    reg        stop_phase;
    reg        idle_phase;
    reg        bus_active_reg;
    reg        bus_control_reg;
    reg        busy_reg;
    reg        m_axis_data_tvalid_reg;
    reg [7:0]  m_axis_data_tdata_reg;
    reg        m_axis_data_tlast_reg;
    reg        s_axis_data_tready_reg;
    reg        s_axis_cmd_ready_reg;

    // Open-drain outputs
    assign scl_o = ~scl_reg;
    assign scl_t = scl_reg;
    assign sda_o = ~sda_reg;
    assign sda_t = sda_reg;

    // Status outputs
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;

    // AXI outputs
    assign s_axis_cmd_ready = s_axis_cmd_ready_reg;
    assign s_axis_data_tready = s_axis_data_tready_reg;
    assign m_axis_data_tdata = m_axis_data_tdata_reg;
    assign m_axis_data_tvalid = m_axis_data_tvalid_reg;
    assign m_axis_data_tlast = m_axis_data_tlast_reg;

    // Prescale counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prescale_cnt <= 16'd0;
            prescale_done <= 1'b0;
        end else begin
            if (prescale_cnt == prescale) begin
                prescale_cnt <= 16'd0;
                prescale_done <= 1'b1;
            end else begin
                prescale_cnt <= prescale_cnt + 16'd1;
                prescale_done <= 1'b0;
            end
        end
    end

    // Main state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            bit_cnt <= 4'd0;
            tx_data <= 8'd0;
            rx_data <= 8'd0;
            tx_bit <= 1'b0;
            rx_bit <= 1'b0;
            ack_bit <= 1'b0;
            is_read <= 1'b0;
            is_write <= 1'b0;
            is_write_multiple <= 1'b0;
            need_stop <= 1'b0;
            missed_ack_reg <= 1'b0;
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            scl_high <= 1'b1;
            sda_high <= 1'b1;
            scl_prev <= 1'b1;
            sda_prev <= 1'b1;
            start_cond <= 1'b0;
            stop_cond <= 1'b0;
            bit_start <= 1'b0;
            bit_end <= 1'b0;
            ack_phase <= 1'b0;
            data_phase <= 1'b0;
            addr_phase <= 1'b0;
            read_phase <= 1'b0;
            write_phase <= 1'b0;
            write_multiple_phase <= 1'b0;
            stop_phase <= 1'b0;
            idle_phase <= 1'b1;
            bus_active_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            busy_reg <= 1'b0;
            m_axis_data_tvalid_reg <= 1'b0;
            m_axis_data_tdata_reg <= 8'd0;
            m_axis_data_tlast_reg <= 1'b0;
            s_axis_data_tready_reg <= 1'b0;
            s_axis_cmd_ready_reg <= 1'b1;
        end else begin
            // Default assignments
            s_axis_cmd_ready_reg <= 1'b0;
            s_axis_data_tready_reg <= 1'b0;
            m_axis_data_tvalid_reg <= 1'b0;
            m_axis_data_tlast_reg <= 1'b0;
            missed_ack_reg <= 1'b0;
            start_cond <= 1'b0;
            stop_cond <= 1'b0;
            bit_start <= 1'b0;
            bit_end <= 1'b0;

            case (state)
                S_IDLE: begin
                    idle_phase <= 1'b1;
                    addr_phase <= 1'b0;
                    data_phase <= 1'b0;
                    read_phase <= 1'b0;
                    write_phase <= 1'b0;
                    write_multiple_phase <= 1'b0;
                    stop_phase <= 1'b0;
                    ack_phase <= 1'b0;
                    bus_active_reg <= 1'b0;
                    bus_control_reg <= 1'b0;
                    busy_reg <= 1'b0;
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b1;
                    scl_high <= 1'b1;
                    sda_high <= 1'b1;
                    s_axis_cmd_ready_reg <= 1'b1;
                    s_axis_data_tready_reg <= 1'b0;
                    m_axis_data_tvalid_reg <= 1'b0;
                    m_axis_data_tlast_reg <= 1'b0;

                    if (s_axis_cmd_valid) begin
                        if (s_axis_cmd_start) begin
                            state <= S_START;
                            idle_phase <= 1'b0;
                            bus_active_reg <= 1'b1;
                            bus_control_reg <= 1'b1;
                            busy_reg <= 1'b1;
                            is_read <= s_axis_cmd_read;
                            is_write <= s_axis_cmd_write;
                            is_write_multiple <= s_axis_cmd_write_multiple;
                            need_stop <= s_axis_cmd_stop;
                            tx_data <= {s_axis_cmd_address, s_axis_cmd_read};
                            bit_cnt <= 4'd0;
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b1;
                        end else if (s_axis_cmd_stop) begin
                            state <= S_STOP;
                            idle_phase <= 1'b0;
                            bus_active_reg <= 1'b1;
                            bus_control_reg <= 1'b1;
                            busy_reg <= 1'b1;
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b1;
                        end
                    end
                end

                S_START: begin
                    idle_phase <= 1'b0;
                    addr_phase <= 1'b0;
                    data_phase <= 1'b0;
                    read_phase <= 1'b0;
                    write_phase <= 1'b0;
                    write_multiple_phase <= 1'b0;
                    stop_phase <= 1'b0;
                    ack_phase <= 1'b0;
                    bus_active_reg <= 1'b1;
                    bus_control_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    s_axis_cmd_ready_reg <= 1'b0;
                    s_axis_data_tready_reg <= 1'b0;
                    m_axis_data_tvalid_reg <= 1'b0;
                    m_axis_data_tlast_reg <= 1'b0;

                    // Start condition: SDA high to low while SCL high
                    if (scl_reg == 1'b1 && sda_reg == 1'b1) begin
                        sda_reg <= 1'b0;
                        sda_high <= 1'b0;
                        start_cond <= 1'b1;
                    end else if (scl_reg == 1'b1 && sda_reg == 1'b0) begin
                        // SDA already low, wait for SCL to go low then high
                        if (scl_i == 1'b0) begin
                            scl_reg <= 1'b0;
                            scl_high <= 1'b0;
                        end
                    end else if (scl_reg == 1'b0 && sda_reg == 1'b0) begin
                        // Both low, raise SCL
                        scl_reg <= 1'b1;
                        scl_high <= 1'b1;
                    end else if (scl_reg == 1'b1 && sda_reg == 1'b0) begin
                        // SCL high, SDA low - start condition complete
                        state <= S_ADDR_BIT;
                        bit_cnt <= 4'd0;
                        tx_bit <= 1'b1; // MSB first
                    end
                end

                S_ADDR_BIT: begin
                    idle_phase <= 1'b0;
                    addr_phase <= 1'b1;
                    data_phase <= 1'b0;
                    read_phase <= 1'b0;
                    write_phase <= 1'b0;
                    write_multiple_phase <= 1'b0;
                    stop_phase <= 1'b0;
                    ack_phase <= 1'b0;
                    bus_active_reg <= 1'b1;
                    bus_control_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    s_axis_cmd_ready_reg <= 1'b0;
                    s_axis_data_tready_reg <= 1'b0;
                    m_axis_data_tvalid_reg <= 1'b0;
                    m_axis_data_tlast_reg <= 1'b0;

                    // Drive SDA with current bit
                    if (bit_cnt == 4'd0) begin
                        tx_bit <= tx_data[7];
                    end else if (bit_cnt == 4'd1) begin
                        tx_bit <= tx_data[6];
                    end else if (bit_cnt == 4'd2) begin
                        tx_bit <= tx_data[5];
                    end else if (bit_cnt == 4'd3) begin
                        tx_bit <= tx_data[4];
                    end else if (bit_cnt == 4'd4) begin
                        tx_bit <= tx_data[3];
                    end else if (bit_cnt == 4'd5) begin
                        tx_bit <= tx_data[2];
                    end else if (bit_cnt == 4'd6) begin
                        tx_bit <= tx_data[1];
                    end else if (bit_cnt == 4'd7) begin
                        tx_bit <= tx_data[0];
                    end

                    // SCL low phase: set SDA
                    if (scl_reg == 1'b0) begin
                        sda_reg <= tx_bit;
                        sda_high <= tx_bit;
                        // Wait for prescale, then raise SCL
                        if (prescale_done) begin
                            scl_reg <= 1'b1;
                            scl_high <= 1'b1;
                        end
                    end else begin
                        // SCL high phase: wait for prescale, then lower SCL
                        if (prescale_done) begin
                            scl_reg <= 1'b0;
                            scl_high <= 1'b0;
                            bit_cnt <= bit_cnt + 4'd1;
                            if (bit_cnt == 4'd7) begin
                                state <= S_ADDR_ACK;
                            end
                        end
                    end
                end

                S_ADDR_ACK: begin
                    idle_phase <= 1'b0;
                    addr_phase <= 1'b0;
                    data_phase <= 1'b0;
                    read_phase <= 1'b0;
                    write_phase <= 1'b0;
                    write_multiple_phase <= 1'b0;
                    stop_phase <= 1'b0;
                    ack_phase <= 1'b1;
                    bus_active_reg <= 1'b1;
                    bus_control_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    s_axis_cmd_ready_reg <= 1'b0;
                    s_axis_data_tready_reg <= 1'b0;
                    m_axis_data_tvalid_reg <= 1'b0;
                    m_axis_data_tlast_reg <= 1'b0;

                    // Release SDA to read ACK
                    sda_reg <= 1'b1;
                    sda_high <= 1'b1;

                    // SCL low phase
                    if (scl_reg == 1'b0) begin
                        if (prescale_done) begin
                            scl_reg <= 1'b1;
                            scl_high <= 1'b1;
                        end
                    end else begin
                        // SCL high phase: sample ACK
                        if (prescale_done) begin
                            scl_reg <= 1'b0;
                            scl_high <= 1'b0;
                            ack_bit <= sda_i;
                            if (sda_i == 1'b1) begin
                                // NACK
                                missed_ack_reg <= 1'b1;
                                state <= S_STOP;
                            end else begin
                                // ACK
                                if (is_read) begin
                                    state <= S_READ_BIT;
                                    bit_cnt <= 4'd0;
                                    rx_data <= 8'd0;
                                end else begin
                                    state <= S_WAIT_DATA;
                                end
                            end
                        end
                    end
                end

                S_DATA_BIT: begin
                    idle_phase <= 1'b0;
                    addr_phase <= 1'b0;
                    data_phase <= 1'b1;
                    read_phase <= 1'b0;
                    write_phase <= 1'b0;
                    write_multiple_phase <= 1'b0;
                    stop_phase <= 1'b0;
                    ack_phase <= 1'b0;
                    bus_active_reg <= 1'b1;
                    bus_control_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    s_axis_cmd_ready_reg <= 1'b0;
                    s_axis_data_tready_reg <= 1'b0;
                    m_axis_data_tvalid_reg <= 1'b0;
                    m_axis_data_tlast_reg <= 1'b0;

                    // Drive SDA with current bit
                    if (bit_cnt == 4'd0) begin
                        tx_bit <= tx_data[7];
                    end else if (bit_cnt == 4'd1) begin
                        tx_bit <= tx_data[6];
                    end else if (bit_cnt == 4'd2) begin
                        tx_bit <= tx_data[5];
                    end else if (bit_cnt == 4'd3) begin
                        tx_bit <= tx_data[4];
                    end else if (bit_cnt == 4'd4) begin
                        tx_bit <= tx_data[3];
                    end else if (bit_cnt == 4'd5) begin
                        tx_bit <= tx_data[2];
                    end else if (bit_cnt == 4'd6) begin
                        tx_bit <= tx_data[1];
                    end else if (bit_cnt == 4'd7) begin
                        tx_bit <= tx_data[0];
                    end

                    // SCL low phase: set SDA
                    if (scl_reg == 1'b0) begin
                        sda_reg <= tx_bit;
                        sda_high <= tx_bit;
                        if (prescale_done) begin
                            scl_reg <= 1'b1;
                            scl_high <= 1'b1;
                        end
                    end else begin
                        // SCL high phase
                        if (prescale_done) begin
                            scl_reg <= 1'b0;
                            scl_high <= 1'b0;
                            bit_cnt <= bit_cnt + 4'd1;
                            if (bit_cnt == 4'd7) begin
                                state <= S_DATA_ACK;
                            end
                        end
                    end
                end

                S_DATA_ACK: begin
                    idle_phase <= 1'b0;
                    addr_phase <= 1'b0;
                    data_phase <= 1'b0;
                    read_phase <= 1'b0;
                    write_phase <= 1'b0;
                    write_multiple_phase <= 1'b0;
                    stop_phase <= 1'b0;
                    ack_phase <= 1'b1;
                    bus_active_reg <= 1'b1;
                    bus_control_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    s_axis_cmd_ready_reg <= 1'b0;
                    s_axis_data_tready_reg <= 1'b0;
                    m_axis_data_tvalid_reg <= 1'b0;
                    m_axis_data_tlast_reg <= 1'b0;

                    // Release SDA to read ACK
                    sda_reg <= 1'b1;
                    sda_high <= 1'b1;

                    // SCL low phase
                    if (scl_reg == 1'b0) begin
                        if (prescale_done) begin
                            scl_reg <= 1'b1;
                            scl_high <= 1'b1;
                        end
                    end else begin
                        // SCL high phase: sample ACK
                        if (prescale_done) begin
                            scl_reg <= 1'b0;
                            scl_high <= 1'b0;
                            ack_bit <= sda_i;
                            if (sda_i == 1'b1) begin
                                // NACK
                                missed_ack_reg <= 1'b1;
                                state <= S_STOP;
                            end else begin
                                // ACK
                                if (is_write_multiple) begin
                                    state <= S_WAIT_DATA;
                                end else begin
                                    state <= S_STOP;
                                end
                            end
                        end
                    end
                end

                S_READ_BIT: begin
                    idle_phase <= 1'b0;
                    addr_phase <= 1'b0;
                    data_phase <= 1'b0;
                    read_phase <= 1'b1;
                    write_phase <= 1'b0;
                    write_multiple_phase <= 1'b0;
                    stop_phase <= 1'b0;
                    ack_phase <= 1'b0;
                    bus_active_reg <= 1'b1;
                    bus_control_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    s_axis_cmd_ready_reg <= 1'b0;
                    s_axis_data_tready_reg <= 1'b0;
                    m_axis_data_tvalid_reg <= 1'b0;
                    m_axis_data_tlast_reg <= 1'b0;

                    // Release SDA to read data
                    sda_reg <= 1'b1;
                    sda_high <= 1'b1;

                    // SCL low phase
                    if (scl_reg == 1'b0) begin
                        if (prescale_done) begin
                            scl_reg <= 1'b1;
                            scl_high <= 1'b1;
                        end
                    end else begin
                        // SCL high phase: sample data
                        if (prescale_done) begin
                            scl_reg <= 1'b0;
                            scl_high <= 1'b0;
                            rx_bit <= sda_i;
                            if (bit_cnt == 4'd0) begin
                                rx_data[7] <= rx_bit;
                            end else if (bit_cnt == 4'd1) begin
                                rx_data[6] <= rx_bit;
                            end else if (bit_cnt == 4'd2) begin
                                rx_data[5] <= rx_bit;
                            end else if (bit_cnt == 4'd3) begin
                                rx_data[4] <= rx_bit;
                            end else if (bit_cnt == 4'd4) begin
                                rx_data[3] <= rx_bit;
                            end else if (bit_cnt == 4'd5) begin
                                rx_data[2] <= rx_bit;
                            end else if (bit_cnt == 4'd6) begin
                                rx_data[1] <= rx_bit;
                            end else if (bit_cnt == 4'd7) begin
                                rx_data[0] <= rx_bit;
                            end
                            bit_cnt <= bit_cnt + 4'd1;
                            if (bit_cnt == 4'd7) begin
                                state <= S_READ_ACK;
                            end
                        end
                    end
                end

                S_READ_ACK: begin
                    idle_phase <= 1'b0;
                    addr_phase <= 1'b0;
                    data_phase <= 1'b0;
                    read_phase <= 1'b0;
                    write_phase <= 1'b0;
                    write_multiple_phase <= 1'b0;
                    stop_phase <= 1'b0;
                    ack_phase <= 1'b1;
                    bus_active_reg <= 1'b1;
                    bus_control_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    s_axis_cmd_ready_reg <= 1'b0;
                    s_axis_data_tready_reg <= 1'b0;
                    m_axis_data_tvalid_reg <= 1'b1;
                    m_axis_data_tdata_reg <= rx_data;
                    m_axis_data_tlast_reg <= 1'b0;

                    // Drive ACK/NACK
                    // For now, always ACK to continue reading
                    sda_reg <= 1'b0;
                    sda_high <= 1'b0;

                    // SCL low phase
                    if (scl_reg == 1'b0) begin
                        if (prescale_done) begin
                            scl_reg <= 1'b1;
                            scl_high <= 1'b1;
                        end
                    end else begin
                        // SCL high phase
                        if (prescale_done) begin
                            scl_reg <= 1'b0;
                            scl_high <= 1'b0;
                            // Check if we should stop
                            if (s_axis_data_tlast && is_read) begin
                                state <= S_STOP;
                            end else begin
                                state <= S_READ_BIT;
                                bit_cnt <= 4'd0;
                                rx_data <= 8'd0;
                            end
                        end
                    end
                end

                S_STOP: begin
                    idle_phase <= 1'b0;
                    addr_phase <= 1'b0;
                    data_phase <= 1'b0;
                    read_phase <= 1'b0;
                    write_phase <= 1'b0;
                    write_multiple_phase <= 1'b0;
                    stop_phase <= 1'b1;
                    ack_phase <= 1'b0;
                    bus_active_reg <= 1'b1;
                    bus_control_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    s_axis_cmd_ready_reg <= 1'b0;
                    s_axis_data_tready_reg <= 1'b0;
                    m_axis_data_tvalid_reg <= 1'b0;
                    m_axis_data_tlast_reg <= 1'b0;

                    // Stop condition: SDA low to high while SCL high
                    if (scl_reg == 1'b0) begin
                        // Ensure SDA is low
                        sda_reg <= 1'b0;
                        sda_high <= 1'b0;
                        if (prescale_done) begin
                            scl_reg <= 1'b1;
                            scl_high <= 1'b1;
                        end
                    end else begin
                        // SCL high, raise SDA
                        sda_reg <= 1'b1;
                        sda_high <= 1'b1;
                        stop_cond <= 1'b1;
                        state <= S_IDLE;
                        idle_phase <= 1'b1;
                        bus_active_reg <= 1'b0;
                        bus_control_reg <= 1'b0;
                        busy_reg <= 1'b0;
                        s_axis_cmd_ready_reg <= 1'b1;
                    end
                end

                S_WAIT_DATA: begin
                    idle_phase <= 1'b0;
                    addr_phase <= 1'b0;
                    data_phase <= 1'b0;
                    read_phase <= 1'b0;
                    write_phase <= 1'b0;
                    write_multiple_phase <= 1'b0;
                    stop_phase <= 1'b0;
                    ack_phase <= 1'b0;
                    bus_active_reg <= 1'b1;
                    bus_control_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    s_axis_cmd_ready_reg <= 1'b0;
                    s_axis_data_tready_reg <= 1'b1;
                    m_axis_data_tvalid_reg <= 1'b0;
                    m_axis_data_tlast_reg <= 1'b0;

                    // Wait for data from host
                    if (s_axis_data_tvalid) begin
                        tx_data <= s_axis_data_tdata;
                        bit_cnt <= 4'd0;
                        state <= S_DATA_BIT;
                    end
                end

                S_WAIT_CMD: begin
                    idle_phase <= 1'b0;
                    addr_phase <= 1'b0;
                    data_phase <= 1'b0;
                    read_phase <= 1'b0;
                    write_phase <= 1'b0;
                    write_multiple_phase <= 1'b0;
                    stop_phase <= 1'b0;
                    ack_phase <= 1'b0;
                    bus_active_reg <= 1'b1;
                    bus_control_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    s_axis_cmd_ready_reg <= 1'b1;
                    s_axis_data_tready_reg <= 1'b0;
                    m_axis_data_tvalid_reg <= 1'b0;
                    m_axis_data_tlast_reg <= 1'b0;

                    // Wait for next command
                    if (s_axis_cmd_valid) begin
                        if (s_axis_cmd_start) begin
                            state <= S_START;
                            is_read <= s_axis_cmd_read;
                            is_write <= s_axis_cmd_write;
                            is_write_multiple <= s_axis_cmd_write_multiple;
                            need_stop <= s_axis_cmd_stop;
                            tx_data <= {s_axis_cmd_address, s_axis_cmd_read};
                            bit_cnt <= 4'd0;
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b1;
                        end else if (s_axis_cmd_stop) begin
                            state <= S_STOP;
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b1;
                        end
                    end
                end

                default: begin
                    state <= S_IDLE;
                    idle_phase <= 1'b1;
                    addr_phase <= 1'b0;
                    data_phase <= 1'b0;
                    read_phase <= 1'b0;
                    write_phase <= 1'b0;
                    write_multiple_phase <= 1'b0;
                    stop_phase <= 1'b0;
                    ack_phase <= 1'b0;
                    bus_active_reg <= 1'b0;
                    bus_control_reg <= 1'b0;
                    busy_reg <= 1'b0;
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b1;
                    scl_high <= 1'b1;
                    sda_high <= 1'b1;
                    s_axis_cmd_ready_reg <= 1'b1;
                    s_axis_data_tready_reg <= 1'b0;
                    m_axis_data_tvalid_reg <= 1'b0;
                    m_axis_data_tlast_reg <= 1'b0;
                end
            endcase
        end
    end

endmodule
