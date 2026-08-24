`timescale 1ns/1ps

module cdc_fifo_gray_clearable_tb;
    integer errors = 0;
    integer received = 0;

    reg src_clk = 0, dst_clk = 0, src_rst_n = 0, dst_rst_n = 0;
    always #5 src_clk = ~src_clk;
    always #7 dst_clk = ~dst_clk;

    reg [7:0] src_data = 0;
    reg src_valid = 0, src_clear = 0, dst_clear = 0;
    wire src_ready, src_pending, dst_pending;
    wire [7:0] dst_data;
    wire dst_valid;
    reg dst_ready = 0;

    cdc_fifo_gray_clearable #(.WIDTH(8), .LOG_DEPTH(3)) dut (
        .src_rst_ni(src_rst_n), .src_clk_i(src_clk),
        .src_clear_i(src_clear), .src_clear_pending_o(src_pending),
        .src_data_i(src_data), .src_valid_i(src_valid), .src_ready_o(src_ready),
        .dst_rst_ni(dst_rst_n), .dst_clk_i(dst_clk),
        .dst_clear_i(dst_clear), .dst_clear_pending_o(dst_pending),
        .dst_data_o(dst_data), .dst_valid_o(dst_valid), .dst_ready_i(dst_ready)
    );

    task send;
        input [7:0] value;
        begin
            @(negedge src_clk);
            while (!src_ready) @(negedge src_clk);
            src_data = value;
            src_valid = 1;
            @(posedge src_clk);
            @(negedge src_clk);
            src_valid = 0;
        end
    endtask

    always @(posedge dst_clk) begin
        if (dst_rst_n && dst_valid && dst_ready) begin
            if (dst_data !== (8'hA0 + received[7:0])) begin
                $display("FAIL clearable item=%0d actual=%h expected=%h",
                    received, dst_data, 8'hA0 + received[7:0]);
                errors = errors + 1;
            end
            received = received + 1;
        end
    end

    integer i;
    initial begin
        repeat (4) @(posedge src_clk); src_rst_n = 1;
        repeat (4) @(posedge dst_clk); dst_rst_n = 1; dst_ready = 1;
        repeat (6) @(posedge src_clk);
        repeat (6) @(posedge dst_clk);
        dst_ready = 0;
        send(8'h11);
        send(8'h22);
        @(negedge src_clk); src_clear = 1;
        @(negedge src_clk); src_clear = 0;
        wait (src_pending === 1'b1);
        wait (src_pending === 1'b0);
        wait (dst_pending === 1'b0);
        repeat (8) @(posedge src_clk);
        repeat (8) @(posedge dst_clk);
        dst_ready = 1;
        received = 0;
        for (i = 0; i < 4; i = i + 1)
            send(8'hA0 + i);
        wait (received == 4);
        if (errors == 0)
            $display("CDC FIFO GRAY CLEARABLE: ALL TESTS PASSED");
        else
            $display("CDC FIFO GRAY CLEARABLE: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #80000;
        $display("CDC FIFO GRAY CLEARABLE: TIMEOUT");
        $finish;
    end
endmodule
