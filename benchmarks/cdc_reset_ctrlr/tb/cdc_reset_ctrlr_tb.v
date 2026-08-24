`timescale 1ns/1ps

module cdc_reset_ctrlr_tb;
    integer errors = 0;

    reg a_clk = 0, b_clk = 0, a_rst_n = 0, b_rst_n = 0;
    always #5 a_clk = ~a_clk;
    always #8 b_clk = ~b_clk;

    reg a_clear = 0, b_clear = 0;
    reg a_clear_ack = 0, b_clear_ack = 0;
    reg a_iso_ack = 0, b_iso_ack = 0;
    wire a_clear_o, b_clear_o, a_iso, b_iso;
    integer saw_a_iso = 0, saw_b_iso = 0, saw_a_clr = 0, saw_b_clr = 0;

    cdc_reset_ctrlr dut (
        .a_clk_i(a_clk), .a_rst_ni(a_rst_n), .a_clear_i(a_clear),
        .a_clear_o(a_clear_o), .a_clear_ack_i(a_clear_ack),
        .a_isolate_o(a_iso), .a_isolate_ack_i(a_iso_ack),
        .b_clk_i(b_clk), .b_rst_ni(b_rst_n), .b_clear_i(b_clear),
        .b_clear_o(b_clear_o), .b_clear_ack_i(b_clear_ack),
        .b_isolate_o(b_iso), .b_isolate_ack_i(b_iso_ack)
    );

    always @(posedge a_clk) begin
        if (a_iso) begin
            saw_a_iso = 1;
            a_iso_ack <= 1'b1;
        end else
            a_iso_ack <= 1'b0;
        if (a_clear_o) begin
            saw_a_clr = 1;
            a_clear_ack <= 1'b1;
        end else
            a_clear_ack <= 1'b0;
    end

    always @(posedge b_clk) begin
        if (b_iso) begin
            saw_b_iso = 1;
            b_iso_ack <= 1'b1;
        end else
            b_iso_ack <= 1'b0;
        if (b_clear_o) begin
            saw_b_clr = 1;
            b_clear_ack <= 1'b1;
        end else
            b_clear_ack <= 1'b0;
    end

    initial begin
        repeat (4) @(posedge a_clk); a_rst_n = 1;
        repeat (4) @(posedge b_clk); b_rst_n = 1;
        @(negedge a_clk); a_clear = 1;
        @(negedge a_clk); a_clear = 0;
        repeat (40) @(posedge a_clk);
        if (!saw_a_iso || !saw_b_iso) begin
            $display("FAIL isolate not asserted on both sides");
            errors = errors + 1;
        end
        if (!saw_a_clr || !saw_b_clr) begin
            $display("FAIL clear not asserted on both sides");
            errors = errors + 1;
        end
        if (a_iso !== 1'b0 || b_iso !== 1'b0) begin
            $display("FAIL isolate stuck after sequence");
            errors = errors + 1;
        end
        if (errors == 0)
            $display("CDC RESET CTRLR: ALL TESTS PASSED");
        else
            $display("CDC RESET CTRLR: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #40000;
        $display("CDC RESET CTRLR: TIMEOUT");
        $finish;
    end
endmodule
