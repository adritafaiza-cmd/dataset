`timescale 1ns/1ps

module async_fifo_sv_enhanced_tb;
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    parameter COUNT = 52;

    reg wclk, rclk, wrst_n, rrst_n, winc, rinc;
    reg [DATA_WIDTH-1:0] wdata;
    wire [DATA_WIDTH-1:0] rdata;
    wire wfull, rempty;
    wire [ADDR_WIDTH:0] waddr, raddr;
    reg [DATA_WIDTH-1:0] expected [0:COUNT-1];
    integer errors, writes, reads, i;

    async_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) dut (
        .wclk(wclk), .wrst_n(wrst_n), .winc(winc), .wdata(wdata),
        .wfull(wfull), .waddr(waddr), .rclk(rclk), .rrst_n(rrst_n),
        .rinc(rinc), .rdata(rdata), .rempty(rempty), .raddr(raddr)
    );

    always #5 wclk = ~wclk;
    always #9 rclk = ~rclk;

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
            @(negedge rclk);
            rinc = 0;
            rrst_n = 0;
            repeat (2) @(negedge wclk);
            winc = 0;
            wrst_n = 0;
            repeat (4) @(posedge wclk);
            wrst_n = 1;
            repeat (3) @(posedge rclk);
            rrst_n = 1;
            repeat (5) @(posedge rclk);
        end
    endtask

    task put;
        input [DATA_WIDTH-1:0] value;
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
            if ((^wfull) === 1'bx || (^waddr) === 1'bx)
                cdc_fail("FIFO_GRAY_POINTER", "write-domain pointer or status contains unknown bits");
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
            if ((^rempty) === 1'bx || (^raddr) === 1'bx)
                cdc_fail("FIFO_GRAY_POINTER", "read-domain pointer or status contains unknown bits");
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
        for (i = 0; i < 6; i = i + 1)
            put(8'he0 + i);
        reset_skewed;

        writes = 0;
        reads = 0;
        for (i = 0; i < COUNT; i = i + 1)
            expected[i] = (i * 8'h39) + 8'h17;

        fork
            begin
                for (i = 0; i < COUNT; i = i + 1) begin
                    put(expected[i]);
                    if ((i % 8) == 5)
                        repeat (2) @(posedge wclk);
                end
            end
            begin
                repeat (6) @(posedge rclk);
                while (reads < COUNT) begin
                    if ((reads % 5) == 0)
                        repeat (2) @(posedge rclk);
                    get;
                end
            end
        join

        if (writes != COUNT || reads != COUNT)
            cdc_fail("FIFO_COHERENCY", "accepted and delivered transaction counts differ");
        if (errors == 0)
            $display("ASYNC FIFO SV ENHANCED: ALL TESTS PASSED");
        else
            $display("ASYNC FIFO SV ENHANCED: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #250000;
        $display("FIFO TEST TIMEOUT: async_fifo_sv global watchdog expired");
        $finish;
    end
endmodule
