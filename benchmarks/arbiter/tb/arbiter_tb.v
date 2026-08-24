`timescale 1ns/1ps

module arbiter_tb;
    integer errors = 0;

    reg clk = 0, rst = 1;
    reg [3:0] request = 0, acknowledge = 0;
    wire [3:0] grant;
    wire grant_valid;
    wire [1:0] grant_encoded;
    always #5 clk = ~clk;

    arbiter #(
        .PORTS(4), .ARB_TYPE_ROUND_ROBIN(1), .ARB_BLOCK(0)
    ) dut (
        .clk(clk), .rst(rst),
        .request(request), .acknowledge(acknowledge),
        .grant(grant), .grant_valid(grant_valid), .grant_encoded(grant_encoded)
    );

    initial begin
        repeat (3) @(posedge clk); rst = 0;
        request = 4'b1010;
        @(posedge clk);
        @(posedge clk);
        if (!grant_valid || grant == 4'b0000) begin
            $display("FAIL no grant");
            errors = errors + 1;
        end
        request = 4'b0000;
        @(posedge clk);
        if (errors == 0) $display("ARBITER: ALL TESTS PASSED");
        else $display("ARBITER: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("ARBITER_TB: TIMEOUT");
        $finish;
    end
endmodule
