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

    // UART signals
    output reg stx_pad_o,
    input wire srx_pad_i,
    output reg rts_pad_o,
    input wire cts_pad_i,
    output reg dtr_pad_o,
    input wire dsr_pad_i,
    input wire ri_pad_i,
    input wire dcd_pad_i,

    // Interrupt
    output reg int_o
);

// Internal registers
reg [7:0] data_reg; // Data buffer
reg [7:0] ier; // Interrupt Enable Register
reg [7:0] fcr; // FIFO Control Register
reg [7:0] lcr; // Line Control Register
reg [7:0] mcr; // Modem Control Register
reg [7:0] lsr; // Line Status Register
reg [7:0] msr; // Modem Status Register
reg [7:0] dll; // Divisor Latch Low
reg [7:0] dlm; // Divisor Latch High

// Transmitter FSM
reg tx_busy;
reg [3:0] tx_bit_count;
reg [7:0] tx_shift;

// Baud rate generator
reg [15:0] baud_counter;
wire [15:0] divisor = {dlm, dll};
wire baud_tick;

// Modem status
assign msr[0] = dcd_pad_i;
assign msr[1] = ri_pad_i;
assign msr[2] = dsr_pad_i;
assign msr[3] = cts_pad_i;

// Line status: bit 0 - data ready, bit 5 - THRE
// Assuming data_reg is written when TX is done
// For simplicity, lsr[0] is set when data is received, and cleared when read
// Similarly, lsr[5] is set when data_reg is empty.

// Wishbone handling
always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
        wb_ack_o <= 0;
        data_reg <= 0;
        ier <= 0;
        fcr <= 0;
        lcr <= 0;
        mcr <= 0;
        lsr <= 8'h60; // Default line status (data ready not set)
        msr <= 0;
        dll <= 0;
        dlm <= 0;
        tx_busy <= 0;
        stx_pad_o <= 1;
        rts_pad_o <= 1; // Active low, default deasserted
        dtr_pad_o <= 1; // Active low, default deasserted
    end else begin
        wb_ack_o <= 0;
        if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
            wb_ack_o <= 1;
            if (wb_we_i) begin
                // Write operation
                case (wb_adr_i[3:0])
                    4'h0: begin
                        if (lcr[7]) // DLAB mode
                            dll <= wb_dat_i[7:0];
                        else
                            data_reg <= wb_dat_i[7:0];
                    end
                    4'h1: begin
                        if (lcr[7])
                            dlm <= wb_dat_i[7:0];
                        else
                            ier <= wb_dat_i[7:0];
                    end
                    4'h2: fcr <= wb_dat_i[7:0];
                    4'h3: lcr <= wb_dat_i[7:0];
                    4'h4: mcr <= wb_dat_i[7:0];
                    // ... other addresses
                endcase
            end else begin
                // Read operation
                case (wb_adr_i[3:0])
                    4'h0: wb_dat_o <= {24'b0, data_reg};
                    4'h5: wb_dat_o <= {24'b0, lsr};
                    4'h6: wb_dat_o <= {24'b0, msr};
                    // ... other addresses
                endcase
            end
        end
    end
end

// Baud rate generation
always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
        baud_counter <= 0;
    end else begin
        if (tx_busy) begin
            if (baud_counter == divisor) begin
                baud_counter <= 0;
            end else begin
                baud_counter <= baud_counter + 1;
            end
        end else begin
            baud_counter <= 0;
        end
    end
end

assign baud_tick = (baud_counter == divisor);

// Transmitter logic
always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
        tx_busy <= 0;
        tx_bit_count <= 0;
        tx_shift <= 0;
        stx_pad_o <= 1;
        lsr[5] <= 1; // THRE set initially
    end else begin
        if (tx_busy) begin
            if (baud_tick) begin
                if (tx_bit_count == 8) begin
                    tx_busy <= 0;
                    stx_pad_o <= 1;
                    lsr[5] <= 1; // THRE set
                end else begin
                    tx_bit_count <= tx_bit_count + 1;
                    stx_pad_o <= tx_shift[7];
                    tx_shift <= {tx_shift[6:0], 1'b0};
                end
            end
        end else if (lsr[5]) begin // THRE is set (ready to transmit)
            if (data_reg != 0) begin // Assuming data is available
                tx_shift <= data_reg;
                tx_bit_count <= 0;
                tx_busy <= 1;
                stx_pad_o <= 0; // Start bit
                lsr[5] <= 0; // THRE cleared
            end
        end
    end
end

// Modem control
// RTS is controlled by MCR bit 1 (active low)
always @* begin
    rts_pad_o = ~mcr[1];
end

// DTR is controlled by MCR bit 0 (active low)
always @* begin
    dtr_pad_o = ~mcr[0];
end

// Interrupt logic
// int_o is asserted if enabled and conditions met
// For example, data received and interrupt enabled
always @* begin
    int_o = (lsr[0] && ier[0]);
end

endmodule
