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
    localparam S_WAIT_ACK = 4'd6;

    reg [3:0] state;
    reg [3:0] next_state;

    // I2C signal control
    reg scl_ctrl;
    reg sda_ctrl;
    reg scl_next;
    reg sda_next;

    // Data registers
    reg [7:0] tx_data;
    reg [7:0] rx_data;
    reg [2:0] bit_count;
    reg [6:0] addr_reg;
    reg read_mode;
    reg write_mode;
    reg write_multiple;
    reg stop_cmd;
    reg start_cmd;

    // ACK handling
    reg ack_received;
    reg missed_ack_reg;

    // Timing
    reg [15:0] prescale_reg;
    reg [15:0] timer;
    reg timer_done;

    // Bus control
    reg bus_control_reg;
    reg bus_active_reg;
    reg busy_reg;

    // AXI-Stream interfaces
    reg s_axis_cmd_ready_reg;
    reg s_axis_data_tready_reg;
    reg m_axis_data_tvalid_reg;
    reg m_axis_data_tlast_reg;
    reg [7:0] m_axis_data_tdata_reg;

    // Prescale configuration
    always @(posedge clk or posedge rst) begin
        if (rst)
            prescale_reg <= 16'd0;
        else
            prescale_reg <= prescale;
    end

    // Timer logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            timer <= 16'd0;
            timer_done <= 1'b0;
        end else begin
            if (timer_done) begin
                timer <= 16'd0;
                timer_done <= 1'b0;
            end else if (timer < prescale_reg) begin
                timer <= timer + 16'd1;
                timer_done <= 1'b0;
            end else begin
                timer <= 16'd0;
                timer_done <= 1'b1;
            end
        end
    end

    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            scl_ctrl <= 1'b1;
            sda_ctrl <= 1'b1;
            bit_count <= 3'd0;
            tx_data <= 8'd0;
            rx_data <= 8'd0;
            addr_reg <= 7'd0;
            read_mode <= 1'b0;
            write_mode <= 1'b0;
            write_multiple <= 1'b0;
            stop_cmd <= 1'b0;
            start_cmd <= 1'b0;
            ack_received <= 1'b0;
            missed_ack_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            busy_reg <= 1'b0;
            s_axis_cmd_ready_reg <= 1'b1;
            s_axis_data_tready_reg <= 1'b0;
            m_axis_data_tvalid_reg <= 1'b0;
            m_axis_data_tlast_reg <= 1'b0;
            m_axis_data_tdata_reg <= 8'd0;
        end else begin
            // Default assignments
            s_axis_cmd_ready_reg <= 1'b0;
            s_axis_data_tready_reg <= 1'b0;
            m_axis_data_tvalid_reg <= 1'b0;
            m_axis_data_tlast_reg <= 1'b0;

            case (state)
                S_IDLE: begin
                    s_axis_cmd_ready_reg <= 1'b1;
                    bus_control_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    busy_reg <= 1'b0;
                    missed_ack_reg <= 1'b0;
                    scl_ctrl <= 1'b1;
                    sda_ctrl <= 1'b1;
                    
                    if (s_axis_cmd_valid) begin
                        addr_reg <= s_axis_cmd_address;
                        read_mode <= s_axis_cmd_read;
                        write_mode <= s_axis_cmd_write;
                        write_multiple <= s_axis_cmd_write_multiple;
                        stop_cmd <= s_axis_cmd_stop;
                        start_cmd <= s_axis_cmd_start;
                        bus_control_reg <= 1'b1;
                        busy_reg <= 1'b1;
                        
                        if (s_axis_cmd_start) begin
                            state <= S_START;
                        end else if (s_axis_cmd_stop) begin
                            state <= S_STOP;
                        end else begin
                            state <= S_ADDR;
                            bit_count <= 3'd7;
                            tx_data <= {s_axis_cmd_address, s_axis_cmd_read};
                        end
                    end
                end

                S_START: begin
                    busy_reg <= 1'b1;
                    bus_active_reg <= 1'b1;
                    
                    // START condition: SDA high to low while SCL high
                    if (timer_done) begin
                        sda_ctrl <= 1'b0;
                        state <= S_ADDR;
                        bit_count <= 3'd7;
                        tx_data <= {addr_reg, read_mode};
                    end else begin
                        // Keep SCL high, SDA high initially
                        scl_ctrl <= 1'b1;
                        sda_ctrl <= 1'b1;
                    end
                end

                S_ADDR: begin
                    busy_reg <= 1'b1;
                    bus_active_reg <= 1'b1;
                    s_axis_data_tready_reg <= 1'b0;
                    
                    if (timer_done) begin
                        // Toggle SCL for each bit
                        if (bit_count == 3'd0) begin
                            // All bits sent, wait for ACK
                            state <= S_WAIT_ACK;
                            scl_ctrl <= 1'b1;
                            sda_ctrl <= 1'b1; // Release SDA for ACK
                        end else begin
                            // Send next bit
                            tx_data <= {tx_data[6:0], 1'b0};
                            sda_ctrl <= tx_data[7];
                            bit_count <= bit_count - 1'b1;
                            scl_ctrl <= ~scl_ctrl;
                        end
                    end
                end

                S_WAIT_ACK: begin
                    busy_reg <= 1'b1;
                    bus_active_reg <= 1'b1;
                    
                    if (timer_done) begin
                        // Sample ACK
                        ack_received <= ~sda_i;
                        missed_ack_reg <= ~sda_i;
                        
                        if (ack_received) begin
                            if (read_mode) begin
                                // Read mode: prepare to receive data
                                state <= S_DATA;
                                bit_count <= 3'd7;
                                sda_ctrl <= 1'b1; // Release SDA
                            end else begin
                                // Write mode: prepare to send data
                                if (s_axis_data_tvalid) begin
                                    tx_data <= s_axis_data_tdata;
                                    state <= S_DATA;
                                    bit_count <= 3'd7;
                                end else begin
                                    state <= S_DATA;
                                    bit_count <= 3'd7;
                                end
                            end
                        end else begin
                            // No ACK, go to stop
                            state <= S_STOP;
                        end
                    end
                end

                S_DATA: begin
                    busy_reg <= 1'b1;
                    bus_active_reg <= 1'b1;
                    
                    if (timer_done) begin
                        if (read_mode) begin
                            // Receive data
                            if (bit_count == 3'd0) begin
                                // All bits received, send ACK/NACK
                                state <= S_ACK;
                                scl_ctrl <= 1'b1;
                                sda_ctrl <= 1'b1; // Release for now, will drive ACK
                            end else begin
                                rx_data <= {rx_data[6:0], sda_i};
                                bit_count <= bit_count - 1'b1;
                                scl_ctrl <= ~scl_ctrl;
                                sda_ctrl <= 1'b1; // Keep released
                            end
                        end else begin
                            // Send data
                            if (bit_count == 3'd0) begin
                                // All bits sent, wait for ACK
                                state <= S_WAIT_ACK;
                                scl_ctrl <= 1'b1;
                                sda_ctrl <= 1'b1; // Release SDA for ACK
                            end else begin
                                tx_data <= {tx_data[6:0], 1'b0};
                                sda_ctrl <= tx_data[7];
                                bit_count <= bit_count - 1'b1;
                                scl_ctrl <= ~scl_ctrl;
                            end
                        end
                    end
                end

                S_ACK: begin
                    busy_reg <= 1'b1;
                    bus_active_reg <= 1'b1;
                    
                    if (timer_done) begin
                        // Send ACK (0) or NACK (1)
                        // For now, always send ACK
                        sda_ctrl <= 1'b0; // ACK
                        scl_ctrl <= 1'b0;
                        
                        // Output received data
                        m_axis_data_tdata_reg <= rx_data;
                        m_axis_data_tvalid_reg <= 1'b1;
                        m_axis_data_tlast_reg <= s_axis_data_tlast;
                        
                        if (m_axis_data_tready) begin
                            if (s_axis_data_tlast) begin
                                state <= S_STOP;
                            end else begin
                                state <= S_DATA;
                                bit_count <= 3'd7;
                                sda_ctrl <= 1'b1;
                            end
                        end else begin
                            state <= S_DATA;
                            bit_count <= 3'd7;
                            sda_ctrl <= 1'b1;
                        end
                    end
                end

                S_STOP: begin
                    busy_reg <= 1'b1;
                    bus_active_reg <= 1'b1;
                    
                    // STOP condition: SDA low to high while SCL high
                    if (timer_done) begin
                        sda_ctrl <= 1'b1;
                        scl_ctrl <= 1'b1;
                        
                        if (stop_on_idle) begin
                            state <= S_IDLE;
                            bus_control_reg <= 1'b0;
                            bus_active_reg <= 1'b0;
                            busy_reg <= 1'b0;
                        end else begin
                            state <= S_IDLE;
                            bus_control_reg <= 1'b0;
                            bus_active_reg <= 1'b0;
                            busy_reg <= 1'b0;
                        end
                    end else begin
                        // Keep SCL high, SDA low initially
                        scl_ctrl <= 1'b1;
                        sda_ctrl <= 1'b0;
                    end
                end

                default: begin
                    state <= S_IDLE;
                    scl_ctrl <= 1'b1;
                    sda_ctrl <= 1'b1;
                    bus_control_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    busy_reg <= 1'b0;
                end
            end
        end
    end

    // Open-drain outputs
    assign scl_o = scl_ctrl;
    assign scl_t = ~scl_ctrl;
    assign sda_o = sda_ctrl;
    assign sda_t = ~sda_ctrl;

    // Status outputs
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;

    // AXI-Stream outputs
    assign s_axis_cmd_ready = s_axis_cmd_ready_reg;
    assign s_axis_data_tready = s_axis_data_tready_reg;
    assign m_axis_data_tdata = m_axis_data_tdata_reg;
    assign m_axis_data_tvalid = m_axis_data_tvalid_reg;
    assign m_axis_data_tlast = m_axis_data_tlast_reg;

endmodule
