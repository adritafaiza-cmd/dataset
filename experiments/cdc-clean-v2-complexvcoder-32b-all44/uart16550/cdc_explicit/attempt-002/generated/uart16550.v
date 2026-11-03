module uart_top (
    input wb_clk_i,
    input wb_rst_i,
    input [7:0] wb_adr_i,
    input [31:0] wb_dat_i,
    output [31:0] wb_dat_o,
    input wb_we_i,
    input wb_stb_i,
    input wb_cyc_i,
    output wb_ack_o,
    input [3:0] wb_sel_i,
    output int_o,
    output stx_pad_o,
    input srx_pad_i,
    output rts_pad_o,
    input cts_pad_i,
    output dtr_pad_o,
    input dsr_pad_i,
    input ri_pad_i,
    input dcd_pad_i
);

    reg [31:0] wb_dat_o_reg;
    reg wb_ack_o_reg;
    reg int_o_reg;
    reg [7:0] rx_data;
    reg rx_data_valid;
    reg tx_ready;
    reg [7:0] tx_data;
    reg tx_data_valid;
    reg [15:0] divisor;
    reg [7:0] line_ctrl;
    reg [7:0] modem_ctrl;
    reg [7:0] int_enable;
    reg [7:0] fifo_ctrl;
    reg [15:0] rx_fifo;
    reg [15:0] tx_fifo;

    wb_slave wb_slave_inst (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wb_adr_i(wb_adr_i),
        .wb_dat_i(wb_dat_i),
        .wb_dat_o(wb_dat_o_reg),
        .wb_we_i(wb_we_i),
        .wb_stb_i(wb_stb_i),
        .wb_cyc_i(wb_cyc_i),
        .wb_ack_o(wb_ack_o_reg),
        .wb_sel_i(wb_sel_i),
        .int_o(int_o_reg),
        .rx_data(rx_data),
        .rx_data_valid(rx_data_valid),
        .tx_ready(tx_ready),
        .tx_data(tx_data),
        .tx_data_valid(tx_data_valid),
        .divisor(divisor),
        .line_ctrl(line_ctrl),
        .modem_ctrl(modem_ctrl),
        .int_enable(int_enable),
        .fifo_ctrl(fifo_ctrl),
        .rx_fifo(rx_fifo),
        .tx_fifo(tx_fifo)
    );

    uart_core uart_core_inst (
        .uart_clk_i(wb_clk_i),
        .uart_rst_i(wb_rst_i),
        .rx_data(rx_data),
        .rx_data_valid(rx_data_valid),
        .tx_ready(tx_ready),
        .tx_data(tx_data),
        .tx_data_valid(tx_data_valid),
        .divisor(divisor),
        .line_ctrl(line_ctrl),
        .modem_ctrl(modem_ctrl),
        .int_enable(int_enable),
        .fifo_ctrl(fifo_ctrl),
        .rx_fifo(rx_fifo),
        .tx_fifo(tx_fifo),
        .stx_pad_o(stx_pad_o),
        .srx_pad_i(srx_pad_i),
        .cts_pad_i(cts_pad_i),
        .dtr_pad_o(dtr_pad_o),
        .dsr_pad_i(dsr_pad_i),
        .ri_pad_i(ri_pad_i),
        .dcd_pad_i(dcd_pad_i)
    );

    assign wb_dat_o = wb_dat_o_reg;
    assign wb_ack_o = wb_ack_o_reg;
    assign int_o = int_o_reg;
    assign rts_pad_o = ~modem_ctrl[1]; // RTS is active low, modem_ctrl[1] is RTS control bit

endmodule

