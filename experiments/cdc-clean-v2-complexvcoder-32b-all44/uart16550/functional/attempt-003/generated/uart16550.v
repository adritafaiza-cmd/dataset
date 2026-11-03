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

    // Internal signals
    reg rst;
    reg [31:0] reg_data_i;
    reg [31:0] reg_data_o;
    reg [7:0] reg_addr;
    reg reg_we;
    reg reg_stb;
    reg tx_clk;
    reg rx_clk;
    reg [7:0] tx_data;
    reg tx_empty;
    reg tx_ready;
    reg [7:0] rx_data;
    reg rx_full;
    reg rx_valid;

    // Wishbone slave interface
    wishbone_slave wb_slave_inst (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wb_adr_i(wb_adr_i),
        .wb_dat_i(wb_dat_i),
        .wb_dat_o(wb_dat_o),
        .wb_we_i(wb_we_i),
        .wb_stb_i(wb_stb_i),
        .wb_cyc_i(wb_cyc_i),
        .wb_ack_o(wb_ack_o),
        .wb_sel_i(wb_sel_i),
        .reg_data_i(reg_data_o),
        .reg_data_o(reg_data_i),
        .reg_addr_i(reg_addr),
        .reg_we_i(reg_we),
        .reg_stb_i(reg_stb)
    );

    // UART transmitter
    uart_transmitter tx_inst (
        .tx_clk(wb_clk_i),
        .rst(rst),
        .tx_data(tx_data),
        .tx_empty(tx_empty),
        .tx_ready(tx_ready),
        .stx_pad_o(stx_pad_o)
    );

    // UART receiver
    uart_receiver rx_inst (
        .rx_clk(wb_clk_i),
        .rst(rst),
        .rx_data(rx_data),
        .rx_full(rx_full),
        .rx_valid(rx_valid),
        .srx_pad_i(srx_pad_i)
    );

    // Modem control
    modem_control modem_ctrl_inst (
        .wb_clk_i(wb_clk_i),
        .rst(rst),
        .reg_data_i(reg_data_o),
        .reg_data_o(reg_data_i),
        .reg_addr_i(reg_addr),
        .reg_we_i(reg_we),
        .reg_stb_i(reg_stb),
        .cts_pad_i(cts_pad_i),
        .dsr_pad_i(dsr_pad_i),
        .ri_pad_i(ri_pad_i),
        .dcd_pad_i(dcd_pad_i),
        .rts_pad_o(rts_pad_o),
        .dtr_pad_o(dtr_pad_o)
    );

    // Interrupt control
    interrupt_control int_ctrl_inst (
        .wb_clk_i(wb_clk_i),
        .rst(rst),
        .reg_data_i(reg_data_o),
        .reg_data_o(reg_data_i),
        .reg_addr_i(reg_addr),
        .reg_we_i(reg_we),
        .reg_stb_i(reg_stb),
        .tx_empty(tx_empty),
        .rx_full(rx_full),
        .rx_valid(rx_valid),
        .int_o(int_o)
    );

    // Reset handling
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            rst <= 1'b1;
        else
            rst <= 1'b0;
    end

endmodule

module wishbone_slave (
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
    input [31:0] reg_data_i,
    output [31:0] reg_data_o,
    output [7:0] reg_addr,
    output reg_we,
    output reg_stb
);

    reg [31:0] data_out;
    reg ack;

    assign wb_dat_o = data_out;
    assign wb_ack_o = ack;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            ack <= 1'b0;
            reg_addr <= 8'b0;
            reg_we <= 1'b0;
            reg_stb <= 1'b0;
        end else begin
            if (wb_cyc_i && wb_stb_i) begin
                ack <= 1'b1;
                reg_addr <= wb_adr_i;
                reg_we <= wb_we_i;
                reg_stb <= wb_stb_i;
                if (wb_we_i) begin
                    reg_data_o <= wb_dat_i;
                end
            end else begin
                ack <= 1'b0;
                reg_stb <= 1'b0;
            end
        end
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            data_out <= 32'b0;
        end else begin
            if (wb_cyc_i && wb_stb_i && ~wb_we_i) begin
                data_out <= reg_data_i;
            end
        end
    end

endmodule

