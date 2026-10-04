`timescale 1ns/1ps

module areset_deassert_sync_tb;
    parameter CHAINS = 2;
    integer errors, pass, i;
    reg clk, async_rst_i;
    wire sync_rst_o;

    areset_deassert_sync #(.CHAINS(CHAINS), .RST_POL(1'b1)) dut (
        .clk(clk), .async_rst_i(async_rst_i), .sync_rst_o(sync_rst_o)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    always @(negedge clk) begin
        if (sync_rst_o !== 1'b0 && sync_rst_o !== 1'b1) begin
            $display("RESET VIOLATION [RESET_X_PROPAGATION]: sync_rst_o=%b expected_known=0_or_1", sync_rst_o);
            errors = errors + 1;
        end
        if (async_rst_i && sync_rst_o !== 1'b1) begin
            $display("RESET VIOLATION [RESET_ASSERT_HOLD]: async_rst_i=%b sync_rst_o=%b expected_sync_rst_o=1", async_rst_i, sync_rst_o);
            errors = errors + 1;
        end
    end

    task reset_cycle;
        begin
            #(1 + ($random & 7));
            async_rst_i = 1;
            #1;
            if (sync_rst_o !== 1'b1) begin
                $display("RESET VIOLATION [RESET_ASYNC_ASSERT]: async_rst_i=%b sync_rst_o=%b expected_sync_rst_o=1", async_rst_i, sync_rst_o);
                errors = errors + 1;
            end
            repeat (1 + ($random & 3)) @(posedge clk);
            @(negedge clk);
            async_rst_i = 0;
            for (i = 1; i < CHAINS; i = i + 1) begin
                @(negedge clk);
                if (sync_rst_o !== 1'b1) begin
                    $display("RESET VIOLATION [RESET_SYNC_DEASSERT_EARLY]: sync_rst_o=%b observed_cycle=%0d required_cycles=%0d expected=1", sync_rst_o, i, CHAINS);
                    errors = errors + 1;
                end
            end
            @(negedge clk);
            if (sync_rst_o !== 1'b0) begin
                $display("RESET VIOLATION [RESET_SYNC_DEASSERT_LATE]: sync_rst_o=%b observed_cycle=%0d expected=0", sync_rst_o, CHAINS);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        async_rst_i = 1;
        #1;
        for (pass = 0; pass < 10; pass = pass + 1)
            reset_cycle;

        if (errors == 0) $display("ARESET DEASSERT SYNC: ALL TESTS PASSED");
        else $display("ARESET DEASSERT SYNC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("ARESET DEASSERT SYNC: TIMEOUT");
        $finish;
    end
endmodule
