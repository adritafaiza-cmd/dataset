// =============================================================================
// SPI Master with Parallel-Side Word Interface
// =============================================================================
//
// Architecture:
//   - Parallel domain (pclk_i): word handshake, transmit FIFO, receive FIFO
//   - Serial domain (sclk_i): SPI shift register, clock generation
//   - CDC: 2-stage synchronizers for control signals, FIFOs for data
//
// Handshake protocol:
//   1. Parallel side: wren_i high -> wr_ack_o pulses, word stored in FIFO
//   2. Serial side: detects FIFO non-empty, starts SPI transfer
//   3. Serial side: after N clocks, pushes received word to receive FIFO
//   4. Parallel side: detects receive FIFO non-empty, do_valid_o pulses
//   5. di_req_o indicates parallel side can accept another word
//
// =============================================================================

module spi_master #(
    parameter N = 8,
    parameter SPI_2X_CLK_DIV = 2
)(
    input              sclk_i,
    input              pclk_i,
    input              rst_i,

    // SPI signals
    output reg         spi_ssel_o,
    output reg         spi_sck_o,
    output             spi_mosi_o,
    input              spi_miso_i,

    // Parallel-side word interface
    output reg         di_req_o,
    input  [N-1:0]     di_i,
    input              wren_i,
    output reg         wr_ack_o,
    output reg         do_valid_o,
    output reg [N-1:0] do_o
);

    // =========================================================================
    // Transmit FIFO (parallel -> serial)
    // =========================================================================
    reg [N-1:0] tx_fifo_mem [0:1];
    reg [1:0]   tx_wr_ptr;
    reg [1:0]   tx_rd_ptr;

    wire tx_fifo_full  = (tx_wr_ptr[1] == tx_rd_ptr[1]) && (tx_wr_ptr[0] != tx_rd_ptr[0]);
    wire tx_fifo_empty = (tx_wr_ptr == tx_rd_ptr);

    // =========================================================================
    // Receive FIFO (serial -> parallel)
    // =========================================================================
    reg [N-1:0] rx_fifo_mem [0:1];
    reg [1:0]   rx_wr_ptr;
    reg [1:0]   rx_rd_ptr;

    wire rx_fifo_full  = (rx_wr_ptr[1] == rx_rd_ptr[1]) && (rx_wr_ptr[0] != rx_rd_ptr[0]);
    wire rx_fifo_empty = (rx_wr_ptr == rx_rd_ptr);

    // =========================================================================
    // Parallel domain: write handshake
    // =========================================================================
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            tx_wr_ptr <= 2'd0;
            wr_ack_o  <= 1'b0;
            di_req_o  <= 1'b0;
        end else begin
            wr_ack_o <= 1'b0;

            if (wren_i && !tx_fifo_full) begin
                tx_fifo_mem[tx_wr_ptr[0]] <= di_i;
                tx_wr_ptr <= tx_wr_ptr + 2'd1;
                wr_ack_o  <= 1'b1;
            end
        end
    end

    // =========================================================================
    // Parallel domain: read handshake
    // =========================================================================
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            rx_rd_ptr  <= 2'd0;
            do_valid_o <= 1'b0;
            do_o       <= {N{1'b0}};
        end else begin
            do_valid_o <= 1'b0;

            if (!rx_fifo_empty) begin
                do_o       <= rx_fifo_mem[rx_rd_ptr[0]];
                rx_rd_ptr  <= rx_rd_ptr + 2'd1;
                do_valid_o <= 1'b1;
            end
        end
    end

    // =========================================================================
    // di_req_o: high when transmit FIFO is not full
    // =========================================================================
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            di_req_o <= 1'b0;
        else
            di_req_o <= !tx_fifo_full;
    end

    // =========================================================================
    // Serial domain: SPI shift register and clock generation
    // =========================================================================
    reg [N-1:0] tx_shift;
    reg [N-1:0] rx_shift;
    reg [3:0]   clk_div;
    reg         sck_phase;
    reg         shifting;

    // Synchronize FIFO status from parallel domain
    reg [1:0] tx_empty_sync;
    reg [1:0] rx_full_sync;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            tx_empty_sync <= 2'b11;
            rx_full_sync  <= 2'b00;
        end else begin
            tx_empty_sync <= {tx_empty_sync[0], tx_fifo_empty};
            rx_full_sync  <= {rx_full_sync[0], rx_fifo_full};
        end
    end

    wire tx_empty_s = tx_empty_sync[1];
    wire rx_full_s  = rx_full_sync[1];

    // SPI state machine
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o  <= 1'b0;
            tx_shift   <= {N{1'b0}};
            rx_shift   <= {N{1'b0}};
            clk_div    <= 4'd0;
            sck_phase  <= 1'b0;
            shifting   <= 1'b0;
            rx_wr_ptr  <= 2'd0;
        end else begin
            // Default: idle
            spi_sck_o <= 1'b0;

            if (!shifting) begin
                // Start transfer if data available and receive FIFO not full
                if (!tx_empty_s && !rx_full_s) begin
                    tx_shift   <= tx_fifo_mem[tx_rd_ptr[0]];
                    tx_rd_ptr  <= tx_rd_ptr + 2'd1;
                    rx_shift   <= {N{1'b0}};
                    clk_div    <= 4'd0;
                    sck_phase  <= 1'b0;
                    shifting   <= 1'b1;
                    spi_ssel_o <= 1'b0;
                end
            end else begin
                // Clock divider
                clk_div <= clk_div + 4'd1;

                if (clk_div == SPI_2X_CLK_DIV - 1) begin
                    clk_div <= 4'd0;

                    if (!sck_phase) begin
                        // Rising edge: shift out, shift in
                        spi_sck_o <= 1'b1;
                        sck_phase <= 1'b1;

                        rx_shift <= {rx_shift[N-2:0], spi_miso_i};
                        tx_shift <= {tx_shift[N-2:0], 1'b0};

                        // Last bit?
                        if (clk_div == SPI_2X_CLK_DIV - 1 && tx_shift[N-1] == 1'b0 &&
                            tx_shift[N-2:0] == {N-1{1'b0}}) begin
                            // Transfer complete
                            rx_fifo_mem[rx_wr_ptr[0]] <= rx_shift;
                            rx_wr_ptr <= rx_wr_ptr + 2'd1;
                            shifting  <= 1'b0;
                            spi_ssel_o <= 1'b1;
                        end
                    end else begin
                        // Falling edge
                        sck_phase <= 1'b0;
                    end
                end
            end
        end
    end

    assign spi_mosi_o = tx_shift[N-1];

endmodule