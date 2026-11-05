`timescale 1ns/1ps

module sync_wedge_tb;
    parameter STAGES = 2;
    integer errors, i, rises, falls, expected_rises, expected_falls;
    reg clk_i, rst_ni, en_i, serial_i;
    reg [STAGES-1:0] model_pipe;
    reg model_q, prev_r, prev_f;
    wire r_edge_o, f_edge_o, serial_o;

    sync_wedge #(.STAGES(STAGES)) dut (
        .clk_i(clk_i), .rst_ni(rst_ni), .en_i(en_i),
        .serial_i(serial_i), .r_edge_o(r_edge_o),
        .f_edge_o(f_edge_o), .serial_o(serial_o)
    );

    initial clk_i = 0;
    always #5 clk_i = ~clk_i;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            model_pipe <= {STAGES{1'b0}};
            model_q <= 1'b0;
        end else begin
            model_pipe <= {model_pipe[STAGES-2:0], serial_i};
            if (en_i)
                model_q <= model_pipe[STAGES-1];
        end
    end

    always @(negedge clk_i) begin
        if (serial_o !== model_q ||
            r_edge_o !== (model_pipe[STAGES-1] & ~model_q) ||
            f_edge_o !== (~model_pipe[STAGES-1] & model_q)) begin
            $display("CDC VIOLATION [CDC_SYNC_EDGE_BEHAVIOR]: r_edge_o=%b expected_r=%b f_edge_o=%b expected_f=%b serial_o=%b expected_q=%b", r_edge_o, (model_pipe[STAGES-1] & ~model_q), f_edge_o, (~model_pipe[STAGES-1] & model_q), serial_o, model_q);
            errors = errors + 1;
        end
        if ((^({r_edge_o, f_edge_o, serial_o})) === 1'bx) begin
            $display("CDC VIOLATION [CDC_SYNC_X_PROPAGATION]: r_edge_o=%b f_edge_o=%b serial_o=%b expected_all_known=1", r_edge_o, f_edge_o, serial_o);
            errors = errors + 1;
        end
        if (r_edge_o && f_edge_o) begin
            $display("CDC VIOLATION [CDC_EDGE_EXCLUSIVITY]: r_edge_o=%b f_edge_o=%b expected_mutually_exclusive=1", r_edge_o, f_edge_o);
            errors = errors + 1;
        end
        if (en_i && ((r_edge_o && prev_r) || (f_edge_o && prev_f))) begin
            $display("CDC VIOLATION [CDC_EDGE_WIDTH]: en_i=%b r_edge_o=%b previous_r=%b f_edge_o=%b previous_f=%b expected_max_enabled_cycles=1", en_i, r_edge_o, prev_r, f_edge_o, prev_f);
            errors = errors + 1;
        end
        if (rst_ni && r_edge_o) rises = rises + 1;
        if (rst_ni && f_edge_o) falls = falls + 1;
        prev_r = r_edge_o;
        prev_f = f_edge_o;
    end

    task send_transition;
        input value;
        begin
            @(negedge clk_i);
            serial_i = value;
            if (value) expected_rises = expected_rises + 1;
            else expected_falls = expected_falls + 1;
            repeat (STAGES + 3) @(posedge clk_i);
        end
    endtask

    initial begin
        errors = 0; rises = 0; falls = 0;
        expected_rises = 0; expected_falls = 0;
        rst_ni = 0; en_i = 1; serial_i = 0;
        model_pipe = 0; model_q = 0; prev_r = 0; prev_f = 0;
        repeat (3) @(posedge clk_i);
        @(negedge clk_i); rst_ni = 1;

        for (i = 0; i < 12; i = i + 1) begin
            send_transition(1'b1);
            send_transition(1'b0);
            if (i == 5) begin
                #3 rst_ni = 0;
                #1;
                if ({r_edge_o, f_edge_o, serial_o} !== 3'b000) begin
                    $display("RESET VIOLATION [RESET_ASYNC_ASSERT]: r_edge_o=%b f_edge_o=%b serial_o=%b expected=000 rst_ni=%b", r_edge_o, f_edge_o, serial_o, rst_ni);
                    errors = errors + 1;
                end
                expected_rises = rises;
                expected_falls = falls;
                repeat (2) @(posedge clk_i);
                @(negedge clk_i); rst_ni = 1;
            end
        end
        repeat (STAGES + 2) @(posedge clk_i);
        if (rises != expected_rises || falls != expected_falls) begin
            $display("CDC VIOLATION [CDC_EDGE_EXACT_ONCE]: observed_rises=%0d expected_rises=%0d observed_falls=%0d expected_falls=%0d",
                     rises, expected_rises, falls, expected_falls);
            errors = errors + 1;
        end

        if (errors == 0) $display("SYNC WEDGE: ALL TESTS PASSED");
        else $display("SYNC WEDGE: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #30000;
        $display("SYNC WEDGE: TIMEOUT");
        $finish;
    end
endmodule
