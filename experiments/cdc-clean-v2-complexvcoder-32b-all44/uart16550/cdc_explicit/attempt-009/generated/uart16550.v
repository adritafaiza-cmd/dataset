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
    reg [383:0] wb_registers;
    wire [383:0] wb_registers_next;
    reg [31:0] wb_dat_o_reg;
    reg wb_ack_o_reg;

    // Wishbone Slave
    wire wb_reg_write_en;
    wire wb_reg_read_en;
    wire [7:0] wb_reg_addr;
    wire [31:0] wb_reg_wdata;
    wire [31:0] wb_reg_rdata;

    // UART Core signals
    wire uart_stx;
    wire uart_int;

    // Modem Control signals
    wire modem_rts;
    wire modem_int;

    // CDC signals
    reg [31:0] wb_dat_o_cdc;
    reg wb_ack_o_cdc;

    // Instantiate Wishbone Slave
    wishbone_slave wb_slave_inst (
        .clk(wb_clk_i),
        .rst(wb_rst_i),
        .adr_i(wb_adr_i),
        .dat_i(wb_dat_i),
        .dat_o(wb_reg_rdata),
        .we_i(wb_we_i),
        .stb_i(wb_stb_i),
        .cyc_i(wb_cyc_i),
        .ack_o(wb_ack_o_reg),
        .sel_i(wb_sel_i),
        .registers(wb_registers_next),
        .int_o(wb_int_o)
    );

    // Instantiate UART Core
    uart_core uart_core_inst (
        .clk(wb_clk_i),
        .rst(wb_rst_i),
        .registers(wb_registers),
        .stx(stx_pad_o),
        .srx(srx_pad_i),
        .int_o(uart_int)
    );

    // Instantiate Modem Control
    modem_control modem_control_inst (
        .clk(wb_clk_i),
        .rst(wb_rst_i),
        .registers(wb_registers),
        .rts(rts_pad_o),
        .cts(cts_pad_i),
        .dtr(dtr_pad_o),
        .dsr(dsr_pad_i),
        .ri(ri_pad_i),
        .dcd(dcd_pad_i)
    );

    // CDC for wb_dat_o and wb_ack_o
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_dat_o_cdc <= 32'b0;
            wb_ack_o_cdc <= 1'b0;
        end else begin
            wb_dat_o_cdc <= wb_dat_o_reg;
            wb_ack_o_cdc <= wb_ack_o_reg;
        end
    end

    // Register outputs
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_dat_o <= 32'b0;
            wb_ack_o <= 1'b0;
        end else begin
            wb_dat_o <= wb_dat_o_cdc;
            wb_ack_o <= wb_ack_o_cdc;
        end
    end

    // Register write and read enable signals
    assign wb_reg_write_en = wb_we_i & wb_stb_i & wb_cyc_i;
    assign wb_reg_read_en = ~wb_we_i & wb_stb_i & wb_cyc_i;
    assign wb_reg_addr = wb_adr_i;
    assign wb_reg_wdata = wb_dat_i;

    // Register read data output
    always @(*) begin
        wb_dat_o_reg = 32'b0;
        if (wb_reg_read_en) begin
            case (wb_reg_addr)
                8'h00: wb_dat_o_reg = wb_registers[31:0]; // RBR/THR/IER
                8'h01: wb_dat_o_reg = wb_registers[63:32]; // IIR/FCR
                8'h02: wb_dat_o_reg = wb_registers[95:64]; // IER
                8'h03: wb_dat_o_reg = wb_registers[127:96]; // LCR
                8'h04: wb_dat_o_reg = wb_registers[159:128]; // MCR
                8'h05: wb_dat_o_reg = wb_registers[191:160]; // LSR
                8'h06: wb_dat_o_reg = wb_registers[223:192]; // MSR
                8'h07: wb_dat_o_reg = wb_registers[255:224]; // SCR
                default: wb_dat_o_reg = 32'b0;
            endcase
        end
    end

    // Register write data input
    always @(*) begin
        wb_registers_next = wb_registers;
        if (wb_reg_write_en) begin
            case (wb_reg_addr)
                8'h00: wb_registers_next[31:0] = wb_reg_wdata; // RBR/THR/IER
                8'h01: wb_registers_next[63:32] = wb_reg_wdata; // IIR/FCR
                8'h02: wb_registers_next[95:64] = wb_reg_wdata; // IER
                8'h03: wb_registers_next[127:96] = wb_reg_wdata; // LCR
                8'h04: wb_registers_next[159:128] = wb_reg_wdata; // MCR
                8'h05: wb_registers_next[191:160] = wb_reg_wdata; // LSR
                8'h06: wb_registers_next[223:192] = wb_reg_wdata; // MSR
                8'h07: wb_registers_next[255:224] = wb_reg_wdata; // SCR
            endcase
        end
    end

    // Interrupt output
    always @(*) begin
        int_o = wb_int_o | uart_int | modem_int;
    end

