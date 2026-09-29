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

    // SCL generation
    reg [15:0] prescaler;
    reg scl_phase;
    reg scl_out;

    // SDA handling
    reg sda_out;
    reg sda_en;

    // Data registers
    reg [7:0] data_reg;
    reg [2:0] bit_count;

    // Command registers
    reg cmd_start_reg;
    reg cmd_read_reg;
    reg cmd_write_reg;
    reg cmd_write_multiple_reg;
    reg cmd_stop_reg;

    // Missed ACK
    reg missed_ack_reg;

    // Handshakes
    assign s_axis_cmd_ready = (state == IDLE);
    assign s_axis_data_tready = (state == WRITE_DATA && bit_count == 0);
    assign m_axis_data_tvalid = (state == READ_DATA && bit_count == 0);

    // SCL outputs
    assign scl_o = scl_out;
    assign scl_t = (scl_out == 0) ? 1 : 0;

    // SDA outputs
    assign sda_o = sda_out;
    assign sda_t = sda_en;

    // Busy signal
    assign busy = (state != IDLE);

    // Missed ACK
    assign missed_ack = missed_ack_reg;

    // SCL generation
    always @(posedge clk) begin
        if (rst) begin
            prescaler <= 0;
            scl_phase <= 0;
            scl_out <= 1;
        end else if (state != IDLE) begin
            if (prescaler >= prescale) begin
                prescaler <= 0;
                scl_phase <= ~scl_phase;
                scl_out <= scl_phase;
            end else begin
                prescaler <= prescaler + 1;
            end
        end else begin
            prescaler <= 0;
            scl_out <= 1;
            scl_phase <= 0;
        end
    end

    // State machine
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            cmd_start_reg <= 0;
            cmd_read_reg <= 0;
            cmd_write_reg <= 0;
            cmd_write_multiple_reg <= 0;
            cmd_stop_reg <= 0;
            data_reg <= 0;
            bit_count <= 0;
            sda_out <= 1;
            sda_en <= 1;
            missed_ack_reg <= 0;
        end else begin
            state <= next_state;
            if (s_axis_cmd_valid && s_axis_cmd_ready) begin
                cmd_start_reg <= s_axis_cmd_start;
                cmd_read_reg <= s_axis_cmd_read;
                cmd_write_reg <= s_axis_cmd_write;
                cmd_write_multiple_reg <= s_axis_cmd_write_multiple;
                cmd_stop_reg <= s_axis_cmd_stop;
            end
            if (state == ADDRESS) begin
                data_reg <= {s_axis_cmd_address, s_axis_cmd_read};
                bit_count <= 7;
            end else if (state == WRITE_DATA) begin
                if (s_axis_data_tvalid && s_axis_data_tready) begin
                    data_reg <= s_axis_data_tdata;
                    bit_count <= 7;
                end
            end else if (state == READ_DATA) begin
                if (bit_count == 0 && m_axis_data_tready) begin
                    bit_count <= 7;
                end
            end else if (state == ACK) begin
                missed_ack_reg <= ~sda_i;
            end
            if (state == START) begin
                sda_out <= 0;
                sda_en <= 1;
            end else if (state == STOP) begin
                sda_out <= 1;
                sda_en <= 1;
            end else if (scl_phase && (state == ADDRESS || state == WRITE_DATA)) begin
                sda_out <= data_reg[bit_count];
                sda_en <= 1;
                bit_count <= bit_count - 1;
            end else if (scl_phase && state == READ_DATA) begin
                data_reg <= {data_reg[6:0], sda_i};
                bit_count <= bit_count - 1;
            end
        end
    end

    // Next state logic
    always @* begin
        next_state = state;
        case (state)
            IDLE: begin
                if (cmd_start_reg) next_state = START;
                else if (cmd_write_reg || cmd_read_reg) next_state = ADDRESS;
                else if (cmd_stop_reg) next_state = STOP;
            end
            START: next_state = ADDRESS;
            ADDRESS: next_state = ACK;
            ACK: next_state = (cmd_write_reg || cmd_read_reg) ? (cmd_write_reg ? WRITE_DATA : READ_DATA) : IDLE;
            WRITE_DATA: begin
                if (bit_count == 0 && s_axis_data_tlast) next_state = (cmd_write_multiple_reg ? WRITE_DATA : IDLE);
                else if (bit_count == 0) next_state = ACK;
                else next_state = WRITE_DATA;
            end
            READ_DATA: begin
                if (bit_count == 0) next_state = ACK;
                else next_state = READ_DATA;
            end
            ACK: next_state = (cmd_stop_reg) ? STOP : IDLE;
            STOP: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Data outputs
    assign m_axis_data_tdata = data_reg;
    assign m_axis_data_tlast = (bit_count == 0);

endmodule
