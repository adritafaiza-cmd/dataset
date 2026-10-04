`timescale 1ns/1ps

module sync_reset_tb;
    parameter N = 2;
    integer errors, pass, i;
    reg clk, rst;
    wire out;

    sync_reset #(.N(N)) dut (.clk(clk), .rst(rst), .out(out));

    initial clk = 0;
    always #5 clk = ~clk;

    always @(negedge clk) begin
        if (out !== 1'b0 && out !== 1'b1) begin
            $display("RESET VIOLATION [RESET_X_PROPAGATION]: out=%b expected_known=0_or_1", out);
            errors = errors + 1;
        end
        if (rst && out !== 1'b1) begin
            $display("RESET VIOLATION [RESET_ASSERT_HOLD]: rst=%b out=%b expected_out=1", rst, out);
            errors = errors + 1;
        end
    end

    task reset_cycle;
        integer delay_ns;
        begin
            delay_ns = 1 + ($random & 7);
            #(delay_ns);
            rst = 1;
            #1;
            if (out !== 1'b1) begin
                $display("RESET VIOLATION [RESET_ASYNC_ASSERT]: rst=%b out=%b expected_out=1 delay_ns=%0d", rst, out, delay_ns);
                errors = errors + 1;
            end
            repeat (1 + ($random & 3)) @(posedge clk);
            @(negedge clk);
            rst = 0;
            for (i = 1; i < N; i = i + 1) begin
                @(negedge clk);
                if (out !== 1'b1) begin
                    $display("RESET VIOLATION [RESET_SYNC_DEASSERT_EARLY]: out=%b observed_cycle=%0d required_cycles=%0d expected_out=1", out, i, N);
                    errors = errors + 1;
                end
            end
            @(negedge clk);
            if (out !== 1'b0) begin
                $display("RESET VIOLATION [RESET_SYNC_DEASSERT_LATE]: out=%b observed_cycle=%0d expected_out=0", out, N);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        rst = 1;
        repeat (2) @(posedge clk);
        for (pass = 0; pass < 8; pass = pass + 1)
            reset_cycle;

        if (errors == 0) $display("SYNC RESET: ALL TESTS PASSED");
        else $display("SYNC RESET: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("SYNC RESET: TIMEOUT");
        $finish;
    end
endmodule
