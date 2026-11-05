`timescale 1ns/1ps

module areset_sync_tb;
    parameter STAGES = 2;
    integer errors, i, age;
    reg clk, async_rst_i, checking;
    reg [STAGES-1:0] expected;
    wire sync_rst_o;

    areset_sync #(.STAGES(STAGES)) dut (
        .clk(clk), .async_rst_i(async_rst_i), .sync_rst_o(sync_rst_o)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    always @(posedge clk)
        expected <= {expected[STAGES-2:0], async_rst_i};

    always @(negedge clk) begin
        if (checking) begin
            if (sync_rst_o !== expected[STAGES-1]) begin
                $display("RESET VIOLATION [RESET_SYNC_STAGE_BEHAVIOR]: sync_rst_o=%b expected_stage_o=%b stages=%0d", sync_rst_o, expected[STAGES-1], STAGES);
                errors = errors + 1;
            end
            if (sync_rst_o !== 1'b0 && sync_rst_o !== 1'b1) begin
                $display("RESET VIOLATION [RESET_X_PROPAGATION]: sync_rst_o=%b expected_known=0_or_1 stages_filled=%0d", sync_rst_o, STAGES);
                errors = errors + 1;
            end
        end
    end

    task drive_level;
        input value;
        begin
            #(1 + ($random & 7));
            async_rst_i = value;
            age = 0;
            while ((sync_rst_o !== value) && (age <= STAGES + 1)) begin
                @(negedge clk);
                age = age + 1;
            end
            if (sync_rst_o !== value || age > STAGES + 1) begin
                $display("RESET VIOLATION [RESET_SYNC_LATENCY]: sync_rst_o=%b target=%b observed_cycles=%0d limit=%0d", sync_rst_o, value, age, STAGES + 1);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        checking = 0;
        async_rst_i = 1;
        expected = {STAGES{1'bx}};
        repeat (STAGES) @(posedge clk);
        @(negedge clk);
        checking = 1;

        for (i = 0; i < 20; i = i + 1) begin
            drive_level(1'b0);
            repeat (1 + ($random & 3)) @(posedge clk);
            drive_level(1'b1);
            repeat (1 + ($random & 3)) @(posedge clk);
        end

        if (errors == 0) $display("ARESET SYNC: ALL TESTS PASSED");
        else $display("ARESET SYNC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("ARESET SYNC: TIMEOUT");
        $finish;
    end
endmodule
