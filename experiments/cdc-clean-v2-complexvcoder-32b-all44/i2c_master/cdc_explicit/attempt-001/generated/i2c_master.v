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

    // States
    localparam IDLE = 4'b0000;
    localparam START = 4'b0001;
    localparam ADDR = 4'b0010;
    localparam RADDR = 4'b0011;
    localparam WRITE = 4'b0100;
    localparam READ = 4'b0101;
    localparam STOP = 4'b0110;
    localparam ACK = 4'b0111;
    localparam NACK = 4'b1000;

    // Internal signals
    reg [3:0] state, next_state;
    reg [2:0] bit_counter;
    reg [7:0] byte_counter;
    reg [7:0] data_shift_reg;
    reg ack_received;
    reg scl_reg, sda_reg;
    reg scl_out, sda_out;
    reg scl_tri, sda_tri;
    reg [10:0] cmd_buffer;
    reg [7:0] data_buffer;
    reg [15:0] prescale_counter;
    reg cmd_ready, data_ready, data_valid, data_last;
    reg busy_reg, bus_control_reg, bus_active_reg, missed_ack_reg;

    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            bit_counter <= 3'b000;
            byte_counter <= 8'b00000000;
            data_shift_reg <= 8'b00000000;
            ack_received <= 1'b0;
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            scl_out <= 1'b1;
            sda_out <= 1'b1;
            scl_tri <= 1'b1;
            sda_tri <= 1'b1;
            cmd_buffer <= 11'b00000000000;
            data_buffer <= 8'b00000000;
            prescale_counter <= 16'b0000000000000000;
            cmd_ready <= 1'b0;
            data_ready <= 1'b0;
            data_valid <= 1'b0;
            data_last <= 1'b0;
            busy_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            missed_ack_reg <= 1'b0;
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    if (s_axis_cmd_valid && !busy_reg) begin
                        cmd_buffer <= {s_axis_cmd_address, s_axis_cmd_start, s_axis_cmd_read, s_axis_cmd_write, s_axis_cmd_write_multiple, s_axis_cmd_stop};
                        cmd_ready <= 1'b1;
                        busy_reg <= 1'b1;
                    end
                end
                START: begin
                    scl_reg <= 1'b0;
                    sda_reg <= 1'b0;
                    next_state <= ADDR;
                end
                ADDR: begin
                    if (bit_counter < 3'b111) begin
                        bit_counter <= bit_counter + 1'b1;
                        sda_reg <= cmd_buffer[10 - bit_counter];
                    end else begin
                        bit_counter <= 3'b000;
                        next_state <= ACK;
                    end
                end
                RADDR: begin
                    sda_reg <= 1'b1;
                    if (bit_counter < 3'b111) begin
                        bit_counter <= bit_counter + 1'b1;
                        data_buffer[7 - bit_counter] <= sda_i;
                    end else begin
                        bit_counter <= 3'b000;
                        next_state <= ACK;
                    end
                end
                WRITE: begin
                    if (bit_counter < 3'b111) begin
                        bit_counter <= bit_counter + 1'b1;
                        sda_reg <= data_shift_reg[7 - bit_counter];
                    end else begin
                        bit_counter <= 3'b000;
                        next_state <= ACK;
                    end
                end
                READ: begin
                    sda_reg <= 1'b1;
                    if (bit_counter < 3'b111) begin
                        bit_counter <= bit_counter + 1'b1;
                        data_buffer[7 - bit_counter] <= sda_i;
                    end else begin
                        bit_counter <= 3'b000;
                        next_state <= NACK;
                    end
                end
                STOP: begin
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b0;
                    next_state <= IDLE;
                end
                ACK: begin
                    if (scl_i) begin
                        ack_received <= !sda_i;
                        if (cmd_buffer[5]) begin // write
                            next_state <= WRITE;
                        end else if (cmd_buffer[4]) begin // read
                            next_state <= READ;
                        end else begin
                            next_state <= STOP;
                        end
                    end
                end
                NACK: begin
                    if (scl_i) begin
                        sda_reg <= 1'b1;
                        next_state <= STOP;
                    end
                end
                default: begin
                    next_state <= IDLE;
                end
            endcase

            // Prescale counter
            if (prescale_counter < prescale - 1) begin
                prescale_counter <= prescale_counter + 1'b1;
            end else begin
                prescale_counter <= 16'b0000000000000000;
                scl_reg <= ~scl_reg;
            end

            // Output control
            scl_out <= scl_reg;
            sda_out <= sda_reg;
            scl_tri <= 1'b0;
            sda_tri <= 1'b0;

            // Command and data interface
            if (cmd_ready && !s_axis_cmd_valid) begin
                cmd_ready <= 1'b0;
            end

            if (data_ready && m_axis_data_tready) begin
                data_ready <= 1'b0;
                data_valid <= 1'b0;
                data_last <= 1'b0;
            end

            // Bus control and status
            busy_reg <= (state != IDLE) || (cmd_ready && s_axis_cmd_valid);
            bus_control_reg <= (state == START) || (state == ADDR) || (state == RADDR) || (state == WRITE) || (state == READ) || (state == ACK) || (state == NACK);
            bus_active_reg <= (state == ADDR) || (state == RADDR) || (state == WRITE) || (state == READ);
            missed_ack_reg <= (state == ACK) && !ack_received;
        end
    end

    // Outputs
    assign s_axis_cmd_ready = cmd_ready;
    assign s_axis_data_tready = data_ready;
    assign m_axis_data_tdata = data_buffer;
    assign m_axis_data_tvalid = data_valid;
    assign m_axis_data_tlast = data_last;
    assign scl_o = scl_out;
    assign scl_t = scl_tri;
    assign sda_o = sda_out;
    assign sda_t = sda_tri;
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;

endmodule
