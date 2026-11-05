`timescale 1ns/1ps

module async_bidir_fifo_enhanced_tb;
    parameter DSIZE = 8;
    parameter ASIZE = 4;
    parameter COUNT = 36;

    reg a_clk, b_clk, a_rst_n, b_rst_n;
    reg a_winc, a_rinc, a_dir, b_winc, b_rinc, b_dir;
    reg [DSIZE-1:0] a_wdata, b_wdata;
    wire [DSIZE-1:0] a_rdata, b_rdata;
    wire a_full, a_afull, a_empty, a_aempty;
    wire b_full, b_afull, b_empty, b_aempty;
    reg [DSIZE-1:0] expected [0:COUNT-1];
    integer errors, writes, reads, i;

    async_bidir_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE),
                       .FALLTHROUGH("TRUE")) dut (
        .a_clk(a_clk), .a_rst_n(a_rst_n), .a_winc(a_winc),
        .a_wdata(a_wdata), .a_rinc(a_rinc), .a_rdata(a_rdata),
        .a_full(a_full), .a_afull(a_afull), .a_empty(a_empty),
        .a_aempty(a_aempty), .a_dir(a_dir),
        .b_clk(b_clk), .b_rst_n(b_rst_n), .b_winc(b_winc),
        .b_wdata(b_wdata), .b_rinc(b_rinc), .b_rdata(b_rdata),
        .b_full(b_full), .b_afull(b_afull), .b_empty(b_empty),
        .b_aempty(b_aempty), .b_dir(b_dir)
    );

    always #5 a_clk = ~a_clk;
    always #8 b_clk = ~b_clk;

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

    task reset_skewed;
        begin
            @(negedge a_clk);
            a_winc = 0;
            a_rinc = 0;
            a_rst_n = 0;
            repeat (2) @(negedge b_clk);
            b_winc = 0;
            b_rinc = 0;
            b_rst_n = 0;
            repeat (4) @(posedge b_clk);
            b_rst_n = 1;
            repeat (3) @(posedge a_clk);
            a_rst_n = 1;
            repeat (6) @(posedge b_clk);
        end
    endtask

    task a_put;
        input [DSIZE-1:0] value;
        integer n;
        begin
            n = 0;
            @(negedge a_clk);
            while (a_full && n < 100) begin
                n = n + 1;
                @(negedge a_clk);
            end
            if (n == 100)
                cdc_fail("FIFO_WRITE_TIMEOUT", "A-side bounded write wait TIMEOUT");
            else begin
                a_wdata = value;
                a_winc = 1;
                @(posedge a_clk);
                writes = writes + 1;
                @(negedge a_clk);
                a_winc = 0;
            end
        end
    endtask

    task b_get;
        integer n;
        begin
            n = 0;
            @(negedge b_clk);
            while (b_empty && n < 140) begin
                n = n + 1;
                @(negedge b_clk);
            end
            if (n == 140)
                cdc_fail("FIFO_READ_TIMEOUT", "B-side bounded read wait TIMEOUT");
            else begin
                if ((^b_rdata) === 1'bx)
                    cdc_fail("FIFO_X_OUTPUT", "B-side read payload contains unknown bits");
                else if (b_rdata !== expected[reads]) begin
                    $display("CDC/RESET VIOLATION [FIFO_DATA_ORDER]: direction=A-to-B index=%0d got=%h expected=%h",
                             reads, b_rdata, expected[reads]);
                    errors = errors + 1;
                end
                b_rinc = 1;
                @(posedge b_clk);
                reads = reads + 1;
                @(negedge b_clk);
                b_rinc = 0;
            end
        end
    endtask

    task b_put;
        input [DSIZE-1:0] value;
        integer n;
        begin
            n = 0;
            @(negedge b_clk);
            while (b_full && n < 100) begin
                n = n + 1;
                @(negedge b_clk);
            end
            if (n == 100)
                cdc_fail("FIFO_WRITE_TIMEOUT", "B-side bounded write wait TIMEOUT");
            else begin
                b_wdata = value;
                b_winc = 1;
                @(posedge b_clk);
                writes = writes + 1;
                @(negedge b_clk);
                b_winc = 0;
            end
        end
    endtask

    task a_get;
        integer n;
        begin
            n = 0;
            @(negedge a_clk);
            while (a_empty && n < 140) begin
                n = n + 1;
                @(negedge a_clk);
            end
            if (n == 140)
                cdc_fail("FIFO_READ_TIMEOUT", "A-side bounded read wait TIMEOUT");
            else begin
                if ((^a_rdata) === 1'bx)
                    cdc_fail("FIFO_X_OUTPUT", "A-side read payload contains unknown bits");
                else if (a_rdata !== expected[reads]) begin
                    $display("CDC/RESET VIOLATION [FIFO_DATA_ORDER]: direction=B-to-A index=%0d got=%h expected=%h",
                             reads, a_rdata, expected[reads]);
                    errors = errors + 1;
                end
                a_rinc = 1;
                @(posedge a_clk);
                reads = reads + 1;
                @(negedge a_clk);
                a_rinc = 0;
            end
        end
    endtask

    always @(posedge a_clk) begin
        if (!a_rst_n) begin
            #1;
            if (a_full !== 1'b0 || a_empty !== 1'b1)
                cdc_fail("FIFO_RESET_SAFETY", "A-side full/empty flags are not reset-safe");
        end else begin
            if ((^a_full) === 1'bx || (^a_empty) === 1'bx ||
                (^a_afull) === 1'bx || (^a_aempty) === 1'bx)
                cdc_fail("FIFO_X_STATUS", "A-side status contains unknown bits");
            if (a_dir && a_winc && a_full)
                cdc_fail("FIFO_OVERFLOW", "A-side write was attempted while full");
            if (!a_dir && a_rinc && a_empty)
                cdc_fail("FIFO_UNDERFLOW", "A-side read was attempted while empty");
        end
    end

    always @(posedge b_clk) begin
        if (!b_rst_n) begin
            #1;
            if (b_full !== 1'b0 || b_empty !== 1'b1)
                cdc_fail("FIFO_RESET_SAFETY", "B-side full/empty flags are not reset-safe");
        end else begin
            if ((^b_full) === 1'bx || (^b_empty) === 1'bx ||
                (^b_afull) === 1'bx || (^b_aempty) === 1'bx)
                cdc_fail("FIFO_X_STATUS", "B-side status contains unknown bits");
            if (b_dir && b_winc && b_full)
                cdc_fail("FIFO_OVERFLOW", "B-side write was attempted while full");
            if (!b_dir && b_rinc && b_empty)
                cdc_fail("FIFO_UNDERFLOW", "B-side read was attempted while empty");
        end
    end

    initial begin
        a_clk = 0;
        b_clk = 0;
        a_rst_n = 0;
        b_rst_n = 0;
        a_winc = 0;
        a_rinc = 0;
        b_winc = 0;
        b_rinc = 0;
        a_wdata = 0;
        b_wdata = 0;
        a_dir = 1;
        b_dir = 0;
        errors = 0;
        writes = 0;
        reads = 0;

        repeat (5) @(posedge a_clk);
        a_rst_n = 1;
        repeat (4) @(posedge b_clk);
        b_rst_n = 1;
        repeat (6) @(posedge b_clk);

        for (i = 0; i < 5; i = i + 1)
            a_put(8'hd0 + i);
        reset_skewed;

        writes = 0;
        reads = 0;
        for (i = 0; i < COUNT; i = i + 1)
            expected[i] = 8'h31 ^ (i * 8'h1d);
        fork
            begin
                for (i = 0; i < COUNT; i = i + 1)
                    a_put(expected[i]);
            end
            begin
                repeat (5) @(posedge b_clk);
                while (reads < COUNT) begin
                    if ((reads % 5) == 2)
                        repeat (2) @(posedge b_clk);
                    b_get;
                end
            end
        join
        if (writes != COUNT || reads != COUNT)
            cdc_fail("FIFO_COHERENCY", "A-to-B accepted and delivered transaction counts differ");

        reset_skewed;
        a_dir = 0;
        b_dir = 1;
        writes = 0;
        reads = 0;
        for (i = 0; i < COUNT; i = i + 1)
            expected[i] = 8'ha7 + (i * 8'h23);
        fork
            begin
                for (i = 0; i < COUNT; i = i + 1)
                    b_put(expected[i]);
            end
            begin
                repeat (5) @(posedge a_clk);
                while (reads < COUNT) begin
                    if ((reads % 6) == 1)
                        repeat (3) @(posedge a_clk);
                    a_get;
                end
            end
        join
        if (writes != COUNT || reads != COUNT)
            cdc_fail("FIFO_COHERENCY", "B-to-A accepted and delivered transaction counts differ");

        if (errors == 0)
            $display("ASYNC BIDIR FIFO ENHANCED: ALL TESTS PASSED");
        else
            $display("ASYNC BIDIR FIFO ENHANCED: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #350000;
        $display("FIFO TEST TIMEOUT: async_bidir_fifo global watchdog expired");
        $finish;
    end
endmodule
