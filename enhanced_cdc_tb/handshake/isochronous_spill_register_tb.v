`timescale 1ns/1ps

module isochronous_spill_register_tb;
    reg src_clk, dst_clk, src_rst_n, dst_rst_n;
    reg [7:0] src_data;
    reg src_valid, dst_ready;
    wire src_ready, dst_valid;
    wire [7:0] dst_data;
    reg [7:0] expected [0:255];
    integer put_count, get_count, flush_count, sb_put, sb_get, errors, wait_cycles;
    reg prev_src_stall, prev_dst_stall;
    reg [7:0] prev_src_data, prev_dst_data;

    isochronous_spill_register #(.WIDTH(8)) dut (
        .src_clk_i(src_clk), .src_rst_ni(src_rst_n),
        .src_valid_i(src_valid), .src_ready_o(src_ready), .src_data_i(src_data),
        .dst_clk_i(dst_clk), .dst_rst_ni(dst_rst_n),
        .dst_valid_o(dst_valid), .dst_ready_i(dst_ready), .dst_data_o(dst_data)
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
        input [7:0] value;
        reg accepted;
        begin
            @(negedge src_clk); src_data=value; src_valid=1;
            wait_cycles=0; accepted=0;
            while (!accepted && wait_cycles<60) begin
                @(posedge src_clk);
                if (src_ready===1'b1) begin
                    expected[sb_put]=value; sb_put=sb_put+1;
                    accepted=1;
                end else wait_cycles=wait_cycles+1;
            end
            if (!accepted) begin cdc_fail("HANDSHAKE_PROGRESS", "source progress timeout"); src_valid=0; end
            else begin
                @(negedge src_clk); src_valid=0; put_count=put_count+1;
            end
        end
    endtask

    task flush_scoreboard;
        begin
            flush_count=flush_count+(sb_put-sb_get);
            sb_get=sb_put;
        end
    endtask

    task wait_empty;
        integer n;
        begin
            n=0;
            while (sb_get!=sb_put && n<80) begin @(posedge dst_clk); n=n+1; end
            if (sb_get!=sb_put) cdc_fail("HANDSHAKE_LOSS", "destination progress timeout");
        end
    endtask

    always @(posedge src_clk) begin
        if (!src_rst_n || !dst_rst_n) prev_src_stall<=0;
        else begin
            if ((^src_ready)===1'bx || (^src_valid)===1'bx ||
                (src_valid && (^src_data)===1'bx)) cdc_fail("HANDSHAKE_STALL_STABILITY", "X on source handshake");
            if (prev_src_stall && (!src_valid || src_data!==prev_src_data))
                protocol_fail("HANDSHAKE_STALL_STABILITY", "source valid/data changed while stalled");
            prev_src_stall<=src_valid&&!src_ready; prev_src_data<=src_data;
        end
    end

    always @(posedge dst_clk) begin
        if (!src_rst_n || !dst_rst_n) begin
            if (dst_valid!==1'b0) cdc_fail("HANDSHAKE_RESET_FLUSH", "output active or X during coordinated reset");
            prev_dst_stall<=0;
        end else begin
            if ((^dst_valid)===1'bx || (dst_valid && (^dst_data)===1'bx))
                cdc_fail("HANDSHAKE_STALL_STABILITY", "X on destination interface");
            if (prev_dst_stall && (!dst_valid || dst_data!==prev_dst_data))
                cdc_fail("HANDSHAKE_STALL_STABILITY", "destination valid/data changed while stalled");
            if (dst_valid&&dst_ready) begin
                if (sb_get>=sb_put) cdc_fail("HANDSHAKE_DUPLICATE", "unexpected or duplicate output");
                else if (dst_data!==expected[sb_get]) cdc_fail("HANDSHAKE_ORDER", "output data/order mismatch");
                sb_get=sb_get+1; get_count=get_count+1;
            end
            prev_dst_stall<=dst_valid&&!dst_ready; prev_dst_data<=dst_data;
        end
    end

    integer i;
    initial begin
        src_clk=0; dst_clk=0; src_rst_n=0; dst_rst_n=0; src_data=0;
        src_valid=0; dst_ready=0; put_count=0; get_count=0; sb_put=0;
        sb_get=0; flush_count=0; errors=0; prev_src_stall=0; prev_dst_stall=0;
        repeat (4) @(posedge src_clk); @(negedge src_clk); src_rst_n=1;
        repeat (3) @(posedge dst_clk); @(negedge dst_clk);
        dst_rst_n=1; dst_ready=1;
        for (i=0;i<8;i=i+1) send(8'h10+i);
        wait_empty;

        @(negedge dst_clk); dst_ready=0; send(8'h30); send(8'h31);
        repeat (4) @(posedge dst_clk); @(negedge dst_clk);
        src_rst_n=0; dst_rst_n=0; flush_scoreboard;
        #1; if (dst_valid!==1'b0) cdc_fail("HANDSHAKE_RESET_FLUSH", "coordinated reset did not clear output");
        repeat (3) @(posedge src_clk); @(negedge src_clk); src_rst_n=1;
        repeat (2) @(posedge dst_clk); @(negedge dst_clk);
        dst_rst_n=1; dst_ready=1;
        for (i=0;i<8;i=i+1) send(8'h40+i);
        wait_empty;

        @(negedge dst_clk); dst_ready=0; send(8'h70);
        repeat (5) @(posedge dst_clk);
        @(negedge dst_clk); dst_ready=1; wait_empty; repeat (3) @(posedge dst_clk);
        if (put_count<19 || get_count<17) cdc_fail("HANDSHAKE_PROGRESS", "insufficient transaction coverage");
        if (get_count+flush_count!=put_count) cdc_fail("HANDSHAKE_LOSS", "accepted transaction conservation failure");
        if (errors==0) $display("ISOCHRONOUS SPILL ENHANCED: ALL TESTS PASSED");
        else $display("ISOCHRONOUS SPILL ENHANCED: TESTS FAILED (%0d)", errors);
        $finish;
    end
    initial begin #800000; $display("FAIL isochronous_spill_register: global timeout"); $finish; end
endmodule
