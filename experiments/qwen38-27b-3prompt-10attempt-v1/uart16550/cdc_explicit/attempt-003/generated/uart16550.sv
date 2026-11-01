module uart_top (
    input  wire wb_clk_i,
    input  wire wb_rst_i,
    input  wire [7:0] wb_adr_i,
    input  wire [7:0] wb_dat_i,
    output wire [7:0] wb_dat_o,
    input  wire wb_we_i,
    input  wire wb_stb_i,
    input  wire wb_cyc_i,
    output wire wb_ack_o,
    input  wire [3:0] wb_sel_i,
    output wire int_o,
    output wire stx_pad_o,
    input  wire srx_pad_i,
    output wire rts_pad_o,
    input  wire cts_pad_i,
    output wire dtr_pad_o,
    input  wire dsr_pad_i,
    input  wire ri_pad_i,
    input  wire dcd_pad_i
);

    // Wishbone signals
    wire wb_valid = wb_cyc_i & wb_stb_i;
    wire wb_write = wb_valid & wb_we_i;
    wire wb_read  = wb_valid & ~wb_we_i;

    // Register addresses
    localparam ADDR_THR = 8'h00;
    localparam ADDR_RBR = 8'h00;
    localparam ADDR_IER = 8'h01;
    localparam ADDR_FCR = 8'h02;
    localparam ADDR_LCR = 8'h03;
    localparam ADDR_MCR = 8'h04;
    localparam ADDR_LSR = 8'h05;
    localparam ADDR_MSR = 8'h06;
    localparam ADDR_SCR = 8'h07;
    localparam ADDR_DLL = 8'h00;
    localparam ADDR_DLM = 8'h01;

    // Internal signals
    reg [7:0] ier_reg;
    reg [7:0] fcr_reg;
    reg [7:0] lcr_reg;
    reg [7:0] mcr_reg;
    reg [7:0] scr_reg;
    reg [7:0] dll_reg;
    reg [7:0] dlm_reg;

    wire lcr_dlab = lcr_reg[7];

    // FIFO signals
    reg [7:0] tx_fifo [0:15];
    reg [3:0] tx_fifo_wr_ptr;
    reg [3:0] tx_fifo_rd_ptr;
    reg [3:0] tx_fifo_count;

    reg [7:0] rx_fifo [0:15];
    reg [3:0] rx_fifo_wr_ptr;
    reg [3:0] rx_fifo_rd_ptr;
    reg [3:0] rx_fifo_count;

    // UART core signals
    reg [15:0] baud_divisor;
    reg [15:0] baud_counter;
    reg baud_counter_en;

    // TX state machine
    reg tx_active;
    reg [3:0] tx_bit_count;
    reg [7:0] tx_shift_reg;
    reg tx_start_bit;

    // RX state machine
    reg rx_active;
    reg [3:0] rx_bit_count;
    reg [7:0] rx_shift_reg;
    reg rx_start_bit;
    reg [15:0] rx_baud_counter;

    // Modem control
    wire rts_active = mcr_reg[1];
    wire dtr_active = mcr_reg[0];
    wire loopback = mcr_reg[4];

    // Interrupt sources
    wire irq_thr_empty = (tx_fifo_count == 0) & ier_reg[0];
    wire irq_rx_data = (rx_fifo_count > 0) & ier_reg[1];
    wire irq_rx_timeout = (rx_fifo_count > 0) & ier_reg[2];
    wire irq_line_status = ier_reg[3];
    wire irq_modem_status = ier_reg[4];

    wire irq_pending = irq_thr_empty | irq_rx_data | irq_rx_timeout | irq_line_status | irq_modem_status;

    // LSR bits
    wire lsr_thr_empty = (tx_fifo_count == 0);
    wire lsr_tx_empty = ~tx_active;
    wire lsr_rx_data = (rx_fifo_count > 0);
    wire lsr_break = 1'b0;
    wire lsr_framing_err = 1'b0;
    wire lsr_parity_err = 1'b0;
    wire lsr_overrun = 1'b0;

    // MSR bits
    wire msr_cts = cts_pad_i;
    wire msr_dsr = dsr_pad_i;
    wire msr_ri = ri_pad_i;
    wire msr_dcd = dcd_pad_i;

    // Baud rate calculation
    wire [15:0] baud_div = {dlm_reg, dll_reg};
    wire [15:0] baud_div_actual = (baud_div == 0) ? 16'd1 : baud_div;

    // TX logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_wr_ptr <= 4'd0;
            tx_fifo_rd_ptr <= 4'd0;
            tx_fifo_count <= 4'd0;
            tx_active <= 1'b0;
            tx_bit_count <= 4'd0;
            tx_shift_reg <= 8'd0;
            tx_start_bit <= 1'b0;
        end else begin
            // TX FIFO write
            if (wb_write && wb_adr_i == ADDR_THR && !lcr_dlab) begin
                tx_fifo[tx_fifo_wr_ptr] <= wb_dat_i;
                tx_fifo_wr_ptr <= tx_fifo_wr_ptr + 4'd1;
                tx_fifo_count <= tx_fifo_count + 4'd1;
            end

            // TX state machine
            if (tx_active) begin
                if (baud_counter_en) begin
                    if (baud_counter == 16'd0) begin
                        baud_counter <= baud_div_actual - 16'd1;
                        if (tx_bit_count == 4'd0) begin
                            // Start bit
                            tx_start_bit <= 1'b0;
                            tx_bit_count <= 4'd1;
                        end else if (tx_bit_count <= 4'd7) begin
                            // Data bits
                            tx_start_bit <= tx_shift_reg[tx_bit_count - 4'd1];
                            tx_bit_count <= tx_bit_count + 4'd1;
                        end else if (tx_bit_count == 4'd8) begin
                            // Parity bit (none)
                            tx_start_bit <= 1'b1;
                            tx_bit_count <= 4'd9;
                        end else if (tx_bit_count == 4'd9) begin
                            // Stop bit
                            tx_start_bit <= 1'b1;
                            tx_bit_count <= 4'd10;
                        end else begin
                            // Done
                            tx_active <= 1'b0;
                            tx_bit_count <= 4'd0;
                            // Read next from FIFO
                            if (tx_fifo_count > 0) begin
                                tx_shift_reg <= tx_fifo[tx_fifo_rd_ptr];
                                tx_fifo_rd_ptr <= tx_fifo_rd_ptr + 4'd1;
                                tx_fifo_count <= tx_fifo_count - 4'd1;
                                tx_active <= 1'b1;
                                tx_bit_count <= 4'd0;
                            end
                        end
                    end else begin
                        baud_counter <= baud_counter - 16'd1;
                    end
                end
            end else begin
                // Load next character if available
                if (tx_fifo_count > 0) begin
                    tx_shift_reg <= tx_fifo[tx_fifo_rd_ptr];
                    tx_fifo_rd_ptr <= tx_fifo_rd_ptr + 4'd1;
                    tx_fifo_count <= tx_fifo_count - 4'd1;
                    tx_active <= 1'b1;
                    tx_bit_count <= 4'd0;
                    baud_counter <= baud_div_actual - 16'd1;
                end
            end
        end
    end

    // Baud counter for TX
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            baud_counter <= 16'd0;
            baud_counter_en <= 1'b0;
        end else begin
            if (tx_active) begin
                baud_counter_en <= 1'b1;
            end else begin
                baud_counter_en <= 1'b0;
            end
        end
    end

    // RX logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_fifo_wr_ptr <= 4'd0;
            rx_fifo_rd_ptr <= 4'd0;
            rx_fifo_count <= 4'd0;
            rx_active <= 1'b0;
            rx_bit_count <= 4'd0;
            rx_shift_reg <= 8'd0;
            rx_start_bit <= 1'b0;
            rx_baud_counter <= 16'd0;
        end else begin
            // RX FIFO read
            if (wb_read && wb_adr_i == ADDR_RBR && !lcr_dlab && rx_fifo_count > 0) begin
                rx_fifo_rd_ptr <= rx_fifo_rd_ptr + 4'd1;
                rx_fifo_count <= rx_fifo_count - 4'd1;
            end

            // RX state machine
            if (rx_active) begin
                if (rx_baud_counter == 16'd0) begin
                    rx_baud_counter <= baud_div_actual - 16'd1;
                    if (rx_bit_count == 4'd0) begin
                        // Start bit
                        rx_start_bit <= srx_pad_i;
                        rx_bit_count <= 4'd1;
                    end else if (rx_bit_count <= 4'd7) begin
                        // Data bits
                        rx_shift_reg[rx_bit_count - 4'd1] <= srx_pad_i;
                        rx_bit_count <= rx_bit_count + 4'd1;
                    end else if (rx_bit_count == 4'd8) begin
                        // Parity bit (ignore)
                        rx_bit_count <= 4'd9;
                    end else if (rx_bit_count == 4'd9) begin
                        // Stop bit
                        rx_bit_count <= 4'd10;
                    end else begin
                        // Done
                        rx_active <= 1'b0;
                        rx_bit_count <= 4'd0;
                        // Write to FIFO
                        rx_fifo[rx_fifo_wr_ptr] <= rx_shift_reg;
                        rx_fifo_wr_ptr <= rx_fifo_wr_ptr + 4'd1;
                        rx_fifo_count <= rx_fifo_count + 4'd1;
                    end
                end else begin
                    rx_baud_counter <= rx_baud_counter - 16'd1;
                end
            end else begin
                // Detect start bit
                if (srx_pad_i == 1'b0) begin
                    rx_active <= 1'b1;
                    rx_bit_count <= 4'd0;
                    rx_baud_counter <= baud_div_actual - 16'd1;
                end
            end
        end
    end

    // Register writes
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            ier_reg <= 8'd0;
            fcr_reg <= 8'd0;
            lcr_reg <= 8'd0;
            mcr_reg <= 8'd0;
            scr_reg <= 8'd0;
            dll_reg <= 8'd0;
            dlm_reg <= 8'd0;
        end else if (wb_write) begin
            case (wb_adr_i)
                ADDR_IER: begin
                    if (!lcr_dlab) begin
                        ier_reg <= wb_dat_i;
                    end else begin
                        dlm_reg <= wb_dat_i;
                    end
                end
                ADDR_FCR: begin
                    fcr_reg <= wb_dat_i;
                    // Reset FIFOs if FCR[0] is set
                    if (wb_dat_i[0]) begin
                        tx_fifo_wr_ptr <= 4'd0;
                        tx_fifo_rd_ptr <= 4'd0;
                        tx_fifo_count <= 4'd0;
                        rx_fifo_wr_ptr <= 4'd0;
                        rx_fifo_rd_ptr <= 4'd0;
                        rx_fifo_count <= 4'd0;
                    end
                end
                ADDR_LCR: begin
                    lcr_reg <= wb_dat_i;
                end
                ADDR_MCR: begin
                    mcr_reg <= wb_dat_i;
                end
                ADDR_SCR: begin
                    scr_reg <= wb_dat_i;
                end
                ADDR_THR: begin
                    if (lcr_dlab) begin
                        dll_reg <= wb_dat_i;
                    end
                end
                default: ;
            endcase
        end
    end

    // Register reads
    reg [7:0] wb_dat_o_reg;
    always @(*) begin
        case (wb_adr_i)
            ADDR_RBR: begin
                if (!lcr_dlab) begin
                    wb_dat_o_reg = (rx_fifo_count > 0) ? rx_fifo[rx_fifo_rd_ptr] : 8'd0;
                end else begin
                    wb_dat_o_reg = dll_reg;
                end
            end
            ADDR_IER: begin
                if (!lcr_dlab) begin
                    wb_dat_o_reg = ier_reg;
                end else begin
                    wb_dat_o_reg = dlm_reg;
                end
            end
            ADDR_FCR: begin
                wb_dat_o_reg = fcr_reg;
            end
            ADDR_LCR: begin
                wb_dat_o_reg = lcr_reg;
            end
            ADDR_MCR: begin
                wb_dat_o_reg = mcr_reg;
            end
            ADDR_LSR: begin
                wb_dat_o_reg = {1'b0, lsr_overrun, lsr_parity_err, lsr_framing_err, lsr_break,
                                lsr_rx_data, lsr_tx_empty, lsr_thr_empty, 1'b0};
            end
            ADDR_MSR: begin
                wb_dat_o_reg = {1'b0, msr_dcd, msr_ri, msr_dsr, msr_cts,
                                1'b0, 1'b0, 1'b0, 1'b0};
            end
            ADDR_SCR: begin
                wb_dat_o_reg = scr_reg;
            end
            default: begin
                wb_dat_o_reg = 8'd0;
            end
        endcase
    end

    assign wb_dat_o = wb_dat_o_reg;

    // Wishbone ACK
    assign wb_ack_o = wb_valid;

    // Interrupt output
    assign int_o = irq_pending;

    // Serial output
    assign stx_pad_o = loopback ? srx_pad_i : tx_start_bit;

    // Modem control outputs
    assign rts_pad_o = rts_active;
    assign dtr_pad_o = dtr_active;

endmodule
