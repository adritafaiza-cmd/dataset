`timescale 1ns/1ps

module pulse_sync_tb;
    integer errors = 0;

    reg clk_a = 0, clk_b = 0, rstn_a = 0, rstn_b = 0, pulseA_i = 0;
    wire pulseB_o, busy_o;
    integer seen = 0;
    always #5 clk_a = ~clk_a;
    always #11 clk_b = ~clk_b;

    pulse_sync #(.STAGES(2)) dut (
        .clk_a(clk_a), .rstn_a(rstn_a), .clk_b(clk_b), .rstn_b(rstn_b),
        .pulseA_i(pulseA_i), .pulseB_o(pulseB_o), .busy_o(busy_o)
    );

    always @(posedge clk_b) if (rstn_b && pulseB_o) seen = seen + 1;

    initial begin
        repeat (4) @(posedge clk_a); rstn_a = 1;
        repeat (4) @(posedge clk_b); rstn_b = 1;
        @(negedge clk_a); pulseA_i = 1;
        @(negedge clk_a); pulseA_i = 0;
        repeat (30) @(posedge clk_b);
        if (seen == 0) begin
            $display("FAIL no toggled pulse crossed");
            errors = errors + 1;
        end
        if (errors == 0) $display("PULSE SYNC: ALL TESTS PASSED");
        else $display("PULSE SYNC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("PULSE_SYNC_TB: TIMEOUT");
        $finish;
    end
endmodule
