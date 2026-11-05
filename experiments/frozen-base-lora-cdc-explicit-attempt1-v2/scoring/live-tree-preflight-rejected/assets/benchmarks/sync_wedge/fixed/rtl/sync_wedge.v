// Copyright 2018 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 rewrite of sync_wedge. Clock-gate replaced by an enable flop.

module sync_wedge #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  en_i,
    input  serial_i,
    output r_edge_o,
    output f_edge_o,
    output serial_o
);

    wire serial;

    sync #(.STAGES(STAGES)) i_sync (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .serial_i(serial_i),
        .serial_o(serial)
    );

    reg serial_q;
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            serial_q <= 1'b0;
        else if (en_i)
            serial_q <= serial;
    end

    assign serial_o = serial_q;
    assign r_edge_o = serial & ~serial_q;
    assign f_edge_o = ~serial & serial_q;

endmodule
