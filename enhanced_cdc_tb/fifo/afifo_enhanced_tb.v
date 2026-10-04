`timescale 1ns/1ps

module afifo_enhanced_tb;
    parameter WIDTH = 8;
    parameter LGFIFO = 3;
    parameter COUNT = 48;

    reg i_wclk, i_rclk;
    reg i_wr_reset_n, i_rd_reset_n;
    reg i_wr, i_rd;
    reg [WIDTH-1:0] i_wr_data;
    wire o_wr_full, o_rd_empty;
    wire [WIDTH-1:0] o_rd_data;
    reg [WIDTH-1:0] expected [0:COUNT-1];
    integer errors, writes, reads, i;

    afifo #(.LGFIFO(LGFIFO), .WIDTH(WIDTH), .NFF(2),
            .OPT_REGISTER_READS(1'b1)) dut (
        .i_wclk(i_wclk), .i_wr_reset_n(i_wr_reset_n),
        .i_wr(i_wr), .i_wr_data(i_wr_data), .o_wr_full(o_wr_full),
        .i_rclk(i_rclk), .i_rd_reset_n(i_rd_reset_n),
        .i_rd(i_rd), .o_rd_data(o_rd_data), .o_rd_empty(o_rd_empty)
    );

    always #5 i_wclk = ~i_wclk;
    always #8 i_rclk = ~i_rclk;

    task cdc_fail;
        input [8*80-1:0] rule_id;
        input [8*80-1:0] details;
        begin
            $display("CDC/RESET VIOLATION [%0s]: %0s at %0t",
                     rule_id, details, $time);
            errors = errors + 1;
        end
    endtask

    task protocol_fail;
        input [8*80-1:0] rule_id;
        input [8*80-1:0] details;
        begin
            $display("PROTOCOL VIOLATION [%0s]: %0s at %0t",
                     rule_id, details, $time);
            errors = errors + 1;
        end
    endtask

    task reset_both_skewed;
        begin
            @(negedge i_wclk);
            i_wr = 0;
            i_wr_reset_n = 0;
            repeat (2) @(negedge i_rclk);
            i_rd = 0;
            i_rd_reset_n = 0;
            repeat (4) @(posedge i_wclk);
            i_wr_reset_n = 1;
            repeat (3) @(posedge i_rclk);
            i_rd_reset_n = 1;
            repeat (5) @(posedge i_rclk);
        end
    endtask

    task write_one;
        input [WIDTH-1:0] value;
        integer guard;
        begin
            guard = 0;
            @(negedge i_wclk);
            while (o_wr_full && guard < 80) begin
                guard = guard + 1;
                @(negedge i_wclk);
            end
            if (guard == 80)
                cdc_fail("FIFO_WRITE_TIMEOUT", "write-side bounded wait TIMEOUT");
            else begin
                i_wr_data = value;
                i_wr = 1;
                @(posedge i_wclk);
                #1;
                writes = writes + 1;
                @(negedge i_wclk);
                i_wr = 0;
            end
        end
    endtask

    task read_one;
        integer guard;
        reg [WIDTH-1:0] accepted_data;
        begin
            guard = 0;
            @(negedge i_rclk);
            while (o_rd_empty && guard < 120) begin
                guard = guard + 1;
                @(negedge i_rclk);
            end
            if (guard == 120)
                cdc_fail("FIFO_READ_TIMEOUT", "read-side bounded wait TIMEOUT");
            else begin
                /*
                 * Registered-read mode presents the current head before the
                 * pop edge.  Save that accepted beat before the edge so the
                 * scoreboard is independent of post-pop prefetch timing.
                 */
                accepted_data = o_rd_data;
                i_rd = 1;
                @(posedge i_rclk);
                #1;
                if ((^accepted_data) === 1'bx)
                    cdc_fail("FIFO_X_OUTPUT", "read payload contains unknown bits");
                else if (accepted_data !== expected[reads]) begin
                    $display("CDC/RESET VIOLATION [FIFO_DATA_ORDER]: index=%0d got=%h expected=%h",
                             reads, accepted_data, expected[reads]);
                    errors = errors + 1;
                end
                reads = reads + 1;
                @(negedge i_rclk);
                i_rd = 0;
            end
        end
    endtask

    always @(posedge i_wclk) begin
        if (!i_wr_reset_n) begin
            #1;
            if (o_wr_full !== 1'b0)
                cdc_fail("FIFO_RESET_SAFETY", "write-full flag asserted during reset");
        end else begin
            if ((^o_wr_full) === 1'bx)
                cdc_fail("FIFO_X_STATUS", "write-full flag is unknown");
            if (i_wr && o_wr_full)
                cdc_fail("FIFO_OVERFLOW", "write was attempted while the FIFO was full");
        end
    end

    always @(posedge i_rclk) begin
        if (!i_rd_reset_n) begin
            #1;
            if (o_rd_empty !== 1'b1)
                cdc_fail("FIFO_RESET_SAFETY", "read-empty flag deasserted during reset");
        end else begin
            if ((^o_rd_empty) === 1'bx)
                cdc_fail("FIFO_X_STATUS", "read-empty flag is unknown");
            if (i_rd && o_rd_empty)
                cdc_fail("FIFO_UNDERFLOW", "read was attempted while the FIFO was empty");
        end
    end

    initial begin
        i_wclk = 0;
        i_rclk = 0;
        i_wr_reset_n = 0;
        i_rd_reset_n = 0;
        i_wr = 0;
        i_rd = 0;
        i_wr_data = 0;
        errors = 0;
        writes = 0;
        reads = 0;

        repeat (4) @(posedge i_wclk);
        i_wr_reset_n = 1;
        repeat (3) @(posedge i_rclk);
        i_rd_reset_n = 1;

        /* Exercise traffic, then assert the two resets at different times. */
        for (i = 0; i < 5; i = i + 1)
            write_one(8'hc0 + i);
        reset_both_skewed;

        writes = 0;
        reads = 0;
        for (i = 0; i < COUNT; i = i + 1)
            expected[i] = (i * 8'h25) ^ 8'h9b;

        fork
            begin
                for (i = 0; i < COUNT; i = i + 1) begin
                    write_one(expected[i]);
                    if ((i % 7) == 3)
                        repeat (2) @(posedge i_wclk);
                end
            end
            begin
                repeat (6) @(posedge i_rclk);
                while (reads < COUNT) begin
                    if ((reads % 5) == 2)
                        repeat (3) @(posedge i_rclk);
                    read_one;
                end
            end
        join

        if (writes != COUNT || reads != COUNT)
            cdc_fail("FIFO_COHERENCY", "accepted and delivered transaction counts differ");
        if (errors == 0)
            $display("AFIFO ENHANCED: ALL TESTS PASSED");
        else
            $display("AFIFO ENHANCED: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #200000;
        $display("FIFO TEST TIMEOUT: afifo global watchdog expired");
        $finish;
    end
endmodule