endmodule

module wishbone_slave (
    input wire clk,
    input wire rst,
    input wire [7:0] adr_i,
    input wire [31:0] dat_i,
    output wire [31:0] dat_o,
    input wire we_i,
    input wire stb_i,
    input wire cyc_i,
    output reg ack_o,
    input wire [3:0] sel_i,
    inout wire [383:0] registers,
    output reg int_o
);

    // Internal signals
    reg [31:0] dat_o_reg;
    reg [31:0] wb_reg_rdata;

    // Register read and write logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ack_o <= 1'b0;
        end else if (stb_i & cyc_i) begin
            ack_o <= 1'b1;
        end else begin
            ack_o <= 1'b0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dat_o_reg <= 32'b0;
        end else if (ack_o) begin
            dat_o_reg <= wb_reg_rdata;
        end
    end

    assign dat_o = dat_o_reg;

    // Register write and read enable signals
    wire wb_reg_write_en = we_i & stb_i & cyc_i;
    wire wb_reg_read_en = ~we_i & stb_i & cyc_i;
    wire [7:0] wb_reg_addr = adr_i;
    wire [31:0] wb_reg_wdata = dat_i;

    // Register read data output
    always @(*) begin
        wb_reg_rdata = 32'b0;
        if (wb_reg_read_en) begin
            case (wb_reg_addr)
                8'h00: wb_reg_rdata = registers[31:0]; // RBR/THR/IER
                8'h01: wb_reg_rdata = registers[63:32]; // IIR/FCR
                8'h02: wb_reg_rdata = registers[95:64]; // IER
                8'h03: wb_reg_rdata = registers[127:96]; // LCR
                8'h04: wb_reg_rdata = registers[159:128]; // MCR
                8'h05: wb_reg_rdata = registers[191:160]; // LSR
                8'h06: wb_reg_rdata = registers[223:192]; // MSR
                8'h07: wb_reg_rdata = registers[255:224]; // SCR
                default: wb_reg_rdata = 32'b0;
            endcase
        end
    end

    // Register write data input
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            registers <= 384'b0;
        end else if (wb_reg_write_en) begin
            case (wb_reg_addr)
                8'h00: registers[31:0] <= wb_reg_wdata; // RBR/THR/IER
                8'h01: registers[63:32] <= wb_reg_wdata; // IIR/FCR
                8'h02: registers[95:64] <= wb_reg_wdata; // IER
                8'h03: registers[127:96] <= wb_reg_wdata; // LCR
                8'h04: registers[159:128] <= wb_reg_wdata; // MCR
                8'h05: registers[191:160] <= wb_reg_wdata; // LSR
                8'h06: registers[223:192] <= wb_reg_wdata; // MSR
                8'h07: registers[255:224] <= wb_reg_wdata; // SCR
            endcase
        end
    end

    // Interrupt logic (simplified)
    always @(*) begin
        int_o = registers[63] | registers[95] | registers[127] | registers[159] | registers[191] | registers[223] | registers[255];
    end

endmodule

