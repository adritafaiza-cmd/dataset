`timescale 1ns/1ps

module rstgen_tb;
    integer errors = 0;

    reg clk_i = 0, rst_ni = 0, test_mode_i = 0;
    wire rst_no, init_no;
    always #5 clk_i = ~clk_i;

    rstgen dut (
        .clk_i(clk_i), .rst_ni(rst_ni), .test_mode_i(test_mode_i),
        .rst_no(rst_no), .init_no(init_no)
    );

    initial begin
        repeat (2) @(posedge clk_i);
        if (rst_no !== 1'b0) begin
            $display("FAIL reset not asserted");
            errors = errors + 1;
        end
        repeat (3) @(posedge clk_i);
        rst_ni = 1;
        @(posedge clk_i);
        if (rst_no !== 1'b0) begin
            $display("FAIL released too early");
            errors = errors + 1;
        end
        repeat (5) @(posedge clk_i);
        if (rst_no !== 1'b1 || init_no !== 1'b1) begin
            $display("FAIL reset did not release");
            errors = errors + 1;
        end
        if (errors == 0) $display("RSTGEN: ALL TESTS PASSED");
        else $display("RSTGEN: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("RSTGEN_TB: TIMEOUT");
        $finish;
    end
endmodule
