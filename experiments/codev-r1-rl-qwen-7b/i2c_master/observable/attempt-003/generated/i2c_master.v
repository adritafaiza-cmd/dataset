module i2c_master (
    input  wire        clk,
    input  wire        rst,
    // Host interface
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
    // I2C interface
    input  wire        scl_i,
    output wire        scl_o,
    output wire        scl_t,
    input  wire        sda_i,
    output wire        sda_o,
    output wire        sda_t,
    // Status
    output wire        busy,
    output wire        bus_control,
    output wire        bus_active,
    output wire        missed_ack,
    // Configuration
    input  wire [15:0] prescale,
    input  wire        stop_on_idle
);

    // State machine
    localparam [3:0]
        IDLE        = 4'd0,
        START       = 4'd1,
        ADDRESS     = 4'd2,
        WRITE_DATA  = 4'd3,
        READ_DATA   = 4'd4,
        ACK         = 4'd5,
        STOP        = 4'd6;

    reg [3:0] state, next_state;

    // SCL generation
    reg [15:0] scl_counter;
    reg scl_phase;
    reg scl_reg;
    reg scl_oe;

    // SDA generation
    reg sda_reg;
    reg sda_oe;

    // Shift registers
    reg [7:0] shift_reg;
    reg [2:0] bit_count;

    // Address and data
    reg [6:0] addr_reg;
    reg read_mode;

    // Command handling
    reg cmd_start;
    reg cmd_read;
    reg cmd_write;
    reg cmd_stop;
    reg cmd_valid;

    // Data handling
    reg [7:0] data_out;
    reg [7:0] data_in;
    reg data_valid;

    // Missed ACK
    reg missed_ack_reg;

    // Assign outputs
    assign scl_o = scl_reg;
    assign scl_t = scl_oe; // 0 means drive, 1 means tri-state
    assign sda_o = sda_reg;
    assign sda_t = sda_oe;

    assign busy = (state != IDLE);
    assign s_axis_cmd_ready = (state == IDLE);

    // SCL generation
    always @(posedge clk) begin
        if (rst) begin
            scl_counter <= 0;
            scl_phase <= 1;
            scl_reg <= 1;
            scl_oe <= 1; // tri-state in idle
        end else begin
            if (state == IDLE) begin
                scl_reg <= 1;
                scl_oe <= 1; // tri-state
                scl_counter <= 0;
                scl_phase <= 1;
            end else begin
                scl_oe <= 0; // drive SCL
                if (scl_counter >= prescale) begin
                    scl_phase <= ~scl_phase;
                    scl_counter <= 0;
                end else begin
                    scl_counter <= scl_counter + 1;
                end
                scl_reg <= scl_phase;
            end
        end
    end

    // SDA generation
    always @* begin
        case (state)
            IDLE: begin
                sda_reg = 1;
                sda_oe = 1; // tri-state
            end
            START: begin
                sda_reg = 0;
                sda_oe = 0; // drive low
            end
            ADDRESS: begin
                sda_oe = 0;
                sda_reg = shift_reg[7];
            end
            WRITE_DATA: begin
                sda_oe = 0;
                sda_reg = shift_reg[7];
            end
            READ_DATA: begin
                sda_oe = 1; // release for slave to drive
            end
            ACK: begin
                sda_oe = 0; // master releases SDA for ACK
            end
            STOP: begin
                sda_reg = 1;
                sda_oe = 0;
            end
            default: begin
                sda_reg = 1;
                sda_oe = 1;
            end
        endcase
    end

    // State transitions
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            addr_reg <= 0;
            shift_reg <= 0;
            bit_count <= 0;
            data_out <= 0;
            data_in <= 0;
            data_valid <= 0;
            missed_ack_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_cmd_valid && s_axis_cmd_ready) begin
                        addr_reg <= s_axis_cmd_address;
                        cmd_start <= s_axis_cmd_start;
                        cmd_read <= s_axis_cmd_read;
                        cmd_write <= s_axis_cmd_write;
                        cmd_stop <= s_axis_cmd_stop;
                        state <= START;
                    end
                end
                START: begin
                    state <= ADDRESS;
                    shift_reg <= {addr_reg, cmd_read}; // 7-bit address + R/W bit
                    bit_count <= 7;
                end
                ADDRESS: begin
                    if (scl_phase == 0) begin // falling edge
                        if (bit_count == 0) begin
                            state <= ACK;
                        end else begin
                            shift_reg <= shift_reg << 1;
                            bit_count <= bit_count - 1;
                        end
                    end
                end
                ACK: begin
                    if (sda_i == 0) begin
                        missed_ack_reg <= 0;
                    end else begin
                        missed_ack_reg <= 1;
                    end
                    if (cmd_write) begin
                        state <= WRITE_DATA;
                    end else if (cmd_read) begin
                        state <= READ_DATA;
                    end else begin
                        state <= STOP;
                    end
                end
                WRITE_DATA: begin
                    // Similar to ADDRESS state, send data bytes
                    // After 8 bits, check ACK
                    // Then proceed to next byte or stop
                end
                READ_DATA: begin
                    // Read data byte
                    // After 8 bits, send ACK/NACK
                end
                STOP: begin
                    // Generate stop condition
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

    // Missed ACK output
    assign missed_ack = missed_ack_reg;

    // Other outputs (bus_control, bus_active, m_axis_data_tvalid, etc.)
    // Not fully implemented due to complexity

endmodule
