`timescale 1ns/1ps

module isochronous_4phase_handshake_tb;
    integer errors = 0;
    integer received = 0;

    reg src_clk = 0, dst_clk = 0, src_rst_n = 0, dst_rst_n = 0;
    always #5 src_clk = ~src_clk;
    always #10 dst_clk = ~dst_clk;

    reg src_valid = 0;
    wire src_ready;
    wire dst_valid;
    reg dst_ready = 0;

    isochronous_4phase_handshake dut (
        .src_clk_i(src_clk), .src_rst_ni(src_rst_n),
        .src_valid_i(src_valid), .src_ready_o(src_ready),
        .dst_clk_i(dst_clk), .dst_rst_ni(dst_rst_n),
        .dst_valid_o(dst_valid), .dst_ready_i(dst_ready)
    );

    always @(posedge dst_clk) begin
        if (dst_rst_n && dst_valid && dst_ready)
            received = received + 1;
    end

    integer i;
    initial begin
        repeat (4) @(posedge src_clk); src_rst_n = 1;
        repeat (4) @(posedge dst_clk); dst_rst_n = 1; dst_ready = 1;
        repeat (6) @(posedge src_clk);
        repeat (6) @(posedge dst_clk);
        for (i = 0; i < 6; i = i + 1) begin
            @(negedge src_clk);
            while (!src_ready) @(negedge src_clk);
            src_valid = 1;
            @(posedge src_clk);
            @(negedge src_clk);
            src_valid = 0;
        end
        wait (received == 6);
        if (errors == 0)
            $display("ISOCHRONOUS 4PHASE: ALL TESTS PASSED");
        else
            $display("ISOCHRONOUS 4PHASE: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #80000;
        $display("ISOCHRONOUS 4PHASE: TIMEOUT");
        $finish;
    end
endmodule