module wb_slave (
    input wb_clk_i,
    input wb_rst_i,
    input [7:0] wb_adr_i,
    input [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o,
    input wb_we_i,
    input wb_stb_i,
    input wb_cyc_i,
    output reg wb_ack_o,
    input [3:0] wb_sel_i,
    output reg int_o,
    output reg [7:0] rx_data,
    output reg rx_data_valid,
    input tx_ready,
    output reg [7:0] tx_data,
    output reg tx_data_valid,
    inout [15:0] divisor,
    inout [7:0] line_ctrl,
    inout [7:0] modem_ctrl,
    inout [7:0] int_enable,
    inout [7:0] fifo_ctrl,
    inout [15:0] rx_fifo,
    inout [15:0] tx_fifo
);

    reg [15:0] reg_divisor;
    reg [7:0] reg_line_ctrl;
    reg [7:0] reg_modem_ctrl;
    reg [7:0] reg_int_enable;
    reg [7:0] reg_fifo_ctrl;
    reg [15:0] reg_rx_fifo;
    reg [15:0] reg_tx_fifo;
    reg [7:0] reg_int_status;
    reg ack;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            reg_divisor <= 16'h0000;
            reg_line_ctrl <= 8'h00;
            reg_modem_ctrl <= 8'h00;
            reg_int_enable <= 8'h00;
            reg_fifo_ctrl <= 8'h00;
            reg_rx_fifo <= 16'h0000;
            reg_tx_fifo <= 16'h0000;
            reg_int_status <= 8'h00;
            ack <= 0;
        end else if (wb_stb_i && wb_cyc_i) begin
            ack <= 1;
            if (wb_we_i) begin
                case (wb_adr_i)
                    8'h00: reg_divisor[7:0] <= wb_dat_i[7:0] & wb_sel_i;
                    8'h01: reg_divisor[15:8] <= wb_dat_i[7:0] & wb_sel_i;
                    8'h02: reg_int_enable <= wb_dat_i[7:0] & wb_sel_i;
                    8'h03: reg_fifo_ctrl <= wb_dat_i[7:0] & wb_sel_i;
                    8'h04: reg_line_ctrl <= wb_dat_i[7:0] & wb_sel_i;
                    8'h05: reg_modem_ctrl <= wb_dat_i[7:0] & wb_sel_i;
                    default: ;
                endcase
            end else begin
                case (wb_adr_i)
                    8'h00: wb_dat_o <= {24'h0, reg_divisor[7:0]};
                    8'h01: wb_dat_o <= {24'h0, reg_divisor[15:8]};
                    8'h02: wb_dat_o <= {24'h0, reg_int_enable};
                    8'h03: wb_dat_o <= {24'h0, reg_fifo_ctrl};
                    8'h04: wb_dat_o <= {24'h0, reg_line_ctrl};
                    8'h05: wb_dat_o <= {24'h0, reg_modem_ctrl};
                    8'h06: wb_dat_o <= {24'h0, reg_int_status};
                    8'h07: wb_dat_o <= {24'h0, reg_rx_fifo[7:0]};
                    8'h08: wb_dat_o <= {24'h0, reg_rx_fifo[15:8]};
                    8'h09: wb_dat_o <= {24'h0, reg_tx_fifo[7:0]};
                    8'h0A: wb_dat_o <= {24'h0, reg_tx_fifo[15:8]};
                    default: wb_dat_o <= 32'h0;
                endcase
            end
        end else begin
            ack <= 0;
        end
    end

    assign wb_ack_o = ack;
    assign divisor = reg_divisor;
    assign line_ctrl = reg_line_ctrl;
    assign modem_ctrl = reg_modem_ctrl;
    assign int_enable = reg_int_enable;
    assign fifo_ctrl = reg_fifo_ctrl;
    assign rx_fifo = reg_rx_fifo;
    assign tx_fifo = reg_tx_fifo;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            int_o <= 0;
        end else begin
            int_o <= (reg_int_status & reg_int_enable) != 0;
        end
    end

endmodule

