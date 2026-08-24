// Copyright 2018 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.

module sync #(
    parameter STAGES = 2,
    parameter ResetValue = 1'b0
)(
    input  clk_i,
    input  rst_ni,
    input  serial_i,
    output serial_o
);

    (* dont_touch = "true" *)
    (* ASYNC_REG = "TRUE" *)
    reg [STAGES-1:0] reg_q;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            reg_q <= {STAGES{ResetValue}};
        else
            reg_q <= {reg_q[STAGES-2:0], serial_i};
    end

    assign serial_o = reg_q[STAGES-1];

endmodule
