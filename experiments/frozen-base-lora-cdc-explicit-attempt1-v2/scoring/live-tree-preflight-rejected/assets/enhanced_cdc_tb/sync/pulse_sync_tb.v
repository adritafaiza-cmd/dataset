`timescale 1ns/1ps

module pulse_sync_tb;
    integer errors, sent, seen, i, wait_cycles;
    reg clk_a, clk_b, rstn_a, rstn_b, pulseA_i;
    reg prev_pulse_b;
    wire pulseB_o, busy_o;

    pulse_sync #(.STAGES(2)) dut (
        .clk_a(clk_a), .rstn_a(rstn_a),
        .clk_b(clk_b), .rstn_b(rstn_b),
        .pulseA_i(pulseA_i), .pulseB_o(pulseB_o), .busy_o(busy_o)
    );

    initial clk_a = 0;
    initial clk_b = 0;
    always #5 clk_a = ~clk_a;
    always #11 clk_b = ~clk_b;

    always @(negedge clk_b) begin
        if (pulseB_o !== 1'b0 && pulseB_o !== 1'b1) begin
            $display("CDC VIOLATION [CDC_PULSE_X_PROPAGATION]: pulseB_o=%b expected_known=0_or_1", pulseB_o);
            errors = errors + 1;
        end
        if (pulseB_o && prev_pulse_b) begin
            $display("CDC VIOLATION [CDC_PULSE_WIDTH]: pulseB_o=%b previous_pulseB_o=%b expected_max_dst_cycles=1", pulseB_o, prev_pulse_b);
            errors = errors + 1;
        end
        if ((!rstn_a || !rstn_b) && pulseB_o) begin
            $display("RESET VIOLATION [RESET_PULSE_ESCAPE]: pulseB_o=%b rstn_a=%b rstn_b=%b expected_pulseB_o=0", pulseB_o, rstn_a, rstn_b);
            errors = errors + 1;
        end
        if (rstn_a && rstn_b && pulseB_o)
            seen = seen + 1;
        prev_pulse_b = pulseB_o;
    end

    always @(negedge clk_a) begin
        if (busy_o !== 1'b0 && busy_o !== 1'b1) begin
            $display("CDC VIOLATION [CDC_HANDSHAKE_X_PROPAGATION]: busy_o=%b expected_known=0_or_1", busy_o);
            errors = errors + 1;
        end
    end

    task wait_not_busy;
        begin
            wait_cycles = 0;
            while ((busy_o !== 1'b0) && (wait_cycles < 30)) begin
                @(negedge clk_a);
                wait_cycles = wait_cycles + 1;
            end
            if (busy_o !== 1'b0) begin
                $display("CDC VIOLATION [CDC_HANDSHAKE_COMPLETION]: busy_o=%b wait_src_cycles=%0d limit=30 expected=0", busy_o, wait_cycles);
                errors = errors + 1;
            end
        end
    endtask

    task send_pulse;
        integer before_seen;
        begin
            wait_not_busy;
            before_seen = seen;
            @(negedge clk_a);
            pulseA_i = 1;
            @(negedge clk_a);
            pulseA_i = 0;
            sent = sent + 1;
            wait_cycles = 0;
            while ((seen == before_seen) && (wait_cycles < 16)) begin
                @(negedge clk_b);
                wait_cycles = wait_cycles + 1;
            end
            if (seen != before_seen + 1) begin
                $display("CDC VIOLATION [CDC_PULSE_LOSS]: sent=%0d seen=%0d before_seen=%0d wait_dst_cycles=%0d limit=16", sent, seen, before_seen, wait_cycles);
                errors = errors + 1;
            end
            wait_not_busy;
            repeat (2) @(negedge clk_b);
            if (seen != sent) begin
                $display("CDC VIOLATION [CDC_PULSE_DUPLICATION]: sent=%0d seen=%0d expected_seen=%0d", sent, seen, sent);
                errors = errors + 1;
            end
        end
    endtask

    task reset_a_only;
        begin
            wait_not_busy;
            #3 rstn_a = 0;
            pulseA_i = 0;
            repeat (3) @(posedge clk_a);
            #2 rstn_a = 1;
            repeat (8) @(posedge clk_a);
            if (seen != sent) begin
                $display("RESET VIOLATION [RESET_PULSE_RECOVERY]: reset_domain=SOURCE sent=%0d seen=%0d expected_no_spurious_pulse=1", sent, seen);
                errors = errors + 1;
            end
        end
    endtask

    task reset_b_only;
        begin
            wait_not_busy;
            #4 rstn_b = 0;
            repeat (3) @(posedge clk_b);
            #3 rstn_b = 1;
            repeat (8) @(posedge clk_b);
            if (seen != sent) begin
                $display("RESET VIOLATION [RESET_PULSE_RECOVERY]: reset_domain=DESTINATION sent=%0d seen=%0d expected_no_spurious_pulse=1", sent, seen);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0; sent = 0; seen = 0; prev_pulse_b = 0;
        rstn_a = 0; rstn_b = 0; pulseA_i = 0;
        repeat (4) @(posedge clk_a);
        #2 rstn_a = 1;
        repeat (2) @(posedge clk_b);
        #3 rstn_b = 1;
        repeat (4) @(posedge clk_b);

        for (i = 0; i < 12; i = i + 1) begin
            send_pulse;
            repeat ($random & 3) @(posedge clk_a);
            if (i == 3) reset_a_only;
            if (i == 7) reset_b_only;
        end

        if (seen != sent) begin
            $display("CDC VIOLATION [CDC_PULSE_EXACT_ONCE]: sent=%0d seen=%0d expected_seen=%0d", sent, seen, sent);
            errors = errors + 1;
        end
        if (errors == 0) $display("PULSE SYNC: ALL TESTS PASSED");
        else $display("PULSE SYNC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #100000;
        $display("PULSE SYNC: TIMEOUT");
        $finish;
    end
endmodule
