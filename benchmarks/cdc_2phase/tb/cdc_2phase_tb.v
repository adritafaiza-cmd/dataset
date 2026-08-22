`timescale 1ns/1ps

module cdc_2phase_tb;
    reg src_clk = 0, dst_clk = 0;
    reg src_rst_n = 0, dst_rst_n = 0;
    always #5 src_clk = ~src_clk;
    always #7 dst_clk = ~dst_clk;

    reg [7:0] src_data = 0;
    reg src_valid = 0;
    wire src_ready;
    wire [7:0] dst_data;
    wire dst_valid;
    reg dst_ready = 0;

    integer received = 0;
    integer errors = 0;

    cdc_2phase #(.WIDTH(8)) dut (
        .src_rst_ni(src_rst_n),
        .src_clk_i(src_clk),
        .src_data_i(src_data),
        .src_valid_i(src_valid),
        .src_ready_o(src_ready),
        .dst_rst_ni(dst_rst_n),
        .dst_clk_i(dst_clk),
        .dst_data_o(dst_data),
        .dst_valid_o(dst_valid),
        .dst_ready_i(dst_ready)
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
            if (dst_data !== 8'h40 + received) begin
                $display("FAIL cdc_2phase item=%0d actual=%h expected=%h",
                    received, dst_data, 8'h40 + received);
                errors = errors + 1;
            end
            received = received + 1;
        end
    end

    integer i;
    initial begin
        repeat (5) @(posedge src_clk);
        @(negedge src_clk); src_rst_n = 1;
        repeat (5) @(posedge dst_clk);
        @(negedge dst_clk); dst_rst_n = 1; dst_ready = 1;
        // Allow both local two-stage reset synchronizers to release.
        repeat (4) @(posedge src_clk);
        repeat (4) @(posedge dst_clk);

        for (i = 0; i < 8; i = i + 1)
            send(8'h40 + i);

        wait (received == 8);
        repeat (3) @(posedge dst_clk);
        if (errors == 0)
            $display("CDC 2PHASE: ALL TESTS PASSED");
        else
            $display("CDC 2PHASE: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("CDC 2PHASE: TIMEOUT");
        $finish;
    end
endmodule
