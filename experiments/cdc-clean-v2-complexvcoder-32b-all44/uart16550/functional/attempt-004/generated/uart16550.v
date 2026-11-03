module uart_top (
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire [7:0] wb_adr_i,
    input wire [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o,
    input wire wb_we_i,
    input wire wb_stb_i,
    input wire wb_cyc_i,
    output reg wb_ack_o,
    input wire [3:0] wb_sel_i,
    output reg int_o,
    output reg stx_pad_o,
    input wire srx_pad_i,
    output reg rts_pad_o,
    input wire cts_pad_i,
    output reg dtr_pad_o,
    input wire dsr_pad_i,
    input wire ri_pad_i,
    input wire dcd_pad_i
);

    // Internal signals
    wire uart_clk;
    wire uart_rst;
    wire [7:0] tx_data;
    wire tx_valid;
    wire tx_ready;
    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_ready;
    wire [7:0] mcr;

    // Wishbone Slave Module
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
        .int_o(int_o),
        .uart_clk(uart_clk),
        .uart_rst(uart_rst),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_ready(rx_ready),
        .mcr(mcr)
    );

    // UART Core Module
    uart_core uart_core_inst (
        .uart_clk(uart_clk),
        .uart_rst(uart_rst),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_ready(rx_ready),
        .stx_pad_o(stx_pad_o),
        .srx_pad_i(srx_pad_i)
    );

    // Modem Control Module
    modem_control modem_ctrl_inst (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .mcr(mcr),
        .rts_pad_o(rts_pad_o),
        .dtr_pad_o(dtr_pad_o),
        .cts_pad_i(cts_pad_i),
        .dsr_pad_i(dsr_pad_i),
        .ri_pad_i(ri_pad_i),
        .dcd_pad_i(dcd_pad_i)
    );

endmodule

// Wishbone Slave Module
module wishbone_slave (
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire [7:0] wb_adr_i,
    input wire [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o,
    input wire wb_we_i,
    input wire wb_stb_i,
    input wire wb_cyc_i,
    output reg wb_ack_o,
    input wire [3:0] wb_sel_i,
    output reg int_o,
    output reg uart_clk,
    output reg uart_rst,
    output reg [7:0] tx_data,
    output reg tx_valid,
    input wire tx_ready,
    input wire [7:0] rx_data,
    input wire rx_valid,
    output reg rx_ready,
    output reg [7:0] mcr
);

    // Internal registers
    reg [7:0] rbr;
    reg [7:0] thr;
    reg [7:0] ier;
    reg [5:0] iir;
    reg [7:0] fcr;
    reg [7:0] lcr;
    reg [7:0] mcr;
    reg [7:0] lsr;
    reg [7:0] msr;

    // FIFOs
    reg [7:0] tx_fifo [0:15];
    reg [3:0] tx_fifo_wr_ptr;
    reg [3:0] tx_fifo_rd_ptr;
    reg [3:0] tx_fifo_count;
    reg [7:0] rx_fifo [0:15];
    reg [3:0] rx_fifo_wr_ptr;
    reg [3:0] rx_fifo_rd_ptr;
    reg [3:0] rx_fifo_count;

    // Control signals
    reg rx_fifo_full;
    reg rx_fifo_empty;
    reg tx_fifo_full;
    reg tx_fifo_empty;

    // Baud rate divisor
    reg [15:0] baud_divisor;

    // Interrupt handling
    reg int_pend;

    // State machine
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam READ = 2'b01;
    localparam WRITE = 2'b10;

    // FIFO control logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_wr_ptr <= 4'b0000;
            tx_fifo_rd_ptr <= 4'b0000;
            tx_fifo_count <= 4'b0000;
            rx_fifo_wr_ptr <= 4'b0000;
            rx_fifo_rd_ptr <= 4'b0000;
            rx_fifo_count <= 4'b0000;
        end else begin
            // TX FIFO
            if (tx_valid && !tx_fifo_full) begin
                tx_fifo[tx_fifo_wr_ptr] <= tx_data;
                tx_fifo_wr_ptr <= tx_fifo_wr_ptr + 1;
                tx_fifo_count <= tx_fifo_count + 1;
            end
            if (tx_ready && !tx_fifo_empty) begin
                tx_fifo_rd_ptr <= tx_fifo_rd_ptr + 1;
                tx_fifo_count <= tx_fifo_count - 1;
            end

            // RX FIFO
            if (rx_valid && !rx_fifo_full) begin
                rx_fifo[rx_fifo_wr_ptr] <= rx_data;
                rx_fifo_wr_ptr <= rx_fifo_wr_ptr + 1;
                rx_fifo_count <= rx_fifo_count + 1;
            end
            if (rx_ready && !rx_fifo_empty) begin
                rx_fifo_rd_ptr <= rx_fifo_rd_ptr + 1;
                rx_fifo_count <= rx_fifo_count - 1;
            end
        end
    end

    // FIFO status flags
    assign tx_fifo_full = (tx_fifo_count == 4'b1000);
    assign tx_fifo_empty = (tx_fifo_count == 4'b0000);
    assign rx_fifo_full = (rx_fifo_count == 4'b1000);
    assign rx_fifo_empty = (rx_fifo_count == 4'b0000);

    // Control signals
    assign tx_valid = !tx_fifo_empty;
    assign rx_ready = !rx_fifo_full;

    // State machine
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            state <= IDLE;
            wb_ack_o <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    wb_ack_o <= 1'b0;
                    if (wb_stb_i && wb_cyc_i) begin
                        if (wb_we_i)
                            state <= WRITE;
                        else
                            state <= READ;
                    end
                end
                READ: begin
                    case (wb_adr_i)
                        8'h00: wb_dat_o <= {24'b0, rbr};
                        8'h01: wb_dat_o <= {24'b0, ier};
                        8'h02: wb_dat_o <= {24'b0, iir};
                        8'h03: wb_dat_o <= {24'b0, lcr};
                        8'h04: wb_dat_o <= {24'b0, mcr};
                        8'h05: wb_dat_o <= {24'b0, lsr};
                        8'h06: wb_dat_o <= {24'b0, msr};
                        8'h07: wb_dat_o <= {16'b0, baud_divisor[15:8]};
                        8'h08: wb_dat_o <= {16'b0, baud_divisor[7:0]};
                        default: wb_dat_o <= 32'b0;
                    endcase
                    wb_ack_o <= 1'b1;
                    state <= IDLE;
                end
                WRITE: begin
                    case (wb_adr_i)
                        8'h00: thr <= wb_dat_i[7:0];
                        8'h01: ier <= wb_dat_i[7:0];
                        8'h03: lcr <= wb_dat_i[7:0];
                        8'h04: mcr <= wb_dat_i[7:0];
                        8'h06: msr <= wb_dat_i[7:0];
                        8'h07: baud_divisor[15:8] <= wb_dat_i[7:0];
                        8'h08: baud_divisor[7:0] <= wb_dat_i[7:0];
                        default: ;
                    endcase
                    wb_ack_o <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

    // UART clock and reset
    assign uart_clk = wb_clk_i;
    assign uart_rst = wb_rst_i;

