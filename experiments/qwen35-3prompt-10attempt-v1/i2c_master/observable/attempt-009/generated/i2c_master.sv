```verilog
`timescale 1ns/1ps

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

    // Internal timing parameters
    localparam int unsigned SCL_PERIOD = 20; // Base period in clock cycles
    localparam int unsigned START_DELAY = 2;
    localparam int unsigned STOP_DELAY = 2;
    localparam int unsigned ACK_DELAY = 2;
    localparam int unsigned DATA_DELAY = 2;
    
    // State Machine States
    localparam int unsigned IDLE = 0;
    localparam int unsigned START = 1;
    localparam int unsigned START_SENT = 2;
    localparam int unsigned ADDRESS = 3;
    localparam int unsigned ADDRESS_ACK = 4;
    localparam int unsigned WRITE_CMD = 5;
    localparam int unsigned WRITE_CMD_ACK = 6;
    localparam int unsigned WRITE_DATA = 7;
    localparam int unsigned WRITE_DATA_ACK = 8;
    localparam int unsigned READ_CMD = 9;
    localparam int unsigned READ_CMD_ACK = 10;
    localparam int unsigned READ_DATA = 11;
    localparam int unsigned READ_DATA_ACK = 12;
    localparam int unsigned STOP = 13;
    localparam int unsigned STOP_SENT = 14;
    localparam int unsigned ERROR = 15;

    reg [3:0] state;
    reg [7:0] cmd_addr;
    reg        cmd_read;
    reg        cmd_write;
    reg        cmd_write_multiple;
    reg        cmd_stop;
    reg        cmd_valid;
    reg        cmd_ready;
    
    reg [7:0] tx_data;
    reg        tx_valid;
    reg        tx_last;
    reg        tx_ready;
    
    reg [7:0] rx_data;
    reg        rx_valid;
    reg        rx_ready;
    reg        rx_last;
    
    reg        busy;
    reg        bus_control;
    reg        bus_active;
    reg        missed_ack;
    
    reg [15:0] prescale_val;
    reg [7:0]  scl_count;
    reg        scl_edge;
    reg        sda_sample;
    reg        sda_edge;
    reg        scl_sample;
    reg        scl_edge_det;
    reg        sda_edge_det;
    reg        scl_high;
    reg        sda_high;
    
    reg [3:0]  state_timer;
    reg [7:0]  state_data;
    reg        state_data_valid;
    reg        state_data_ready;
    
    reg [7:0]  cmd_byte_count;
    reg [7:0]  cmd_byte_index;
    reg        cmd_done;
    
    reg [7:0]  rx_byte_count;
    reg [7:0]  rx_byte_index;
    reg        rx_done;

    // Timing configuration
    assign scl_t = scl_count < prescale_val[7:0] ? 1'b1 : 1'b0;
    assign scl_o = scl_t;
    assign sda_t = sda_sample;
    assign sda_o = sda_sample;

    // SCL Edge Detection
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_edge <= 1'b0;
            scl_high <= 1'b0;
        end else begin
            scl_edge <= scl_i;
            scl_high <= scl_i;
        end
    end

    // SDA Edge Detection
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sda_edge <= 1'b0;
            sda_high <= 1'b0;
        end else begin
            sda_edge <= sda_i;
            sda_high <= sda_i;
        end
    end

    // State Machine Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            busy <= 1'b0;
            bus_control <= 1'b0;
            bus_active <= 1'b0;
            missed_ack <= 1'b0;
            cmd_ready <= 1'b0;
            tx_ready <= 1'b0;
            rx_ready <= 1'b0;
            cmd_done <= 1'b0;
            rx_done <= 1'b0;
            cmd_byte_count <= 8'd0;
            cmd_byte_index <= 8'd0;
            rx_byte_count <= 8'd0;
            rx_byte_index <= 8'd0;
            scl_count <= 8'd0;
            state_timer <= 4'd0;
            state_data_valid <= 1'b0;
            state_data_ready <= 1'b0;
            tx_valid <= 1'b0;
            tx_last <= 1'b0;
            rx_valid <= 1'b0;
            rx_last <= 1'b0;
            sda_sample <= 1'b1;
            scl_sample <= 1'b1;
        end else begin
            // State transitions
            case (state)
                IDLE: begin
                    if (cmd_valid && !cmd_done) begin
                        state <= START;
                        busy <= 1'b1;
                        bus_control <= 1'b1;
                        bus_active <= 1'b1;
                        missed_ack <= 1'b0;
                        cmd_ready <= 1'b1;
                        tx_ready <= 1'b1;
                        rx_ready <= 1'b1;
                        cmd_addr <= s_axis_cmd_address;
                        cmd_read <= s_axis_cmd_read;
                        cmd_write <= s_axis_cmd_write;
                        cmd_write_multiple <= s_axis_cmd_write_multiple;
                        cmd_stop <= s_axis_cmd_stop;
                        cmd_byte_count <= (cmd_write || cmd_write_multiple) ? 8'd1 : 8'd0;
                        cmd_byte_index <= 8'd0;
                        rx_byte_count <= (cmd_read) ? 8'd1 : 8'd0;
                        rx_byte_index <= 8'd0;
                        scl_count <= 8'd0;
                        state_timer <= 4'd0;
                        state_data_valid <= 1'b0;
                        state_data_ready <= 1'b0;
                        tx_valid <= 1'b0;
                        tx_last <= 1'b0;
                        rx_valid <= 1'b0;
                        rx_last <= 1'b0;
                        sda_sample <= 1'b1;
                        scl_sample <= 1'b1;
                    end else begin
                        cmd_ready <= 1'b0;
                        tx_ready <= 1'b0;
                        rx_ready <= 1'b0;
                    end
                end

                START: begin
                    if (scl_high) begin
                        state <= START_SENT;
                        sda_sample <= 1'b0;
                        scl_count <= 8'd0;
                        state_timer <= 4'd0;
                        state_data_valid <= 1'b0;
                        state_data_ready <= 1'b0;
                        tx_valid <= 1'b0;
                        tx_last <= 1'b0;
                        rx_valid <= 1'b0;
                        rx_last <= 1'b0;
                    end
                end

                START_SENT: begin
                    if (scl_high) begin
                        state <= ADDRESS;
                        sda_sample <= 1'b1;
                        scl_count <= 8'd0;
                        state_timer <= 4'd0;
                        state_data_valid <= 1'b0;
                        state_data_ready <= 1'b0;
                        tx_valid <= 1'b0;
                        tx_last <= 1'b0;
                        rx_valid <= 1'b0;
                        rx_last <= 1'b0;
                    end
                end

                ADDRESS: begin
                    if (scl_high) begin
                        state <= ADDRESS_ACK;
                        sda_sample <= 1'b1;
                        scl_count <= 8'd0;
                        state_timer <= 4'd0;
                        state_data_valid <= 1'b0;
                        state_data_ready <= 1'b0;
                        tx_valid <= 1'b0;
                        tx_last <= 1'b0;
                        rx_valid <= 1'b0;
                        rx_last <= 1'b0;
                    end
                end

                ADDRESS_ACK: begin
                    if (scl_high) begin
                        if (sda_i == 1'b0) begin
                            state <= (cmd_read) ? READ_CMD : WRITE_CMD;
                            sda_sample <= 1'b1;
                            scl_count <= 8'd0;
                            state_timer <= 4'd0;
                            state_data_valid <= 1'b0;
                            state_data_ready <= 1'b0;
                            tx_valid <= 1'b0;
                            tx_last <= 1'b0;
                            rx_valid <= 1'b0;
                            rx_last <= 1'b0;
                        end else begin
                            state <= ERROR;
                            missed_ack <= 1'b1;
                            busy <= 1'b0;
                            bus_control <= 1'b0;
                            bus_active <= 1'b0;
                            cmd_ready <= 1'b0;
                            tx_ready <= 1'b0;
                            rx_ready <= 1'b0;
                        end
                    end
                end

                WRITE_CMD: begin
                    if (scl_high) begin
                        state <= WRITE_CMD_ACK;
                        sda_sample <= 1'b1;
                        scl_count <= 8'd0;
                        state_timer <= 4'd0;
                        state_data_valid <= 1'b0;
                        state_data_ready <= 1'b0;
                        tx_valid <= 1'b0;
                        tx_last <= 1'b0;
                        rx_valid <= 1'b0;
                        rx_last <= 1'b0;
                    end
                end

                WRITE_CMD_ACK: begin
                    if (scl_high) begin
                        if (sda_i == 1'b0) begin
                            state <= WRITE_DATA;
                            sda_sample <= 1'b1;
                            scl_count <= 8'd0;
                            state_timer <= 4'd0;
                            state_data_valid <= 1'b0;
                            state_data_ready <= 1'b0;
                            tx_valid <= 1'b0;
                            tx_last <= 1'b0;
                            rx_valid <= 1'b0;
                            rx_last <= 1'b0;
                        end else begin
                            state <= ERROR;
                            missed_ack <= 1'b1;
                            busy <= 1'b0;
                            bus_control <= 1'b0;
                            bus_active <= 1'b0;
                            cmd_ready <= 1'b0;
                            tx_ready <= 1'b0;
                            rx_ready <= 1'b0;
                        end
                    end
                end

                WRITE_DATA: begin
                    if (scl_high) begin
                        state <= WRITE_DATA_ACK;
                        sda_sample <= 1'b1;
                        scl_count <= 8'd0;
                        state_timer <= 4'd0;
                        state_data_valid <= 1'b0;
                        state_data_ready <= 1'b0;
                        tx_valid <= 1'b0;
                        tx_last <= 1'b0;
                        rx_valid <= 1'b0;
                        rx_last <= 1'b0;
                    end
                end

                WRITE_DATA_ACK: begin
                    if (scl_high) begin
                        if (sda_i == 1'b0) begin
                            if (cmd_byte_count > 1) begin
                                state <= WRITE_DATA;
                                cmd_byte_index <= cmd_byte_index + 8'd1;
                                sda_sample <= 1'b1;
                                scl_count <= 8'd0;
                                state_timer <= 4'd0;
                                state_data_valid <= 1'b0;
                                state_data_ready <= 1'b0;
                                tx_valid <= 1'b0;
                                tx_last <= 1'b0;
                                rx_valid <= 1'b0;
                                rx_last <= 1'b0;
                            end else begin
                                state <= STOP;
                                sda_sample <= 1'b1;
                                scl_count <= 8'd0;
                                state_timer <= 4'd0;
                                state_data_valid <= 1'b0;
                                state_data_ready <= 1'b0;
                                tx_valid <= 1'b0;
                                tx_last <= 1'b0;
                                rx_valid <= 1'b0;
                                rx_last <= 1'b0;
                            end
                        end else begin
                            state <= ERROR;
                            missed_ack <= 1'b1;
                            busy <= 1'b0;
                            bus_control <= 1'b0;
                            bus_active <= 1'b0;
                            cmd_ready <= 1'b0;
                            tx_ready <= 1'b0;
                            rx_ready <= 1'b0;
                        end
                    end
                end

                READ_CMD: begin
                    if (scl_high) begin
                        state <= READ_CMD_ACK;
                        sda_sample <= 1'b1;
                        scl_count <= 8'd0;
                        state_timer <= 4'd0;
                        state_data_valid <= 1'b0;
                        state_data_ready <= 1'b0;
                        tx_valid <= 1'b0;
                        tx_last <= 1'b0;
                        rx_valid <= 1'b0;
                        rx_last <= 1'b0;
                    end
                end

                READ_CMD_ACK: begin
                    if (scl_high) begin
                        if (sda_i == 1'b0) begin
                            state <= READ_DATA;
                            sda_sample <= 1'b1;
                            scl_count <= 8'd0;
                            state_timer <= 4'd0;
                            state_data_valid <= 1'b0;
                            state_data_ready <= 1'b0;
                            tx_valid <= 1'b0;
                            tx_last <= 1'b0;
                            rx_valid <= 1'b0;
                            rx_last <= 1'b0;
                        end else begin
                            state <= ERROR;
                            missed_ack <= 1'b1;
                            busy <= 1'b0;
                            bus_control <= 1'b0;
                            bus_active <= 1'b0;
                            cmd_ready <= 1'b0;
                            tx_ready <= 1'b0;
                            rx_ready <= 1'b0;
                        end
                    end
                end

                READ_DATA: begin
                    if (scl_high) begin
                        state <= READ_DATA_ACK;
                        sda_sample <= 1'b1;
                        scl_count <= 8'd0;
                        state_timer <= 4'd0;
                        state_data_valid <= 1'b0;
                        state_data_ready <= 1'b0;
                        tx_valid <= 1'b0;
                        tx_last <= 1'b0;
                        rx_valid <= 1'b0;
                        rx_last <= 1'b0;
                    end
                end

                READ_DATA_ACK: begin
                    if (scl_high) begin
                        if (sda_i == 1'b0) begin
                            if (rx_byte_count > 1) begin
                                state <= READ_DATA;
                                rx_byte_index <= rx_byte_index + 8'd1;
                                sda_sample <= 1'b1;
                                scl_count <= 8'd0;
                                state_timer <= 4'd0;
                                state_data_valid <= 1'b0;
                                state_data_ready <= 1'b0;
                                tx_valid <= 1'b0;
                                tx_last <= 1'b0;
                                rx_valid <= 1'b0;
                                rx_last <= 1'b0;
                            end else begin
                                state <= STOP;
                                sda_sample <= 1'b1;
                                scl_count <= 8'd0;
                                state_timer <= 4'd0;
                                state_data_valid <= 1'b0;
                                state_data_ready <= 1'b0;
                                tx_valid <= 1'b0;
                                tx_last <= 1'b0;
                                rx_valid <= 1'b0;
                                rx_last <= 1'b0;
                            end
                        end else begin
                            state <= ERROR;
                            missed_ack <= 1'b1;
                            busy <= 1'b0;
                            bus_control <= 1'b0;
                            bus_active <= 1'b0;
                            cmd_ready <= 1'b0;
                            tx_ready <= 1'b0;
                            rx_ready <= 1'b0;
                        end
                    end
                end

                STOP: begin
                    if (scl_high) begin
                        state <= STOP_SENT;
                        sda_sample <= 1'b0;
                        scl_count <= 8'd0;
                        state_timer <= 4'd0;
                        state_data_valid <= 1'b0;
                        state_data_ready <= 1'b0;
                        tx_valid <= 1'b0;
                        tx_last <= 1'b0;
                        rx_valid <= 1'b0;
                        rx_last <= 1'b0;
                    end
                end

                STOP_SENT: begin
                    if (scl_high) begin
                        state <= IDLE;
                        busy <= 1'b0;
                        bus_control <= 1'b0;
                        bus_active <= 1'b0;
                        cmd_ready <= 1'b0;
                        tx_ready <= 1'b0;
                        rx_ready <= 1'b0;
                        cmd_done <= 1'b1;
                        rx_done <= 1'b1;
                        sda_sample <= 1'b1;
                        scl_count <= 8'd0;
                        state_timer <= 4'd0;
                        state_data_valid <= 1'b0;
                        state_data_ready <= 1'b0;
                        tx_valid <= 1'b0;
                        tx_last <= 1'b0;
                        rx_valid <= 1'b0;
                        rx_last <= 1'b0;
                    end
                end

                ERROR: begin
                    state <= IDLE;
                    busy <= 1'b0;
                    bus_control <= 1'b0;
                    bus_active <= 1'b0;
                    cmd_ready <= 1'b0;
                    tx_ready <= 1'b0;
                    rx_ready <= 1'b0;
                    cmd_done <= 1'b1;
                    rx_done <= 1'b1;
                    sda_sample <= 1'b1;
                    scl_count <= 8'd0;
                    state_timer <= 4'd0;
                    state_data_valid <= 1'b0;
                    state_data_ready <= 1'b0;
                    tx_valid <= 1'b0;
                    tx_last <= 1'b0;
                    rx_valid <= 1'b0;
                    rx_last <= 1'b0;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // Data Transmission Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_valid <= 1'b0;
            tx_last <= 1'b0;
            tx_ready <= 1'b0;
            sda_sample <= 1'b1;
        end else begin
            tx_ready <= 1'b0;
            sda_sample <= 1'b1;

            case (state)
                START: begin
                    if (scl_high) begin
                        sda_sample <= 1'b0;
                    end
                end

                START_SENT: begin
                    if (scl_high) begin
                        sda_sample <= 1'b1;
                    end
                end

                ADDRESS: begin
                    if (scl_high) begin
                        sda_sample <= 1'b1;
                    end
                end

                ADDRESS_ACK: begin
                    if (scl_high) begin
                        sda_sample <= 1'b1;
                    end
                end

                WRITE_CMD: begin
                    if (scl_high) begin
                        sda_sample <= 1'b1;
                    end
                end

                WRITE_CMD_ACK: begin
                    if (scl_high) begin
                        sda_sample <= 1'b1;
                    end
                end

                WRITE_DATA: begin
                    if (scl_high) begin
                        sda_sample <= tx_data;
                        tx_valid <= 1'b1;
                        tx_last <= (cmd_byte_index == cmd_byte_count - 1) ? 1'b1 : 1'b0;
                        tx_ready <= 1'b1;
                    end
                end

                WRITE_DATA_ACK: begin
                    if (scl_high) begin
                        sda_sample <= 1'b1;
                    end
                end

                READ_CMD: begin
                    if (scl_high) begin
                        sda_sample <= 1'b1;
                    end
                end

                READ_CMD_ACK: begin
                    if (scl_high) begin
                        sda_sample <= 1'b1;
                    end
                end

                READ_DATA: begin
                    if (scl_high) begin
                        sda_sample <= 1'b1;
                    end
                end

                READ_DATA_ACK: begin
                    if (scl_high) begin
                        sda_sample <= 1'b1;
                    end
                end

                STOP: begin
                    if (scl_high) begin
                        sda_sample <= 1'b0;
                    end
                end

                STOP_SENT: begin
                    if (scl_high) begin
                        sda_sample <= 1'b1;
                    end
                end

                ERROR: begin
                    sda_sample <= 1'b1;
                end

                default: begin
                    sda_sample <= 1'b1;
                end
            endcase
        end
    end

    // Data Reception Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_valid <= 1'b0;
            rx_last <= 1'b0;
            rx_ready <= 1'b0;
            rx_data <= 8'd0;
        end else begin
            rx_ready <= 1'b0;
            rx_data <= 8'd0;

            case (state)
                START: begin
                    if (scl_high) begin
                        rx_data <= 8'd0;
                        rx_valid <= 1'b0;
                    end
                end

                START_SENT: begin
                    if (scl_high) begin
                        rx_data <= 8'd0;
                        rx_valid <= 1'b0;
                    end
                end

                ADDRESS: begin
                    if (scl_high) begin
                        rx_data <= 8'd0;
                        rx_valid <= 1'b0;
                    end
                end

                ADDRESS_ACK: begin
                    if (scl_high) begin
                        rx_data <= 8'd0;
                        rx_valid <= 1'b0;
                    end
                end

                WRITE_CMD: begin
                    if (scl_high) begin
                        rx_data <= 8'd0;
                        rx_valid <= 1'b0;
                    end
                end

                WRITE_CMD_ACK: begin
                    if (scl_high) begin
                        rx_data <= 8'd0;
                        rx_valid <= 1'b0;
                    end
                end

                WRITE_DATA: begin
                    if (scl_high) begin
                        rx_data <= 8'd0;
                        rx_valid <= 1'b0;
                    end
                end

                WRITE_DATA_ACK: begin
                    if (scl_high) begin
                        rx_data <= 8'd0;
                        rx_valid <= 1'b0;
                    end
                end

                READ_CMD: begin
                    if (scl_high) begin
                        rx_data <= 8'd0;
                        rx_valid <= 1'b0;
                    end
                end

                READ_CMD_ACK: begin
                    if (scl_high) begin
                        rx_data <= 8'd0;
                        rx_valid <= 1'b0;
                    end
                end

                READ_DATA: begin
                    if (scl_high) begin
                        rx_data <= sda_i;
                        rx_valid <= 1'b1;
                        rx_last <= (rx_byte_index == rx_byte_count - 1) ? 1'b1 : 1'b0;
                        rx_ready <= 1'b1;
                    end
                end

                READ_DATA_ACK: begin
                    if (scl_high) begin
                        rx_data <= 8'd0;
                        rx_valid <= 1'b0;
                    end
                end

                STOP: begin
                    if (scl_high) begin
                        rx_data <= 8'd0;
                        rx_valid <= 1'b0;
                    end
                end

                STOP_SENT: begin
                    if (scl_high) begin
                        rx_data <= 8'd0;
                        rx_valid <= 1'b0;
                    end
                end

                ERROR: begin
                    rx_data <= 8'd0;
                    rx_valid <= 1'b0;
                end

                default: begin
                    rx_data <= 8'd0;
                    rx_valid <= 1'b0;
                end
            endcase
        end
    end

    // Output Assignments
    assign m_axis_data_tdata = rx_data;
    assign m_axis_data_tvalid = rx_valid;
    assign m_axis_data_tready = m_axis_data_tready;
    assign m_axis_data_tlast = rx_last;
    
    assign s_axis_cmd_ready = cmd_ready;
    assign s_axis_data_tready = tx_ready;
    
    assign busy = busy;
    assign bus_control = bus_control;
    assign bus_active = bus_active;
    assign missed_ack = missed_ack;

endmodule
```<|im_end|>
