`timescale 1ns / 1ps

module async_fifo_unit_test;

    parameter DSIZE = 32;
    parameter ASIZE = 4;
    parameter FALLTHROUGH = "TRUE";
    parameter MAX_TRAFFIC = 10;

    reg              wclk;
    reg              wrst_n;
    reg              winc;
    reg  [DSIZE-1:0] wdata;
    wire             wfull;
    wire             awfull;

    reg              rclk;
    reg              rrst_n;
    reg              rinc;
    wire [DSIZE-1:0] rdata;
    wire             rempty;
    wire             arempty;

    integer errors;
    integer i;
    integer wi;
    integer ri;

    async_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FALLTHROUGH(FALLTHROUGH)
    ) dut (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .wdata(wdata),
        .wfull(wfull),
        .awfull(awfull),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .rinc(rinc),
        .rdata(rdata),
        .rempty(rempty),
        .arempty(arempty)
    );

    initial wclk = 1'b0;
    always #2 wclk = ~wclk;

    initial rclk = 1'b0;
    always #3 rclk = ~rclk;

    initial begin
        $dumpfile("async_fifo_unit_test.vcd");
        $dumpvars(0, async_fifo_unit_test);
    end

    task reset_fifo;
    begin
        wrst_n = 1'b0;
        rrst_n = 1'b0;
        winc = 1'b0;
        rinc = 1'b0;
        wdata = {DSIZE{1'b0}};

        #100;
        wrst_n = 1'b1;
        rrst_n = 1'b1;
        #50;
    end
    endtask

    task check_equal;
        input [DSIZE-1:0] actual;
        input [DSIZE-1:0] expected;
        input [255:0] name;
    begin
        if (actual !== expected) begin
            $display("FAIL: %s actual=%h expected=%h", name, actual, expected);
            errors = errors + 1;
        end else begin
            $display("PASS: %s", name);
        end
    end
    endtask

    task check_flag;
        input actual;
        input expected;
        input [255:0] name;
    begin
        if (actual !== expected) begin
            $display("FAIL: %s actual=%b expected=%b", name, actual, expected);
            errors = errors + 1;
        end else begin
            $display("PASS: %s", name);
        end
    end
    endtask

    initial begin
        errors = 0;

        $display("TEST_IDLE");
        reset_fifo;
        check_flag(wfull, 1'b0, "wfull should be 0 after reset");
        check_flag(rempty, 1'b1, "rempty should be 1 after reset");

        $display("TEST_SINGLE_WRITE_THEN_READ");
        reset_fifo;
        @(posedge wclk);
        winc = 1'b1;
        wdata = 32'h0000000A;
        @(posedge wclk);
        winc = 1'b0;

        wait (rempty == 1'b0);
        @(posedge rclk);
        rinc = 1'b1;
        @(negedge rclk);
        check_equal(rdata, 32'h0000000A, "single read data");
        rinc = 1'b0;

        $display("TEST_MULTIPLE_WRITE_THEN_READ");
        reset_fifo;
        for (i = 0; i < 10; i = i + 1) begin
            @(negedge wclk);
            winc = 1'b1;
            wdata = i;
        end
        @(negedge wclk);
        winc = 1'b0;

        #100;
        rinc = 1'b1;
        for (i = 0; i < 10; i = i + 1) begin
            wait (rempty == 1'b0);
            @(posedge rclk);
            check_equal(rdata, i, "multiple read data");
        end
        rinc = 1'b0;

        $display("TEST_FULL_FLAG");
        reset_fifo;
        winc = 1'b1;
        for (i = 0; i < (1 << ASIZE); i = i + 1) begin
            @(negedge wclk);
            wdata = i;
        end
        @(negedge wclk);
        winc = 1'b0;
        @(posedge wclk);
        check_flag(wfull, 1'b1, "wfull should be 1");

        $display("TEST_EMPTY_FLAG");
        reset_fifo;
        check_flag(rempty, 1'b1, "rempty should be 1 initially");

        winc = 1'b1;
        for (i = 0; i < (1 << ASIZE); i = i + 1) begin
            @(posedge wclk);
            wdata = i;
        end
        winc = 1'b0;
        #100;
        check_flag(rempty, 1'b0, "rempty should be 0 after writes");

        $display("TEST_ALMOST_EMPTY_FLAG");
        reset_fifo;
        check_flag(arempty, 1'b0, "arempty initial");

        winc = 1'b1;
        @(negedge wclk);
        wdata = 0;
        @(negedge wclk);
        winc = 1'b0;
        #100;
        check_flag(arempty, 1'b1, "arempty should be 1");

        $display("TEST_ALMOST_FULL_FLAG");
        reset_fifo;
        winc = 1'b1;
        for (i = 0; i < (1 << ASIZE); i = i + 1) begin
            @(negedge wclk);
            wdata = i;
        end
        @(negedge wclk);
        winc = 1'b0;
        repeat (4) @(posedge wclk);
        check_flag(awfull, 1'b0, "awfull should be 0");

	/*
        $display("TEST_CONCURRENT_WRITE_READ");
        reset_fifo;

        fork
            begin
                winc = 1'b1;
                for (wi = 0; i < MAX_TRAFFIC; wi = wi + 1) begin
                    while (wfull)
                        @(negedge wclk);
                    @(negedge wclk);
                    wdata = wi;
                end
                winc = 1'b0;
            end

            begin
                for (ri = 0; i < MAX_TRAFFIC; ri = ri + 1) begin
                    while (rempty)
                        @(posedge rclk);
                    @(negedge rclk);
                    rinc = 1'b1;
                    @(posedge rclk);
                    @(negedge rclk);
                   check_equal(rdata, ri, "concurrent read data"); 
                end
                rinc = 1'b0;
            end
        join

	*/
        if (errors == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("TESTS FAILED: %0d errors", errors);
        end

        $finish;
    end

endmodule
