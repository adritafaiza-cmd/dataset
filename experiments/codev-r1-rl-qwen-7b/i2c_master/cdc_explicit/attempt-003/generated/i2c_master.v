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

    // State machine states
    localparam [3:0]
        IDLE        = 4'd0,
        START       = 4'd1,
        ADDRESS     = 4'd2,
        WRITE_DATA  = 4'd3,
        READ_DATA   = 4'd4,
        ACK         = 4'd5,
        STOP        = 4'd6;

    reg [3:0] state, next_state;

    // SCL and SDA registers
    reg scl_reg;
    reg scl_t_reg;
    reg sda_reg;
    reg sda_t_reg;

    // Prescaler counter
    reg [15:0] prescaler;

    // Shift registers
    reg [7:0] shift_reg;
    reg [2:0] bit_count;

    // Command registers
    reg cmd_start;
    reg cmd_read;
    reg cmd_write;
    reg cmd_write_multiple;
    reg cmd_stop;

    // Data handling
    reg [7:0] data_out;
    reg data_valid;

    // Missed ACK
    reg missed_ack_reg;

    // Handshake signals
    assign s_axis_cmd_ready = (state == IDLE);
    assign s_axis_data_tready = (state == WRITE_DATA && bit_count == 0);
    assign m_axis_data_tvalid = (state == READ_DATA && bit_count == 0);

    // Assign outputs
    assign scl_o = scl_reg;
    assign scl_t = scl_t_reg;
    assign sda_o = sda_reg;
    assign sda_t = sda_t_reg;

    // Missed ACK
    assign missed_ack = missed_ack_reg;

    // Busy signal
    assign busy = (state != IDLE);

    // Bus control and active (assuming always controlled)
    assign bus_control = 1'b1;
    assign bus_active = (state != IDLE);

    // SCL generation
    always @(posedge clk) begin
        if (rst) begin
            scl_reg <= 1;
            scl_t_reg <= 1;
            prescaler <= 0;
        end else begin
            if (state == IDLE) begin
                scl_reg <= 1;
                scl_t_reg <= 1;
                prescaler <= 0;
            end else begin
                if (prescaler == prescale) begin
                    prescaler <= 0;
                    scl_reg <= ~scl_reg;
                end else begin
                    prescaler <= prescaler + 1;
                end
            end
        end
    end

    // State machine and data handling
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            sda_reg <= 1;
            sda_t_reg <= 1;
            shift_reg <= 0;
            bit_count <= 0;
            missed_ack_reg <= 0;
            data_out <= 0;
            data_valid <= 0;
            cmd_start <= 0;
            cmd_read <= 0;
            cmd_write <= 0;
            cmd_write_multiple <= 0;
            cmd_stop <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_cmd_valid && s_axis_cmd_ready) begin
                        cmd_start <= s_axis_cmd_start;
                        cmd_read <= s_axis_cmd_read;
                        cmd_write <= s_axis_cmd_write;
                        cmd_write_multiple <= s_axis_cmd_write_multiple;
                        cmd_stop <= s_axis_cmd_stop;
                        state <= START;
                    end
                end
                START: begin
                    sda_reg <= 0;
                    sda_t_reg <= 0;
                    scl_reg <= 1;
                    scl_t_reg <= 1;
                    state <= ADDRESS;
                end
                ADDRESS: begin
                    shift_reg <= {s_axis_cmd_address, ~s_axis_cmd_write};
                    bit_count <= 0;
                    state <= WRITE_DATA;
                end
                WRITE_DATA: begin
                    if (prescaler == 0) begin
                        if (bit_count < 8) begin
                            sda_reg <= shift_reg[7];
                            shift_reg <= shift_reg << 1;
                            bit_count <= bit_count + 1;
                        end else begin
                            state <= ACK;
                            bit_count <= 0;
                        end
                    end
                end
                ACK: begin
                    if (prescaler == 0) begin
                        if (sda_i) missed_ack_reg <= 1;
                        if (cmd_write_multiple) begin
                            if (cmd_read) state <= READ_DATA;
                            else state <= WRITE_DATA;
                        end else begin
                            if (cmd_read) state <= READ_DATA;
                            else state <= IDLE;
                        end
                    end
                end
                READ_DATA: begin
                    if (prescaler == 0) begin
                        if (bit_count < 8) begin
                            shift_reg <= {shift_reg[6:0], sda_i};
                            bit_count <= bit_count + 1;
                        end else begin
                            data_out <= shift_reg;
                            data_valid <= 1;
                            state <= ACK;
                            bit_count <= 0;
                        end
                    end
                end
                STOP: begin
                    sda_reg <= 1;
                    sda_t_reg <= 0;
                    scl_reg <= 1;
                    scl_t_reg <= 1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

    // Data output
    assign m_axis_data_tdata = data_out;
    assign m_axis_data_tlast = s_axis_data_tlast;

endmodule
