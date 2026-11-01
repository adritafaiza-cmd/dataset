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
    localparam S_IDLE          = 4'd0;
    localparam S_START         = 4'd1;
    localparam S_SEND_BIT      = 4'd2;
    localparam S_RECV_BIT      = 4'd3;
    localparam S_ACK           = 4'd4;
    localparam S_STOP          = 4'd5;
    localparam S_DONE          = 4'd6;

    // Operation modes
    localparam OP_NONE         = 2'd0;
    localparam OP_WRITE        = 2'd1;
    localparam OP_READ         = 2'd2;
    localparam OP_WRITE_MULTI  = 2'd3;

    reg [3:0]  state;
    reg [3:0]  next_state;

    reg [1:0]  op_mode;
    reg [6:0]  addr_reg;
    reg [7:0]  data_reg;
    reg [2:0]  bit_cnt;
    reg [7:0]  shift_out;
    reg [7:0]  shift_in;
    reg        ack_received;
    reg        ack_missed;
    reg        data_valid;
    reg        data_last;
    reg        cmd_pending;
    reg        write_multi_pending;
    reg        stop_pending;
    reg        start_pending;
    reg        read_pending;
    reg        write_pending;
    reg        write_multi_cmd;
    reg        stop_cmd;
    reg        start_cmd;
    reg        read_cmd;
    reg        write_cmd;
    reg [6:0]  cmd_addr;

    // Timing
    reg [15:0] prescale_reg;
    reg [15:0] timer;
    reg        timer_done;

    // I2C signals
    reg        scl_out;
    reg        sda_out;
    reg        scl_tri;
    reg        sda_tri;

    // Internal signals
    wire       scl_high;
    wire       sda_high;

    assign scl_high = scl_i;
    assign sda_high = sda_i;

    // Output assignments
    assign scl_o = scl_out;
    assign sda_o = sda_out;
    assign scl_t = scl_tri;
    assign sda_t = sda_tri;

    assign busy = (state != S_IDLE) || cmd_pending;
    assign bus_control = (state != S_IDLE);
    assign bus_active = (state != S_IDLE) && (state != S_DONE);
    assign missed_ack = ack_missed;

    // AXI command ready
    assign s_axis_cmd_ready = (state == S_IDLE) && !cmd_pending;

    // AXI data ready
    assign s_axis_data_tready = (state == S_IDLE) && cmd_pending && 
                                 (op_mode == OP_WRITE || op_mode == OP_WRITE_MULTI) &&
                                 !write_multi_pending;

    // AXI data output
    assign m_axis_data_tdata = shift_in;
    assign m_axis_data_tvalid = data_valid;
    assign m_axis_data_tlast = data_last;

    // Timer logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prescale_reg <= 16'd1;
            timer <= 16'd0;
            timer_done <= 1'b0;
        end else begin
            prescale_reg <= prescale;
            if (timer_done) begin
                timer <= 16'd0;
                timer_done <= 1'b0;
            end else if (timer < prescale_reg) begin
                timer <= timer + 16'd1;
            end else begin
                timer_done <= 1'b1;
            end
        end
    end

    // Command capture
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_pending <= 1'b0;
            start_pending <= 1'b0;
            read_pending <= 1'b0;
            write_pending <= 1'b0;
            write_multi_pending <= 1'b0;
            stop_pending <= 1'b0;
            start_cmd <= 1'b0;
            read_cmd <= 1'b0;
            write_cmd <= 1'b0;
            write_multi_cmd <= 1'b0;
            stop_cmd <= 1'b0;
            cmd_addr <= 7'd0;
            op_mode <= OP_NONE;
        end else if (state == S_IDLE && !cmd_pending) begin
            if (s_axis_cmd_valid) begin
                cmd_pending <= 1'b1;
                cmd_addr <= s_axis_cmd_address;
                start_cmd <= s_axis_cmd_start;
                read_cmd <= s_axis_cmd_read;
                write_cmd <= s_axis_cmd_write;
                write_multi_cmd <= s_axis_cmd_write_multiple;
                stop_cmd <= s_axis_cmd_stop;
                
                if (s_axis_cmd_start) begin
                    op_mode <= OP_NONE;
                end else if (s_axis_cmd_read) begin
                    op_mode <= OP_READ;
                end else if (s_axis_cmd_write_multiple) begin
                    op_mode <= OP_WRITE_MULTI;
                end else if (s_axis_cmd_write) begin
                    op_mode <= OP_WRITE;
                end else if (s_axis_cmd_stop) begin
                    op_mode <= OP_NONE;
                end
            end
        end else if (state == S_DONE) begin
            cmd_pending <= 1'b0;
            start_pending <= 1'b0;
            read_pending <= 1'b0;
            write_pending <= 1'b0;
            write_multi_pending <= 1'b0;
            stop_pending <= 1'b0;
            start_cmd <= 1'b0;
            read_cmd <= 1'b0;
            write_cmd <= 1'b0;
            write_multi_cmd <= 1'b0;
            stop_cmd <= 1'b0;
            op_mode <= OP_NONE;
        end
    end

    // Data capture for write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_reg <= 8'd0;
        end else if (s_axis_data_tready && s_axis_data_tvalid) begin
            data_reg <= s_axis_data_tdata;
        end
    end

    // Main state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            bit_cnt <= 3'd0;
            shift_out <= 8'd0;
            shift_in <= 8'd0;
            ack_received <= 1'b0;
            ack_missed <= 1'b0;
            data_valid <= 1'b0;
            data_last <= 1'b0;
            scl_out <= 1'b1;
            sda_out <= 1'b1;
            scl_tri <= 1'b1;
            sda_tri <= 1'b1;
        end else begin
            // Default: hold outputs
            scl_tri <= 1'b1;
            sda_tri <= 1'b1;
            
            case (state)
                S_IDLE: begin
                    scl_out <= 1'b1;
                    sda_out <= 1'b1;
                    scl_tri <= 1'b1;
                    sda_tri <= 1'b1;
                    data_valid <= 1'b0;
                    data_last <= 1'b0;
                    ack_missed <= 1'b0;
                    
                    if (cmd_pending && timer_done) begin
                        if (start_cmd) begin
                            // Generate START condition
                            state <= S_START;
                            bit_cnt <= 3'd0;
                            scl_out <= 1'b1;
                            sda_out <= 1'b1;
                            scl_tri <= 1'b0;
                            sda_tri <= 1'b0;
                        end else if (stop_cmd) begin
                            // Generate STOP condition
                            state <= S_STOP;
                            bit_cnt <= 3'd0;
                            scl_out <= 1'b1;
                            sda_out <= 1'b0;
                            scl_tri <= 1'b0;
                            sda_tri <= 1'b0;
                        end else if (read_cmd) begin
                            // Read operation: send address with R bit
                            state <= S_SEND_BIT;
                            bit_cnt <= 3'd7;
                            shift_out <= {cmd_addr, 1'b1};
                            scl_out <= 1'b1;
                            sda_out <= 1'b1;
                            scl_tri <= 1'b0;
                            sda_tri <= 1'b0;
                        end else if (write_cmd) begin
                            // Write operation: send address with W bit
                            state <= S_SEND_BIT;
                            bit_cnt <= 3'd7;
                            shift_out <= {cmd_addr, 1'b0};
                            scl_out <= 1'b1;
                            sda_out <= 1'b1;
                            scl_tri <= 1'b0;
                            sda_tri <= 1'b0;
                        end else if (write_multi_cmd) begin
                            // Write multiple: send address with W bit
                            state <= S_SEND_BIT;
                            bit_cnt <= 3'd7;
                            shift_out <= {cmd_addr, 1'b0};
                            scl_out <= 1'b1;
                            sda_out <= 1'b1;
                            scl_tri <= 1'b0;
                            sda_tri <= 1'b0;
                        end
                    end
                end

                S_START: begin
                    // START: SCL high, SDA high -> SCL high, SDA low
                    if (timer_done) begin
                        sda_out <= 1'b0;
                        state <= S_SEND_BIT;
                        bit_cnt <= 3'd7;
                        if (read_cmd) begin
                            shift_out <= {cmd_addr, 1'b1};
                        end else begin
                            shift_out <= {cmd_addr, 1'b0};
                        end
                    end
                end

                S_SEND_BIT: begin
                    // Send one bit
                    if (timer_done) begin
                        if (bit_cnt == 3'd0) begin
                            // All bits sent, wait for ACK
                            state <= S_ACK;
                            bit_cnt <= 3'd0;
                            scl_out <= 1'b1;
                            sda_out <= 1'b1;
                            scl_tri <= 1'b0;
                            sda_tri <= 1'b1; // Release SDA for ACK
                        end else begin
                            // Drive SDA with current bit
                            sda_out <= shift_out[7];
                            sda_tri <= 1'b0;
                            scl_out <= 1'b0;
                            scl_tri <= 1'b0;
                            bit_cnt <= bit_cnt - 3'd1;
                            shift_out <= {shift_out[6:0], 1'b0};
                        end
                    end
                end

                S_ACK: begin
                    // Wait for ACK from slave
                    if (timer_done) begin
                        ack_received <= ~sda_i; // ACK is SDA low
                        if (sda_i) begin
                            ack_missed <= 1'b1;
                        end
                        state <= S_DONE;
                        scl_out <= 1'b1;
                        sda_out <= 1'b1;
                        scl_tri <= 1'b1;
                        sda_tri <= 1'b1;
                    end
                end

                S_RECV_BIT: begin
                    // Receive one bit
                    if (timer_done) begin
                        if (bit_cnt == 3'd0) begin
                            // All bits received, send ACK/NACK
                            state <= S_ACK;
                            bit_cnt <= 3'd0;
                            scl_out <= 1'b1;
                            sda_out <= 1'b0; // ACK
                            scl_tri <= 1'b0;
                            sda_tri <= 1'b0;
                        end else begin
                            // Sample SDA
                            shift_in <= {shift_in[6:0], sda_i};
                            scl_out <= 1'b0;
                            scl_tri <= 1'b0;
                            sda_tri <= 1'b1; // Release SDA
                            bit_cnt <= bit_cnt - 3'd1;
                        end
                    end
                end

                S_STOP: begin
                    // STOP: SCL low, SDA low -> SCL high, SDA high
                    if (timer_done) begin
                        sda_out <= 1'b1;
                        state <= S_DONE;
                        scl_out <= 1'b1;
                        sda_out <= 1'b1;
                        scl_tri <= 1'b1;
                        sda_tri <= 1'b1;
                    end
                end

                S_DONE: begin
                    scl_out <= 1'b1;
                    sda_out <= 1'b1;
                    scl_tri <= 1'b1;
                    sda_tri <= 1'b1;
                    data_valid <= 1'b0;
                    data_last <= 1'b0;
                    
                    if (timer_done) begin
                        state <= S_IDLE;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            end
        end
    end

endmodule