module uart_transmitter (
    input tx_clk,
    input rst,
    input [7:0] tx_data,
    output tx_empty,
    output tx_ready,
    output stx_pad_o
);

    reg [7:0] tx_shift_reg;
    reg [3:0] bit_cnt;
    reg tx_busy;

    assign tx_empty = ~tx_busy;
    assign tx_ready = ~tx_busy;

    always @(posedge tx_clk or posedge rst) begin
        if (rst) begin
            tx_shift_reg <= 8'b0;
            bit_cnt <= 4'b0;
            tx_busy <= 1'b0;
            stx_pad_o <= 1'b1;
        end else begin
            if (tx_ready && tx_data_valid) begin
                tx_shift_reg <= tx_data;
                bit_cnt <= 4'b0;
                tx_busy <= 1'b1;
                stx_pad_o <= 1'b0;
            end else if (tx_busy) begin
                if (bit_cnt < 4'd8) begin
                    stx_pad_o <= tx_shift_reg[0];
                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    bit_cnt <= bit_cnt + 4'b1;
                end else begin
                    stx_pad_o <= 1'b1;
                    tx_busy <= 1'b0;
                end
            end
        end
    end

endmodule

module uart_receiver (
    input rx_clk,
    input rst,
    output [7:0] rx_data,
    output rx_full,
    output rx_valid,
    input srx_pad_i
);

    reg [7:0] rx_shift_reg;
    reg [3:0] bit_cnt;
    reg rx_busy;
    reg rx_full_reg;
    reg [7:0] rx_data_reg;

    assign rx_data = rx_data_reg;
    assign rx_full = rx_full_reg;

    always @(posedge rx_clk or posedge rst) begin
        if (rst) begin
            rx_shift_reg <= 8'b0;
            bit_cnt <= 4'b0;
            rx_busy <= 1'b0;
            rx_full_reg <= 1'b0;
            rx_valid <= 1'b0;
            rx_data_reg <= 8'b0;
        end else begin
            if (~rx_busy && ~srx_pad_i) begin
                rx_busy <= 1'b1;
                bit_cnt <= 4'b0;
            end else if (rx_busy) begin
                if (bit_cnt < 4'd8) begin
                    rx_shift_reg <= {rx_shift_reg[6:0], srx_pad_i};
                    bit_cnt <= bit_cnt + 4'b1;
                end else begin
                    if (~rx_full_reg) begin
                        rx_data_reg <= rx_shift_reg;
                        rx_valid <= 1'b1;
                        rx_full_reg <= 1'b1;
                    end
                    rx_busy <= 1'b0;
                end
            end
            if (rx_valid && rx_data_read) begin
                rx_valid <= 1'b0;
                rx_full_reg <= 1'b0;
            end
        end
    end

endmodule

module modem_control (
    input wb_clk_i,
    input rst,
    input [31:0] reg_data_i,
    output [31:0] reg_data_o,
    input [7:0] reg_addr,
    input reg_we,
    input reg_stb,
    input cts_pad_i,
    input dsr_pad_i,
    input ri_pad_i,
    input dcd_pad_i,
    output rts_pad_o,
    output dtr_pad_o
);

    reg [31:0] modem_reg;

    assign reg_data_o = modem_reg;

    always @(posedge wb_clk_i or posedge rst) begin
        if (rst) begin
            modem_reg <= 32'b0;
            rts_pad_o <= 1'b0;
            dtr_pad_o <= 1'b0;
        end else begin
            if (reg_stb && reg_we && (reg_addr == 8'h06)) begin
                modem_reg <= reg_data_i;
                rts_pad_o <= reg_data_i[1];
                dtr_pad_o <= reg_data_i[0];
            end
        end
    end

endmodule

module interrupt_control (
    input wb_clk_i,
    input rst,
    input [31:0] reg_data_i,
    output [31:0] reg_data_o,
    input [7:0] reg_addr,
    input reg_we,
    input reg_stb,
    input tx_empty,
    input rx_full,
    input rx_valid,
    output int_o
);

    reg [31:0] interrupt_reg;

    assign reg_data_o = interrupt_reg;
    assign int_o = interrupt_reg[0] | interrupt_reg[1];

    always @(posedge wb_clk_i or posedge rst) begin
        if (rst) begin
            interrupt_reg <= 32'b0;
        end else begin
            if (reg_stb && reg_we && (reg_addr == 8'h01)) begin
                interrupt_reg <= reg_data_i;
            end
            if (rx_valid && interrupt_reg[6]) begin
                interrupt_reg[0] <= 1'b1;
            end
            if (tx_empty && interrupt_reg[2]) begin
                interrupt_reg[1] <= 1'b1;
            end
            if (reg_stb && ~reg_we && (reg_addr == 8'h02)) begin
                interrupt_reg[0] <= 1'b0;
                interrupt_reg[1] <= 1'b0;
            end
        end
    end

endmodule
