`timescale 1ns/1ps

module cdc_fifo_gray_clearable_enhanced_tb;
    parameter WIDTH = 8;
    parameter COUNT = 48;

    reg src_clk, dst_clk, src_rst_n, dst_rst_n;
    reg src_clear, dst_clear, src_valid, dst_ready;
    reg [WIDTH-1:0] src_data;
    wire src_ready, src_pending, dst_pending, dst_valid;
    wire [WIDTH-1:0] dst_data;
    reg [WIDTH-1:0] expected [0:COUNT-1];
    reg prev_stalled, score_enable;
    reg [WIDTH-1:0] prev_data;
    integer errors, sent, received, i;

    cdc_fifo_gray_clearable #(.WIDTH(WIDTH), .LOG_DEPTH(3)) dut (
        .src_rst_ni(src_rst_n), .src_clk_i(src_clk),
        .src_clear_i(src_clear), .src_clear_pending_o(src_pending),
        .src_data_i(src_data), .src_valid_i(src_valid),
        .src_ready_o(src_ready), .dst_rst_ni(dst_rst_n),
        .dst_clk_i(dst_clk), .dst_clear_i(dst_clear),
        .dst_clear_pending_o(dst_pending), .dst_data_o(dst_data),
        .dst_valid_o(dst_valid), .dst_ready_i(dst_ready)
    );

    always #5 src_clk = ~src_clk;
    always #8 dst_clk = ~dst_clk;

    task cdc_fail;
        input [8*80-1:0] rule_id;
        input [8*80-1:0] details;
        begin
            $display("CDC/RESET VIOLATION [%0s]: %0s at %0t",
                     rule_id, details, $time);
            errors = errors + 1;
        end
    endtask

    task protocol_fail;
        input [8*80-1:0] rule_id;
        input [8*80-1:0] details;
        begin
            $display("PROTOCOL VIOLATION [%0s]: %0s at %0t",
                     rule_id, details, $time);
            errors = errors + 1;
        end
    endtask

    task send_one;
        input [WIDTH-1:0] value;
        integer n;
        begin
            @(negedge src_clk);
            src_data = value;
            src_valid = 1;
            n = 0;
            #1;
            while (!src_ready && n < 140) begin
                n = n + 1;
                @(negedge src_clk);
                #1;
            end
            if (n == 140)
                cdc_fail("FIFO_HANDSHAKE_TIMEOUT", "source handshake TIMEOUT");
            else begin
                @(posedge src_clk);
                if (score_enable)
                    sent = sent + 1;
            end
            @(negedge src_clk);
            src_valid = 0;
        end
    endtask

    task wait_clear_done;
        integer n;
        begin
            n = 0;
            while (!(src_pending || dst_pending) && n < 80) begin
                n = n + 1;
                @(posedge dst_clk);
            end
            if (n == 80)
                cdc_fail("FIFO_CLEAR_HANDSHAKE", "clear request did not cross domains or assert pending");
            n = 0;
            while ((src_pending || dst_pending) && n < 160) begin
                n = n + 1;
                @(posedge dst_clk);
            end
            if (n == 160)
                cdc_fail("FIFO_CLEAR_HANDSHAKE", "clear pending did not retire after request completion");
            repeat (5) @(posedge dst_clk);
            if (dst_valid !== 1'b0)
                cdc_fail("FIFO_RESET_FLUSH", "clear operation did not discard queued output");
        end
    endtask

    task reset_midtraffic;
        begin
            @(negedge src_clk);
            src_valid = 0;
            src_rst_n = 0;
            repeat (2) @(negedge dst_clk);
            dst_ready = 0;
            dst_rst_n = 0;
            repeat (4) @(posedge src_clk);
            src_rst_n = 1;
            repeat (3) @(posedge dst_clk);
            dst_rst_n = 1;
            repeat (6) @(posedge dst_clk);
        end
    endtask

    always @(posedge src_clk) begin
        if (src_rst_n) begin
            if ((^src_ready) === 1'bx || (^src_pending) === 1'bx)
                cdc_fail("FIFO_X_STATUS", "source status is unknown");
            if (src_valid && ((^src_data) === 1'bx))
                protocol_fail("FIFO_X_INPUT", "source payload contains unknown bits");
        end
    end

    always @(posedge dst_clk) begin
        if (!dst_rst_n) begin
            #1;
            if (dst_valid !== 1'b0)
                cdc_fail("FIFO_RESET_SAFETY", "destination valid remained asserted during reset");
            prev_stalled <= 0;
        end else begin
            if ((^dst_valid) === 1'bx || (^dst_pending) === 1'bx)
                cdc_fail("FIFO_X_STATUS", "destination status is unknown");
            if (prev_stalled && !src_pending && !dst_pending &&
                !src_clear && !dst_clear &&
                (!dst_valid || dst_data !== prev_data))
                cdc_fail("FIFO_BACKPRESSURE_STABILITY", "output changed while stalled");
            if (dst_valid && ((^dst_data) === 1'bx))
                cdc_fail("FIFO_X_OUTPUT", "destination payload contains unknown bits");
            if (score_enable && dst_valid && dst_ready) begin
                if (received >= sent)
                    cdc_fail("FIFO_COHERENCY", "destination produced a transaction without an accepted source transfer");
                if (dst_data !== expected[received]) begin
                    $display("CDC/RESET VIOLATION [FIFO_DATA_ORDER]: index=%0d got=%h expected=%h",
                             received, dst_data, expected[received]);
                    errors = errors + 1;
                end
                received = received + 1;
            end
            if (src_pending || dst_pending || src_clear || dst_clear)
                prev_stalled <= 0;
            else
                prev_stalled <= dst_valid && !dst_ready;
            prev_data <= dst_data;
        end
    end

    initial begin
        src_clk = 0; dst_clk = 0;
        src_rst_n = 0; dst_rst_n = 0;
        src_clear = 0; dst_clear = 0;
        src_valid = 0; src_data = 0; dst_ready = 0;
        prev_stalled = 0; prev_data = 0; score_enable = 0;
        errors = 0; sent = 0; received = 0;

        repeat (5) @(posedge src_clk); src_rst_n = 1;
        repeat (4) @(posedge dst_clk); dst_rst_n = 1;
        repeat (5) @(posedge dst_clk);

        /* Source-requested clear must discard stalled queued traffic. */
        send_one(8'h11);
        send_one(8'h22);
        @(negedge src_clk); src_clear = 1;
        @(negedge src_clk); src_clear = 0;
        wait_clear_done;

        /* Destination-requested clear exercises the reverse clear crossing. */
        send_one(8'h33);
        send_one(8'h44);
        @(negedge dst_clk); dst_clear = 1;
        @(negedge dst_clk); dst_clear = 0;
        wait_clear_done;

        send_one(8'h55);
        reset_midtraffic;

        sent = 0;
        received = 0;
        score_enable = 1;
        for (i = 0; i < COUNT; i = i + 1)
            expected[i] = 8'h6d ^ (i * 8'h31);

        fork
            begin
                for (i = 0; i < COUNT; i = i + 1)
                    send_one(expected[i]);
            end
            begin
                repeat (4) @(posedge dst_clk);
                while (received < COUNT) begin
                    @(negedge dst_clk);
                    if ((received % 7) == 3) begin
                        dst_ready = 0;
                        repeat (3) @(negedge dst_clk);
                        dst_ready = 1;
                    end else
                        dst_ready = 1;
                end
                dst_ready = 0;
            end
        join

        if (sent != COUNT || received != COUNT)
            cdc_fail("FIFO_COHERENCY", "accepted and delivered transaction counts differ");
        if (errors == 0)
            $display("CDC FIFO GRAY CLEARABLE ENHANCED: ALL TESTS PASSED");
        else
            $display("CDC FIFO GRAY CLEARABLE ENHANCED: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #350000;
        $display("FIFO TEST TIMEOUT: cdc_fifo_gray_clearable global watchdog expired");
        $finish;
    end
endmodule
