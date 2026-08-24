`timescale 1ns/1ps

module sync_tb;
    integer errors = 0;

    reg clk_i = 0, rst_ni = 0, serial_i = 0;
    wire serial_o;
    always #5 clk_i = ~clk_i;

    sync #(.STAGES(2)) dut (
        .clk_i(clk_i), .rst_ni(rst_ni), .serial_i(serial_i), .serial_o(serial_o)
    );

    initial begin
        repeat (3) @(posedge clk_i);
        rst_ni = 1;
        serial_i = 1;
        repeat (3) @(posedge clk_i);
        if (serial_o !== 1'b1) begin
            $display("FAIL 2-FF did not propagate 1");
            errors = errors + 1;
        end
        serial_i = 0;
        repeat (3) @(posedge clk_i);
        if (serial_o !== 1'b0) begin
            $display("FAIL 2-FF did not propagate 0");
            errors = errors + 1;
        end
        if (errors == 0) $display("SYNC: ALL TESTS PASSED");
        else $display("SYNC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("SYNC_TB: TIMEOUT");
        $finish;
    end
endmodule
