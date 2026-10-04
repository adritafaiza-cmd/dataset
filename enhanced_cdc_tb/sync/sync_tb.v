`timescale 1ns/1ps

module sync_tb;
    parameter STAGES = 2;
    integer errors, i;
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

    task assert_reset_at_random_phase;
        integer delay_ns;
        begin
            delay_ns = 1 + ($random & 7);
            #(delay_ns);
            rst_ni = 1'b0;
            #1;
            if (serial_o !== 1'b0) begin
                $display("RESET VIOLATION [RESET_ASYNC_ASSERT]: serial_o=%b expected=0 rst_ni=%b delay_ns=%0d", serial_o, rst_ni, delay_ns);
                errors = errors + 1;
            end
            repeat (1 + ($random & 3)) @(posedge clk_i);
            @(negedge clk_i);
            rst_ni = 1'b1;
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

        for (i = 0; i < 80; i = i + 1) begin
            @(negedge clk_i);
            serial_i = $random;
            if ((i == 19) || (i == 47))
                assert_reset_at_random_phase;
        end
        repeat (STAGES + 2) @(posedge clk_i);

        if (errors == 0) $display("SYNC: ALL TESTS PASSED");
        else $display("SYNC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("SYNC: TIMEOUT");
        $finish;
    end
endmodule
