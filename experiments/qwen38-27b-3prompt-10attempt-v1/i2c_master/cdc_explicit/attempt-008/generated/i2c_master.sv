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

    // I2C signals
    reg scl_reg;
    reg sda_reg;
    reg scl_t_reg;
    reg sda_t_reg;

    // Data registers
    reg [7:0] tx_data;
    reg [7:0] rx_data;
    reg [2:0] bit_count;
    reg [6:0] addr_reg;
    reg read_op;
    reg write_op;
    reg write_multiple;
    reg stop_cmd;
    reg start_cmd;

    // ACK handling
    reg ack_received;
    reg missed_ack_reg;

    // Prescale counter
    reg [15:0] prescale_reg;
    reg [15:0] counter;
    reg counter_done;

    // Bus control
    reg bus_control_reg;
    reg bus_active_reg;
    reg busy_reg;

    // Command interface
    reg cmd_ready;
    reg data_tready;
    reg m_data_tvalid;
    reg m_data_tlast;
    reg [7:0] m_data_tdata;

    // Synchronization for prescale (single clock, so just register)
    reg [15:0] prescale_sync;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prescale_sync <= 16'd0;
        end else begin
            prescale_sync <= prescale;
        end
    end

    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (s_axis_cmd_valid && s_axis_cmd_ready) begin
                    if (s_axis_cmd_start)
                        next_state = S_START;
                    else if (s_axis_cmd_stop)
                        next_state = S_STOP;
                    else
                        next_state = S_ADDR;
                end
            end
            S_START: begin
                if (counter_done)
                    next_state = S_ADDR;
            end
            S_ADDR: begin
                if (counter_done)
                    next_state = S_ACK;
            end
            S_ACK: begin
                if (counter_done) begin
                    if (ack_received) begin
                        if (read_op)
                            next_state = S_DATA;
                        else if (write_op) begin
                            if (s_axis_data_tvalid)
                                next_state = S_DATA;
                            else
                                next_state = S_WAIT;
                        end
                        else
                            next_state = S_STOP;
                    end else begin
                        next_state = S_STOP;
                    end
                end
            end
            S_DATA: begin
                if (counter_done) begin
                    if (read_op) begin
                        next_state = S_ACK;
                    end else begin
                        if (s_axis_data_tlast)
                            next_state = S_ACK;
                        else
                            next_state = S_ACK;
                    end
                end
            end
            S_WAIT: begin
                if (s_axis_data_tvalid)
                    next_state = S_DATA;
            end
            S_STOP: begin
                if (counter_done)
                    next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end

    // Prescale counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 16'd0;
            counter_done <= 1'b0;
        end else begin
            if (state == S_IDLE) begin
                counter <= 16'd0;
                counter_done <= 1'b0;
            end else begin
                if (counter_done) begin
                    counter <= 16'd0;
                    counter_done <= 1'b0;
                end else if (counter >= prescale_sync) begin
                    counter <= 16'd0;
                    counter_done <= 1'b1;
                end else begin
                    counter <= counter + 1'b1;
                    counter_done <= 1'b0;
                end
            end
        end
    end

    // Command acceptance
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_ready <= 1'b1;
            addr_reg <= 7'd0;
            read_op <= 1'b0;
            write_op <= 1'b0;
            write_multiple <= 1'b0;
            stop_cmd <= 1'b0;
            start_cmd <= 1'b0;
        end else begin
            if (state == S_IDLE) begin
                cmd_ready <= 1'b1;
                if (s_axis_cmd_valid) begin
                    addr_reg <= s_axis_cmd_address;
                    read_op <= s_axis_cmd_read;
                    write_op <= s_axis_cmd_write;
                    write_multiple <= s_axis_cmd_write_multiple;
                    stop_cmd <= s_axis_cmd_stop;
                    start_cmd <= s_axis_cmd_start;
                    cmd_ready <= 1'b0;
                end
            end else begin
                cmd_ready <= 1'b0;
            end
        end
    end

    // Data interface
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_tready <= 1'b0;
            m_data_tvalid <= 1'b0;
            m_data_tlast <= 1'b0;
            m_data_tdata <= 8'd0;
            tx_data <= 8'd0;
            rx_data <= 8'd0;
            bit_count <= 3'd0;
            ack_received <= 1'b0;
            missed_ack_reg <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    data_tready <= 1'b0;
                    m_data_tvalid <= 1'b0;
                    m_data_tlast <= 1'b0;
                    missed_ack_reg <= 1'b0;
                end
                S_START: begin
                    data_tready <= 1'b0;
                    m_data_tvalid <= 1'b0;
                    m_data_tlast <= 1'b0;
                end
                S_ADDR: begin
                    data_tready <= 1'b0;
                    m_data_tvalid <= 1'b0;
                    m_data_tlast <= 1'b0;
                    if (counter_done) begin
                        bit_count <= 3'd0;
                        if (read_op)
                            tx_data <= {addr_reg, 1'b1};
                        else
                            tx_data <= {addr_reg, 1'b0};
                    end
                end
                S_ACK: begin
                    data_tready <= 1'b0;
                    m_data_tvalid <= 1'b0;
                    m_data_tlast <= 1'b0;
                    if (counter_done) begin
                        if (read_op) begin
                            // Master receives ACK from slave
                            ack_received <= ~sda_i;
                            if (sda_i)
                                missed_ack_reg <= 1'b1;
                        end else begin
                            // Master sends ACK
                            ack_received <= 1'b1;
                        end
                        if (read_op) begin
                            // Prepare to send ACK for read data
                            bit_count <= 3'd0;
                        end else begin
                            // Prepare next data byte
                            if (s_axis_data_tvalid) begin
                                tx_data <= s_axis_data_tdata;
                                bit_count <= 3'd0;
                            end
                        end
                    end
                end
                S_DATA: begin
                    if (read_op) begin
                        data_tready <= 1'b0;
                        if (counter_done) begin
                            if (bit_count == 3'd7) begin
                                m_data_tdata <= rx_data;
                                m_data_tvalid <= 1'b1;
                                m_data_tlast <= s_axis_data_tlast;
                                bit_count <= 3'd0;
                            end else begin
                                rx_data <= {rx_data[6:0], sda_i};
                                bit_count <= bit_count + 1'b1;
                            end
                        end else begin
                            if (bit_count == 3'd7) begin
                                rx_data <= {rx_data[6:0], sda_i};
                                bit_count <= bit_count + 1'b1;
                            end
                        end
                    end else begin
                        if (counter_done) begin
                            if (bit_count == 3'd7) begin
                                bit_count <= 3'd0;
                            end else begin
                                bit_count <= bit_count + 1'b1;
                            end
                        end
                        data_tready <= (state == S_WAIT) ? 1'b1 : 1'b0;
                    end
                end
                S_WAIT: begin
                    data_tready <= 1'b1;
                    m_data_tvalid <= 1'b0;
                    m_data_tlast <= 1'b0;
                    if (s_axis_data_tvalid) begin
                        tx_data <= s_axis_data_tdata;
                        bit_count <= 3'd0;
                    end
                end
                S_STOP: begin
                    data_tready <= 1'b0;
                    m_data_tvalid <= 1'b0;
                    m_data_tlast <= 1'b0;
                end
                default: begin
                    data_tready <= 1'b0;
                    m_data_tvalid <= 1'b0;
                    m_data_tlast <= 1'b0;
                end
            endcase
        end
    end

    // I2C signal generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            scl_t_reg <= 1'b1;
            sda_t_reg <= 1'b1;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            busy_reg <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b1;
                    scl_t_reg <= 1'b1;
                    sda_t_reg <= 1'b1;
                    bus_control_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    busy_reg <= 1'b0;
                end
                S_START: begin
                    bus_control_reg <= 1'b1;
                    bus_active_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    if (counter_done) begin
                        // SCL high, SDA low
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b0;
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b0;
                    end else begin
                        // SCL high, SDA high
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b1;
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b0;
                    end
                end
                S_ADDR: begin
                    bus_control_reg <= 1'b1;
                    bus_active_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    if (counter_done) begin
                        // Toggle SCL
                        if (bit_count == 3'd7) begin
                            scl_reg <= 1'b0;
                            scl_t_reg <= 1'b0;
                        end else begin
                            scl_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                        end
                        sda_reg <= tx_data[7 - bit_count];
                        sda_t_reg <= 1'b0;
                    end else begin
                        scl_reg <= 1'b1;
                        sda_reg <= tx_data[7 - bit_count];
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b0;
                    end
                end
                S_ACK: begin
                    bus_control_reg <= 1'b1;
                    bus_active_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    if (counter_done) begin
                        if (read_op) begin
                            // Release SDA to read ACK
                            sda_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            scl_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                        end else begin
                            // Send ACK (SDA low)
                            sda_reg <= 1'b0;
                            sda_t_reg <= 1'b0;
                            scl_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                        end
                    end else begin
                        if (read_op) begin
                            sda_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                            scl_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                        end else begin
                            sda_reg <= 1'b0;
                            sda_t_reg <= 1'b0;
                            scl_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                        end
                    end
                end
                S_DATA: begin
                    bus_control_reg <= 1'b1;
                    bus_active_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    if (read_op) begin
                        // Master receives data
                        if (counter_done) begin
                            if (bit_count == 3'd7) begin
                                scl_reg <= 1'b0;
                                scl_t_reg <= 1'b0;
                            end else begin
                                scl_reg <= 1'b1;
                                scl_t_reg <= 1'b0;
                            end
                            sda_reg <= 1'b1;
                            sda_t_reg <= 1'b1;
                        end else begin
                            scl_reg <= 1'b1;
                            sda_reg <= 1'b1;
                            scl_t_reg <= 1'b0;
                            sda_t_reg <= 1'b1;
                        end
                    end else begin
                        // Master sends data
                        if (counter_done) begin
                            if (bit_count == 3'd7) begin
                                scl_reg <= 1'b0;
                                scl_t_reg <= 1'b0;
                            end else begin
                                scl_reg <= 1'b1;
                                scl_t_reg <= 1'b0;
                            end
                            sda_reg <= tx_data[7 - bit_count];
                            sda_t_reg <= 1'b0;
                        end else begin
                            scl_reg <= 1'b1;
                            sda_reg <= tx_data[7 - bit_count];
                            scl_t_reg <= 1'b0;
                            sda_t_reg <= 1'b0;
                        end
                    end
                end
                S_WAIT: begin
                    bus_control_reg <= 1'b1;
                    bus_active_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b1;
                    scl_t_reg <= 1'b0;
                    sda_t_reg <= 1'b1;
                end
                S_STOP: begin
                    bus_control_reg <= 1'b1;
                    bus_active_reg <= 1'b1;
                    busy_reg <= 1'b1;
                    if (counter_done) begin
                        // SCL high, SDA high
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b1;
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b0;
                    end else begin
                        // SCL high, SDA low
                        scl_reg <= 1'b1;
                        sda_reg <= 1'b0;
                        scl_t_reg <= 1'b0;
                        sda_t_reg <= 1'b0;
                    end
                end
                default: begin
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b1;
                    scl_t_reg <= 1'b1;
                    sda_t_reg <= 1'b1;
                    bus_control_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    busy_reg <= 1'b0;
                end
            endcase
        end
    end

    // Output assignments
    assign scl_o = scl_reg;
    assign scl_t = scl_t_reg;
    assign sda_o = sda_reg;
    assign sda_t = sda_t_reg;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;
    assign s_axis_cmd_ready = cmd_ready;
    assign s_axis_data_tready = data_tready;
    assign m_axis_data_tdata = m_data_tdata;
    assign m_axis_data_tvalid = m_data_tvalid;
    assign m_axis_data_tlast = m_data_tlast;

endmodule
