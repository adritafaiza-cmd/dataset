module uart_top (
    input  wire          wb_clk_i,
    input  wire          wb_rst_i,
    input  wire  [7:0]   wb_adr_i,
    input  wire  [31:0]  wb_dat_i,
    output wire  [31:0]  wb_dat_o,
    input  wire          wb_we_i,
    input  wire          wb_stb_i,
    input  wire          wb_cyc_i,
    output wire          wb_ack_o,
    input  wire  [3:0]   wb_sel_i,
    output wire          int_o,
    output wire          stx_pad_o,
    input  wire          srx_pad_i,
    output wire          rts_pad_o,
    input  wire          cts_pad_i,
    output wire          dtr_pad_o,
    input  wire          dsr_pad_i,
    input  wire          ri_pad_i,
    input  wire          dcd_pad_i
);

    // Internal signals
    wire  [31:0] reg_data_in;
    wire  [31:0] reg_data_out;
    wire         reg_write;
    wire         reg_read;
    wire  [15:0] divisor;
    wire         baud_clk;
    wire         baud_rst;

    // Wishbone Slave instance
    wishbone_slave wb_slave_inst (
        .wb_clk_i    (wb_clk_i),
        .wb_rst_i    (wb_rst_i),
        .wb_adr_i    (wb_adr_i),
        .wb_dat_i    (wb_dat_i),
        .wb_dat_o    (wb_dat_o),
        .wb_we_i     (wb_we_i),
        .wb_stb_i    (wb_stb_i),
        .wb_cyc_i    (wb_cyc_i),
        .wb_ack_o    (wb_ack_o),
        .wb_sel_i    (wb_sel_i),
        .reg_data_in (reg_data_in),
        .reg_data_out(reg_data_out),
        .reg_write   (reg_write),
        .reg_read    (reg_read)
    );

    // UART Core instance
    uart_core uart_core_inst (
        .wb_clk_i    (wb_clk_i),
        .wb_rst_i    (wb_rst_i),
        .baud_clk    (baud_clk),
        .baud_rst    (baud_rst),
        .reg_data_in (reg_data_in),
        .reg_data_out(reg_data_out),
        .reg_write   (reg_write),
        .reg_read    (reg_read),
        .stx_pad_o   (stx_pad_o),
        .srx_pad_i   (srx_pad_i),
        .cts_pad_i   (cts_pad_i),
        .rts_pad_o   (rts_pad_o),
        .dtr_pad_o   (dtr_pad_o),
        .dsr_pad_i   (dsr_pad_i),
        .ri_pad_i    (ri_pad_i),
        .dcd_pad_i   (dcd_pad_i),
        .int_o       (int_o),
        .divisor     (divisor)
    );

    // Baud Generator instance
    baud_generator baud_gen_inst (
        .wb_clk_i    (wb_clk_i),
        .wb_rst_i    (wb_rst_i),
        .divisor     (divisor),
        .baud_clk    (baud_clk),
        .baud_rst    (baud_rst)
    );

endmodule

module wishbone_slave (
    input  wire          wb_clk_i,
    input  wire          wb_rst_i,
    input  wire  [7:0]   wb_adr_i,
    input  wire  [31:0]  wb_dat_i,
    output wire  [31:0]  wb_dat_o,
    input  wire          wb_we_i,
    input  wire          wb_stb_i,
    input  wire          wb_cyc_i,
    output wire          wb_ack_o,
    input  wire  [3:0]   wb_sel_i,
    input  wire  [31:0]  reg_data_in,
    output wire  [31:0]  reg_data_out,
    output wire          reg_write,
    output wire          reg_read
);

    reg [31:0] reg_bank [0:31];
    reg [31:0] reg_data_out_reg;
    reg        wb_ack_o_reg;
    reg        reg_write_reg;
    reg        reg_read_reg;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_ack_o_reg  <= 0;
            reg_write_reg <= 0;
            reg_read_reg  <= 0;
        end else begin
            wb_ack_o_reg <= 0;
            reg_write_reg <= 0;
            reg_read_reg  <= 0;

            if (wb_cyc_i && wb_stb_i) begin
                wb_ack_o_reg <= 1;

                if (wb_we_i) begin
                    reg_write_reg <= 1;
                    reg_bank[wb_adr_i] <= wb_dat_i;
                end else begin
                    reg_read_reg <= 1;
                    reg_data_out_reg <= reg_bank[wb_adr_i];
                end
            end
        end
    end

    assign reg_data_out = reg_data_out_reg;
    assign wb_ack_o     = wb_ack_o_reg;
    assign reg_write    = reg_write_reg;
    assign reg_read     = reg_read_reg;

