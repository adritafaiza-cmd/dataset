`timescale 1ns/1ps

module async_fifo_enhanced_tb;
    parameter DSIZE = 32;
    parameter ASIZE = 4;
    parameter COUNT = 64;

    reg wclk, rclk, wrst_n, rrst_n, winc, rinc;
    reg [DSIZE-1:0] wdata;
    wire [DSIZE-1:0] rdata;
    wire wfull, awfull, rempty, arempty;
    reg [DSIZE-1:0] expected [0:COUNT-1];
    integer errors, writes, reads, wi, guard;

    async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH("TRUE")) dut (
        .wclk(wclk), .wrst_n(wrst_n), .winc(winc), .wdata(wdata),
        .wfull(wfull), .awfull(awfull), .rclk(rclk), .rrst_n(rrst_n),
        .rinc(rinc), .rdata(rdata), .rempty(rempty), .arempty(arempty)
    );

    always #4 wclk = ~wclk;
    always #7 rclk = ~rclk;

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

    task coordinated_reset;
        begin
            @(negedge wclk);
            winc = 0;
            wrst_n = 0;
            repeat (2) @(negedge rclk);
            rinc = 0;
            rrst_n = 0;
            repeat (4) @(posedge rclk);
            rrst_n = 1;
            repeat (3) @(posedge wclk);
            wrst_n = 1;
            repeat (5) @(posedge rclk);
        end
    endtask

    task put;
        input [DSIZE-1:0] value;
        integer n;
        begin
            n = 0;
            @(negedge wclk);
            while (wfull && n < 100) begin
                n = n + 1;
                @(negedge wclk);
            end
            if (n == 100)
                cdc_fail("FIFO_WRITE_TIMEOUT", "write-side bounded wait TIMEOUT");
            else begin
                wdata = value;
                winc = 1;
                @(posedge wclk);
                writes = writes + 1;
                @(negedge wclk);
                winc = 0;
            end
        end
    endtask

    task get;
        integer n;
        begin
            n = 0;
            @(negedge rclk);
            while (rempty && n < 140) begin
                n = n + 1;
                @(negedge rclk);
            end
            if (n == 140)
                cdc_fail("FIFO_READ_TIMEOUT", "read-side bounded wait TIMEOUT");
            else begin
                /* FALLTHROUGH data is valid before the consuming edge. */
                if ((^rdata) === 1'bx)
                    cdc_fail("FIFO_X_OUTPUT", "read payload contains unknown bits");
                else if (rdata !== expected[reads]) begin
                    $display("CDC/RESET VIOLATION [FIFO_DATA_ORDER]: index=%0d got=%h expected=%h",
                             reads, rdata, expected[reads]);
                    errors = errors + 1;
                end
                rinc = 1;
                @(posedge rclk);
                reads = reads + 1;
                @(negedge rclk);
                rinc = 0;
            end
        end
    endtask

    always @(posedge wclk) begin
        if (!wrst_n) begin
            #1;
            if (wfull !== 1'b0)
                cdc_fail("FIFO_RESET_SAFETY", "write-full flag asserted during reset");
        end else begin
            if ((^wfull) === 1'bx || (^awfull) === 1'bx)
                cdc_fail("FIFO_X_STATUS", "write-domain fullness status contains unknown bits");
            if (winc && wfull)
                cdc_fail("FIFO_OVERFLOW", "write was attempted while the FIFO was full");
        end
    end

    always @(posedge rclk) begin
        if (!rrst_n) begin
            #1;
            if (rempty !== 1'b1)
                cdc_fail("FIFO_RESET_SAFETY", "read-empty flag deasserted during reset");
        end else begin
            if ((^rempty) === 1'bx || (^arempty) === 1'bx)
                cdc_fail("FIFO_X_STATUS", "read-domain emptiness status contains unknown bits");
            if (rinc && rempty)
                cdc_fail("FIFO_UNDERFLOW", "read was attempted while the FIFO was empty");
        end
    end

    initial begin
        wclk = 0;
        rclk = 0;
        wrst_n = 0;
        rrst_n = 0;
        winc = 0;
        rinc = 0;
        wdata = 0;
        errors = 0;
        writes = 0;
        reads = 0;

        repeat (5) @(posedge wclk);
        wrst_n = 1;
        repeat (4) @(posedge rclk);
        rrst_n = 1;
        repeat (5) @(posedge rclk);

        /* Mid-traffic skewed assertion; contents are intentionally discarded. */
        for (wi = 0; wi < 7; wi = wi + 1)
            put(32'hde000000 + wi);
        coordinated_reset;

        writes = 0;
        reads = 0;
        for (wi = 0; wi < COUNT; wi = wi + 1)
            expected[wi] = 32'h51000000 ^ (wi * 32'h00010203);

        fork
            begin
                for (wi = 0; wi < COUNT; wi = wi + 1) begin
                    put(expected[wi]);
                    if ((wi % 9) == 4)
                        repeat (2) @(posedge wclk);
                end
            end
            begin
                repeat (7) @(posedge rclk);
                while (reads < COUNT) begin
                    if ((reads % 6) == 1)
                        repeat (2) @(posedge rclk);
                    get;
                end
            end
        join

        if (writes != COUNT || reads != COUNT)
            cdc_fail("FIFO_COHERENCY", "accepted and delivered transaction counts differ");
        if (errors == 0)
            $display("ASYNC FIFO ENHANCED: ALL TESTS PASSED");
        else
            $display("ASYNC FIFO ENHANCED: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #250000;
        $display("FIFO TEST TIMEOUT: async_fifo global watchdog expired");
        $finish;
    end
endmodule
