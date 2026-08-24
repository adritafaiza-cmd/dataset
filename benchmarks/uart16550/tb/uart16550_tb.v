`timescale 1ns/1ps

// 8-bit Wishbone loopback. Compile with +define+DATA_BUS_WIDTH_8.
module uart16550_tb;
    integer errors = 0;

    reg        wb_clk_i = 0;
    reg        wb_rst_i = 1;
    reg  [2:0] wb_adr_i = 0;
    reg  [7:0] wb_dat_i = 0;
    wire [7:0] wb_dat_o;
    reg        wb_we_i = 0;
    reg        wb_stb_i = 0;
    reg        wb_cyc_i = 0;
    wire       wb_ack_o;
    wire       int_o, stx, rts, dtr;

    always #5 wb_clk_i = ~wb_clk_i;

    uart_top dut (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wb_adr_i(wb_adr_i),
        .wb_dat_i(wb_dat_i),
        .wb_dat_o(wb_dat_o),
        .wb_we_i(wb_we_i),
        .wb_stb_i(wb_stb_i),
        .wb_cyc_i(wb_cyc_i),
        .wb_ack_o(wb_ack_o),
        .wb_sel_i(4'b0001),
        .int_o(int_o),
        .stx_pad_o(stx),
        .srx_pad_i(stx),
        .rts_pad_o(rts),
        .cts_pad_i(1'b1),
        .dtr_pad_o(dtr),
        .dsr_pad_i(1'b1),
        .ri_pad_i(1'b1),
        .dcd_pad_i(1'b1)
    );

    task wb_write;
        input [2:0] addr;
        input [7:0] data;
        begin
            @(negedge wb_clk_i);
            wb_adr_i = addr;
            wb_dat_i = data;
            wb_we_i = 1;
            wb_stb_i = 1;
            wb_cyc_i = 1;
            @(posedge wb_clk_i);
            while (!wb_ack_o) @(posedge wb_clk_i);
            @(negedge wb_clk_i);
            wb_we_i = 0;
            wb_stb_i = 0;
            wb_cyc_i = 0;
        end
    endtask

    task wb_read;
        input  [2:0] addr;
        output [7:0] data;
        begin
            @(negedge wb_clk_i);
            wb_adr_i = addr;
            wb_we_i = 0;
            wb_stb_i = 1;
            wb_cyc_i = 1;
            @(posedge wb_clk_i);
            while (!wb_ack_o) @(posedge wb_clk_i);
            data = wb_dat_o;
            @(negedge wb_clk_i);
            wb_stb_i = 0;
            wb_cyc_i = 0;
        end
    endtask

    reg [7:0] lsr, rxb;
    integer spins;

    initial begin
        repeat (8) @(posedge wb_clk_i);
        wb_rst_i = 0;
        repeat (4) @(posedge wb_clk_i);

        if (stx !== 1'b1) begin
            $display("FAIL TX line not idle-high");
            errors = errors + 1;
        end

        // LCR DLAB=1, then divisor=1 for a fast loopback, then 8N1.
        wb_write(3'd3, 8'h80);
        wb_write(3'd0, 8'h01);
        wb_write(3'd1, 8'h00);
        wb_write(3'd3, 8'h03);
        wb_write(3'd2, 8'h07);
        wb_write(3'd4, 8'h00);
        wb_write(3'd0, 8'h5A);

        spins = 0;
        lsr = 8'h00;
        while ((lsr[0] !== 1'b1) && (spins < 4000)) begin
            wb_read(3'd5, lsr);
            spins = spins + 1;
        end
        if (lsr[0] !== 1'b1) begin
            $display("FAIL RX data-ready never set (LSR=%h)", lsr);
            errors = errors + 1;
        end else begin
            wb_read(3'd0, rxb);
            if (rxb !== 8'h5A) begin
                $display("FAIL loopback got %h", rxb);
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display("UART16550: ALL TESTS PASSED");
        else
            $display("UART16550: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #200000;
        $display("UART16550_TB: TIMEOUT");
        $finish;
    end
endmodule
