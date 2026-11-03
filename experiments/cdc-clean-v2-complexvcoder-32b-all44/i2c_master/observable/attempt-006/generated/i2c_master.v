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

    // Internal signals
    reg [0:0] scl_reg;
    reg [0:0] sda_reg;
    reg [2:0] bit_count;
    reg [7:0] byte_count;
    reg [3:0] state;
    reg [3:0] next_state;
    reg [0:0] s_axis_cmd_ready_reg;
    reg [0:0] s_axis_data_tready_reg;
    reg [0:0] m_axis_data_tvalid_reg;
    reg [0:0] m_axis_data_tlast_reg;
    reg [0:0] busy_reg;
    reg [0:0] bus_control_reg;
    reg [0:0] bus_active_reg;
    reg [0:0] missed_ack_reg;
    reg [6:0] cmd_buffer;
    reg [7:0] data_buffer;
    reg [15:0] prescale_counter;

    // States
    parameter IDLE = 4'b0000;
    parameter START = 4'b0001;
    parameter ADDRESS = 4'b0010;
    parameter R_W_BIT = 4'b0011;
    parameter ACK1 = 4'b0100;
    parameter WRITE = 4'b0101;
    parameter ACK2 = 4'b0110;
    parameter READ = 4'b0111;
    parameter ACK3 = 4'b1000;
    parameter STOP = 4'b1001;

    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (s_axis_cmd_valid) begin
                    next_state = START;
                end
            end
            START: begin
                if (prescale_counter == 0) begin
                    next_state = ADDRESS;
                end
            end
            ADDRESS: begin
                if (bit_count == 7 && prescale_counter == 0) begin
                    next_state = R_W_BIT;
                end
            end
            R_W_BIT: begin
                if (prescale_counter == 0) begin
                    next_state = ACK1;
                end
            end
            ACK1: begin
                if (prescale_counter == 0) begin
                    if (sda_i) begin
                        next_state = IDLE;
                        missed_ack_reg = 1'b1;
                    end else if (s_axis_cmd_read) begin
                        next_state = READ;
                    end else if (s_axis_cmd_write) begin
                        next_state = WRITE;
                    end
                end
            end
            WRITE: begin
                if (bit_count == 7 && prescale_counter == 0) begin
                    next_state = ACK2;
                end
            end
            ACK2: begin
                if (prescale_counter == 0) begin
                    if (sda_i) begin
                        next_state = IDLE;
                        missed_ack_reg = 1'b1;
                    end else if (s_axis_data_tvalid && !s_axis_data_tlast) begin
                        next_state = WRITE;
                    end else if (s_axis_data_tvalid && s_axis_data_tlast) begin
                        if (s_axis_cmd_stop) begin
                            next_state = STOP;
                        end else begin
                            next_state = IDLE;
                        end
                    end
                end
            end
            READ: begin
                if (bit_count == 7 && prescale_counter == 0) begin
                    next_state = ACK3;
                end
            end
            ACK3: begin
                if (prescale_counter == 0) begin
                    if (byte_count == 0 && s_axis_cmd_stop) begin
                        next_state = STOP;
                    end else if (byte_count > 0) begin
                        next_state = READ;
                    end else begin
                        next_state = IDLE;
                    end
                end
            end
            STOP: begin
                if (prescale_counter == 0) begin
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Prescale counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prescale_counter <= 16'h0;
        end else if (prescale_counter == prescale) begin
            prescale_counter <= 16'h0;
        end else begin
            prescale_counter <= prescale_counter + 1'b1;
        end
    end

    // Command buffer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_buffer <= 7'b0;
        end else if (state == IDLE && s_axis_cmd_valid) begin
            cmd_buffer <= s_axis_cmd_address;
        end
    end

    // Byte count
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            byte_count <= 8'b0;
        end else if (state == IDLE && s_axis_cmd_valid) begin
            byte_count <= 8'b0;
        end else if (state == READ && bit_count == 7 && prescale_counter == 0) begin
            byte_count <= byte_count + 1'b1;
        end
    end

    // Bit count
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_count <= 3'b0;
        end else if (state == START || state == STOP) begin
            bit_count <= 3'b0;
        end else if (prescale_counter == 0) begin
            bit_count <= bit_count + 1'b1;
        end
    end

    // SDA and SCL control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            s_axis_cmd_ready_reg <= 1'b0;
            s_axis_data_tready_reg <= 1'b0;
            m_axis_data_tvalid_reg <= 1'b0;
            m_axis_data_tlast_reg <= 1'b0;
            busy_reg <= 1'b0;
            bus_control_reg <= 1'b0;
            bus_active_reg <= 1'b0;
            missed_ack_reg <= 1'b0;
            data_buffer <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b1;
                    s_axis_cmd_ready_reg <= 1'b1;
                    s_axis_data_tready_reg <= 1'b0;
                    m_axis_data_tvalid_reg <= 1'b0;
                    m_axis_data_tlast_reg <= 1'b0;
                    busy_reg <= 1'b0;
                    bus_control_reg <= 1'b0;
                    bus_active_reg <= 1'b0;
                    missed_ack_reg <= 1'b0;
                    if (s_axis_cmd_valid) begin
                        busy_reg <= 1'b1;
                        bus_control_reg <= 1'b1;
                        bus_active_reg <= 1'b1;
                        s_axis_cmd_ready_reg <= 1'b0;
                    end
                end
                START: begin
                    if (prescale_counter == 0) begin
                        if (bit_count == 0) begin
                            sda_reg <= 1'b0;
                        end else if (bit_count == 4) begin
                            scl_reg <= 1'b0;
                        end
                    end
                end
                ADDRESS: begin
                    if (prescale_counter == 0) begin
                        sda_reg <= cmd_buffer[6-bit_count];
                    end
                end
                R_W_BIT: begin
                    if (prescale_counter == 0) begin
                        sda_reg <= s_axis_cmd_read;
                    end
                end
                ACK1: begin
                    if (prescale_counter == 0) begin
                        scl_reg <= 1'b1;
                    end
                end
                WRITE: begin
                    if (prescale_counter == 0) begin
                        sda_reg <= s_axis_data_tdata[7-bit_count];
                    end
                end
                ACK2: begin
                    if (prescale_counter == 0) begin
                        scl_reg <= 1'b1;
                    end
                end
                READ: begin
                    if (prescale_counter == 0) begin
                        scl_reg <= 1'b1;
                    end else if (prescale_counter == prescale/2) begin
                        data_buffer[7-bit_count] <= sda_i;
                    end
                end
                ACK3: begin
                    if (prescale_counter == 0) begin
                        scl_reg <= 1'b1;
                        sda_reg <= (byte_count == 0 && s_axis_cmd_stop) ? 1'b1 : 1'b0;
                    end
                end
                STOP: begin
                    if (prescale_counter == 0) begin
                        if (bit_count == 0) begin
                            sda_reg <= 1'b0;
                        end else if (bit_count == 4) begin
                            scl_reg <= 1'b1;
                        end else if (bit_count == 8) begin
                            sda_reg <= 1'b1;
                            busy_reg <= 1'b0;
                            bus_control_reg <= 1'b0;
                            bus_active_reg <= 1'b0;
                        end
                    end
                end
                default: begin
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b1;
                end
            endcase

            // Output data
            if (state == READ && bit_count == 7 && prescale_counter == 0) begin
                m_axis_data_tdata <= data_buffer;
                m_axis_data_tvalid_reg <= 1'b1;
                m_axis_data_tlast_reg <= (byte_count == 0);
            end else if (state != READ) begin
                m_axis_data_tvalid_reg <= 1'b0;
                m_axis_data_tlast_reg <= 1'b0;
            end

            // Ready signals
            if (state == IDLE && s_axis_cmd_valid) begin
                s_axis_cmd_ready_reg <= 1'b0;
            end else if (state == WRITE && bit_count == 7 && prescale_counter == 0) begin
                s_axis_data_tready_reg <= 1'b1;
            end else begin
                s_axis_data_tready_reg <= 1'b0;
            end
        end
    end

    // Output assignments
    assign s_axis_cmd_ready = s_axis_cmd_ready_reg;
    assign s_axis_data_tready = s_axis_data_tready_reg;
    assign m_axis_data_tdata = m_axis_data_tdata;
    assign m_axis_data_tvalid = m_axis_data_tvalid_reg;
    assign m_axis_data_tlast = m_axis_data_tlast_reg;
    assign scl_o = scl_reg;
    assign scl_t = 1'b0; // Drive SCL as output
    assign sda_o = sda_reg;
    assign sda_t = 1'b0; // Drive SDA as output
    assign busy = busy_reg;
    assign bus_control = bus_control_reg;
    assign bus_active = bus_active_reg;
    assign missed_ack = missed_ack_reg;

endmodule
