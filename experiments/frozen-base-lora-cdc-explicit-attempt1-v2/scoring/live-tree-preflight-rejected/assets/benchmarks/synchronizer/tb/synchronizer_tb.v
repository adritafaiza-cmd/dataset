`timescale 1ns/1ps

module synchronizer_tb;
    integer errors = 0;

    reg clk = 0, rstn = 0, async_sig_i = 0;
    wire sync_sig_o;
    always #5 clk = ~clk;

    synchronizer #(.STAGES(2)) dut (
        .clk(clk), .rstn(rstn), .async_sig_i(async_sig_i), .sync_sig_o(sync_sig_o)
    );

    initial begin
        repeat (3) @(posedge clk); rstn = 1;
        async_sig_i = 1;
        repeat (3) @(posedge clk);
        if (sync_sig_o !== 1'b1) begin
            $display("FAIL 2-FF did not propagate 1");
            errors = errors + 1;
        end
        async_sig_i = 0;
        repeat (3) @(posedge clk);
        if (sync_sig_o !== 1'b0) begin
            $display("FAIL 2-FF did not propagate 0");
            errors = errors + 1;
        end
        if (errors == 0)
            $display("SYNCHRONIZER: ALL TESTS PASSED");
        else
            $display("SYNCHRONIZER: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("SYNCHRONIZER: TIMEOUT");
        $finish;
    end
endmodule
