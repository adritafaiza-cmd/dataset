`timescale 1ns/1ps

module cdc_reset_ctrlr_tb;
    integer errors, transactions, i, wait_cycles;
    integer a_iso_count, b_iso_count, a_clear_count, b_clear_count;
    integer a_done_count, b_done_count;
    integer a_phase, b_phase;
    reg a_clk, b_clk, a_rst_n, b_rst_n;
    reg a_clear, b_clear, a_clear_ack, b_clear_ack, a_iso_ack, b_iso_ack;
    reg prev_a_iso, prev_b_iso, prev_a_clear, prev_b_clear;
    wire a_clear_o, b_clear_o, a_iso, b_iso;

    cdc_reset_ctrlr dut (
        .a_clk_i(a_clk), .a_rst_ni(a_rst_n), .a_clear_i(a_clear),
        .a_clear_o(a_clear_o), .a_clear_ack_i(a_clear_ack),
        .a_isolate_o(a_iso), .a_isolate_ack_i(a_iso_ack),
        .b_clk_i(b_clk), .b_rst_ni(b_rst_n), .b_clear_i(b_clear),
        .b_clear_o(b_clear_o), .b_clear_ack_i(b_clear_ack),
        .b_isolate_o(b_iso), .b_isolate_ack_i(b_iso_ack)
    );

    initial a_clk = 0;
    initial b_clk = 0;
    always #5 a_clk = ~a_clk;
    always #8 b_clk = ~b_clk;

    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_iso_ack <= 0;
            a_clear_ack <= 0;
        end else begin
            a_iso_ack <= a_iso;
            a_clear_ack <= a_clear_o;
        end
    end

    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_iso_ack <= 0;
            b_clear_ack <= 0;
        end else begin
            b_iso_ack <= b_iso;
            b_clear_ack <= b_clear_o;
        end
    end

    always @(negedge a_clk) begin
        if ((^({a_iso, a_clear_o})) === 1'bx) begin
            $display("CDC VIOLATION [CDC_RESET_CTRL_X_PROPAGATION]: domain=A isolate=%b clear=%b expected_all_known=1", a_iso, a_clear_o);
            errors = errors + 1;
        end
        if (!a_rst_n && (a_iso !== 0 || a_clear_o !== 0)) begin
            $display("RESET VIOLATION [RESET_CTRL_ASSERT_STATE]: domain=A rst_n=%b isolate=%b clear=%b expected_outputs=00", a_rst_n, a_iso, a_clear_o);
            errors = errors + 1;
        end
        if (a_clear_o && !a_iso) begin
            $display("CDC VIOLATION [CDC_RESET_CTRL_ISOLATION_ORDER]: domain=A clear=%b isolate=%b expected_isolate=1", a_clear_o, a_iso);
            errors = errors + 1;
        end
        if (a_iso && !prev_a_iso) begin
            a_iso_count = a_iso_count + 1;
            a_phase = 1;
        end
        if (a_clear_o && !prev_a_clear) begin
            a_clear_count = a_clear_count + 1;
            if (a_phase != 1) begin
                $display("CDC VIOLATION [CDC_RESET_CTRL_CLEAR_ORDER]: domain=A phase=%0d expected_phase=1 clear_count=%0d isolate_count=%0d", a_phase, a_clear_count, a_iso_count);
                errors = errors + 1;
            end
            a_phase = 2;
        end
        if (!a_iso && prev_a_iso) begin
            if (a_phase != 2 || a_clear_o) begin
                $display("CDC VIOLATION [CDC_RESET_CTRL_RELEASE_ORDER]: domain=A phase=%0d clear=%b isolate=%b previous_isolate=%b expected_phase=2", a_phase, a_clear_o, a_iso, prev_a_iso);
                errors = errors + 1;
            end
            a_done_count = a_done_count + 1;
            a_phase = 0;
        end
        prev_a_iso = a_iso;
        prev_a_clear = a_clear_o;
    end

    always @(negedge b_clk) begin
        if ((^({b_iso, b_clear_o})) === 1'bx) begin
            $display("CDC VIOLATION [CDC_RESET_CTRL_X_PROPAGATION]: domain=B isolate=%b clear=%b expected_all_known=1", b_iso, b_clear_o);
            errors = errors + 1;
        end
        if (!b_rst_n && (b_iso !== 0 || b_clear_o !== 0)) begin
            $display("RESET VIOLATION [RESET_CTRL_ASSERT_STATE]: domain=B rst_n=%b isolate=%b clear=%b expected_outputs=00", b_rst_n, b_iso, b_clear_o);
            errors = errors + 1;
        end
        if (b_clear_o && !b_iso) begin
            $display("CDC VIOLATION [CDC_RESET_CTRL_ISOLATION_ORDER]: domain=B clear=%b isolate=%b expected_isolate=1", b_clear_o, b_iso);
            errors = errors + 1;
        end
        if (b_iso && !prev_b_iso) begin
            b_iso_count = b_iso_count + 1;
            b_phase = 1;
        end
        if (b_clear_o && !prev_b_clear) begin
            b_clear_count = b_clear_count + 1;
            if (b_phase != 1) begin
                $display("CDC VIOLATION [CDC_RESET_CTRL_CLEAR_ORDER]: domain=B phase=%0d expected_phase=1 clear_count=%0d isolate_count=%0d", b_phase, b_clear_count, b_iso_count);
                errors = errors + 1;
            end
            b_phase = 2;
        end
        if (!b_iso && prev_b_iso) begin
            if (b_phase != 2 || b_clear_o) begin
                $display("CDC VIOLATION [CDC_RESET_CTRL_RELEASE_ORDER]: domain=B phase=%0d clear=%b isolate=%b previous_isolate=%b expected_phase=2", b_phase, b_clear_o, b_iso, prev_b_iso);
                errors = errors + 1;
            end
            b_done_count = b_done_count + 1;
            b_phase = 0;
        end
        prev_b_iso = b_iso;
        prev_b_clear = b_clear_o;
    end

    task request_from_a;
        integer before_a, before_b;
        begin
            before_a = a_done_count;
            before_b = b_done_count;
            @(negedge a_clk); a_clear = 1;
            @(negedge a_clk); a_clear = 0;
            wait_cycles = 0;
            while (((a_done_count == before_a) || (b_done_count == before_b)) &&
                   (wait_cycles < 100)) begin
                @(negedge a_clk);
                wait_cycles = wait_cycles + 1;
            end
            transactions = transactions + 1;
            if (a_done_count != before_a + 1 || b_done_count != before_b + 1) begin
                $display("CDC VIOLATION [CDC_RESET_CTRL_EXACT_ONCE]: source=A before_a=%0d after_a=%0d before_b=%0d after_b=%0d wait_cycles=%0d expected_delta=1", before_a, a_done_count, before_b, b_done_count, wait_cycles);
                errors = errors + 1;
            end
            repeat (6) @(posedge a_clk);
            repeat (6) @(posedge b_clk);
        end
    endtask

    task request_from_b;
        integer before_a, before_b;
        begin
            before_a = a_done_count;
            before_b = b_done_count;
            @(negedge b_clk); b_clear = 1;
            @(negedge b_clk); b_clear = 0;
            wait_cycles = 0;
            while (((a_done_count == before_a) || (b_done_count == before_b)) &&
                   (wait_cycles < 100)) begin
                @(negedge b_clk);
                wait_cycles = wait_cycles + 1;
            end
            transactions = transactions + 1;
            if (a_done_count != before_a + 1 || b_done_count != before_b + 1) begin
                $display("CDC VIOLATION [CDC_RESET_CTRL_EXACT_ONCE]: source=B before_a=%0d after_a=%0d before_b=%0d after_b=%0d wait_cycles=%0d expected_delta=1", before_a, a_done_count, before_b, b_done_count, wait_cycles);
                errors = errors + 1;
            end
            repeat (6) @(posedge a_clk);
            repeat (6) @(posedge b_clk);
        end
    endtask

    task independent_reset_test;
        integer before_a, before_b;
        begin
            before_a = a_done_count;
            before_b = b_done_count;
            #3 a_rst_n = 0;
            #1;
            if (a_iso !== 0 || a_clear_o !== 0) begin
                $display("RESET VIOLATION [RESET_ASYNC_ASSERT]: domain=A rst_n=%b isolate=%b clear=%b expected_outputs=00", a_rst_n, a_iso, a_clear_o);
                errors = errors + 1;
            end
            repeat (3) @(posedge a_clk);
            #2 a_rst_n = 1;
            repeat (8) @(posedge a_clk);
            #3 b_rst_n = 0;
            #1;
            if (b_iso !== 0 || b_clear_o !== 0) begin
                $display("RESET VIOLATION [RESET_ASYNC_ASSERT]: domain=B rst_n=%b isolate=%b clear=%b expected_outputs=00", b_rst_n, b_iso, b_clear_o);
                errors = errors + 1;
            end
            repeat (3) @(posedge b_clk);
            #2 b_rst_n = 1;
            repeat (8) @(posedge b_clk);
            if (a_done_count != before_a || b_done_count != before_b) begin
                $display("RESET VIOLATION [RESET_CTRL_RECOVERY]: before_a=%0d after_a=%0d before_b=%0d after_b=%0d expected_delta=0", before_a, a_done_count, before_b, b_done_count);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0; transactions = 0;
        a_iso_count = 0; b_iso_count = 0; a_clear_count = 0; b_clear_count = 0;
        a_done_count = 0; b_done_count = 0; a_phase = 0; b_phase = 0;
        prev_a_iso = 0; prev_b_iso = 0; prev_a_clear = 0; prev_b_clear = 0;
        a_rst_n = 0; b_rst_n = 0; a_clear = 0; b_clear = 0;
        a_clear_ack = 0; b_clear_ack = 0; a_iso_ack = 0; b_iso_ack = 0;
        repeat (4) @(posedge a_clk); #2 a_rst_n = 1;
        repeat (3) @(posedge b_clk); #3 b_rst_n = 1;
        repeat (5) @(posedge b_clk);

        for (i = 0; i < 3; i = i + 1) begin
            request_from_a;
            request_from_b;
            if (i == 1)
                independent_reset_test;
        end

        if (a_iso_count != transactions || b_iso_count != transactions ||
            a_clear_count != transactions || b_clear_count != transactions ||
            a_done_count != transactions || b_done_count != transactions) begin
            $display("CDC VIOLATION [CDC_RESET_CTRL_TRANSACTION_COUNTS]: transactions=%0d A_iso_clear_done=%0d/%0d/%0d B_iso_clear_done=%0d/%0d/%0d expected_each=%0d",
                     transactions, a_iso_count, a_clear_count, a_done_count,
                     b_iso_count, b_clear_count, b_done_count, transactions);
            errors = errors + 1;
        end
        if (a_iso || b_iso || a_clear_o || b_clear_o) begin
            $display("CDC VIOLATION [CDC_RESET_CTRL_IDLE_RECOVERY]: a_iso=%b b_iso=%b a_clear=%b b_clear=%b expected=0000", a_iso, b_iso, a_clear_o, b_clear_o);
            errors = errors + 1;
        end

        if (errors == 0) $display("CDC RESET CTRLR: ALL TESTS PASSED");
        else $display("CDC RESET CTRLR: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #200000;
        $display("CDC RESET CTRLR: TIMEOUT");
        $finish;
    end
endmodule
