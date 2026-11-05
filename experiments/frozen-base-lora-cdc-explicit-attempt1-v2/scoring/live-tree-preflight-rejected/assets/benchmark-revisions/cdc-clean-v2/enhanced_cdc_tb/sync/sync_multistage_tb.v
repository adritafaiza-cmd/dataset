`timescale 1ns/1ps

module sync_multistage_tb;
    parameter STAGES = 4;
    integer errors, i, age;
    reg clk_i, rst_ni, serial_i;
    reg [STAGES-1:0] expected;
    wire serial_o;

    sync #(.STAGES(STAGES)) dut (
        .clk_i(clk_i), .rst_ni(rst_ni),
        .serial_i(serial_i), .serial_o(serial_o)
    );

    initial clk_i = 0;
    always #5 clk_i = ~clk_i;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            expected <= {STAGES{1'b0}};
        else
            expected <= {expected[STAGES-2:0], serial_i};
    end

    always @(negedge clk_i) begin
        if (serial_o !== expected[STAGES-1]) begin
            $display("CDC VIOLATION [CDC_SYNC_STAGE_BEHAVIOR]: serial_o=%b expected_stage_o=%b stages=%0d", serial_o, expected[STAGES-1], STAGES);
            errors = errors + 1;
        end
        if (serial_o !== 1'b0 && serial_o !== 1'b1) begin
            $display("CDC VIOLATION [CDC_SYNC_X_PROPAGATION]: serial_o=%b expected_known=0_or_1 stages=%0d", serial_o, STAGES);
            errors = errors + 1;
        end
    end

    task drive_and_bound;
        input value;
        begin
            @(negedge clk_i);
            serial_i = value;
            age = 0;
            while ((serial_o !== value) && (age <= STAGES)) begin
                @(negedge clk_i);
                age = age + 1;
            end
            if (serial_o !== value || age < STAGES) begin
                $display("CDC VIOLATION [CDC_SYNC_LATENCY]: serial_o=%b target=%b observed_cycles=%0d expected_cycles=%0d", serial_o, value, age, STAGES);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        rst_ni = 0;
        serial_i = 0;
        expected = 0;
        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        rst_ni = 1;

        drive_and_bound(1'b1);
        drive_and_bound(1'b0);
        drive_and_bound(1'b1);

        for (i = 0; i < 48; i = i + 1) begin
            @(negedge clk_i);
            serial_i = $random;
            if (i == 23) begin
                #3 rst_ni = 0;
                #1;
                if (serial_o !== 0) begin
                    $display("RESET VIOLATION [RESET_ASYNC_ASSERT]: serial_o=%b expected=0 rst_ni=%b", serial_o, rst_ni);
                    errors = errors + 1;
                end
                repeat (2) @(posedge clk_i);
                @(negedge clk_i);
                rst_ni = 1;
            end
        end
        repeat (STAGES + 1) @(posedge clk_i);

        if (errors == 0) $display("SYNC MULTISTAGE: ALL TESTS PASSED");
        else $display("SYNC MULTISTAGE: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("SYNC MULTISTAGE: TIMEOUT");
        $finish;
    end
endmodule