module uart_core (
    input uart_clk_i,
    input uart_rst_i,
    output reg [7:0] rx_data,
    output reg rx_data_valid,
    input tx_ready,
    output reg [7:0] tx_data,
    output reg tx_data_valid,
    input [15:0] divisor,
    input [7:0] line_ctrl,
    input [7:0] modem_ctrl,
    input [7:0] int_enable,
    input [7:0] fifo_ctrl,
    input [15:0] rx_fifo,
    input [15:0] tx_fifo,
    output reg stx_pad_o,
    input srx_pad_i,
    input cts_pad_i,
    output reg dtr_pad_o,
    input dsr_pad_i,
    input ri_pad_i,
    input dcd_pad_i
);

    reg [7:0] shift_reg;
    reg [3:0] bit_cnt;
    reg tx_busy;
    reg [15:0] baud_cnt;
    reg [15:0] baud_clk;

    assign dtr_pad_o = modem_ctrl[0];

    baud_gen baud_gen_inst (
        .clk_i(uart_clk_i),
        .rst_i(uart_rst_i),
        .divisor(divisor),
        .baud_clk_o(baud_clk)
    );

    rx_logic rx_logic_inst (
        .clk_i(baud_clk),
        .rst_i(uart_rst_i),
        .srx_pad_i(srx_pad_i),
        .line_ctrl(line_ctrl),
        .rx_data(rx_data),
        .rx_data_valid(rx_data_valid)
    );

    always @(posedge baud_clk or posedge uart_rst_i) begin
        if (uart_rst_i) begin
            tx_busy <= 0;
            bit_cnt <= 0;
            stx_pad_o <= 1;
            tx_data_valid <= 0;
        end else if (tx_data_valid && !tx_busy && tx_ready) begin
            tx_busy <= 1;
            bit_cnt <= 0;
            stx_pad_o <= 0;
            shift_reg <= tx_data;
            tx_data_valid <= 0;
        end else if (tx_busy) begin
            if (bit_cnt < 10) begin
                stx_pad_o <= shift_reg[0];
                shift_reg <= {shift_reg[6:0], 1'b1};
                bit_cnt <= bit_cnt + 1;
            end else begin
                tx_busy <= 0;
                stx_pad_o <= 1;
            end
        end
    end

endmodule

module baud_gen (
    input clk_i,
    input rst_i,
    input [15:0] divisor,
    output reg baud_clk_o
);

    reg [15:0] baud_cnt;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            baud_cnt <= 16'h0000;
            baud_clk_o <= 0;
        end else begin
            if (baud_cnt == divisor) begin
                baud_clk_o <= ~baud_clk_o;
                baud_cnt <= 16'h0000;
            end else begin
                baud_cnt <= baud_cnt + 1;
            end
        end
    end

endmodule

module rx_logic (
    input clk_i,
    input rst_i,
    input srx_pad_i,
    input [7:0] line_ctrl,
    output reg [7:0] rx_data,
    output reg rx_data_valid
);

    reg [7:0] shift_reg;
    reg [3:0] bit_cnt;
    reg [1:0] rx_state;
    reg start_bit_detected;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            rx_state <= 0;
            start_bit_detected <= 0;
            bit_cnt <= 0;
            rx_data <= 0;
            rx_data_valid <= 0;
        end else begin
            case (rx_state)
                2'b00: begin // Idle
                    if (!srx_pad_i) begin
                        start_bit_detected <= 1;
                        rx_state <= 2'b01;
                    end
                end
                2'b01: begin // Start bit
                    if (start_bit_detected) begin
                        start_bit_detected <= 0;
                        bit_cnt <= 0;
                        rx_state <= 2'b10;
                    end
                end
                2'b10: begin // Data bits
                    if (bit_cnt < 8) begin
                        shift_reg <= {srx_pad_i, shift_reg[7:1]};
                        bit_cnt <= bit_cnt + 1;
                    end else begin
                        rx_data <= shift_reg;
                        rx_state <= 2'b11;
                    end
                end
                2'b11: begin // Stop bit
                    rx_data_valid <= 1;
                    rx_state <= 2'b00;
                end
                default: rx_state <= 2'b00;
            endcase

            if (rx_data_valid) begin
                rx_data_valid <= 0;
            end
        end
    end

endmodule
