`timescale 1ns/1ps

module arbiter_tb;
    reg clk, rst;
    reg [3:0] request, acknowledge;
    wire [3:0] grant;
    wire grant_valid;
    wire [1:0] grant_encoded;
    integer errors, grants_seen, i, n;
    integer served0, served1, served2, served3;

    arbiter #(
        .PORTS(4), .ARB_TYPE_ROUND_ROBIN(1), .ARB_BLOCK(0),
        .ARB_BLOCK_ACK(1), .ARB_LSB_HIGH_PRIORITY(0)
    ) dut (
        .clk(clk), .rst(rst), .request(request), .acknowledge(acknowledge),
        .grant(grant), .grant_valid(grant_valid), .grant_encoded(grant_encoded)
    );
    always #5 clk=~clk;

    task protocol_fail;
        input [8*40-1:0] rule_id;
        input [8*80-1:0] text;
        begin errors=errors+1; $display("PROTOCOL VIOLATION [%0s]: %0s", rule_id, text); end
    endtask

    task expect_grant_bounded;
        input [3:0] req;
        integer k;
        begin
            @(negedge clk); request=req; k=0;
            while (!(grant_valid && ((grant & req)!=0)) && k<6) begin
                @(negedge clk); k=k+1;
            end
            if (!(grant_valid && ((grant & req)!=0))) protocol_fail("HANDSHAKE_PROGRESS", "bounded grant timeout");
        end
    endtask

    always @(posedge clk) begin
        #1;
        if (rst) begin
            if (grant_valid!==1'b0 || grant!==4'b0000 || grant_encoded!==2'b00)
                protocol_fail("HANDSHAKE_RESET_FLUSH", "grant active or X during reset");
        end else begin
            if ((^grant_valid)===1'bx || (^grant)===1'bx || (^grant_encoded)===1'bx)
                protocol_fail("HANDSHAKE_STALL_STABILITY", "X on arbiter output");
            if (grant_valid) begin
                if (grant==0 || (grant & (grant-1'b1))!=0) protocol_fail("HANDSHAKE_ORDER", "grant is not one-hot");
                if ((grant_encoded==0 && grant!=4'b0001) ||
                    (grant_encoded==1 && grant!=4'b0010) ||
                    (grant_encoded==2 && grant!=4'b0100) ||
                    (grant_encoded==3 && grant!=4'b1000))
                    protocol_fail("HANDSHAKE_ORDER", "encoded grant disagrees with one-hot grant");
                grants_seen=grants_seen+1;
                if (grant[0]) served0=served0+1;
                if (grant[1]) served1=served1+1;
                if (grant[2]) served2=served2+1;
                if (grant[3]) served3=served3+1;
            end else if (grant!==0) protocol_fail("HANDSHAKE_STALL_STABILITY", "grant nonzero while grant_valid is low");
        end
    end

    initial begin
        clk=0; rst=1; request=0; acknowledge=0; errors=0; grants_seen=0;
        served0=0; served1=0; served2=0; served3=0;
        repeat (4) @(posedge clk); @(negedge clk); rst=0;

        expect_grant_bounded(4'b0001);
        expect_grant_bounded(4'b0010);
        expect_grant_bounded(4'b0100);
        expect_grant_bounded(4'b1000);

        served0=0; served1=0; served2=0; served3=0;
        @(negedge clk); request=4'b1111;
        repeat (12) @(posedge clk);
        if (served0==0 || served1==0 || served2==0 || served3==0)
            protocol_fail("HANDSHAKE_PROGRESS", "round-robin fairness failure under persistent requests");

        @(negedge clk); request=4'b1011; acknowledge=4'b0101;
        repeat (3) @(posedge clk);
        @(negedge clk); request=4'b0110; acknowledge=4'b1010;
        repeat (3) @(posedge clk);
        @(negedge clk); request=4'b1111;
        repeat (2) @(posedge clk);

        // Mid-traffic synchronous reset; no CDC behavior is claimed here.
        @(negedge clk); rst=1;
        repeat (3) @(posedge clk);
        @(negedge clk); request=4'b0101; acknowledge=0; rst=0;
        expect_grant_bounded(4'b0101);

        @(negedge clk); request=0;
        repeat (3) @(posedge clk);
        if (grant_valid || grant!=0) protocol_fail("HANDSHAKE_STALL_STABILITY", "grant did not clear after requests stopped");
        if (grants_seen<20) protocol_fail("HANDSHAKE_PROGRESS", "insufficient arbitration coverage");
        if (errors==0) $display("ARBITER ENHANCED: ALL TESTS PASSED");
        else $display("ARBITER ENHANCED: TESTS FAILED (%0d)", errors);
        $finish;
    end
    initial begin #100000; $display("FAIL arbiter: global timeout"); $finish; end
endmodule
