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
    wire [7:0]         bit_bang_control;
    wire [7:0]         bit_bang_status;
    wire [7:0]         data_out;
    wire [7:0]         data_in;

    /*
     * Instantiate submodules
     */
    i2c_state_machine u_state_machine (
        .clk                  (clk),
        .rst                  (rst),
        .s_axis_cmd_address   (s_axis_cmd_address),
        .s_axis_cmd_start     (s_axis_cmd_start),
        .s_axis_cmd_read      (s_axis_cmd_read),
        .s_axis_cmd_write     (s_axis_cmd_write),
        .s_axis_cmd_write_multiple(s_axis_cmd_write_multiple),
        .s_axis_cmd_stop      (s_axis_cmd_stop),
        .s_axis_cmd_valid     (s_axis_cmd_valid),
        .s_axis_cmd_ready     (s_axis_cmd_ready),
        .bit_bang_control     (bit_bang_control),
        .bit_bang_status      (bit_bang_status),
        .data_out             (data_out),
        .data_in              (data_in),
        .busy                 (busy),
        .bus_control          (bus_control),
        .bus_active           (bus_active),
        .missed_ack           (missed_ack)
    );

    i2c_bit_bang u_bit_bang (
        .clk                  (clk),
        .rst                  (rst),
        .prescale             (prescale),
        .stop_on_idle         (stop_on_idle),
        .control              (bit_bang_control),
        .status               (bit_bang_status),
        .data_out             (data_out),
        .data_in              (data_in),
        .scl_i                (scl_i),
        .scl_o                (scl_o),
        .scl_t                (scl_t),
        .sda_i                (sda_i),
        .sda_o                (sda_o),
        .sda_t                (sda_t)
    );

    i2c_data_handler u_data_handler (
        .clk                  (clk),
        .rst                  (rst),
        .s_axis_data_tdata    (s_axis_data_tdata),
        .s_axis_data_tvalid   (s_axis_data_tvalid),
        .s_axis_data_tready   (s_axis_data_tready),
        .s_axis_data_tlast    (s_axis_data_tlast),
        .m_axis_data_tdata    (m_axis_data_tdata),
        .m_axis_data_tvalid   (m_axis_data_tvalid),
        .m_axis_data_tready   (m_axis_data_tready),
        .m_axis_data_tlast    (m_axis_data_tlast),
        .data_out             (data_out),
        .data_in              (data_in)
    );

endmodule

