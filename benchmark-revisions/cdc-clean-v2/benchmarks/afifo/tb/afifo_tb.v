`timescale 1ns/1ps
// Public contract for the default configuration:
// LGFIFO=3, WIDTH=8, registered reads, posedge writes.
// Storage accepts 8 words before any read. Empty can rise between words.

module afifo_tb;
    integer errors = 0;
    integer received = 0;
    integer i;
    integer guard;

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

    always @(posedge i_wclk) begin
        if (!i_wr_reset_n && o_wr_full) begin
            $display("FAIL: o_wr_full high during write reset");
            errors = errors + 1;
        end
    end

    always @(posedge i_rclk) begin
        if (!i_rd_reset_n && !o_rd_empty) begin
            $display("FAIL: o_rd_empty low during read reset");
            errors = errors + 1;
        end
    end

    initial begin
        repeat (4) @(posedge i_wclk);
        i_wr_reset_n = 1;
        repeat (4) @(posedge i_rclk);
        i_rd_reset_n = 1;

        // A read while empty must not create a word.
        @(negedge i_rclk);
        i_rd = 1;
        repeat (3) @(posedge i_rclk);
        @(negedge i_rclk);
        i_rd = 0;

        for (i = 0; i < 8; i = i + 1) begin
            @(negedge i_wclk);
            guard = 0;
            while (o_wr_full) begin
                @(negedge i_wclk);
                guard = guard + 1;
                if (guard > 20) begin
                    $display("FAIL: full while fewer than 8 writes accepted");
                    errors = errors + 1;
                    $finish;
                end
            end
            i_wr_data = i[7:0];
            i_wr = 1;
            @(posedge i_wclk);
            @(negedge i_wclk);
            i_wr = 0;
        end

        @(negedge i_wclk);
        if (o_wr_full !== 1'b1) begin
            $display("FAIL: o_wr_full low after 8 writes with no read");
            errors = errors + 1;
        end
        i_wr_data = 8'hA5;
        i_wr = 1;
        @(posedge i_wclk);
        @(negedge i_wclk);
        i_wr = 0;

        for (i = 0; i < 8; i = i + 1) begin
            @(negedge i_rclk);
            guard = 0;
            while (o_rd_empty) begin
                @(negedge i_rclk);
                guard = guard + 1;
                if (guard > 80) begin
                    $display("FAIL: timeout waiting for word %0d", i);
                    errors = errors + 1;
                    $finish;
                end
            end
            if (errors == 0) begin
                i_rd = 1;
                @(posedge i_rclk);
                if (o_rd_data !== i[7:0]) begin
                    $display("FAIL: item=%0d got=%h", i, o_rd_data);
                    errors = errors + 1;
                end
                received = received + 1;
                @(negedge i_rclk);
                i_rd = 0;
            end
        end

        // No ninth word from the rejected write.
        repeat (30) begin
            @(posedge i_rclk);
            if (!o_rd_empty) begin
                $display("FAIL: extra word visible after 8 reads, data=%h", o_rd_data);
                errors = errors + 1;
            end
        end

        if (received != 8) begin
            $display("FAIL: received %0d words", received);
            errors = errors + 1;
        end
        if (errors == 0)
            $display("AFIFO: ALL TESTS PASSED");
        else
            $display("AFIFO: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #200000;
        $display("AFIFO: TIMEOUT");
        $finish;
    end
endmodule
