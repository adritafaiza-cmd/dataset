`timescale 1ns/1ps

module sync_reset_tb;
    integer errors = 0;

    reg clk = 0, rst = 1;
    wire out;
    always #5 clk = ~clk;

    sync_reset #(.N(2)) dut (.clk(clk), .rst(rst), .out(out));

    initial begin
        repeat (3) @(posedge clk);
        if (out !== 1'b1) begin
            $display("FAIL reset not asserted");
            errors = errors + 1;
        end
        @(negedge clk); rst = 0;
        repeat (3) @(posedge clk);
        if (out !== 1'b0) begin
            $display("FAIL reset did not release");
            errors = errors + 1;
        end
        if (errors == 0)
            $display("SYNC RESET: ALL TESTS PASSED");
        else
            $display("SYNC RESET: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("SYNC RESET: TIMEOUT");
        $finish;
    end
endmodule