endmodule

// UART Core Module
module uart_core (
    input wire uart_clk,
    input wire uart_rst,
    input wire [7:0] tx_data,
    input wire tx_valid,
    output reg tx_ready,
    output reg [7:0] rx_data,
    output reg rx_valid,
    input wire rx_ready,
    output reg stx_pad_o,
    input wire srx_pad_i
);

    // TX Logic
    reg [7:0] tx_shift_reg;
    reg [3:0] tx_bit_cnt;
    reg tx_state;

    // RX Logic
    reg [7:0] rx_shift_reg;
    reg [3:0] rx_bit_cnt;
    reg rx_state;

    // TX State Machine
    always @(posedge uart_clk or posedge uart_rst) begin
        if (uart_rst) begin
            tx_state <= 1'b0;
            tx_shift_reg <= 8'b0;
            tx_bit_cnt <= 4'b0;
            tx_ready <= 1'b1;
            stx_pad_o <= 1'b1;
        end else begin
            case (tx_state)
                1'b0: begin
                    if (tx_valid) begin
                        tx_shift_reg <= tx_data;
                        tx_bit_cnt <= 4'b0;
                        tx_ready <= 1'b0;
                        tx_state <= 1'b1;
                        stx_pad_o <= 1'b0; // Start bit
                    end
                end
                1'b1: begin
                    tx_bit_cnt <= tx_bit_cnt + 1;
                    if (tx_bit_cnt == 4'b1000) begin
                        tx_state <= 1'b0;
                        tx_ready <= 1'b1;
                        stx_pad_o <= 1'b1; // Stop bit
                    end else begin
                        stx_pad_o <= tx_shift_reg[0];
                        tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
                    end
                end
            endcase
        end
    end

    // RX State Machine
    always @(posedge uart_clk or posedge uart_rst) begin
        if (uart_rst) begin
            rx_state <= 1'b0;
            rx_shift_reg <= 8'b0;
            rx_bit_cnt <= 4'b0;
            rx_data <= 8'b0;
            rx_valid <= 1'b0;
        end else begin
            case (rx_state)
                1'b0: begin
                    if (!srx_pad_i) begin // Start bit
                        rx_bit_cnt <= 4'b0;
                        rx_state <= 1'b1;
                    end
                end
                1'b1: begin
                    rx_bit_cnt <= rx_bit_cnt + 1;
                    if (rx_bit_cnt == 4'b1000) begin
                        rx_data <= rx_shift_reg;
                        rx_valid <= 1'b1;
                        rx_state <= 1'b0;
                    end else begin
                        rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                    end
                end
            endcase
        end
    end

    // RX Ready
    always @(posedge uart_clk or posedge uart_rst) begin
        if (uart_rst)
            rx_valid <= 1'b0;
        else if (rx_ready)
            rx_valid <= 1'b0;
    end

endmodule

// Modem Control Module
module modem_control (
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire [7:0] mcr,
    output reg rts_pad_o,
    output reg dtr_pad_o,
    input wire cts_pad_i,
    input wire dsr_pad_i,
    input wire ri_pad_i,
    input wire dcd_pad_i
);

    // Modem Control Register
    reg [7:0] mcr_reg;

    // Assign outputs based on MCR
    assign rts_pad_o = mcr[1];
    assign dtr_pad_o = mcr[0];

    // Register MCR
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            mcr_reg <= 8'b0;
        else
            mcr_reg <= mcr;
    end

endmodule
