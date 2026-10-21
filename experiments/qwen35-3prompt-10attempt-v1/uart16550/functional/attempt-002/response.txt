```verilog
module uart_top (
    wb_clk_i,
    wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_sel_i,
    wb_ack_o,
    int_o,
    stx_pad_o, srx_pad_i,
    rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
);

    // Wishbone Bus Parameters
    parameter WB_ADDR_WIDTH = 16;
    parameter WB_DATA_WIDTH = 32;

    // Internal Signals
    reg [WB_DATA_WIDTH-1:0] wb_dat_o_reg;
    reg wb_ack_o_reg;
    reg int_o_reg;
    reg stx_pad_o_reg;
    reg rts_pad_o_reg;
    reg dtr_pad_o_reg;

    // Registers Map (Standard 16550 Layout)
    // 0x00: IER (Interrupt Enable Register)
    // 0x01: IIR (Interrupt Identification Register)
    // 0x02: FCR (FIFO Control Register)
    // 0x03: LCR (Line Control Register)
    // 0x04: MCR (Modem Control Register)
    // 0x05: LSR (Line Status Register)
    // 0x06: MSR (Modem Status Register)
    // 0x07: SCR (Scratch Register)
    // 0x08: DR (Data Register / THR)
    // 0x09: RHR (Receive Holding Register)
    // 0x0A: ISR (Interrupt Status Register)
    // 0x0B: SP (Baud Rate Divisor L)
    // 0x0C: DP (Baud Rate Divisor H)

    reg [7:0] reg_ier;
    reg [7:0] reg_iir;
    reg [7:0] reg_fcr;
    reg [7:0] reg_lcr;
    reg [7:0] reg_mcr;
    reg [7:0] reg_lsr;
    reg [7:0] reg_msr;
    reg [7:0] reg_scr;
    reg [7:0] reg_dr;
    reg [7:0] reg_rhr;
    reg [7:0] reg_isr;
    reg [7:0] reg_sp;
    reg [7:0] reg_dp;

    // Internal State
    reg [15:0] baud_div;
    reg [7:0] tx_data;
    reg tx_busy;
    reg tx_done;
    reg [7:0] rx_data;
    reg rx_valid;
    reg [3:0] rx_fifo_cnt;
    reg [3:0] tx_fifo_cnt;
    reg [3:0] rx_fifo_ptr;
    reg [3:0] tx_fifo_ptr;
    reg [3:0] rx_fifo_mask;
    reg [3:0] tx_fifo_mask;
    reg [3:0] rx_fifo_data [0:15];
    reg [3:0] tx_fifo_data [0:15];
    reg [3:0] rx_fifo_next_ptr;
    reg [3:0] tx_fifo_next_ptr;
    reg [3:0] rx_fifo_next_mask;
    reg [3:0] tx_fifo_next_mask;
    reg [3:0] rx_fifo_next_data [0:15];
    reg [3:0] tx_fifo_next_data [0:15];
    reg [3:0] rx_fifo_next_next_ptr;
    reg [3:0] tx_fifo_next_next_ptr;
    reg [3:0] rx_fifo_next_next_mask;
    reg [3:0] tx_fifo_next_next_mask;
    reg [3:0] rx_fifo_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_data [0:15];
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_ptr;
    reg [3:0] rx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask;
    reg [3:0] tx_fifo_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_mask