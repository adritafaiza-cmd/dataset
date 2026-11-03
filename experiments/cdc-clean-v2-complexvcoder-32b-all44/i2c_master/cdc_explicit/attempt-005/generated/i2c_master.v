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
     * Internal Signals
     */
    reg [6:0]          cmd_address;
    reg                cmd_start;
    reg                cmd_read;
    reg                cmd_write;
    reg                cmd_write_multiple;
    reg                cmd_stop;
    reg                cmd_valid;
    reg                cmd_ready;
    reg [7:0]          data_tdata;
    reg                data_tvalid;
    reg                data_tready;
    reg                data_tlast;
    reg [7:0]          data_out_tdata;
    reg                data_out_tvalid;
    reg                data_out_tready;
    reg                data_out_tlast;
    reg                scl_out;
    reg                scl_tristate;
    reg                sda_out;
    reg                sda_tristate;
    reg                busy_flag;
    reg                bus_control_flag;
    reg                bus_active_flag;
    reg                missed_ack_flag;
    reg [15:0]         prescale_value;
    reg                stop_on_idle_flag;
    reg [2:0]          bit_counter;
    reg [7:0]          byte_counter;
    reg [3:0]          state;
    reg [3:0]          next_state;
    reg [15:0]         timer;
    reg                start_condition;
    reg                stop_condition;
    reg                read_bit;
    reg                write_bit;
    reg                ack_bit;
    reg [7:0]          shift_register;

    /*
     * State Definitions
     */
    localparam IDLE = 4'b0000;
    localparam START = 4'b0001;
    localparam ADDR = 4'b0010;
    localparam R_W = 4'b0011;
    localparam ACK_ADDR = 4'b0100;
    localparam WRITE_DATA = 4'b0101;
    localparam ACK_WRITE = 4'b0110;
    localparam READ_DATA = 4'b0111;
    localparam ACK_READ = 4'b1000;
    localparam STOP = 4'b1001;

    /*
     * Command Handling
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_ready <= 0;
            cmd_address <= 0;
            cmd_start <= 0;
            cmd_read <= 0;
            cmd_write <= 0;
            cmd_write_multiple <= 0;
            cmd_stop <= 0;
            cmd_valid <= 0;
        end else begin
            if (cmd_ready && s_axis_cmd_valid) begin
                cmd_address <= s_axis_cmd_address;
                cmd_start <= s_axis_cmd_start;
                cmd_read <= s_axis_cmd_read;
                cmd_write <= s_axis_cmd_write;
                cmd_write_multiple <= s_axis_cmd_write_multiple;
                cmd_stop <= s_axis_cmd_stop;
                cmd_valid <= s_axis_cmd_valid;
            end
            cmd_ready <= !cmd_valid;
        end
    end

    /*
     * Data Handling
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_tready <= 0;
            data_tdata <= 0;
            data_tvalid <= 0;
            data_tlast <= 0;
        end else begin
            if (data_tready && s_axis_data_tvalid) begin
                data_tdata <= s_axis_data_tdata;
                data_tvalid <= s_axis_data_tvalid;
                data_tlast <= s_axis_data_tlast;
            end
            data_tready <= (state == WRITE_DATA) && !busy_flag;
        end
    end

    /*
     * Output Data Handling
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out_tready <= 0;
            data_out_tdata <= 0;
            data_out_tvalid <= 0;
            data_out_tlast <= 0;
        end else begin
            if (m_axis_data_tready && data_out_tvalid) begin
                data_out_tvalid <= 0;
            end else if (state == ACK_READ) begin
                data_out_tdata <= shift_register;
                data_out_tvalid <= 1;
                data_out_tlast <= read_bit;
            end
            data_out_tready <= m_axis_data_tready;
        end
    end

    /*
     * State Machine
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            busy_flag <= 0;
            bus_control_flag <= 0;
            bus_active_flag <= 0;
            missed_ack_flag <= 0;
            timer <= 0;
            bit_counter <= 0;
            byte_counter <= 0;
            shift_register <= 0;
            scl_out <= 1;
            scl_tristate <= 1;
            sda_out <= 1;
            sda_tristate <= 1;
            start_condition <= 0;
            stop_condition <= 0;
            read_bit <= 0;
            write_bit <= 0;
            ack_bit <= 0;
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    busy_flag <= 0;
                    bus_control_flag <= 0;
                    bus_active_flag <= 0;
                    missed_ack_flag <= 0;
                    timer <= 0;
                    bit_counter <= 0;
                    byte_counter <= 0;
                    shift_register <= 0;
                    scl_out <= 1;
                    scl_tristate <= 1;
                    sda_out <= 1;
                    sda_t <= 1;
                    start_condition <= 0;
                    stop_condition <= 0;
                    read_bit <= 0;
                    write_bit <= 0;
                    ack_bit <= 0;
                    if (cmd_valid && cmd_start) begin
                        next_state <= START;
                    end else begin
                        next_state <= IDLE;
                    end
                end
                START: begin
                    busy_flag <= 1;
                    bus_control_flag <= 1;
                    bus_active_flag <= 1;
                    timer <= prescale_value;
                    scl_out <= 1;
                    sda_out <= 0;
                    sda_t <= 0;
                    start_condition <= 1;
                    if (timer == 0) begin
                        next_state <= ADDR;
                    end else begin
                        timer <= timer - 1;
                        next_state <= START;
                    end
                end
                ADDR: begin
                    timer <= prescale_value;
                    bit_counter <= 3'b111;
                    shift_register <= {cmd_address, cmd_read};
                    scl_out <= 0;
                    sda_t <= 0;
                    write_bit <= shift_register[7];
                    if (timer == 0) begin
                        next_state <= R_W;
                    end else begin
                        timer <= timer - 1;
                        next_state <= ADDR;
                    end
                end
                R_W: begin
                    timer <= prescale_value;
                    scl_out <= 1;
                    if (timer == 0) begin
                        next_state <= ACK_ADDR;
                    end else begin
                        timer <= timer - 1;
                        next_state <= R_W;
                    end
                end
                ACK_ADDR: begin
                    timer <= prescale_value;
                    scl_out <= 0;
                    sda_t <= 1;
                    if (timer == 0) begin
                        ack_bit <= sda_i;
                        if (ack_bit) begin
                            missed_ack_flag <= 1;
                            next_state <= STOP;
                        end else begin
                            if (cmd_read) begin
                                next_state <= READ_DATA;
                            end else if (cmd_write || cmd_write_multiple) begin
                                next_state <= WRITE_DATA;
                            end
                        end
                    end else begin
                        timer <= timer - 1;
                        next_state <= ACK_ADDR;
                    end
                end
                WRITE_DATA: begin
                    timer <= prescale_value;
                    bit_counter <= 3'b111;
                    shift_register <= data_tdata;
                    scl_out <= 0;
                    sda_t <= 0;
                    write_bit <= shift_register[7];
                    if (timer == 0) begin
                        next_state <= ACK_WRITE;
                    end else begin
                        timer <= timer - 1;
                        next_state <= WRITE_DATA;
                    end
                end
                ACK_WRITE: begin
                    timer <= prescale_value;
                    scl_out <= 1;
                    sda_t <= 1;
                    if (timer == 0) begin
                        ack_bit <= sda_i;
                        if (ack_bit) begin
                            missed_ack_flag <= 1;
                            next_state <= STOP;
                        end else begin
                            if (cmd_write_multiple && !data_tlast) begin
                                next_state <= WRITE_DATA;
                            end else begin
                                next_state <= STOP;
                            end
                        end
                    end else begin
                        timer <= timer - 1;
                        next_state <= ACK_WRITE;
                    end
                end
                READ_DATA: begin
                    timer <= prescale_value;
                    bit_counter <= 3'b111;
                    scl_out <= 0;
                    sda_t <= 1;
                    if (timer == 0) begin
                        read_bit <= sda_i;
                        shift_register <= {shift_register[6:0], read_bit};
                        next_state <= ACK_READ;
                    end else begin
                        timer <= timer - 1;
                        next_state <= READ_DATA;
                    end
                end
                ACK_READ: begin
                    timer <= prescale_value;
                    scl_out <= 1;
                    sda_t <= 0;
                    sda_out <= byte_counter == 8'h01;
                    if (timer == 0) begin
                        if (cmd_write_multiple && !data_tlast) begin
                            next_state <= READ_DATA;
                        end else begin
                            next_state <= STOP;
                        end
                    end else begin
                        timer <= timer - 1;
                        next_state <= ACK_READ;
                    end
                end
                STOP: begin
                    timer <= prescale_value;
                    scl_out <= 0;
                    sda_out <= 0;
                    sda_t <= 0;
                    stop_condition <= 1;
                    if (timer == 0) begin
                        scl_out <= 1;
                        sda_out <= 1;
                        sda_t <= 1;
                        next_state <= IDLE;
                    end else begin
                        timer <= timer - 1;
                        next_state <= STOP;
                    end
                end
                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

    /*
     * Bit Shifting
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_counter <= 0;
            byte_counter <= 0;
        end else begin
            if (state == ADDR || state == WRITE_DATA || state == READ_DATA) begin
                if (timer == 0) begin
                    if (bit_counter == 0) begin
                        bit_counter <= 3'b111;
                        byte_counter <= byte_counter + 8'd1;
                    end else begin
                        bit_counter <= bit_counter - 1;
                    end
                    shift_register <= shift_register << 1;
                end
            end
        end
    end

    /*
     * Output Assignments
     */
    assign s_axis_cmd_ready = cmd_ready;
    assign s_axis_data_tready = data_tready;
    assign m_axis_data_tdata = data_out_tdata;
    assign m_axis_data_tvalid = data_out_tvalid;
    assign m_axis_data_tlast = data_out_tlast;
    assign scl_o = scl_out;
    assign scl_t = scl_tristate;
    assign sda_o = sda_out;
    assign sda_t = sda_t;
    assign busy = busy_flag;
    assign bus_control = bus_control_flag;
    assign bus_active = bus_active_flag;
    assign missed_ack = missed_ack_flag;

endmodule
