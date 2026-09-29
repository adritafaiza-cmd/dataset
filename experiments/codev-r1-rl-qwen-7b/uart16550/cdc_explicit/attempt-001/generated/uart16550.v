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

    // UART serial interface
    output stx_pad_o,
    input srx_pad_i,

    // Modem control
    output rts_pad_o,
    input cts_pad_i,
    output dtr_pad_o,
    input dsr_pad_i,
    input ri_pad_i,
    input dcd_pad_i,

    // Interrupt
    output int_o
);

    // Internal registers
    reg [7:0] DR;        // Data register
    reg [7:0] IER;       // Interrupt Enable Register
    reg [7:0] FCR;       // FIFO Control Register
    reg [7:0] LCR;       // Line Control Register
    reg [7:0] MCR;       // Modem Control Register
    reg [7:0] LSR;       // Line Status Register
    reg [7:0] MSR;       // Modem Status Register
    reg [7:0] SR;        // Scratch Register
    reg [7:0] DLL;       // Divisor Latch Low
    reg [7:0] DLM;       // Divisor Latch High

    // Line Control bits
    wire dlab = LCR[7];

    // Line Status bits
    wire data_ready = LSR[0];
    wire thre = LSR[5];

    // Modem Control bits
    wire rts = MCR[1];
    wire dtr = MCR[0];

    // Assign modem outputs
    assign rts_pad_o = rts;
    assign dtr_pad_o = dtr;

    // Baud rate generation (simplified)
    reg [15:0] baud_counter;
    reg baud_tick;
    wire [15:0] divisor = {DLM, DLL};

    // Baud tick generation (16x oversampling)
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            baud_counter <= 0;
            baud_tick <= 0;
        end else begin
            if (baud_counter >= divisor - 1) begin
                baud_counter <= 0;
                baud_tick <= 1;
            end else begin
                baud_counter <= baud_counter + 1;
                baud_tick <= 0;
            end
        end
    end

    // Transmitter logic (simplified)
    reg tx_busy;
    reg [3:0] tx_bit;
    reg [7:0] tx_data;
    reg stx_reg;

    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            tx_busy <= 0;
            stx_reg <= 1;
            tx_bit <= 0;
            tx_data <= 0;
        end else if (baud_tick) begin
            if (tx_busy) begin
                if (tx_bit == 9) begin
                    tx_busy <= 0;
                    stx_reg <= 1;
                end else begin
                    tx_bit <= tx_bit + 1;
                    stx_reg <= tx_data[tx_bit];
                end
            end else if (!thre && wb_we_i && !wb_adr_i[31:3] && wb_adr_i[2:0] == 0) begin
                tx_data <= DR;
                tx_busy <= 1;
                tx_bit <= 0;
                stx_reg <= 0; // Start bit
            end
        end
    end

    assign stx_pad_o = stx_reg;

    // Receiver logic (simplified)
    reg rx_busy;
    reg [3:0] rx_bit;
    reg [7:0] rx_data;
    reg data_received;

    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            rx_busy <= 0;
            rx_bit <= 0;
            data_received <= 0;
        end else if (baud_tick) begin
            if (rx_busy) begin
                if (rx_bit == 9) begin
                    DR <= rx_data;
                    LSR[0] <= 1; // Data ready
                    rx_busy <= 0;
                end else begin
                    rx_bit <= rx_bit + 1;
                    rx_data <= {rx_data[6:0], srx_pad_i};
                end
            end else if (srx_pad_i == 0) begin // Start bit detected
                rx_busy <= 1;
                rx_bit <= 0;
            end
        end else if (wb_we_i && wb_adr_i[2:0] == 0) begin
            LSR[0] <= 0; // Clear data ready
        end
    end

    // Wishbone read logic
    always @* begin
        wb_dat_o = 32'h0;
        if (wb_stb_i && wb_cyc_i && !wb_we_i) begin
            case (wb_adr_i[2:0])
                3'h0: wb_dat_o[7:0] = dlab ? DLL : DR;
                3'h1: wb_dat_o[7:0] = IER;
                3'h2: wb_dat_o[7:0] = FCR;
                3'h3: wb_dat_o[7:0] = LCR;
                3'h4: wb_dat_o[7:0] = MCR;
                3'h5: wb_dat_o[7:0] = LSR;
                3'h6: wb_dat_o[7:0] = MSR;
                3'h7: wb_dat_o[7:0] = SR;
                default: wb_dat_o[7:0] = 0;
            endcase
        end
    end

    // Wishbone write logic
    always @(posedge wb_clk_i) begin
        wb_ack_o <= wb_stb_i && wb_cyc_i;
        if (wb_stb_i && wb_cyc_i && wb_we_i) begin
            case (wb_adr_i[2:0])
                3'h0: if (dlab) DLL <= wb_dat_i[7:0]; else DR <= wb_dat_i[7:0];
                3'h1: IER <= wb_dat_i[7:0];
                3'h2: FCR <= wb_dat_i[7:0];
                3'h3: LCR <= wb_dat_i[7:0];
                3'h4: MCR <= wb_dat_i[7:0];
                3'h5: ; // LSR is read-only
                3'h6: ; // MSR is read-only
                3'h7: SR <= wb_dat_i[7:0];
                default: ;
            endcase
        end
    end

    // Line Status defaults
    initial begin
        LSR = 8'h60; // THRE active
    end

    // Interrupt (simplified)
    assign int_o = 0;

endmodule
