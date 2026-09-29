module uart_top (
    // Wishbone interface
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire [31:0] wb_adr_i,
    input wire [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o,
    input wire wb_we_i,
    input wire wb_stb_i,
    input wire wb_cyc_i,
    output reg wb_ack_o,
    input wire [3:0] wb_sel_i,

    // UART serial
    output wire stx_pad_o,
    input wire srx_pad_i,

    // Modem
    output wire rts_pad_o,
    input wire cts_pad_i,
    output wire dtr_pad_o,
    input wire dsr_pad_i,
    input wire ri_pad_i,
    input wire dcd_pad_i
);

// Internal registers
reg [7:0] data_reg; // Data register
reg [7:0] ier; // Interrupt Enable Register
reg [7:0] fcr; // FIFO Control Register
reg [7:0] lcr; // Line Control Register
reg [7:0] mcr; // Modem Control Register
reg [7:0] lsr; // Line Status Register
reg [7:0] msr; // Modem Status Register
reg [7:0] scr; // Scratch Register
reg [15:0] dll; // Divisor Latch

// FIFOs
reg [7:0] tx_fifo [0:15];
reg [7:0] rx_fifo [0:15];
reg [3:0] tx_wr_ptr, tx_rd_ptr;
reg [3:0] rx_wr_ptr, rx_rd_ptr;
reg tx_fifo_full, tx_fifo_empty;
reg rx_fifo_full, rx_fifo_empty;

// Baud rate generation
reg [15:0] baud_counter;
wire baud_tick = (baud_counter == 0);

// Transmitter and Receiver logic
reg stx_busy;
reg [3:0] stx_bit_count;
reg [10:0] stx_shift;

// Receiver logic
reg srx_sync, srx_prev;

// Modem control
assign rts_pad_o = ~mcr[1]; // Active low
assign dtr_pad_o = ~mcr[0]; // Active low

// Serial output
assign stx_pad_o = stx_busy ? stx_shift[10] : 1'b1;

// Wishbone ack generation
always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
        wb_ack_o <= 0;
    end else begin
        wb_ack_o <= wb_cyc_i & wb_stb_i & !wb_ack_o;
    end
end

// Wishbone read/write handling
always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
        // Reset registers
        data_reg <= 0;
        ier <= 0;
        fcr <= 0;
        lcr <= 0;
        mcr <= 0;
        lsr <= 8'h60;
        scr <= 0;
        dll <= 0;
        tx_wr_ptr <= 0;
        tx_rd_ptr <= 0;
        tx_fifo_full <= 0;
        tx_fifo_empty <= 1;
        rx_wr_ptr <= 0;
        rx_rd_ptr <= 0;
        rx_fifo_full <= 0;
        rx_fifo_empty <= 1;
        baud_counter <= 0;
        stx_busy <= 0;
        stx_bit_count <= 0;
        stx_shift <= 0;
        srx_sync <= 0;
        srx_prev <= 0;
    end else if (wb_ack_o) begin
        // Handle Wishbone transactions
        if (wb_we_i) begin
            case (wb_adr_i[3:0])
                4'h0: if (lcr[7]) dll <= {dll[15:8], wb_dat_i[7:0]};
                      else begin
                          data_reg <= wb_dat_i[7:0];
                          if (!tx_fifo_full) begin
                              tx_fifo[tx_wr_ptr] <= data_reg;
                              tx_wr_ptr <= tx_wr_ptr + 1;
                              tx_fifo_empty <= 0;
                              if (tx_wr_ptr == tx_rd_ptr) tx_fifo_full <= 1;
                          end
                      end
                4'h1: ier <= wb_dat_i[7:0];
                4'h2: fcr <= wb_dat_i[7:0];
                4'h3: lcr <= wb_dat_i[7:0];
                4'h4: mcr <= wb_dat_i[7:0];
                4'h7: scr <= wb_dat_i[7:0];
                4'h8: dll <= {dll[15:8], wb_dat_i[7:0]};
                4'h9: dll <= {wb_dat_i[7:0], dll[7:0]};
            endcase
        end else begin
            case (wb_adr_i[3:0])
                4'h0: wb_dat_o <= {24'h0, rx_fifo[rx_rd_ptr]};
                4'h1: wb_dat_o <= {24'h0, ier};
                4'h5: wb_dat_o <= {24'h0, lsr};
                4'h6: wb_dat_o <= {24'h0, msr};
                4'h7: wb_dat_o <= {24'h0, scr};
            endcase
        end
    end

    // Baud rate counter
    if (baud_tick) begin
        baud_counter <= dll;
        if (stx_busy) begin
            if (stx_bit_count == 11) stx_busy <= 0;
            else begin
                stx_bit_count <= stx_bit_count + 1;
                stx_shift <= stx_shift >> 1;
            end
        end else if (!tx_fifo_empty) begin
            stx_shift <= {1'b1, tx_fifo[tx_rd_ptr], 2'b11};
            stx_busy <= 1;
            stx_bit_count <= 0;
            tx_rd_ptr <= tx_rd_ptr + 1;
            if (tx_rd_ptr == tx_wr_ptr) begin
                tx_fifo_empty <= 1;
                tx_fifo_full <= 0;
            end
        end
    end else baud_counter <= baud_counter - 1;

    // Receiver logic
    srx_sync <= srx_pad_i;
    srx_prev <= srx_sync;
    if (srx_prev && !srx_sync && !stx_busy) begin
        stx_shift <= {1'b1, 8'h00, 1'b1};
        stx_busy <= 1;
        stx_bit_count <= 0;
    end

    // Update LSR
    lsr[0] <= !rx_fifo_empty;
    lsr[5] <= tx_fifo_empty;
end

endmodule
