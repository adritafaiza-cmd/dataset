module uart16550 (
    input  wire        wb_clk_i,
    input  wire        wb_rst_i,
    input  wire  [7:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output wire [31:0] wb_dat_o,
    input  wire        wb_we_i,
    input  wire        wb_stb_i,
    input  wire        wb_cyc_i,
    output wire        wb_ack_o,
    input  wire  [3:0] wb_sel_i,
    output wire        int_o,
    output wire        stx_pad_o,
    input  wire        srx_pad_i,
    output wire        rts_pad_o,
    input  wire        cts_pad_i,
    output wire        dtr_pad_o,
    input  wire        dsr_pad_i,
    input  wire        ri_pad_i,
    input  wire        dcd_pad_i
);

    wire [31:0] wb_slave_dat_o;
    wire        wb_slave_we_i;
    wire [7:0]  wb_slave_adr_i;
    wire [31:0] wb_slave_dat_i;
    wire        wb_slave_ack_o;

    wishbone_slave wb_slave_inst (
        .clk_i  (wb_clk_i),
        .rst_i  (wb_rst_i),
        .adr_i  (wb_adr_i),
        .dat_i  (wb_dat_i),
        .dat_o  (wb_slave_dat_o),
        .we_i   (wb_we_i),
        .stb_i  (wb_stb_i),
        .cyc_i  (wb_cyc_i),
        .ack_o  (wb_slave_ack_o),
        .sel_i  (wb_sel_i)
    );

    uart_core uart_core_inst (
        .clk_i      (wb_clk_i),
        .rst_i      (wb_rst_i),
        .wb_dat_i   (wb_slave_dat_o),
        .wb_we_i    (wb_slave_we_i),
        .wb_adr_i   (wb_slave_adr_i),
        .wb_ack_o   (wb_slave_ack_o),
        .tx_pad_o   (stx_pad_o),
        .rx_pad_i   (srx_pad_i),
        .rts_pad_o  (rts_pad_o),
        .cts_pad_i  (cts_pad_i),
        .dtr_pad_o  (dtr_pad_o),
        .dsr_pad_i  (dsr_pad_i),
        .ri_pad_i   (ri_pad_i),
        .dcd_pad_i  (dcd_pad_i),
        .int_o      (int_o)
    );

    assign wb_dat_o  = wb_slave_dat_i;
    assign wb_ack_o  = wb_slave_ack_o;
    assign wb_slave_we_i  = wb_we_i;
    assign wb_slave_adr_i = wb_adr_i;
    assign wb_slave_dat_i = wb_dat_o;

endmodule

module wishbone_slave (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire  [7:0] adr_i,
    input  wire [31:0] dat_i,
    output wire [31:0] dat_o,
    input  wire        we_i,
    input  wire        stb_i,
    input  wire        cyc_i,
    output wire        ack_o,
    input  wire  [3:0] sel_i
);

    reg [31:0] registers [0:255];
    reg [31:0] dat_o_reg;
    reg        ack_o_reg;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            dat_o_reg <= 32'h0;
            ack_o_reg <= 1'b0;
            for (integer i = 0; i < 256; i = i + 1)
                registers[i] <= 32'h0;
        end else begin
            ack_o_reg <= 1'b0;
            if (cyc_i && stb_i) begin
                if (we_i) begin
                    case (sel_i)
                        4'b0001: registers[adr_i] <= {registers[adr_i][31:8], dat_i[7:0]};
                        4'b0010: registers[adr_i] <= {registers[adr_i][31:16], dat_i[15:8], registers[adr_i][7:0]};
                        4'b0100: registers[adr_i] <= {registers[adr_i][31:24], dat_i[23:16], registers[adr_i][15:0]};
                        4'b1000: registers[adr_i] <= {dat_i[31:24], registers[adr_i][23:0]};
                        4'b0011: registers[adr_i] <= {registers[adr_i][31:16], dat_i[15:0]};
                        4'b0101: registers[adr_i] <= {registers[adr_i][31:24], dat_i[23:8], registers[adr_i][7:0]};
                        4'b0110: registers[adr_i] <= {registers[adr_i][31:24], dat_i[23:16], dat_i[15:8], registers[adr_i][7:0]};
                        4'b1001: registers[adr_i] <= {dat_i[31:16], registers[adr_i][15:0]};
                        4'b1010: registers[adr_i] <= {dat_i[31:24], dat_i[23:8], registers[adr_i][15:0]};
                        4'b1011: registers[adr_i] <= {dat_i[31:24], dat_i[23:16], dat_i[15:8], registers[adr_i][7:0]};
                        4'b1100: registers[adr_i] <= {dat_i[31:16], dat_i[15:8], registers[adr_i][7:0]};
                        4'b1101: registers[adr_i] <= {dat_i[31:16], dat_i[15:8], dat_i[7:0]};
                        4'b1110: registers[adr_i] <= {dat_i[31:16], dat_i[15:0]};
                        4'b1111: registers[adr_i] <= dat_i;
                        default: registers[adr_i] <= registers[adr_i];
                    endcase
                end else begin
                    dat_o_reg <= registers[adr_i];
                end
                ack_o_reg <= 1'b1;
            end
        end
    end

    assign dat_o = dat_o_reg;
    assign ack_o = ack_o_reg;

endmodule

module uart_core (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire [31:0] wb_dat_i,
    input  wire        wb_we_i,
    input  wire  [7:0] wb_adr_i,
    output wire        wb_ack_o,
    output wire        tx_pad_o,
    input  wire        rx_pad_i,
    output wire        rts_pad_o,
    input  wire        cts_pad_i,
    output wire        dtr_pad_o,
    input  wire        dsr_pad_i,
    input  wire        ri_pad_i,
    input  wire        dcd_pad_i,
    output wire        int_o
);

    reg [31:0] registers [0:255];
    reg        wb_ack_o_reg;
    reg        tx_pad_o_reg;
    reg        rts_pad_o_reg;
    reg        dtr_pad_o_reg;
    reg        int_o_reg;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            wb_ack_o_reg  <= 1'b0;
            tx_pad_o_reg  <= 1'b1;
            rts_pad_o_reg <= 1'b1;
            dtr_pad_o_reg <= 1'b1;
            int_o_reg     <= 1'b0;
            for (integer i = 0; i < 256; i = i + 1)
                registers[i] <= 32'h0;
        end else begin
            wb_ack_o_reg <= 1'b0;
            if (wb_we_i) begin
                registers[wb_adr_i] <= wb_dat_i;
                wb_ack_o_reg <= 1'b1;
            end

            // Simple UART core logic (simplified for demonstration)
            case (wb_adr_i)
                8'h00: begin // THR (Transmit Holding Register)
                    tx_pad_o_reg <= wb_dat_i[0];
                    wb_ack_o_reg <= 1'b1;
                end
                8'h01: begin // IER (Interrupt Enable Register)
                    // Handle interrupt enables
                    wb_ack_o_reg <= 1'b1;
                end
                8'h02: begin // IIR (Interrupt Identification Register)
                    // Handle interrupt identification
                    wb_ack_o_reg <= 1'b1;
                end
                8'h03: begin // FCR (FIFO Control Register)
                    // Handle FIFO control
                    wb_ack_o_reg <= 1'b1;
                end
                8'h04: begin // LCR (Line Control Register)
                    // Handle line control
                    wb_ack_o_reg <= 1'b1;
                end
                8'h06: begin // MCR (Modem Control Register)
                    rts_pad_o_reg <= wb_dat_i[1];
                    dtr_pad_o_reg <= wb_dat_i[0];
                    wb_ack_o_reg <= 1'b1;
                end
                8'h07: begin // LSR (Line Status Register)
                    // Handle line status read
                    wb_ack_o_reg <= 1'b1;
                end
                8'h08: begin // MSR (Modem Status Register)
                    // Handle modem status read
                    wb_ack_o_reg <= 1'b1;
                end
                8'h09: begin // SCR (Scratch Register)
                    // Handle scratch register
                    wb_ack_o_reg <= 1'b1;
                end
                default: begin
                    wb_ack_o_reg <= 1'b0;
                end
            endcase

            // Simple interrupt generation logic (simplified for demonstration)
            int_o_reg <= (registers[8'h01] & registers[8'h02]) ? 1'b1 : 1'b0;
        end
    end

    assign tx_pad_o  = tx_pad_o_reg;
    assign rts_pad_o = rts_pad_o_reg;
    assign dtr_pad_o = dtr_pad_o_reg;
    assign int_o     = int_o_reg;
    assign wb_ack_o  = wb_ack_o_reg;

endmodule
