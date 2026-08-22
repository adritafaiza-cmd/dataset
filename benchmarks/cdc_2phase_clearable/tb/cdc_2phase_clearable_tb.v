`timescale 1ns/1ps

module cdc_2phase_clearable_tb;
    reg src_clk = 0, dst_clk = 0;
    reg src_rst_n = 0, dst_rst_n = 0;
    always #5 src_clk = ~src_clk;
    always #7 dst_clk = ~dst_clk;

    reg src_clear = 0, dst_clear = 0;
    wire src_clear_pending, dst_clear_pending;
    reg [7:0] src_data = 0;
    reg src_valid = 0;
    wire src_ready;
    wire [7:0] dst_data;
    wire dst_valid;
    reg dst_ready = 0;

    integer received = 0;
    integer errors = 0;

    cdc_2phase_clearable #(
        .WIDTH(8),
        .SYNC_STAGES(3),
        .CLEAR_ON_ASYNC_RESET(1)
    ) dut (
        .src_rst_ni(src_rst_n),
        .src_clk_i(src_clk),
        .src_clear_i(src_clear),
        .src_clear_pending_o(src_clear_pending),
        .src_data_i(src_data),
        .src_valid_i(src_valid),
        .src_ready_o(src_ready),
        .dst_rst_ni(dst_rst_n),
        .dst_clk_i(dst_clk),
        .dst_clear_i(dst_clear),
        .dst_clear_pending_o(dst_clear_pending),
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
            if (dst_data !== 8'h20 + received) begin
                $display("FAIL clearable item=%0d actual=%h expected=%h",
                    received, dst_data, 8'h20 + received);
                errors = errors + 1;
            end
            received = received + 1;
        end
    end

    initial begin
        repeat (5) @(posedge src_clk);
        @(negedge src_clk); src_rst_n = 1;
        repeat (5) @(posedge dst_clk);
        @(negedge dst_clk); dst_rst_n = 1; dst_ready = 1;

        // Wait for local reset release and the controller's startup clear.
        repeat (4) @(posedge src_clk);
        repeat (4) @(posedge dst_clk);
        wait (src_clear_pending || dst_clear_pending);
        wait (!src_clear_pending && !dst_clear_pending);
        send(8'h20);
        send(8'h21);
        wait (received == 2);

        @(negedge src_clk); src_clear = 1;
        @(negedge src_clk); src_clear = 0;
        wait (src_clear_pending);
        wait (!src_clear_pending && !dst_clear_pending);

        send(8'h22);
        send(8'h23);
        wait (received == 4);

        repeat (3) @(posedge dst_clk);
        if (errors == 0)
            $display("CDC 2PHASE CLEARABLE: ALL TESTS PASSED");
        else
            $display("CDC 2PHASE CLEARABLE: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #100000;
        $display("CDC 2PHASE CLEARABLE: TIMEOUT");
        $finish;
    end
endmodule