module uart_core (
    input wire clk,
    input wire rst,
    inout wire [383:0] registers,
    output reg stx,
    input wire srx,
    output reg int_o
);

    // Internal signals
    reg [7:0] tx_fifo [0:15];
    reg [7:0] rx_fifo [0:15];
    reg [3:0] tx_fifo_wr_ptr;
    reg [3:0] tx_fifo_rd_ptr;
    reg [3:0] rx_fifo_wr_ptr;
    reg [3:0] rx_fifo_rd_ptr;
    reg tx_fifo_full;
    reg tx_fifo_empty;
    reg rx_fifo_full;
    reg rx_fifo_empty;
    reg [7:0] baud_divisor;
    reg [7:0] line_control;
    reg [7:0] modem_control;
    reg [7:0] line_status;
    reg [7:0] modem_status;
    reg [7:0] scratch;
    reg [3:0] tx_fifo_count;
    reg [3:0] rx_fifo_count;
    reg tx_shift_reg [0:7];
    reg rx_shift_reg [0:7];
    reg [3:0] tx_bit_count;
    reg [3:0] rx_bit_count;
    reg tx_busy;
    reg rx_busy;
    reg [7:0] divisor_latch_lsb;
    reg [7:0] divisor_latch_msb;

    // CDC signals
    reg [7:0] srx_pad_i_cdc;
    reg [7:0] stx_pad_o_cdc;

    // CDC for srx_pad_i and stx_pad_o
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            srx_pad_i_cdc <= 1'b0;
            stx_pad_o_cdc <= 1'b0;
        end else begin
            srx_pad_i_cdc <= srx;
            stx_pad_o_cdc <= stx;
        end
    end

    // Register logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            divisor_latch_lsb <= 8'b0;
            divisor_latch_msb <= 8'b0;
            line_control <= 8'b0;
            modem_control <= 8'b0;
            line_status <= 8'b0;
            modem_status <= 8'b0;
            scratch <= 8'b0;
        end else begin
            if (registers[159] & 1'b1) begin // DLAB set
                if (registers[31] & 1'b1) // Writing to DLL
                    divisor_latch_lsb <= registers[31:24];
                if (registers[63] & 1'b1) // Writing to DLM
                    divisor_latch_msb <= registers[63:56];
            end else begin
                if (registers[31] & 1'b1) // Writing to RBR/THR/IER
                    tx_fifo[tx_fifo_wr_ptr] <= registers[31:24];
                if (registers[63] & 1'b1) // Writing to IER
                    registers[95:88] <= registers[63:56];
                if (registers[95] & 1'b1) // Writing to IER
                    registers[95:88] <= registers[95:88];
                if (registers[127] & 1'b1) // Writing to LCR
                    line_control <= registers[127:120];
                if (registers[159] & 1'b1) // Writing to MCR
                    modem_control <= registers[159:152];
                if (registers[191] & 1'b1) // Writing to LSR
                    registers[191:184] <= registers[191:184];
                if (registers[223] & 1'b1) // Writing to MSR
                    registers[223:216] <= registers[223:216];
                if (registers[255] & 1'b1) // Writing to SCR
                    scratch <= registers[255:248];
            end
        end
    end

    // FIFO logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_fifo_wr_ptr <= 4'b0;
            tx_fifo_rd_ptr <= 4'b0;
            tx_fifo_full <= 1'b0;
            tx_fifo_empty <= 1'b1;
            rx_fifo_wr_ptr <= 4'b0;
            rx_fifo_rd_ptr <= 4'b0;
            rx_fifo_full <= 1'b0;
            rx_fifo_empty <= 1'b1;
            tx_fifo_count <= 4'b0;
            rx_fifo_count <= 4'b0;
        end else begin
            // TX FIFO write
            if (registers[31] & 1'b1 & ~tx_fifo_full) begin
                tx_fifo[tx_fifo_wr_ptr] <= registers[31:24];
                tx_fifo_wr_ptr <= tx_fifo_wr_ptr + 1;
                tx_fifo_count <= tx_fifo_count + 1;
                tx_fifo_empty <= 1'b0;
                if (tx_fifo_wr_ptr == tx_fifo_rd_ptr)
                    tx_fifo_full <= 1'b1;
            end

            // TX FIFO read
            if (tx_busy & ~tx_fifo_empty) begin
                tx_fifo_rd_ptr <= tx_fifo_rd_ptr + 1;
                tx_fifo_count <= tx_fifo_count - 1;
                tx_fifo_full <= 1'b0;
                if (tx_fifo_wr_ptr == tx_fifo_rd_ptr)
                    tx_fifo_empty <= 1'b1;
            end

            // RX FIFO write
            if (rx_busy & ~rx_fifo_full) begin
                rx_fifo[rx_fifo_wr_ptr] <= rx_shift_reg;
                rx_fifo_wr_ptr <= rx_fifo_wr_ptr + 1;
                rx_fifo_count <= rx_fifo_count + 1;
                rx_fifo_empty <= 1'b0;
                if (rx_fifo_wr_ptr == rx_fifo_rd_ptr)
                    rx_fifo_full <= 1'b1;
            end

            // RX FIFO read
            if (registers[63] & 1'b1 & ~rx_fifo_empty) begin
                rx_fifo_rd_ptr <= rx_fifo_rd_ptr + 1;
                rx_fifo_count <= rx_fifo_count - 1;
                rx_fifo_full <= 1'b0;
                if (rx_fifo_wr_ptr == rx_fifo_rd_ptr)
                    rx_fifo_empty <= 1'b1;
            end
        end
    end

    // Baud rate generation
    reg [15:0] baud_counter;
    reg [15:0] baud_divisor_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            baud_counter <= 16'b0;
            baud_divisor_reg <= {divisor_latch_msb, divisor_latch_lsb};
        end else begin
            if (baud_counter == baud_divisor_reg - 1) begin
                baud_counter <= 16'b0;
            end else begin
                baud_counter <= baud_counter + 1;
            end
        end
    end

    // TX logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_busy <= 1'b0;
            tx_shift_reg <= 8'b0;
            tx_bit_count <= 4'b0;
        end else if (baud_counter == baud_divisor_reg - 1) begin
            if (~tx_busy & ~tx_fifo_empty) begin
                tx_busy <= 1'b1;
                tx_shift_reg <= tx_fifo[tx_fifo_rd_ptr];
                tx_bit_count <= 4'b0;
                stx <= 1'b0;
            end else if (tx_busy) begin
                if (tx_bit_count < 8) begin
                    stx <= tx_shift_reg[tx_bit_count];
                    tx_bit_count <= tx_bit_count + 1;
                end else begin
                    stx <= 1'b1;
                    tx_busy <= 1'b0;
                end
            end
        end
    end

    // RX logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_busy <= 1'b0;
            rx_shift_reg <= 8'b0;
            rx_bit_count <= 4'b0;
        end else if (baud_counter == baud_divisor_reg - 1) begin
            if (~rx_busy & srx_pad_i_cdc) begin
                rx_busy <= 1'b1;
                rx_shift_reg <= 8'b0;
                rx_bit_count <= 4'b0;
            end else if (rx_busy) begin
                if (rx_bit_count < 8) begin
                    rx_shift_reg[rx_bit_count] <= srx_pad_i_cdc;
                    rx_bit_count <= rx_bit_count + 1;
                end else begin
                    rx_busy <= 1'b0;
                end
            end
        end
    end

    // Interrupt logic (simplified)
    always @(*) begin
        int_o = tx_fifo_count > 8 | rx_fifo_count > 8;
    end

endmodule

module modem_control (
    input wire clk,
    input wire rst,
    inout wire [383:0] registers,
    output reg rts,
    input wire cts,
    output reg dtr,
    input wire dsr,
    input wire ri,
    input wire dcd
);

    // Register logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rts <= 1'b0;
            dtr <= 1'b0;
        end else begin
            if (registers[159] & 1'b1) // Writing to MCR
                rts <= registers[159:152] & 1'b1;
            if (registers[159] & 1'b1) // Writing to MCR
                dtr <= registers[159:152] & 1'b2;
        end
    end

    // Modem status register update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            registers[223:216] <= 8'b0;
        end else begin
            registers[223:216] <= {1'b0, 1'b0, ri, dsr, cts, 1'b0, 1'b0, dcd};
        end
    end

endmodule
