`timescale 1ns/1ps

module areset_deassert_sync_tb;
    integer errors = 0;

    reg clk = 0, async_rst_i = 1;
    wire sync_rst_o;
    always #5 clk = ~clk;

    areset_deassert_sync #(.CHAINS(2), .RST_POL(1'b1)) dut (
        .clk(clk), .async_rst_i(async_rst_i), .sync_rst_o(sync_rst_o)
    );

    initial begin
        repeat (3) @(posedge clk);
        if (sync_rst_o !== 1'b1) begin
            $display("FAIL reset not asserted");
            errors = errors + 1;
        end
        @(negedge clk); async_rst_i = 0;
        repeat (4) @(posedge clk);
        if (sync_rst_o !== 1'b0) begin
            $display("FAIL reset did not release");
            errors = errors + 1;
        end
        if (errors == 0)
            $display("ARESET DEASSERT SYNC: ALL TESTS PASSED");
        else
            $display("ARESET DEASSERT SYNC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("ARESET DEASSERT SYNC: TIMEOUT");
        $finish;
    end
endmodule