endmodule

module uart_core (
    input  wire          wb_clk_i,
    input  wire          wb_rst_i,
    input  wire          baud_clk,
    input  wire          baud_rst,
    input  wire  [31:0]  reg_data_in,
    output wire  [31:0]  reg_data_out,
    input  wire          reg_write,
    input  wire          reg_read,
    output wire          stx_pad_o,
    input  wire          srx_pad_i,
    input  wire          cts_pad_i,
    output wire          rts_pad_o,
    output wire          dtr_pad_o,
    input  wire          dsr_pad_i,
    input  wire          ri_pad_i,
    input  wire          dcd_pad_i,
    output wire          int_o,
    output wire  [15:0]  divisor
);

    // Internal registers
    reg  [31:0] reg_bank [0:31];
    reg  [7:0]  tx_fifo [0:15];
    reg  [3:0]  tx_fifo_wr_ptr;
    reg  [3:0]  tx_fifo_rd_ptr;
    reg         tx_fifo_full;
    reg         tx_fifo_empty;
    reg  [7:0]  rx_fifo [0:15];
    reg  [3:0]  rx_fifo_wr_ptr;
    reg  [3:0]  rx_fifo_rd_ptr;
    reg         rx_fifo_full;
    reg         rx_fifo_empty;
    reg  [15:0] divisor_reg;

    // UART control and status registers
    reg  [7:0] rbr_thr; // Receiver Buffer Register / Transmitter Holding Register
    reg  [7:0] ier;     // Interrupt Enable Register
    reg  [5:0] iir;     // Interrupt Identification Register
    reg  [7:0] fcr;     // FIFO Control Register
    reg  [7:0] lcr;     // Line Control Register
    reg  [7:0] mcr;     // Modem Control Register
    reg  [7:0] lsr;     // Line Status Register
    reg  [7:0] msr;     // Modem Status Register
    reg  [7:0] scr;     // Scratch Register

    // UART signals
    reg  [7:0] tx_data;
    reg        tx_start;
    reg        tx_done;
    reg  [7:0] rx_data;
    reg        rx_valid;

    // UART control and status registers
    assign reg_data_out = reg_bank[wb_adr_i];

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            reg_bank[0]  <= 8'b0;  // RBR/THR
            reg_bank[1]  <= 8'b0;  // IER
            reg_bank[2]  <= 6'b0;  // IIR
            reg_bank[3]  <= 8'b0;  // LCR
            reg_bank[4]  <= 8'b0;  // MCR
            reg_bank[5]  <= 5'b0;  // LSR
            reg_bank[6]  <= 8'b0;  // MSR
            reg_bank[7]  <= 8'b0;  // SCR
            reg_bank[11] <= 16'b0; // Divisor Latch Low Byte
            reg_bank[12] <= 16'b0; // Divisor Latch High Byte
            divisor_reg  <= 16'b0;
            iir          <= 6'b100000; // No interrupt pending
            lsr          <= 5'b0;
            msr          <= 8'b0;
            tx_fifo_wr_ptr <= 4'b0;
            tx_fifo_rd_ptr <= 4'b0;
            tx_fifo_full   <= 1'b0;
            tx_fifo_empty  <= 1'b1;
            rx_fifo_wr_ptr <= 4'b0;
            rx_fifo_rd_ptr <= 4'b0;
            rx_fifo_full   <= 1'b0;
            rx_fifo_empty  <= 1'b1;
        end else begin
            // Register writes
            if (reg_write) begin
                case (wb_adr_i)
                    8'h00: reg_bank[0] <= wb_dat_i[7:0]; // RBR/THR
                    8'h01: reg_bank[1] <= wb_dat_i[7:0]; // IER
                    8'h03: reg_bank[3] <= wb_dat_i[7:0]; // LCR
                    8'h04: reg_bank[4] <= wb_dat_i[7:0]; // MCR
                    8'h07: reg_bank[7] <= wb_dat_i[7:0]; // SCR
                    8'h08: begin
                        if (lcr[7]) begin
                            reg_bank[11] <= wb_dat_i[7:0]; // Divisor Latch Low Byte
                        end else begin
                            reg_bank[0] <= wb_dat_i[7:0]; // RBR/THR
                        end
                    end
                    8'h09: begin
                        if (lcr[7]) begin
                            reg_bank[12] <= wb_dat_i[7:0]; // Divisor Latch High Byte
                            divisor_reg  <= {reg_bank[12], reg_bank[11]};
                        end else begin
                            reg_bank[1] <= wb_dat_i[7:0]; // IER
                        end
                    end
                    8'h02: begin
                        if (fcr[0]) begin
                            tx_fifo_wr_ptr <= 4'b0;
                            tx_fifo_rd_ptr <= 4'b0;
                            tx_fifo_full   <= 1'b0;
                            tx_fifo_empty  <= 1'b1;
                            rx_fifo_wr_ptr <= 4'b0;
                            rx_fifo_rd_ptr <= 4'b0;
                            rx_fifo_full   <= 1'b0;
                            rx_fifo_empty  <= 1'b1;
                        end
                    end
                    default: ;
                endcase
            end

            // Register reads
            if (reg_read) begin
                case (wb_adr_i)
                    8'h00: reg_bank[0] <= rbr_thr; // RBR/THR
                    8'h01: reg_bank[1] <= ier;     // IER
                    8'h02: reg_bank[2] <= iir;     // IIR
                    8'h03: reg_bank[3] <= lcr;     // LCR
                    8'h04: reg_bank[4] <= mcr;     // MCR
                    8'h05: reg_bank[5] <= lsr;     // LSR
                    8'h06: reg_bank[6] <= msr;     // MSR
                    8'h07: reg_bank[7] <= scr;     // SCR
                    8'h08: reg_bank[8] <= divisor_reg[7:0]; // Divisor Latch Low Byte
                    8'h09: reg_bank[9] <= divisor_reg[15:8]; // Divisor Latch High Byte
                    default: ;
                endcase
            end

            // Line Status Register (LSR)
            lsr[0] <= ~rx_fifo_empty; // Data Ready
            lsr[1] <= 1'b0;           // Overrun Error
            lsr[2] <= 1'b0;           // Parity Error
            lsr[3] <= 1'b0;           // Framing Error
            lsr[4] <= 1'b0;           // Break Interrupt
            lsr[5] <= tx_fifo_full;   // Transmitter Holding Register Empty
            lsr[6] <= tx_fifo_empty;  // Transmitter Empty
            lsr[7] <= 1'b0;           // Erroneous Character

            // Modem Status Register (MSR)
            msr[0] <= dcd_pad_i;      // Delta Clear to Send
            msr[1] <= ri_pad_i;       // Trailing Edge Ring Indicator
            msr[2] <= dsr_pad_i;      // Delta Data Set Ready
            msr[3] <= cts_pad_i;      // Clear to Send
            msr[4] <= dcd_pad_i;      // Data Carrier Detect
            msr[5] <= dsr_pad_i;      // Data Set Ready
            msr[6] <= ri_pad_i;       // Ring Indicator
            msr[7] <= 1'b0;           // Delta Ring Indicator

            // Transmit FIFO
            if (tx_start && !tx_fifo_full) begin
                tx_fifo[tx_fifo_wr_ptr] <= tx_data;
                tx_fifo_wr_ptr <= tx_fifo_wr_ptr + 1;
                if (tx_fifo_wr_ptr == 4'd15)
                    tx_fifo_wr_ptr <= 4'b0;
                if (tx_fifo_rd_ptr == tx_fifo_wr_ptr)
                    tx_fifo_full <= 1'b1;
                tx_fifo_empty <= 1'b0;
            end

            if (tx_done) begin
                tx_fifo_rd_ptr <= tx_fifo_rd_ptr + 1;
                if (tx_fifo_rd_ptr == 4'd15)
                    tx_fifo_rd_ptr <= 4'b0;
                if (tx_fifo_wr_ptr == tx_fifo_rd_ptr)
                    tx_fifo_empty <= 1'b1;
                tx_fifo_full <= 1'b0;
            end

            // Receive FIFO
            if (rx_valid && !rx_fifo_full) begin
                rx_fifo[rx_fifo_wr_ptr] <= rx_data;
                rx_fifo_wr_ptr <= rx_fifo_wr_ptr + 1;
                if (rx_fifo_wr_ptr == 4'd15)
                    rx_fifo_wr_ptr <= 4'b0;
                if (rx_fifo_rd_ptr == rx_fifo_wr_ptr)
                    rx_fifo_full <= 1'b1;
                rx_fifo_empty <= 1'b0;
            end

            // Interrupt Identification Register (IIR)
            iir[0] <= rx_fifo_empty ? 1'b0 : 1'b1; // Pending interrupt
            iir[3:1] <= rx_fifo_empty ? 3'b010 : 3'b001; // Interrupt ID

            // Interrupt output
            int_o <= iir[0];
        end
    end

    // UART transmitter
    reg [3:0] bit_count;
    reg [7:0] tx_shift_reg;
    reg       tx_shift_reg_valid;

    always @(posedge baud_clk or posedge baud_rst) begin
        if (baud_rst) begin
            bit_count <= 4'b0;
            tx_shift_reg <= 8'b0;
            tx_shift_reg_valid <= 1'b0;
            tx_start <= 1'b0;
            tx_done <= 1'b0;
            stx_pad_o <= 1'b1;
        end else begin
            if (!tx_shift_reg_valid && !tx_fifo_empty) begin
                tx_shift_reg <= {tx_fifo[tx_fifo_rd_ptr], 1'b0}; // Start bit
                tx_shift_reg_valid <= 1'b1;
                bit_count <= 4'b0;
                tx_start <= 1'b1;
            end

            if (tx_shift_reg_valid) begin
                stx_pad_o <= tx_shift_reg[0];
                tx_shift_reg <= {tx_shift_reg[7:1], 1'b1}; // Stop bit
                bit_count <= bit_count + 1;

                if (bit_count == 4'd9) begin // 8 bits + 1 start bit + 1 stop bit
                    tx_shift_reg_valid <= 1'b0;
                    tx_done <= 1'b1;
                    bit_count <= 4'b0;
                end else begin
                    tx_done <= 1'b0;
                end
            end
        end
    end

    // UART receiver
    reg [3:0] rx_bit_count;
    reg [7:0] rx_shift_reg;
    reg       rx_shift_reg_valid;

    always @(posedge baud_clk or posedge baud_rst) begin
        if (baud_rst) begin
            rx_bit_count <= 4'b0;
            rx_shift_reg <= 8'b0;
            rx_shift_reg_valid <= 1'b0;
            rx_valid <= 1'b0;
        end else begin
            if (!rx_shift_reg_valid && !srx_pad_i) begin // Start bit detected
                rx_shift_reg <= 8'b0;
                rx_shift_reg_valid <= 1'b1;
                rx_bit_count <= 4'b0;
            end

            if (rx_shift_reg_valid) begin
                rx_shift_reg <= {rx_shift_reg[6:0], srx_pad_i};
                rx_bit_count <= rx_bit_count + 1;

                if (rx_bit_count == 4'd8) begin // 8 bits received
                    rx_shift_reg_valid <= 1'b0;
                    rx_valid <= 1'b1;
                    rx_data <= rx_shift_reg;
                end else begin
                    rx_valid <= 1'b0;
                end
            end
        end
    end

    // Modem Control Register (MCR)
    assign rts_pad_o = mcr[1];
    assign dtr_pad_o = mcr[0];

endmodule

module baud_generator (
    input  wire          wb_clk_i,
    input  wire          wb_rst_i,
    input  wire  [15:0]  divisor,
    output wire          baud_clk,
    output wire          baud_rst
);

    reg [15:0] baud_div;
    reg        baud_clk_reg;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            baud_div <= 16'b0;
            baud_clk_reg <= 1'b0;
        end else begin
            if (baud_div == divisor - 1) begin
                baud_div <= 16'b0;
                baud_clk_reg <= ~baud_clk_reg;
            end else begin
                baud_div <= baud_div + 1;
            end
        end
    end

    assign baud_clk = baud_clk_reg;
    assign baud_rst = wb_rst_i;

endmodule
