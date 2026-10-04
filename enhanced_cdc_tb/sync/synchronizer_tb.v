`timescale 1ns/1ps

module synchronizer_tb;
    parameter STAGES = 2;
    integer errors, i;
    reg clk, rstn, async_sig_i;
    reg [STAGES-1:0] expected;
    wire sync_sig_o;

    synchronizer #(.STAGES(STAGES)) dut (
        .clk(clk), .rstn(rstn),
        .async_sig_i(async_sig_i), .sync_sig_o(sync_sig_o)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rstn)
            expected <= {STAGES{1'b0}};
        else
            expected <= {expected[STAGES-2:0], async_sig_i};
    end

    always @(negedge clk) begin
        if (sync_sig_o !== expected[STAGES-1]) begin
            $display("CDC VIOLATION [CDC_SYNC_STAGE_BEHAVIOR]: sync_sig_o=%b expected_stage_o=%b stages=%0d", sync_sig_o, expected[STAGES-1], STAGES);
            errors = errors + 1;
        end
        if (sync_sig_o !== 1'b0 && sync_sig_o !== 1'b1) begin
            $display("CDC VIOLATION [CDC_SYNC_X_PROPAGATION]: sync_sig_o=%b expected_known=0_or_1 stages=%0d", sync_sig_o, STAGES);
            errors = errors + 1;
        end
    end

    initial begin
        errors = 0;
        rstn = 0;
        async_sig_i = 0;
        expected = 0;
        repeat (3) @(posedge clk);
        @(negedge clk);
        rstn = 1;

        for (i = 0; i < 100; i = i + 1) begin
            #(1 + ($random & 7));
            async_sig_i = $random;
            if ((i == 31) || (i == 70)) begin
                @(negedge clk);
                rstn = 0;
                repeat (2) @(posedge clk);
                @(negedge clk);
                rstn = 1;
            end
        end
        repeat (STAGES + 2) @(posedge clk);

        if (errors == 0) $display("SYNCHRONIZER: ALL TESTS PASSED");
        else $display("SYNCHRONIZER: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("SYNCHRONIZER: TIMEOUT");
        $finish;
    end
endmodule
