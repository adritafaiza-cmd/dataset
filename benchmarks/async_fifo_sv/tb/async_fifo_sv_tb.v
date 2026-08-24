`timescale 1ns/1ps

module async_fifo_sv_tb;
    integer errors = 0;

    reg wclk = 0, rclk = 0, wrst_n = 0, rrst_n = 0, winc = 0, rinc = 0;
    reg [7:0] wdata = 0;
    wire [7:0] rdata;
    wire wfull, rempty;
    wire [4:0] waddr, raddr;
    integer received = 0;
    always #5 wclk = ~wclk;
    always #9 rclk = ~rclk;

    async_fifo #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) dut (
        .wclk(wclk), .wrst_n(wrst_n), .winc(winc), .wdata(wdata),
        .wfull(wfull), .waddr(waddr),
        .rclk(rclk), .rrst_n(rrst_n), .rinc(rinc), .rdata(rdata),
        .rempty(rempty), .raddr(raddr)
    );

    integer i;
    initial begin
        repeat (4) @(posedge wclk); wrst_n = 1;
        repeat (4) @(posedge rclk); rrst_n = 1;
        repeat (4) @(posedge wclk);
        repeat (4) @(posedge rclk);
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge wclk);
            while (wfull) @(negedge wclk);
            wdata = i[7:0];
            winc = 1;
            @(posedge wclk);
            @(negedge wclk);
            winc = 0;
        end
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge rclk);
            while (rempty) @(negedge rclk);
            rinc = 1;
            @(posedge rclk);
            if (rdata !== i[7:0]) begin
                $display("FAIL item=%0d got=%h", i, rdata);
                errors = errors + 1;
            end
            received = received + 1;
            @(negedge rclk);
            rinc = 0;
        end
        if (errors == 0) $display("ASYNC FIFO SV: ALL TESTS PASSED");
        else $display("ASYNC FIFO SV: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #40000;
        $display("ASYNC_FIFO_SV_TB: TIMEOUT");
        $finish;
    end
endmodule
