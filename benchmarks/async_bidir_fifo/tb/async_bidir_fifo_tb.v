`timescale 1ns/1ps

module async_bidir_fifo_tb;

    parameter DSIZE = 8;
    parameter ASIZE = 4;

    reg a_clk = 0;
    reg b_clk = 0;

    always #5 a_clk = ~a_clk;
    always #7 b_clk = ~b_clk;

    reg a_rst_n;
    reg b_rst_n;

    reg a_winc;
    reg [DSIZE-1:0] a_wdata;
    reg a_rinc;
    wire [DSIZE-1:0] a_rdata;
    wire a_full, a_afull, a_empty, a_aempty;
    reg a_dir;

    reg b_winc;
    reg [DSIZE-1:0] b_wdata;
    reg b_rinc;
    wire [DSIZE-1:0] b_rdata;
    wire b_full, b_afull, b_empty, b_aempty;
    reg b_dir;

    integer errors;

    async_bidir_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FALLTHROUGH("TRUE")
    ) dut (
        .a_clk(a_clk),
        .a_rst_n(a_rst_n),
        .a_winc(a_winc),
        .a_wdata(a_wdata),
        .a_rinc(a_rinc),
        .a_rdata(a_rdata),
        .a_full(a_full),
        .a_afull(a_afull),
        .a_empty(a_empty),
        .a_aempty(a_aempty),
        .a_dir(a_dir),

        .b_clk(b_clk),
        .b_rst_n(b_rst_n),
        .b_winc(b_winc),
        .b_wdata(b_wdata),
        .b_rinc(b_rinc),
        .b_rdata(b_rdata),
        .b_full(b_full),
        .b_afull(b_afull),
        .b_empty(b_empty),
        .b_aempty(b_aempty),
        .b_dir(b_dir)
    );

    task reset_dut;
    begin
        a_rst_n = 0;
        b_rst_n = 0;
        a_winc = 0;
        a_rinc = 0;
        b_winc = 0;
        b_rinc = 0;
        a_wdata = 0;
        b_wdata = 0;

        // A writes, B reads
        a_dir = 1'b1;
        b_dir = 1'b0;

        #100;
        a_rst_n = 1;
        b_rst_n = 1;
        #100;
    end
    endtask

    task check_data;
        input [DSIZE-1:0] actual;
        input [DSIZE-1:0] expected;
    begin
        if (actual !== expected) begin
            $display("FAIL: actual=%h expected=%h", actual, expected);
            errors = errors + 1;
        end else begin
            $display("PASS: data=%h", actual);
        end
    end
    endtask

    initial begin
        errors = 0;
        reset_dut;

        $display("TEST 1: A writes, B reads");

        @(negedge a_clk);
        a_wdata = 8'hA5;
        a_winc = 1;

        @(negedge a_clk);
        a_winc = 0;

        wait (b_empty == 0);
        repeat (8) @(posedge b_clk);
        check_data(b_rdata,8'hA5);
        
	@(negedge b_clk);
        b_rinc = 1;

        @(negedge b_clk);
        b_rinc = 0;

        #100;

        $display("TEST 2: B writes, A reads");

        // Reset before changing direction
        reset_dut;

        // B writes, A reads
        a_dir = 1'b0;
        b_dir = 1'b1;

        #50;

        @(negedge b_clk);
        b_wdata = 8'h3C;
        b_winc = 1;

        @(negedge b_clk);
        b_winc = 0;

        wait (a_empty == 0);
        repeat (8) @(posedge a_clk);
        check_data(a_rdata, 8'h3C);

        @(negedge a_clk);
        a_rinc = 1;

        @(negedge a_clk);
        a_rinc = 0;

        #100;

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule
