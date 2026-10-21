```verilog
module uart_top (
    wb_clk_i,
    wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_sel_i,
    wb_ack_o,
    int_o,
    stx_pad_o, srx_pad_i,
    rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
);

    // Wishbone Interface
    input wb_clk_i;
    input wb_rst_i;
    input [2:0] wb_adr_i;
    input [7:0] wb_dat_i;
    output reg [7:0] wb_dat_o;
    input wb_we_i;
    input wb_stb_i;
    input wb_cyc_i;
    input [3:0] wb_sel_i;
    output wb_ack_o;

    // Modem Pins
    input cts_pad_i, dsr_pad_i, ri_pad_i, dcd_pad_i;
    output stx_pad_o, rts_pad_o, dtr_pad_o;

    // Interrupt Output
    output int_o;

    // Internal Signals
    reg [7:0] wb_dat_o_reg;
    reg wb_ack_o_reg;
    reg int_o_reg;
    reg stx_pad_o_reg;
    reg rts_pad_o_reg;
    reg dtr_pad_o_reg;

    // Baud Rate Generator Configuration
    // Assuming 16MHz clock and 9600 baud for standard 16550 behavior
    // Baud = 16_000_000 / 16 / 9600 = 104.166...
    // We use a 16-bit counter for the baud generator
    parameter BAUD_DIV = 104; 
    reg [15:0] baud_counter;
    reg baud_counter_enable;
    reg [7:0] shift_reg;
    reg shift_reg_valid;
    reg [7:0] rx_fifo [0:15];
    reg [3:0] rx_fifo_count;
    reg [7:0] tx_fifo [0:15];
    reg [3:0] tx_fifo_count;
    reg tx_fifo_empty;
    reg tx_fifo_full;
    reg tx_fifo_valid;
    reg [7:0] tx_shift_reg;
    reg tx_shift_reg_valid;
    reg [7:0] lcr; // Line Control Register
    reg [7:0] ier; // Interrupt Enable Register
    reg [7:0] iir; // Interrupt Identification Register
    reg [7:0] fcr; // FIFO Control Register
    reg [7:0] lsr; // Line Status Register
    reg [7:0] mcr; // Modem Control Register
    reg [7:0] msr; // Modem Status Register
    reg [7:0] isr; // Interrupt Status Register
    reg [7:0] rbr; // Receive Buffer Register
    reg [7:0] thr; // Transmit Holding Register
    reg [7:0] div_l; // Divisor Latch (Low)
    reg [7:0] div_h; // Divisor Latch (High)
    reg div_latch_enable;
    reg [7:0] divisor;
    reg [15:0] baud_counter_reg;
    reg [7:0] rx_fifo_ptr;
    reg [7:0] tx_fifo_ptr;
    reg [7:0] rx_fifo_count_reg;
    reg [7:0] tx_fifo_count_reg;
    reg [7:0] rx_fifo_data;
    reg [7:0] tx_fifo_data;
    reg [7:0] rx_fifo_data_reg;
    reg [7:0] tx_fifo_data_reg;
    reg [7:0] rx_fifo_count_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] tx_fifo_data_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg;
    reg [7:0] rx_fifo_count_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg_reg