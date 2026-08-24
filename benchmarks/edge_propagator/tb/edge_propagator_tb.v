`timescale 1ns/1ps

module edge_propagator_tb;
    integer errors = 0;

    reg clk_tx_i = 0, clk_rx_i = 0;
    reg rstn_tx_i = 0, rstn_rx_i = 0, edge_i = 0;
    wire edge_o;
    integer seen = 0;
    always #5 clk_tx_i = ~clk_tx_i;
    always #7 clk_rx_i = ~clk_rx_i;

    edge_propagator dut (
        .clk_tx_i(clk_tx_i), .rstn_tx_i(rstn_tx_i), .edge_i(edge_i),
        .clk_rx_i(clk_rx_i), .rstn_rx_i(rstn_rx_i), .edge_o(edge_o)
    );

    always @(posedge clk_rx_i) if (rstn_rx_i && edge_o) seen = seen + 1;

    initial begin
        repeat (4) @(posedge clk_tx_i);
        rstn_tx_i = 1;
        repeat (4) @(posedge clk_rx_i);
        rstn_rx_i = 1;
        @(negedge clk_tx_i); edge_i = 1;
        @(negedge clk_tx_i); edge_i = 0;
        repeat (20) @(posedge clk_rx_i);
        if (seen == 0) begin
            $display("FAIL no pulse crossed");
            errors = errors + 1;
        end
        if (errors == 0) $display("EDGE PROPAGATOR: ALL TESTS PASSED");
        else $display("EDGE PROPAGATOR: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("EDGE_PROPAGATOR_TB: TIMEOUT");
        $finish;
    end
endmodule
