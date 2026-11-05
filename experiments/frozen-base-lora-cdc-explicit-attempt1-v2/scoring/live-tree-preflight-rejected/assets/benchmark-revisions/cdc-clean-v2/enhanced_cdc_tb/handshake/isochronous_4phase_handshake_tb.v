`timescale 1ns/1ps

module isochronous_4phase_handshake_tb;
    reg src_clk, dst_clk, src_rst_n, dst_rst_n, src_valid, dst_ready;
    wire src_ready, dst_valid;
    integer src_count, dst_count, flush_count, outstanding, errors, wait_cycles;
    reg prev_src_stall, prev_dst_stall;

    isochronous_4phase_handshake dut (
        .src_clk_i(src_clk), .src_rst_ni(src_rst_n),
        .src_valid_i(src_valid), .src_ready_o(src_ready),
        .dst_clk_i(dst_clk), .dst_rst_ni(dst_rst_n),
        .dst_valid_o(dst_valid), .dst_ready_i(dst_ready)
    );
    always #5 src_clk=~src_clk;
    always #10 dst_clk=~dst_clk;

    task cdc_fail;
        input [8*40-1:0] rule_id;
        input [8*88-1:0] text;
        begin errors=errors+1; $display("CDC/RESET VIOLATION [%0s]: %0s", rule_id, text); end
    endtask

    task protocol_fail;
        input [8*40-1:0] rule_id;
        input [8*88-1:0] text;
        begin errors=errors+1; $display("PROTOCOL VIOLATION [%0s]: %0s", rule_id, text); end
    endtask

    task send;
        reg accepted;
        begin
            @(negedge src_clk); src_valid=1; wait_cycles=0; accepted=0;
            while (!accepted && wait_cycles<100) begin
                @(posedge src_clk);
                if (src_ready===1'b1) begin
                    src_count=src_count+1; outstanding=outstanding+1;
                    accepted=1;
                end else wait_cycles=wait_cycles+1;
            end
            if (!accepted) begin cdc_fail("HANDSHAKE_PROGRESS", "source progress timeout"); src_valid=0; end
            else begin
                @(negedge src_clk); src_valid=0;
            end
        end
    endtask

    task wait_empty;
        integer n;
        begin
            n=0;
            while (outstanding!=0 && n<120) begin @(posedge dst_clk); n=n+1; end
            if (outstanding!=0) cdc_fail("HANDSHAKE_LOSS", "destination progress timeout");
        end
    endtask

    always @(posedge src_clk) begin
        if (!src_rst_n || !dst_rst_n) prev_src_stall<=0;
        else begin
            if ((^src_ready)===1'bx || (^src_valid)===1'bx) cdc_fail("HANDSHAKE_STALL_STABILITY", "X on source handshake");
            if (prev_src_stall && !src_valid) protocol_fail("HANDSHAKE_STALL_STABILITY", "source valid dropped while stalled");
            prev_src_stall<=src_valid&&!src_ready;
        end
    end

    always @(posedge dst_clk) begin
        if (!src_rst_n || !dst_rst_n) begin
            if (dst_valid!==1'b0) cdc_fail("HANDSHAKE_RESET_FLUSH", "output active or X during reset");
            prev_dst_stall<=0;
        end else begin
            if ((^dst_valid)===1'bx) cdc_fail("HANDSHAKE_STALL_STABILITY", "X on destination valid");
            if (prev_dst_stall && !dst_valid) cdc_fail("HANDSHAKE_STALL_STABILITY", "destination valid dropped while stalled");
            if (dst_valid&&dst_ready) begin
                if (outstanding<=0) cdc_fail("HANDSHAKE_DUPLICATE", "unexpected or duplicate destination transaction");
                else outstanding=outstanding-1;
                dst_count=dst_count+1;
            end
            prev_dst_stall<=dst_valid&&!dst_ready;
        end
    end

    integer i;
    initial begin
        src_clk=0; dst_clk=0; src_rst_n=0; dst_rst_n=0; src_valid=0;
        dst_ready=0; src_count=0; dst_count=0; flush_count=0;
        outstanding=0; errors=0;
        prev_src_stall=0; prev_dst_stall=0;
        repeat (4) @(posedge src_clk); @(negedge src_clk); src_rst_n=1;
        repeat (3) @(posedge dst_clk); @(negedge dst_clk); dst_rst_n=1;
        repeat (5) @(posedge dst_clk); @(negedge dst_clk); dst_ready=1;
        for (i=0;i<6;i=i+1) send;
        wait_empty;

        @(negedge dst_clk); dst_ready=0; send; repeat (4) @(posedge dst_clk);
        @(negedge src_clk); src_rst_n=0;
        flush_count=flush_count+outstanding; outstanding=0;
        #1; if (dst_valid!==1'b0) cdc_fail("HANDSHAKE_RESET_FLUSH", "source reset did not isolate output");
        repeat (3) @(posedge src_clk); @(negedge src_clk); src_rst_n=1;
        repeat (6) @(posedge dst_clk); @(negedge dst_clk); dst_ready=1;
        send; send; wait_empty;

        @(negedge dst_clk); dst_ready=0; send; repeat (4) @(posedge dst_clk);
        @(negedge dst_clk); dst_rst_n=0;
        flush_count=flush_count+outstanding; outstanding=0;
        #1; if (dst_valid!==1'b0) cdc_fail("HANDSHAKE_RESET_FLUSH", "destination reset did not isolate output");
        repeat (3) @(posedge dst_clk); @(negedge dst_clk); dst_rst_n=1;
        repeat (6) @(posedge src_clk); @(negedge dst_clk); dst_ready=1;
        for (i=0;i<5;i=i+1) send;
        wait_empty; repeat (3) @(posedge dst_clk);
        if (src_count<15 || dst_count<13) cdc_fail("HANDSHAKE_PROGRESS", "insufficient transaction coverage");
        if (dst_count+flush_count!=src_count) cdc_fail("HANDSHAKE_LOSS", "accepted transaction conservation failure");
        if (errors==0) $display("ISOCHRONOUS 4PHASE ENHANCED: ALL TESTS PASSED");
        else $display("ISOCHRONOUS 4PHASE ENHANCED: TESTS FAILED (%0d)", errors);
        $finish;
    end
    initial begin #1200000; $display("FAIL isochronous_4phase_handshake: global timeout"); $finish; end
endmodule
