`timescale 1ns/1ps

module data_sync_tb;
    integer errors = 0;

    reg clk = 0, rstn = 0, dready_i = 0;
    reg [7:0] din = 0;
    wire [7:0] dout;
    wire dready_o;
    always #5 clk = ~clk;

    data_sync #(.STAGES(2), .DWIDTH(8)) dut (
        .clk(clk), .rstn(rstn), .din(din), .dready_i(dready_i),
        .dout(dout), .dready_o(dready_o)
    );

    initial begin
        repeat (3) @(posedge clk); rstn = 1;
        din = 8'h5A; dready_i = 1;
        repeat (4) @(posedge clk);
        if (dready_o !== 1'b1 || dout !== 8'h5A) begin
            $display("FAIL data_sync captured %h ready=%b", dout, dready_o);
            errors = errors + 1;
        end
        dready_i = 0;
        repeat (4) @(posedge clk);
        if (dready_o !== 1'b0) begin
            $display("FAIL data_sync ready stuck");
            errors = errors + 1;
        end
        if (errors == 0)
            $display("DATA SYNC: ALL TESTS PASSED");
        else
            $display("DATA SYNC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("DATA SYNC: TIMEOUT");
        $finish;
    end
endmodule