module i2c_state_machine (
    input  wire        clk,
    input  wire        rst,
    input  wire [6:0]  s_axis_cmd_address,
    input  wire        s_axis_cmd_start,
    input  wire        s_axis_cmd_read,
    input  wire        s_axis_cmd_write,
    input  wire        s_axis_cmd_write_multiple,
    input  wire        s_axis_cmd_stop,
    input  wire        s_axis_cmd_valid,
    output reg         s_axis_cmd_ready,
    output reg [7:0]   bit_bang_control,
    input  wire [7:0]  bit_bang_status,
    output reg [7:0]   data_out,
    input  wire [7:0]  data_in,
    output reg         busy,
    output reg         bus_control,
    output reg         bus_active,
    output reg         missed_ack
);

    typedef enum reg [2:0] {
        IDLE,
        START,
        ADDR,
        RW,
        ACK_ADDR,
        READ,
        ACK_READ,
        WRITE,
        ACK_WRITE,
        STOP
    } state_t;

    state_t state, next_state;

    reg [2:0] bit_cnt;
    reg [7:0] addr;
    reg [7:0] data_reg;
    reg       start_sent;
    reg       stop_sent;
    reg       read_op;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            bit_cnt <= 3'd0;
            addr <= 8'd0;
            data_reg <= 8'd0;
            start_sent <= 1'b0;
            stop_sent <= 1'b0;
            read_op <= 1'b0;
            s_axis_cmd_ready <= 1'b0;
            bit_bang_control <= 8'd0;
            busy <= 1'b0;
            bus_control <= 1'b0;
            bus_active <= 1'b0;
            missed_ack <= 1'b0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    s_axis_cmd_ready <= 1'b1;
                    bit_bang_control <= 8'd0;
                    busy <= 1'b0;
                    bus_control <= 1'b0;
                    bus_active <= 1'b0;
                    missed_ack <= 1'b0;
                    if (s_axis_cmd_valid) begin
                        addr <= {s_axis_cmd_address, s_axis_cmd_read};
                        read_op <= s_axis_cmd_read;
                        s_axis_cmd_ready <= 1'b0;
                        next_state <= START;
                    end
                end

                START: begin
                    bit_bang_control <= 8'b00000010; // Start condition
                    next_state <= ADDR;
                end

                ADDR: begin
                    if (bit_bang_status[0]) begin
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 3'd7) begin
                            bit_bang_control <= 8'b00000001; // Send ACK
                            next_state <= ACK_ADDR;
                        end else begin
                            bit_bang_control <= {addr[6:0], 1'b0}; // Send address bit
                            addr <= {addr[5:0], 1'b0};
                        end
                    end
                end

                ACK_ADDR: begin
                    if (bit_bang_status[0]) begin
                        if (bit_bang_status[1]) begin
                            missed_ack <= 1'b1;
                        end
                        bit_cnt <= 3'd0;
                        if (read_op) begin
                            next_state <= READ;
                        end else begin
                            next_state <= WRITE;
                        end
                    end
                end

                READ: begin
                    if (bit_bang_status[0]) begin
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 3'd7) begin
                            bit_bang_control <= 8'b00000001; // Send NACK
                            next_state <= ACK_READ;
                        end else begin
                            bit_bang_control <= 8'b00000000; // Read data bit
                        end
                    end
                end

                ACK_READ: begin
                    if (bit_bang_status[0]) begin
                        data_reg <= {data_reg[6:0], bit_bang_status[2]};
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 3'd7) begin
                            bit_bang_control <= 8'b00000010; // Stop condition
                            next_state <= STOP;
                        end else begin
                            next_state <= READ;
                        end
                    end
                end

                WRITE: begin
                    if (bit_bang_status[0]) begin
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 3'd7) begin
                            bit_bang_control <= 8'b00000001; // Send ACK
                            next_state <= ACK_WRITE;
                        end else begin
                            bit_bang_control <= {data_reg[6:0], 1'b0}; // Send data bit
                            data_reg <= {data_reg[5:0], 1'b0};
                        end
                    end
                end

                ACK_WRITE: begin
                    if (bit_bang_status[0]) begin
                        if (bit_bang_status[1]) begin
                            missed_ack <= 1'b1;
                        end
                        bit_cnt <= 3'd0;
                        next_state <= WRITE;
                    end
                end

                STOP: begin
                    if (bit_bang_status[0]) begin
                        next_state <= IDLE;
                    end
                end

                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

    assign data_out = data_reg;
    assign busy = (state != IDLE);
    assign bus_control = (state != IDLE);
    assign bus_active = (state != IDLE);
endmodule

module i2c_bit_bang (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] prescale,
    input  wire        stop_on_idle,
    input  wire [7:0]  control,
    output reg [7:0]   status,
    input  wire [7:0]  data_out,
    output reg [7:0]   data_in,
    input  wire        scl_i,
    output reg         scl_o,
    output reg         scl_t,
    input  wire        sda_i,
    output reg         sda_o,
    output reg         sda_t
);

    reg [15:0] prescale_cnt;
    reg [2:0]  bit_cnt;
    reg        scl_reg;
    reg        sda_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prescale_cnt <= 16'd0;
            bit_cnt <= 3'd0;
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            scl_o <= 1'b1;
            scl_t <= 1'b1;
            sda_o <= 1'b1;
            sda_t <= 1'b1;
            status <= 8'd0;
        end else begin
            if (prescale_cnt == prescale) begin
                prescale_cnt <= 16'd0;

                if (control[1]) begin // Start condition
                    scl_reg <= 1'b1;
                    sda_reg <= 1'b1;
                    scl_o <= 1'b0;
                    scl_t <= 1'b0;
                    sda_o <= 1'b0;
                    sda_t <= 1'b0;
                    status[0] <= 1'b1;
                end else if (control[0]) begin // Stop condition
                    scl_reg <= 1'b0;
                    sda_reg <= 1'b0;
                    scl_o <= 1'b1;
                    scl_t <= 1'b0;
                    sda_o <= 1'b1;
                    sda_t <= 1'b0;
                    status[0] <= 1'b1;
                end else begin
                    scl_reg <= ~scl_reg;
                    if (scl_reg) begin // SCL high
                        if (control[2]) begin // Send data bit
                            sda_reg <= control[3 + bit_cnt];
                            sda_o <= sda_reg;
                            sda_t <= 1'b0;
                        end else begin // Receive data bit
                            sda_reg <= sda_i;
                            data_in[bit_cnt] <= sda_i;
                            sda_o <= sda_reg;
                            sda_t <= 1'b1;
                        end
                        if (bit_cnt == 3'd7) begin
                            bit_cnt <= 3'd0;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end else begin // SCL low
                        sda_o <= sda_reg;
                        sda_t <= 1'b0;
                    end
                    scl_o <= scl_reg;
                    scl_t <= 1'b0;
                    status[0] <= 1'b1;
                end

                if (bit_cnt == 3'd7) begin // ACK/NACK
                    if (control[2]) begin // Send ACK/NACK
                        status[1] <= sda_i;
                    end
                end

            end else begin
                prescale_cnt <= prescale_cnt + 1;
                status[0] <= 1'b0;
            end
        end
    end
endmodule

module i2c_data_handler (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  s_axis_data_tdata,
    input  wire        s_axis_data_tvalid,
    output reg         s_axis_data_tready,
    input  wire        s_axis_data_tlast,
    output reg [7:0]   m_axis_data_tdata,
    output reg         m_axis_data_tvalid,
    input  wire        m_axis_data_tready,
    output reg         m_axis_data_tlast,
    output reg [7:0]   data_out,
    input  wire [7:0]  data_in
);

    reg [7:0] data_reg;
    reg       data_valid;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_data_tready <= 1'b0;
            m_axis_data_tdata <= 8'd0;
            m_axis_data_tvalid <= 1'b0;
            m_axis_data_tlast <= 1'b0;
            data_out <= 8'd0;
            data_valid <= 1'b0;
        end else begin
            if (s_axis_data_tvalid && s_axis_data_tready) begin
                data_reg <= s_axis_data_tdata;
                data_valid <= 1'b1;
                s_axis_data_tready <= 1'b0;
            end else if (!m_axis_data_tvalid || (m_axis_data_tvalid && m_axis_data_tready)) begin
                if (data_valid) begin
                    data_out <= data_reg;
                    data_valid <= 1'b0;
                    s_axis_data_tready <= 1'b1;
                end
            end

            if (data_valid) begin
                m_axis_data_tdata <= data_in;
                m_axis_data_tvalid <= 1'b1;
                m_axis_data_tlast <= s_axis_data_tlast;
            end else begin
                m_axis_data_tvalid <= 1'b0;
                m_axis_data_tlast <= 1'b0;
            end
        end
    end
endmodule
