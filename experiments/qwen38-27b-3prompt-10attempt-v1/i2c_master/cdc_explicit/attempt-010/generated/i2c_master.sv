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

    reg [3:0] state;
    reg [3:0] next_state;

    // Timing counter
    reg [15:0] timer;
    reg [15:0] timer_next;
    reg [15:0] prescale_reg;

    // Bit counter
    reg [2:0] bit_cnt;
    reg [2:0] bit_cnt_next;

    // Data registers
    reg [7:0] tx_data;
    reg [7:0] rx_data;
    reg [7:0] tx_data_next;
    reg [7:0] rx_data_next;

    // Command registers
    reg [6:0] addr_reg;
    reg       read_reg;
    reg       write_reg;
    reg       write_multiple_reg;
    reg       start_reg;
    reg       stop_reg;

    // Status
    reg       missed_ack_reg;
    reg       busy_reg;
    reg       bus_control_reg;
    reg       bus_active_reg;

    // I2C signals
    reg       scl_o_reg;
    reg       scl_t_reg;
    reg       sda_o_reg;
    reg       sda_t_reg;

    // Handshake
    reg       s_axis_cmd_ready_reg;
    reg       s_axis_data_tready_reg;
    reg       m_axis_data_tvalid_reg;
    reg       m_axis_data_tlast_reg;
    reg [7:0] m_axis_data_tdata_reg;

    // Internal signals
    wire      scl_i_sync;
    wire      sda_i_sync;
    wire      scl_i_sync2;
    wire      sda_i_sync2;

    // Synchronize inputs
    reg [1:0] scl_i_sync_r;
    reg [1:0] sda_i_sync_r;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_i_sync_r <= 2'b00;
            sda_i_sync_r <= 2'b00;
        end else begin
            scl_i_sync_r <= {scl_i_sync_r[0], scl_i};
            sda_i_sync_r <= {sda_i_sync_r[0], sda_i};
        end
    end

    assign scl_i_sync = scl_i_sync_r[1];
    assign sda_i_sync = sda_i_sync_r[1];

    // Synchronize prescale
    reg [15:0] prescale_sync_r;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prescale_sync_r <= 16'd0;
        end else begin
            prescale_sync_r <= prescale;
        end
    end

    // Synchronize stop_on_idle
    reg stop_on_idle_sync_r;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stop_on_idle_sync_r <= 1'b0;
        end else begin
            stop_on_idle_sync_r <= stop_on_idle;
        end
    end

    // Synchronize command inputs
    reg [6:0]  s_axis_cmd_address_sync_r;
    reg        s_axis_cmd_start_sync_r;
    reg        s_axis_cmd_read_sync_r;
    reg        s_axis_cmd_write_sync_r;
    reg        s_axis_cmd_write_multiple_sync_r;
    reg        s_axis_cmd_stop_sync_r;
    reg        s_axis_cmd_valid_sync_r;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_cmd_address_sync_r <= 7'd0;
            s_axis_cmd_start_sync_r <= 1'b0;
            s_axis_cmd_read_sync_r <= 1'b0;
            s_axis_cmd_write_sync_r <= 1'b0;
            s_axis_cmd_write_multiple_sync_r <= 1'b0;
            s_axis_cmd_stop_sync_r <= 1'b0;
            s_axis_cmd_valid_sync_r <= 1'b0;
        end else begin
            s_axis_cmd_address_sync_r <= s_axis_cmd_address;
            s_axis_cmd_start_sync_r <= s_axis_cmd_start;
            s_axis_cmd_read_sync_r <= s_axis_cmd_read;
            s_axis_cmd_write_sync_r <= s_axis_cmd_write;
            s_axis_cmd_write_multiple_sync_r <= s_axis_cmd_write_multiple;
            s_axis_cmd_stop_sync_r <= s_axis_cmd_stop;
            s_axis_cmd_valid_sync_r <= s_axis_cmd_valid;
        end
    end

    // Synchronize data inputs
    reg [7:0] s_axis_data_tdata_sync_r;
    reg       s_axis_data_tvalid_sync_r;
    reg       s_axis_data_tlast_sync_r;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_data_tdata_sync_r <= 8'd0;
            s_axis_data_tvalid_sync_r <= 1'b0;
            s_axis_data_tlast_sync_r <= 1'b0;
        end else begin
            s_axis_data_tdata_sync_r <= s_axis_data_tdata;
            s_axis_data_tvalid_sync_r <= s_axis_data_tvalid;
            s_axis_data_tlast_sync_r <= s_axis_data_tlast;
        end
    end

    // Synchronize m_axis_data_tready
    reg m_axis_data_tready_sync_r;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_data_tready_sync_r <= 1'b0;
        end else begin
            m_axis_data_tready_sync_r <= m_axis_data_tready;
        end
    end

    // State machine next state logic
    always @(*) begin
        next_state = state;
        timer_next = timer;
        bit_cnt_next = bit_cnt;
        tx_data_next = tx_data;
        rx_data_next = rx_data;
        scl_o_reg = scl_o_reg;
        scl_t_reg = scl_t_reg;
        sda_o_reg = sda_o_reg;
        sda_t_reg = sda_t_reg;
        s_axis_cmd_ready_reg = s_axis_cmd_ready_reg;
        s_axis_data_tready_reg = s_axis_data_tready_reg;
        m_axis_data_tvalid_reg = m_axis_data_tvalid_reg;
        m_axis_data_tlast_reg = m_axis_data_tlast_reg;
        m_axis_data_tdata_reg = m_axis_data_tdata_reg;
        missed_ack_reg = missed_ack_reg;
        busy_reg = busy_reg;
        bus_control_reg = bus_control_reg;
        bus_active_reg = bus_active_reg;

        case (state)
            S_IDLE: begin
                if (s_axis_cmd_valid_sync_r) begin
                    next_state = S_START;
                    timer_next = 16'd0;
                    bit_cnt_next = 3'd0;
                    tx_data_next = {s_axis_cmd_address_sync_r, s_axis_cmd_read_sync_r};
                    rx_data_next = 8'd0;
                    scl_o_reg = 1'b1;
                    scl_t_reg = 1'b0;
                    sda_o_reg = 1'b1;
                    sda_t_reg = 1'b0;
                    s_axis_cmd_ready_reg = 1'b1;
                    s_axis_data_tready_reg = 1'b0;
                    m_axis_data_tvalid_reg = 1'b0;
                    m_axis_data_tlast_reg = 1'b0;
                    m_axis_data_tdata_reg = 8'd0;
                    missed_ack_reg = 1'b0;
                    busy_reg = 1'b1;
                    bus_control_reg = 1'b1;
                    bus_active_reg = 1'b1;
                end else begin
                    s_axis_cmd_ready_reg = 1'b1;
                    s_axis_data_tready_reg = 1'b0;
                    m_axis_data_tvalid_reg = 1'b0;
                    m_axis_data_tlast_reg = 1'b0;
                    m_axis_data_tdata_reg = 8'd0;
                    missed_ack_reg = 1'b0;
                    busy_reg = 1'b0;
                    bus_control_reg = 1'b0;
                    bus_active_reg = 1'b0;
                    scl_o_reg = 1'b1;
                    scl_t_reg = 1'b0;
                    sda_o_reg = 1'b1;
                    sda_t_reg = 1'b0;
                end
            end

            S_START: begin
                // START condition: SDA high to low while SCL high
                if (timer_next < prescale_sync_r) begin
                    timer_next = timer_next + 16'd1;
                    // Keep SCL high, SDA high initially
                    scl_o_reg = 1'b1;
                    scl_t_reg = 1'b0;
                    sda_o_reg = 1'b1;
                    sda_t_reg = 1'b0;
                end else begin
                    // Pull SDA low to generate START
                    sda_o_reg = 1'b0;
                    sda_t_reg = 1'b0;
                    timer_next = 16'd0;
                    next_state = S_ADDR;
                end
            end

            S_ADDR: begin
                // Send address bits MSB first
                if (timer_next < prescale_sync_r) begin
                    timer_next = timer_next + 16'd1;
                    // Drive SDA with current bit
                    sda_o_reg = tx_data_next[7];
                    sda_t_reg = 1'b0;
                    scl_o_reg = 1'b1;
                    scl_t_reg = 1'b0;
                end else begin
                    // Clock SCL low
                    scl_o_reg = 1'b0;
                    scl_t_reg = 1'b0;
                    timer_next = 16'd0;
                    // Shift data
                    tx_data_next = {tx_data_next[6:0], 1'b0};
                    bit_cnt_next = bit_cnt_next + 3'd1;
                    if (bit_cnt_next == 3'd7) begin
                        // After 8 bits, go to ACK
                        next_state = S_ACK;
                        bit_cnt_next = 3'd0;
                    end
                end
            end

            S_ACK: begin
                // Release SDA, read ACK
                if (timer_next < prescale_sync_r) begin
                    timer_next = timer_next + 16'd1;
                    // Release SDA (high impedance)
                    sda_o_reg = 1'b1;
                    sda_t_reg = 1'b1;
                    scl_o_reg = 1'b1;
                    scl_t_reg = 1'b0;
                end else begin
                    // Sample SDA for ACK
                    if (sda_i_sync) begin
                        // NACK
                        missed_ack_reg = 1'b1;
                        next_state = S_STOP;
                    end else begin
                        // ACK
                        missed_ack_reg = 1'b0;
                        if (read_reg) begin
                            // Read operation: go to data phase
                            next_state = S_DATA;
                        end else begin
                            // Write operation: go to data phase
                            next_state = S_DATA;
                        end
                    end
                    timer_next = 16'd0;
                    bit_cnt_next = 3'd0;
                end
            end

            S_DATA: begin
                if (read_reg) begin
                    // Read operation: receive data
                    if (timer_next < prescale_sync_r) begin
                        timer_next = timer_next + 16'd1;
                        // Release SDA, clock SCL
                        sda_o_reg = 1'b1;
                        sda_t_reg = 1'b1;
                        scl_o_reg = 1'b1;
                        scl_t_reg = 1'b0;
                    end else begin
                        // Sample SDA
                        rx_data_next = {rx_data_next[6:0], sda_i_sync};
                        scl_o_reg = 1'b0;
                        scl_t_reg = 1'b0;
                        timer_next = 16'd0;
                        bit_cnt_next = bit_cnt_next + 3'd1;
                        if (bit_cnt_next == 3'd7) begin
                            // After 8 bits, go to ACK
                            next_state = S_ACK;
                            bit_cnt_next = 3'd0;
                        end
                    end
                end else begin
                    // Write operation: send data
                    if (timer_next < prescale_sync_r) begin
                        timer_next = timer_next + 16'd1;
                        // Drive SDA with current bit
                        sda_o_reg = tx_data_next[7];
                        sda_t_reg = 1'b0;
                        scl_o_reg = 1'b1;
                        scl_t_reg = 1'b0;
                    end else begin
                        // Clock SCL low
                        scl_o_reg = 1'b0;
                        scl_t_reg = 1'b0;
                        timer_next = 16'd0;
                        // Shift data
                        tx_data_next = {tx_data_next[6:0], 1'b0};
                        bit_cnt_next = bit_cnt_next + 3'd1;
                        if (bit_cnt_next == 3'd7) begin
                            // After 8 bits, go to ACK
                            next_state = S_ACK;
                            bit_cnt_next = 3'd0;
                        end
                    end
                end
            end

            S_STOP: begin
                // STOP condition: SDA low to high while SCL high
                if (timer_next < prescale_sync_r) begin
                    timer_next = timer_next + 16'd1;
                    // Keep SCL high, SDA low initially
                    scl_o_reg = 1'b1;
                    scl_t_reg = 1'b0;
                    sda_o_reg = 1'b0;
                    sda_t_reg = 1'b0;
                end else begin
                    // Release SDA to generate STOP
                    sda_o_reg = 1'b1;
                    sda_t_reg = 1'b1;
                    timer_next = 16'd0;
                    next_state = S_IDLE;
                    s_axis_cmd_ready_reg = 1'b1;
                    s_axis_data_tready_reg = 1'b0;
                    m_axis_data_tvalid_reg = 1'b0;
                    m_axis_data_tlast_reg = 1'b0;
                    m_axis_data_tdata_reg = 8'd0;
                    busy_reg = 1'b0;
                    bus_control_reg = 1'b0;
                    bus_active_reg = 1'b0;
                end
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    // State machine state register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            timer <= 16'd0;
            bit_cnt <= 3'd0;
            tx_data <= 8'd0;
            rx_data <= 8'd0;
            addr_reg <= 7'd0;
            read_reg <= 1'b0;
            write_reg <= 1'b0;
            write_multiple_reg <= 1'b0;
            start_reg <= 1'b0;
            stop_reg <= 1'b0;
            missed_ack_reg <= 1'b0;
            busy_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            scl_o_reg <= 1'b1;
            scl_t_reg <= 1'b0;
            sda_o_reg <= 1'b1;
            sda_t_reg <= 1'b0;
            s_axis_cmd_ready_reg <= 1'b1;
            s_axis_data_tready_reg <= 1'b0;
            m_axis_data_tvalid_reg <= 1'b0;
            m_axis_data_tlast_reg <= 1'b0;
            m_axis_data_tdata_reg <= 8'd0;
        end else begin
            state <= next_state;
            timer <= timer_next;
            bit_cnt <= bit_cnt_next;
            tx_data <= tx_data_next;
            rx_data <= rx_data_next;
            missed_ack_reg <= missed_ack_reg;
            busy_reg <= busy_reg;
            bus_control_reg <= bus_control_reg;
            bus_active_reg <= bus_active_reg;
            scl_o_reg <= scl_o_reg;
            scl_t_reg <= scl_t_reg;
            sda_o_reg <= sda_o_reg;
            sda_t_reg <= sda_t_reg;
            s_axis_cmd_ready_reg <= s_axis_cmd_ready_reg;
            s_axis_data_tready_reg <= s_axis_data_tready_reg;
            m_axis_data_tvalid_reg <= m_axis_data_tvalid_reg;
            m_axis_data_tlast_reg <= m_axis_data_tlast_reg;
            m_axis_data_tdata_reg <= m_axis_data_tdata_reg;

            // Update command registers when accepting command
            if (state == S_IDLE && s_axis_cmd_valid_sync_r) begin
                addr_reg <= s_axis_cmd_address_sync_r;
                read_reg <= s_axis_cmd_read_sync_r;
                write_reg <= s_axis_cmd_write_sync_r;
                write_multiple_reg <= s_axis_cmd_write_multiple_sync_r;
                start_reg <= s_axis_cmd_start_sync_r;
                stop_reg <= s_axis_cmd_stop_sync_r;
            end
        end
    end

    // Assign outputs
    assign s_axis_cmd_ready = s_axis_cmd_ready_reg;
    assign s_axis_data_tready = s_axis_data_tready_reg;
    assign m_axis_data_tdata = m_axis_data_tdata_reg;
    assign m_axis_data_tvalid = m_axis_data_tvalid_reg;
    assign m_axis_data_tlast = m_axis_data_tlast_reg;
    assign scl_o = scl_o_reg;
    assign scl_t = scl_t_reg;
    assign sda_o = sda_o_reg;
    assign sda_t = sda_t_reg;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;

endmodule
