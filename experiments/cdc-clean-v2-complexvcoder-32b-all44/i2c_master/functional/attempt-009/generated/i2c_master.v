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

    /*
     * Internal signals
     */
    reg [8:0]          cmd_reg;
    reg                cmd_valid_reg;
    reg                cmd_ready_reg;
    reg [7:0]          data_reg;
    reg                data_valid_reg;
    reg                data_ready_reg;
    reg [7:0]          m_data_reg;
    reg                m_data_valid_reg;
    reg                m_data_tlast_reg;
    reg                scl_reg;
    reg                sda_reg;
    reg                busy_reg;
    reg                bus_control_reg;
    reg                bus_active_reg;
    reg                missed_ack_reg;
    reg [2:0]          bit_counter;
    reg [7:0]          byte_counter;
    reg [3:0]          state;
    reg [3:0]          next_state;
    reg [15:0]         timer;
    reg                timer_reset;
    reg                timer_tick;
    reg                scl_drive;
    reg                sda_drive;
    reg                scl_open;
    reg                sda_open;
    reg                ack;
    reg                start;
    reg                stop;
    reg                read;
    reg                write;
    reg                write_multiple;

    /*
     * State definitions
     */
    parameter IDLE        = 4'b0000;
    parameter START       = 4'b0001;
    parameter ADDRESS     = 4'b0010;
    parameter DATA        = 4'b0011;
    parameter STOP        = 4'b0100;
    parameter ERROR       = 4'b0101;

    /*
     * Timer logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            timer <= 16'd0;
        end else if (timer_reset) begin
            timer <= prescale;
        end else if (timer_tick && timer > 0) begin
            timer <= timer - 1;
        end
    end

    assign timer_tick = (timer == 16'd0) && (prescale > 0);

    /*
     * Command and data interface logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_reg <= 9'd0;
            cmd_valid_reg <= 1'b0;
            cmd_ready_reg <= 1'b0;
            data_reg <= 8'd0;
            data_valid_reg <= 1'b0;
            data_ready_reg <= 1'b0;
            m_data_reg <= 8'd0;
            m_data_valid_reg <= 1'b0;
            m_data_tlast_reg <= 1'b0;
        end else begin
            cmd_ready_reg <= ~cmd_valid_reg;
            data_ready_reg <= ~data_valid_reg;

            if (s_axis_cmd_valid && cmd_ready_reg) begin
                cmd_reg[7:1] <= {s_axis_cmd_address, s_axis_cmd_start};
                cmd_reg[0] <= s_axis_cmd_read;
                cmd_valid_reg <= 1'b1;
            end else if (next_state == IDLE) begin
                cmd_valid_reg <= 1'b0;
            end

            if (s_axis_data_tvalid && data_ready_reg) begin
                data_reg <= s_axis_data_tdata;
                data_valid_reg <= 1'b1;
            end else if (next_state == IDLE) begin
                data_valid_reg <= 1'b0;
            end

            if (m_axis_data_tready && m_data_valid_reg) begin
                m_data_valid_reg <= 1'b0;
            end else if (state == DATA && read) begin
                m_data_reg <= {sda_i, sda_reg, sda_reg, sda_reg, sda_reg, sda_reg, sda_reg, sda_reg};
                m_data_valid_reg <= 1'b1;
                m_data_tlast_reg <= s_axis_data_tlast;
            end
        end
    end

    /*
     * State machine
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        timer_reset = 1'b0;
        start = 1'b0;
        stop = 1'b0;
        read = 1'b0;
        write = 1'b0;
        write_multiple = 1'b0;
        scl_drive = 1'b0;
        sda_drive = 1'b0;
        scl_open = 1'b1;
        sda_open = 1'b1;
        ack = 1'b0;

        case (state)
            IDLE: begin
                timer_reset = 1'b1;
                if (cmd_valid_reg) begin
                    start = 1'b1;
                    next_state = START;
                end
            end
            START: begin
                scl_drive = 1'b0;
                sda_drive = 1'b0;
                scl_open = 1'b0;
                sda_open = 1'b0;
                if (timer_tick) begin
                    next_state = ADDRESS;
                end
            end
            ADDRESS: begin
                scl_drive = 1'b0;
                sda_drive = cmd_reg[8 - bit_counter];
                scl_open = 1'b0;
                sda_open = 1'b0;
                if (timer_tick) begin
                    if (bit_counter == 3'd7) begin
                        next_state = ADDRESS_ACK;
                    end else begin
                        bit_counter <= bit_counter + 1;
                    end
                end
            end
            ADDRESS_ACK: begin
                scl_drive = 1'b1;
                sda_open = 1'b1;
                if (timer_tick) begin
                    ack = sda_i;
                    if (ack) begin
                        next_state = ERROR;
                    end else begin
                        next_state = DATA;
                        byte_counter <= 8'd0;
                    end
                end
            end
            DATA: begin
                scl_drive = 1'b0;
                if (read) begin
                    sda_open = 1'b1;
                end else begin
                    sda_drive = data_reg[7 - bit_counter];
                end
                scl_open = 1'b0;
                if (timer_tick) begin
                    if (bit_counter == 3'd7) begin
                        next_state = DATA_ACK;
                    end else begin
                        bit_counter <= bit_counter + 1;
                    end
                end
            end
            DATA_ACK: begin
                scl_drive = 1'b1;
                if (read) begin
                    sda_open = 1'b1;
                end else begin
                    sda_drive = 1'b1;
                end
                if (timer_tick) begin
                    if (read) begin
                        ack = sda_i;
                    end else begin
                        ack = 1'b1;
                    end
                    if (!ack) begin
                        next_state = ERROR;
                    end else begin
                        if (s_axis_data_tlast && !write_multiple) begin
                            next_state = STOP;
                        end else begin
                            byte_counter <= byte_counter + 1;
                            next_state = DATA;
                        end
                    end
                end
            end
            STOP: begin
                scl_drive = 1'b0;
                sda_drive = 1'b0;
                scl_open = 1'b0;
                sda_open = 1'b0;
                if (timer_tick) begin
                    scl_drive = 1'b1;
                    sda_open = 1'b1;
                    if (timer_tick) begin
                        next_state = IDLE;
                    end
                end
            end
            ERROR: begin
                scl_drive = 1'b1;
                sda_drive = 1'b1;
                scl_open = 1'b1;
                sda_open = 1'b1;
                next_state = IDLE;
            end
        endcase
    end

    /*
     * Output assignments
     */
    assign s_axis_cmd_ready = cmd_ready_reg;
    assign s_axis_data_tready = data_ready_reg;
    assign m_axis_data_tdata = m_data_reg;
    assign m_axis_data_tvalid = m_data_valid_reg;
    assign m_axis_data_tlast = m_data_tlast_reg;
    assign scl_o = scl_drive;
    assign scl_t = scl_open;
    assign sda_o = sda_drive;
    assign sda_t = sda_open;
    assign busy = (state != IDLE);
    assign bus_control = (state != IDLE);
    assign bus_active = (state != IDLE);
    assign missed_ack = (state == ERROR);

endmodule
