`timescale 1ns/1ps

module afifo_tb;
    integer errors = 0;
    integer received = 0;

    reg i_wclk = 0, i_rclk = 0, i_wr_reset_n = 0, i_rd_reset_n = 0;
    always #5 i_wclk = ~i_wclk;
    always #9 i_rclk = ~i_rclk;

    reg i_wr = 0, i_rd = 0;
    reg [7:0] i_wr_data = 0;
    wire o_wr_full, o_rd_empty;
    wire [7:0] o_rd_data;

    afifo #(.LGFIFO(3), .WIDTH(8), .NFF(2), .OPT_REGISTER_READS(1'b1)) dut (
        .i_wclk(i_wclk), .i_wr_reset_n(i_wr_reset_n), .i_wr(i_wr),
        .i_wr_data(i_wr_data), .o_wr_full(o_wr_full),
        .i_rclk(i_rclk), .i_rd_reset_n(i_rd_reset_n), .i_rd(i_rd),
        .o_rd_data(o_rd_data), .o_rd_empty(o_rd_empty)
    );

    integer i;
    initial begin
        repeat (4) @(posedge i_wclk); i_wr_reset_n = 1;
        repeat (4) @(posedge i_rclk); i_rd_reset_n = 1;
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge i_wclk);
            while (o_wr_full) @(negedge i_wclk);
            i_wr_data = i[7:0];
            i_wr = 1;
            @(posedge i_wclk);
            @(negedge i_wclk);
            i_wr = 0;
        end
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge i_rclk);
            while (o_rd_empty) @(negedge i_rclk);
            i_rd = 1;
            @(posedge i_rclk);
            if (o_rd_data !== i[7:0]) begin
                $display("FAIL afifo item=%0d got=%h", i, o_rd_data);
                errors = errors + 1;
            end
            received = received + 1;
            @(negedge i_rclk);
            i_rd = 0;
        end
        if (errors == 0)
            $display("AFIFO: ALL TESTS PASSED");
        else
            $display("AFIFO: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #80000;
        $display("AFIFO: TIMEOUT");
        $finish;
    end
endmodule
