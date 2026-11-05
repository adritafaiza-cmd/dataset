`timescale 1ns/1ps

module sync_wedge_tb;
    integer errors = 0;
    integer rises = 0, falls = 0;

    reg clk_i = 0, rst_ni = 0, en_i = 1, serial_i = 0;
    wire r_edge_o, f_edge_o, serial_o;
    always #5 clk_i = ~clk_i;

    sync_wedge #(.STAGES(2)) dut (
        .clk_i(clk_i), .rst_ni(rst_ni), .en_i(en_i),
        .serial_i(serial_i), .r_edge_o(r_edge_o), .f_edge_o(f_edge_o),
        .serial_o(serial_o)
    );

    always @(posedge clk_i) begin
        if (rst_ni && r_edge_o) rises = rises + 1;
        if (rst_ni && f_edge_o) falls = falls + 1;
    end

    initial begin
        repeat (3) @(posedge clk_i);
        rst_ni = 1;
        @(negedge clk_i); serial_i = 1;
        repeat (6) @(posedge clk_i);
        @(negedge clk_i); serial_i = 0;
        repeat (6) @(posedge clk_i);
        if (rises != 1 || falls != 1) begin
            $display("FAIL edges rise=%0d fall=%0d", rises, falls);
            errors = errors + 1;
        end
        if (serial_o !== 1'b0) begin
            $display("FAIL serial_o stuck");
            errors = errors + 1;
        end
        if (errors == 0)
            $display("SYNC WEDGE: ALL TESTS PASSED");
        else
            $display("SYNC WEDGE: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("SYNC WEDGE: TIMEOUT");
        $finish;
    end
endmodule
