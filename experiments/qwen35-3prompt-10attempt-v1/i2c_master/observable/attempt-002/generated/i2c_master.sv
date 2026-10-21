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
    localparam int unsigned SDA_HOLD_TIME = 2; // Cycles
    localparam int unsigned SCL_LOW_TIME  = 2; // Cycles
    localparam int unsigned SCL_HIGH_TIME = 2; // Cycles
    localparam int unsigned START_DELAY   = 2; // Cycles
    localparam int unsigned STOP_DELAY    = 2; // Cycles
    localparam int unsigned ACK_DELAY     = 2; // Cycles
    localparam int unsigned IDLE_DELAY    = 2; // Cycles

    // State Machine States
    localparam int unsigned STATE_IDLE = 0;
    localparam int unsigned STATE_PREPARE = 1;
    localparam int unsigned STATE_START = 2;
    localparam int unsigned STATE_ADDR_WRITE = 3;
    localparam int unsigned STATE_ADDR_READ = 4;
    localparam int unsigned STATE_DATA_WRITE = 5;
    localparam int unsigned STATE_DATA_READ = 6;
    localparam int unsigned STATE_ACK_CHECK = 7;
    localparam int unsigned STATE_STOP = 8;
    localparam int unsigned STATE_IDLE_WAIT = 9;

    // Internal Signals
    reg [2:0] state, next_state;
    reg [7:0] cmd_addr;
    reg cmd_read, cmd_write, cmd_write_multiple, cmd_stop;
    reg cmd_valid;
    reg [7:0] data_in;
    reg data_in_valid, data_in_last;
    reg [7:0] data_out;
    reg data_out_valid, data_out_last;
    reg data_out_ready;
    
    reg scl_state; // 0: Low, 1: High
    reg sda_state; // 0: Low, 1: High
    reg scl_hold;
    reg sda_hold;
    reg scl_pulse;
    reg sda_pulse;
    
    reg [7:0] shift_reg; // For data shifting
    reg [3:0] shift_count;
    reg [3:0] byte_count;
    reg [3:0] total_bytes;
    reg [3:0] bytes_sent;
    reg [3:0] bytes_received;
    reg ack_received;
    reg missed_ack_flag;
    reg bus_ctrl_req;
    reg bus_ctrl_granted;
    reg bus_active_flag;
    reg busy_flag;
    
    reg [15:0] prescaler_val;
    reg [7:0] scl_counter;
    reg [7:0] sda_counter;
    reg scl_dir;
    reg sda_dir;
    
    // Output registers for I/O
    reg scl_out;
    reg sda_out;
    reg scl_t_out;
    reg sda_t_out;

    // Timing counters
    reg [7:0] scl_timer;
    reg [7:0] sda_timer;
    reg scl_timer_en;
    reg sda_timer_en;
    reg scl_timer_done;
    reg sda_timer_done;

    // Command Queue State
    reg cmd_queue_valid;
    reg cmd_queue_ready;
    reg cmd_queue_full;
    reg cmd_queue_empty;
    reg [3:0] cmd_queue_ptr;
    reg [3:0] cmd_queue_tail;
    reg [7:0] cmd_queue_data [0:3];
    reg [2:0] cmd_queue_state [0:3];
    reg [7:0] cmd_queue_addr [0:3];
    reg cmd_queue_read;
    reg cmd_queue_write;

    // Internal registers for current transaction
    reg [7:0] current_addr;
    reg current_read;
    reg current_write;
    reg current_write_multiple;
    reg current_stop;
    reg current_valid;
    reg [7:0] current_data;
    reg current_data_valid;
    reg current_data_last;
    reg [7:0] current_data_out;
    reg current_data_out_valid;
    reg current_data_out_last;
    reg current_data_out_ready;
    
    reg [3:0] tx_count;
    reg [3:0] rx_count;
    reg [3:0] tx_total;
    reg [3:0] rx_total;
    reg tx_done;
    reg rx_done;
    reg tx_error;
    reg rx_error;
    reg tx_idle;
    reg rx_idle;

    // State Machine Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            busy_flag <= 1'b0;
            bus_ctrl_req <= 1'b0;
            bus_ctrl_granted <= 1'b0;
            bus_active_flag <= 1'b0;
            missed_ack_flag <= 1'b0;
            scl_state <= 1'b0;
            sda_state <= 1'b1; // Open drain high
            scl_counter <= 0;
            sda_counter <= 0;
            scl_timer <= 0;
            sda_timer <= 0;
            scl_timer_en <= 1'b0;
            sda_timer_en <= 1'b0;
            scl_timer_done <= 1'b0;
            sda_timer_done <= 1'b0;
            scl_dir <= 1'b0;
            sda_dir <= 1'b0;
            shift_count <= 0;
            byte_count <= 0;
            total_bytes <= 0;
            bytes_sent <= 0;
            bytes_received <= 0;
            ack_received <= 1'b0;
            cmd_queue_valid <= 1'b0;
            cmd_queue_ready <= 1'b1;
            cmd_queue_full <= 1'b0;
            cmd_queue_empty <= 1'b1;
            cmd_queue_ptr <= 0;
            cmd_queue_tail <= 0;
            cmd_queue_read <= 1'b0;
            cmd_queue_write <= 1'b0;
            tx_count <= 0;
            rx_count <= 0;
            tx_total <= 0;
            rx_total <= 0;
            tx_done <= 1'b0;
            rx_done <= 1'b0;
            tx_error <= 1'b0;
            rx_error <= 1'b0;
            tx_idle <= 1'b1;
            rx_idle <= 1'b1;
            current_valid <= 1'b0;
            current_data_valid <= 1'b0;
            current_data_out_valid <= 1'b0;
            current_data_out_ready <= 1'b0;
            current_data_last <= 1'b0;
            current_data_out_last <= 1'b0;
            current_read <= 1'b0;
            current_write <= 1'b0;
            current_write_multiple <= 1'b0;
            current_stop <= 1'b0;
            current_addr <= 0;
            current_data <= 0;
            current_data_out <= 0;
        end
        else begin
            state <= next_state;
            busy_flag <= (state != STATE_IDLE) ? 1'b1 : 1'b0;
            bus_ctrl_req <= (state == STATE_PREPARE) ? 1'b1 : 1'b0;
            bus_ctrl_granted <= bus_ctrl_req;
            bus_active_flag <= (state == STATE_START || state == STATE_ADDR_WRITE || state == STATE_ADDR_READ || state == STATE_DATA_WRITE || state == STATE_DATA_READ || state == STATE_ACK_CHECK || state == STATE_STOP) ? 1'b1 : 1'b0;
            missed_ack_flag <= (state == STATE_ACK_CHECK && !ack_received) ? 1'b1 : 1'b0;
            
            // I/O Direction Control
            scl_dir <= (state == STATE_IDLE || state == STATE_IDLE_WAIT || state == STATE_PREPARE) ? 1'b0 : 1'b1;
            sda_dir <= (state == STATE_IDLE || state == STATE_IDLE_WAIT || state == STATE_PREPARE) ? 1'b0 : 1'b1;
            
            // Data Shifting
            if (state == STATE_DATA_WRITE && shift_count < 8) begin
                shift_reg <= {shift_reg[6:0], current_data[7]};
                shift_count <= shift_count + 1;
            end
            else if (state == STATE_DATA_READ && shift_count < 8) begin
                shift_reg <= {shift_reg[6:0], sda_i};
                shift_count <= shift_count + 1;
            end
            else if (state == STATE_DATA_WRITE && shift_count == 8) begin
                shift_count <= 0;
                bytes_sent <= bytes_sent + 1;
                if (bytes_sent >= tx_total) begin
                    tx_done <= 1'b1;
                    if (state == STATE_STOP) next_state <= STATE_STOP;
                    else next_state <= STATE_ACK_CHECK;
                end
                else next_state <= STATE_DATA_WRITE;
            end
            else if (state == STATE_DATA_READ && shift_count == 8) begin
                shift_count <= 0;
                bytes_received <= bytes_received + 1;
                if (bytes_received >= rx_total) begin
                    rx_done <= 1'b1;
                    if (state == STATE_STOP) next_state <= STATE_STOP;
                    else next_state <= STATE_ACK_CHECK;
                end
                else next_state <= STATE_DATA_READ;
            end
            else if (state == STATE_ACK_CHECK) begin
                if (ack_received) begin
                    if (current_read) next_state <= STATE_DATA_READ;
                    else if (current_write) next_state <= STATE_DATA_WRITE;
                    else next_state <= STATE_STOP;
                end
                else begin
                    missed_ack_flag <= 1'b1;
                    if (current_read) next_state <= STATE_DATA_READ;
                    else if (current_write) next_state <= STATE_DATA_WRITE;
                    else next_state <= STATE_STOP;
                end
            end
            else if (state == STATE_STOP) begin
                next_state <= STATE_IDLE_WAIT;
            end
            else if (state == STATE_IDLE_WAIT) begin
                if (stop_on_idle && !scl_i && !sda_i) next_state <= STATE_IDLE;
                else next_state <= STATE_IDLE;
            end
            else next_state <= state;
        end
    end

    // Command Queue Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_queue_valid <= 1'b0;
            cmd_queue_ready <= 1'b1;
            cmd_queue_full <= 1'b0;
            cmd_queue_empty <= 1'b1;
            cmd_queue_ptr <= 0;
            cmd_queue_tail <= 0;
            cmd_queue_read <= 1'b0;
            cmd_queue_write <= 1'b0;
        end
        else begin
            cmd_queue_valid <= cmd_queue_read;
            cmd_queue_ready <= cmd_queue_write;
            cmd_queue_full <= (cmd_queue_ptr == cmd_queue_tail);
            cmd_queue_empty <= (cmd_queue_ptr == cmd_queue_tail) && (cmd_queue_ptr == 0);
            
            if (cmd_queue_write) begin
                cmd_queue_ptr <= cmd_queue_ptr + 1;
                cmd_queue_data[cmd_queue_ptr] <= current_addr;
                cmd_queue_state[cmd_queue_ptr] <= state;
                cmd_queue_addr[cmd_queue_ptr] <= current_data;
            end
            if (cmd_queue_read) begin
                cmd_queue_tail <= cmd_queue_tail + 1;
            end
        end
    end

    // I/O Output Logic
    always @(*) begin
        scl_out = scl_state;
        sda_out = sda_state;
        scl_t_out = scl_state;
        sda_t_out = sda_state;
        
        if (scl_dir) scl_out = scl_state;
        else scl_out = scl_i;
        
        if (sda_dir) sda_out = sda_state;
        else sda_out = sda_i;
        
        if (scl_dir) scl_t_out = scl_state;
        else scl_t_out = scl_i;
        
        if (sda_dir) sda_t_out = sda_state;
        else sda_t_out = sda_i;
    end

    // Timing Control Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_counter <= 0;
            sda_counter <= 0;
            scl_timer <= 0;
            sda_timer <= 0;
            scl_timer_en <= 1'b0;
            sda_timer_en <= 1'b0;
            scl_timer_done <= 1'b0;
            sda_timer_done <= 1'b0;
        end
        else begin
            scl_timer_en <= (state == STATE_START || state == STATE_ADDR_WRITE || state == STATE_ADDR_READ || state == STATE_DATA_WRITE || state == STATE_DATA_READ || state == STATE_ACK_CHECK || state == STATE_STOP) ? 1'b1 : 1'b0;
            sda_timer_en <= (state == STATE_START || state == STATE_ADDR_WRITE || state == STATE_ADDR_READ || state == STATE_DATA_WRITE || state == STATE_DATA_READ || state == STATE_ACK_CHECK || state == STATE_STOP) ? 1'b1 : 1'b0;
            
            if (scl_timer_en) begin
                if (scl_timer_done) scl_timer <= 0;
                else scl_timer <= scl_timer + 1;
            end
            if (sda_timer_en) begin
                if (sda_timer_done) sda_timer <= 0;
                else sda_timer <= sda_timer + 1;
            end
            
            if (scl_timer == prescaler_val) begin
                scl_timer_done <= 1'b1;
                scl_timer <= 0;
            end
            if (sda_timer == prescaler_val) begin
                sda_timer_done <= 1'b1;
                sda_timer <= 0;
            end
        end
    end

    // SCL Control Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_state <= 1'b0;
            scl_hold <= 1'b0;
            scl_pulse <= 1'b0;
        end
        else begin
            if (scl_timer_done) begin
                if (scl_state) begin
                    scl_state <= 1'b0;
                    scl_hold <= 1'b1;
                end
                else begin
                    scl_state <= 1'b1;
                    scl_hold <= 1'b0;
                end
            end
            else if (scl_hold) begin
                if (scl_state) scl_state <= 1'b0;
                else scl_state <= 1'b1;
            end
            else begin
                if (scl_state) scl_state <= 1'b0;
                else scl_state <= 1'b1;
            end
        end
    end

    // SDA Control Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sda_state <= 1'b1;
            sda_hold <= 1'b0;
            sda_pulse <= 1'b0;
        end
        else begin
            if (sda_timer_done) begin
                if (sda_state) begin
                    sda_state <= 1'b0;
                    sda_hold <= 1'b1;
                end
                else begin
                    sda_state <= 1'b1;
                    sda_hold <= 1'b0;
                end
            end
            else if (sda_hold) begin
                if (sda_state) sda_state <= 1'b0;
                else sda_state <= 1'b1;
            end
            else begin
                if (sda_state) sda_state <= 1'b0;
                else sda_state <= 1'b1;
            end
        end
    end

    // State Transition Logic
    always @(*) begin
        case (state)
            STATE_IDLE: begin
                if (bus_ctrl_granted && cmd_queue_valid) begin
                    cmd_addr <= cmd_queue_addr[cmd_queue_ptr];
                    cmd_read <= 0;
                    cmd_write <= 0;
                    cmd_write_multiple <= 0;
                    cmd_stop <= 0;
                    current_valid <= 1'b1;
                    current_addr <= cmd_queue_addr[cmd_queue_ptr];
                    current_data <= cmd_queue_addr[cmd_queue_ptr + 1];
                    current_data_valid <= 1'b1;
                    current_data_last <= 1'b0;
                    current_read <= 0;
                    current_write <= 0;
                    current_write_multiple <= 0;
                    current_stop <= 0;
                    tx_count <= 0;
                    rx_count <= 0;
                    tx_total <= 0;
                    rx_total <= 0;
                    tx_done <= 1'b0;
                    rx_done <= 1'b0;
                    tx_error <= 1'b0;
                    rx_error <= 1'b0;
                    tx_idle <= 1'b1;
                    rx_idle <= 1'b1;
                    next_state <= STATE_PREPARE;
                end
                else next_state <= STATE_IDLE;
            end
            
            STATE_PREPARE: begin
                if (bus_ctrl_granted) begin
                    next_state <= STATE_START;
                end
                else next_state <= STATE_PREPARE;
            end
            
            STATE_START: begin
                if (scl_timer_done) begin
                    scl_state <= 1'b0;
                    sda_state <= 1'b1;
                    next_state <= STATE_ADDR_WRITE;
                end
                else next_state <= STATE_START;
            end
            
            STATE_ADDR_WRITE: begin
                if (scl_timer_done) begin
                    scl_state <= 1'b0;
                    sda_state <= 1'b0;
                    next_state <= STATE_ADDR_WRITE;
                end
                else next_state <= STATE_ADDR_WRITE;
            end
            
            STATE_ADDR_READ: begin
                if (scl_timer_done) begin
                    scl_state <= 1'b0;
                    sda_state <= 1'b1;
                    next_state <= STATE_ADDR_READ;
                end
                else next_state <= STATE_ADDR_READ;
            end
            
            STATE_DATA_WRITE: begin
                if (scl_timer_done) begin
                    scl_state <= 1'b0;
                    sda_state <= 1'b0;
                    next_state <= STATE_DATA_WRITE;
                end
                else next_state <= STATE_DATA_WRITE;
            end
            
            STATE_DATA_READ: begin
                if (scl_timer_done) begin
                    scl_state <= 1'b0;
                    sda_state <= 1'b1;
                    next_state <= STATE_DATA_READ;
                end
                else next_state <= STATE_DATA_READ;
            end
            
            STATE_ACK_CHECK: begin
                if (scl_timer_done) begin
                    scl_state <= 1'b0;
                    sda_state <= 1'b0;
                    ack_received <= 1'b0;
                    next_state <= STATE_ACK_CHECK;
                end
                else next_state <= STATE_ACK_CHECK;
            end
            
            STATE_STOP: begin
                if (scl_timer_done) begin
                    scl_state <= 1'b0;
                    sda_state <= 1'b1;
                    next_state <= STATE_STOP;
                end
                else next_state <= STATE_STOP;
            end
            
            STATE_IDLE_WAIT: begin
                if (stop_on_idle && !scl_i && !sda_i) next_state <= STATE_IDLE;
                else next_state <= STATE_IDLE;
            end
            
            default: next_state <= STATE_IDLE;
        endcase
    end

    // Data Shifting Logic
    always @(*) begin
        if (state == STATE_DATA_WRITE && shift_count < 8) begin
            shift_reg <= {shift_reg[6:0], current_data[7]};
            shift_count <= shift_count + 1;
        end
        else if (state == STATE_DATA_READ && shift_count < 8) begin
            shift_reg <= {shift_reg[6:0], sda_i};
            shift_count <= shift_count + 1;
        end
        else if (state == STATE_DATA_WRITE && shift_count == 8) begin
            shift_count <= 0;
            bytes_sent <= bytes_sent + 1;
            if (bytes_sent >= tx_total) begin
                tx_done <= 1'b1;
                if (state == STATE_STOP) next_state <= STATE_STOP;
                else next_state <= STATE_ACK_CHECK;
            end
            else next_state <= STATE_DATA_WRITE;
        end
        else if (state == STATE_DATA_READ && shift_count == 8) begin
            shift_count <= 0;
            bytes_received <= bytes_received + 1;
            if (bytes_received >= rx_total) begin
                rx_done <= 1'b1;
                if (state == STATE_STOP) next_state <= STATE_STOP;
                else next_state <= STATE_ACK_CHECK;
            end
            else next_state <= STATE_DATA_READ;
        end
        else if (state == STATE_ACK_CHECK) begin
            if (ack_received) begin
                if (current_read) next_state <= STATE_DATA_READ;
                else if (current_write) next_state <= STATE_DATA_WRITE;
                else next_state <= STATE_STOP;
            end
            else begin
                missed_ack_flag <= 1'b1;
                if (current_read) next_state <= STATE_DATA_READ;
                else if (current_write) next_state <= STATE_DATA_WRITE;
                else next_state <= STATE_STOP;
            end
        end
        else if (state == STATE_STOP) begin
            next_state <= STATE_IDLE_WAIT;
        end
        else if (state == STATE_IDLE_WAIT) begin
            if (stop_on_idle && !scl_i && !sda_i) next_state <= STATE_IDLE;
            else next_state <= STATE_IDLE;
        end
        else next_state <= state;
    end

    // Output Logic
    assign s_axis_cmd_ready = (state == STATE_IDLE) ? 1'b1 : 1'b0;
    assign s_axis_data_tready = (state == STATE_IDLE) ? 1'b1 : 1'b0;
    assign m_axis_data_tvalid = (state == STATE_DATA_READ && shift_count == 8) ? 1'b1 : 1'b0;
    assign m_axis_data_tdata = shift_reg;
    assign m_axis_data_tlast = (bytes_received >= rx_total) ? 1'b1 : 1'b0;
    assign busy = busy_flag;
    assign bus_control = bus_ctrl_req;
    assign bus_active = bus_active_flag;
    assign missed_ack = missed_ack_flag;
    assign scl_o = scl_out;
    assign sda_o = sda_out;
    assign scl_t = scl_t_out;
    assign sda_t = sda_t_out;

    // Host Interface Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cmd_queue_valid <= 1'b0;
            cmd_queue_ready <= 1'b1;
            cmd_queue_full <= 1'b0;
            cmd_queue_empty <= 1'b1;
            cmd_queue_ptr <= 0;
            cmd_queue_tail <= 0;
            cmd_queue_read <= 1'b0;
            cmd_queue_write <= 1'b0;
        end
        else begin
            cmd_queue_valid <= cmd_queue_read;
            cmd_queue_ready <= cmd_queue_write;
            cmd_queue_full <= (cmd_queue_ptr == cmd_queue_tail);
            cmd_queue_empty <= (cmd_queue_ptr == cmd_queue_tail) && (cmd_queue_ptr == 0);
            
            if (cmd_queue_write) begin
                cmd_queue_ptr <= cmd_queue_ptr + 1;
                cmd_queue_data[cmd_queue_ptr] <= current_addr;
                cmd_queue_state[cmd_queue_ptr] <= state;
                cmd_queue_addr[cmd_queue_ptr] <= current_data;
            end
            if (cmd_queue_read) begin
                cmd_queue_tail <= cmd_queue_tail + 1;
            end
        end
    end

    // Data Shifting Logic
    always @(*) begin
        if (state == STATE_DATA_WRITE && shift_count < 8) begin
            shift_reg <= {shift_reg[6:0], current_data[7]};
            shift_count <= shift_count + 1;
        end
        else if (state == STATE_DATA_READ && shift_count < 8) begin
            shift_reg <= {shift_reg[6:0], sda_i};
            shift_count <= shift_count + 1;
        end
        else if (state == STATE_DATA_WRITE && shift_count == 8) begin
            shift_count <= 0;
            bytes_sent <= bytes_sent + 1;
            if (bytes_sent >= tx_total) begin
                tx_done <= 1'b1;
                if (state == STATE_STOP) next_state <= STATE_STOP;
                else next_state <= STATE_ACK_CHECK;
            end
            else next_state <= STATE_DATA_WRITE;
        end
        else if (state == STATE_DATA_READ && shift_count == 8) begin
            shift_count <= 0;
            bytes_received <= bytes_received + 1;
            if (bytes_received >= rx_total) begin
                rx_done <= 1'b1;
                if (state == STATE_STOP) next_state <= STATE_STOP;
                else next_state <= STATE_ACK_CHECK;
            end
            else next_state <= STATE_DATA_READ;
        end
        else if (state == STATE_ACK_CHECK) begin
            if (ack_received) begin
                if (current_read) next_state <= STATE_DATA_READ;
                else if (current_write) next_state <= STATE_DATA_WRITE;
                else next_state <= STATE_STOP;
            end
            else begin
                missed_ack_flag <= 1'b1;
                if (current_read) next_state <= STATE_DATA_READ;
                else if (current_write) next_state <= STATE_DATA_WRITE;
                else next_state <= STATE_STOP;
            end
        end
        else if (state == STATE_STOP) begin
            next_state <= STATE_IDLE_WAIT;
        end
        else if (state == STATE_IDLE_WAIT) begin
            if (stop_on_idle && !scl_i && !sda_i) next_state <= STATE_IDLE;
            else next_state <= STATE_IDLE;
        end
        else next_state <= state;
    end

    // Output Logic
    assign s_axis_cmd_ready = (state == STATE_IDLE) ? 1'b1 : 1'b0;
    assign s_axis_data_tready = (state == STATE_IDLE) ? 1'b1 : 1'b0;
    assign m_axis_data_tvalid = (state == STATE_DATA_READ && shift_count == 8) ? 1'b1 : 1'b0;
    assign m_axis_data_tdata = shift_reg;
    assign m_axis_data_tlast = (bytes_received >= rx_total) ? 1'b1 : 1'b0;
    assign busy = busy_flag;
    assign bus_control = bus_ctrl_req;
    assign bus_active = bus_active_flag;
    assign missed_ack = missed_ack_flag;
    assign scl_o = scl_out;
    assign sda_o = sda_out;
    assign scl_t = scl_t_out;
    assign sda_t = sda_t_out;

endmodule
```<|im_end|>
