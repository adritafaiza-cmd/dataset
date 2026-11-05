`timescale 1ns/1ps

module rstgen_tb;
    parameter RELEASE_CYCLES = 4;
    integer errors, pass, i;
    reg clk_i, rst_ni, test_mode_i;
    wire rst_no, init_no;

    rstgen dut (
        .clk_i(clk_i), .rst_ni(rst_ni), .test_mode_i(test_mode_i),
        .rst_no(rst_no), .init_no(init_no)
    );

    initial clk_i = 0;
    always #5 clk_i = ~clk_i;

    always @(negedge clk_i) begin
        if ((rst_no !== 1'b0 && rst_no !== 1'b1) ||
            (init_no !== 1'b0 && init_no !== 1'b1)) begin
            $display("RESET VIOLATION [RESET_X_PROPAGATION]: rst_no=%b init_no=%b expected_all_known=1", rst_no, init_no);
            errors = errors + 1;
        end
        if (!rst_ni && (rst_no !== 0 || init_no !== 0)) begin
            $display("RESET VIOLATION [RESET_ASSERT_HOLD]: rst_ni=%b rst_no=%b init_no=%b expected_outputs=00", rst_ni, rst_no, init_no);
            errors = errors + 1;
        end
    end

    task functional_reset_cycle;
        begin
            #(1 + ($random & 7));
            rst_ni = 0;
            #1;
            if (rst_no !== 0 || init_no !== 0) begin
                $display("RESET VIOLATION [RESET_ASYNC_ASSERT]: rst_ni=%b rst_no=%b init_no=%b expected_outputs=00", rst_ni, rst_no, init_no);
                errors = errors + 1;
            end
            repeat (1 + ($random & 3)) @(posedge clk_i);
            @(negedge clk_i);
            rst_ni = 1;
            for (i = 1; i < RELEASE_CYCLES; i = i + 1) begin
                @(negedge clk_i);
                if (rst_no !== 0 || init_no !== 0) begin
                    $display("RESET VIOLATION [RESET_SYNC_DEASSERT_EARLY]: rst_no=%b init_no=%b observed_cycle=%0d required_cycles=%0d expected_outputs=00", rst_no, init_no, i, RELEASE_CYCLES);
                    errors = errors + 1;
                end
            end
            @(negedge clk_i);
            if (rst_no !== 1 || init_no !== 1) begin
                $display("RESET VIOLATION [RESET_SYNC_DEASSERT_LATE]: rst_no=%b init_no=%b observed_cycle=%0d expected_outputs=11", rst_no, init_no, RELEASE_CYCLES);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        rst_ni = 0;
        test_mode_i = 0;
        #1;
        repeat (2) @(posedge clk_i);

        for (pass = 0; pass < 8; pass = pass + 1)
            functional_reset_cycle;

        @(negedge clk_i);
        test_mode_i = 1;
        #1;
        if (rst_no !== 1 || init_no !== 1) begin
            $display("RESET VIOLATION [RESET_TESTMODE_STABILITY]: test_mode_i=%b rst_no=%b init_no=%b expected_outputs=11", test_mode_i, rst_no, init_no);
            errors = errors + 1;
        end
        functional_reset_cycle;

        @(negedge clk_i);
        test_mode_i = 0;
        #1;
        if (rst_no !== 1 || init_no !== 1) begin
            $display("RESET VIOLATION [RESET_TESTMODE_STABILITY]: test_mode_i=%b rst_no=%b init_no=%b expected_outputs=11", test_mode_i, rst_no, init_no);
            errors = errors + 1;
        end

        if (errors == 0) $display("RSTGEN: ALL TESTS PASSED");
        else $display("RSTGEN: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #50000;
        $display("RSTGEN: TIMEOUT");
        $finish;
    end
endmodule
