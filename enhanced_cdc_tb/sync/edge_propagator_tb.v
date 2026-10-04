`timescale 1ns/1ps

module edge_propagator_tb;
    integer errors, sent, seen, i, wait_cycles;
    reg clk_tx_i, clk_rx_i, rstn_tx_i, rstn_rx_i, edge_i;
    reg prev_edge_o;
    wire edge_o;

    edge_propagator dut (
        .clk_tx_i(clk_tx_i), .rstn_tx_i(rstn_tx_i), .edge_i(edge_i),
        .clk_rx_i(clk_rx_i), .rstn_rx_i(rstn_rx_i), .edge_o(edge_o)
    );

    initial clk_tx_i = 0;
    initial clk_rx_i = 0;
    always #5 clk_tx_i = ~clk_tx_i;
    always #7 clk_rx_i = ~clk_rx_i;

    always @(negedge clk_rx_i) begin
        if (edge_o !== 1'b0 && edge_o !== 1'b1) begin
            $display("CDC VIOLATION [CDC_EDGE_X_PROPAGATION]: edge_o=%b expected_known=0_or_1", edge_o);
            errors = errors + 1;
        end
        if (edge_o && prev_edge_o) begin
            $display("CDC VIOLATION [CDC_EDGE_WIDTH]: edge_o=%b previous_edge_o=%b expected_max_rx_cycles=1", edge_o, prev_edge_o);
            errors = errors + 1;
        end
        if ((!rstn_tx_i || !rstn_rx_i) && edge_o) begin
            $display("RESET VIOLATION [RESET_EDGE_ESCAPE]: edge_o=%b rstn_tx_i=%b rstn_rx_i=%b expected_edge_o=0", edge_o, rstn_tx_i, rstn_rx_i);
            errors = errors + 1;
        end
        if (rstn_tx_i && rstn_rx_i && edge_o)
            seen = seen + 1;
        prev_edge_o = edge_o;
    end

    task send_edge;
        integer before_seen;
        begin
            before_seen = seen;
            @(negedge clk_tx_i);
            edge_i = 1;
            @(negedge clk_tx_i);
            edge_i = 0;
            sent = sent + 1;
            wait_cycles = 0;
            while ((seen == before_seen) && (wait_cycles < 16)) begin
                @(negedge clk_rx_i);
                wait_cycles = wait_cycles + 1;
            end
            if (seen != before_seen + 1) begin
                $display("CDC VIOLATION [CDC_EDGE_LOSS]: sent=%0d seen=%0d before_seen=%0d wait_rx_cycles=%0d limit=16", sent, seen, before_seen, wait_cycles);
                errors = errors + 1;
            end
            repeat (10) @(posedge clk_tx_i);
            repeat (3) @(posedge clk_rx_i);
            if (seen != sent) begin
                $display("CDC VIOLATION [CDC_EDGE_DUPLICATION]: sent=%0d seen=%0d expected_seen=%0d", sent, seen, sent);
                errors = errors + 1;
            end
        end
    endtask

    task independent_resets;
        begin
            #3 rstn_tx_i = 0;
            edge_i = 0;
            repeat (3) @(posedge clk_tx_i);
            #2 rstn_tx_i = 1;
            repeat (8) @(posedge clk_tx_i);
            if (seen != sent) begin
                $display("RESET VIOLATION [RESET_EDGE_RECOVERY]: reset_domain=TX sent=%0d seen=%0d expected_no_spurious_edge=1", sent, seen);
                errors = errors + 1;
            end
            #4 rstn_rx_i = 0;
            repeat (3) @(posedge clk_rx_i);
            #2 rstn_rx_i = 1;
            repeat (8) @(posedge clk_rx_i);
            repeat (8) @(posedge clk_tx_i);
            if (seen != sent) begin
                $display("RESET VIOLATION [RESET_EDGE_RECOVERY]: reset_domain=RX sent=%0d seen=%0d expected_no_spurious_edge=1", sent, seen);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0; sent = 0; seen = 0; prev_edge_o = 0;
        rstn_tx_i = 0; rstn_rx_i = 0; edge_i = 0;
        repeat (4) @(posedge clk_tx_i);
        #2 rstn_tx_i = 1;
        repeat (3) @(posedge clk_rx_i);
        #3 rstn_rx_i = 1;
        repeat (4) @(posedge clk_rx_i);

        for (i = 0; i < 12; i = i + 1) begin
            send_edge;
            if (i == 5)
                independent_resets;
        end

        if (seen != sent) begin
            $display("CDC VIOLATION [CDC_EDGE_EXACT_ONCE]: sent=%0d seen=%0d expected_seen=%0d", sent, seen, sent);
            errors = errors + 1;
        end
        if (errors == 0) $display("EDGE PROPAGATOR: ALL TESTS PASSED");
        else $display("EDGE PROPAGATOR: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #100000;
        $display("EDGE PROPAGATOR: TIMEOUT");
        $finish;
    end
endmodule
