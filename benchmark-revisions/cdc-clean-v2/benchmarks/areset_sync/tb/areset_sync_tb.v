`timescale 1ns/1ps

module areset_sync_tb;
    integer errors = 0;

    reg clk = 0, async_rst_i = 1;
    wire sync_rst_o;
    always #5 clk = ~clk;

    areset_sync #(.STAGES(2)) dut (
        .clk(clk), .async_rst_i(async_rst_i), .sync_rst_o(sync_rst_o)
    );

    // Plain-Verilog CDC check: after pipeline fill the synchronized level is known.
    integer cdc_warmup = 0;
    always @(negedge clk) begin
        if (cdc_warmup < 2)
            cdc_warmup = cdc_warmup + 1;
        else if (sync_rst_o !== 1'b0 && sync_rst_o !== 1'b1) begin
            $display("CDC VIOLATION: sync_rst_o is unknown after pipeline fill");
            errors = errors + 1;
        end
    end

    initial begin
        repeat (4) @(posedge clk);
        if (sync_rst_o !== 1'b1) begin
            $display("FAIL reset not synchronized high");
            errors = errors + 1;
        end
        async_rst_i = 0;
        repeat (3) @(posedge clk);
        if (sync_rst_o !== 1'b0) begin
            $display("FAIL reset did not release");
            errors = errors + 1;
        end
        if (errors == 0) $display("ARESET SYNC: ALL TESTS PASSED");
        else $display("ARESET SYNC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("ARESET_SYNC_TB: TIMEOUT");
        $finish;
    end
endmodule
