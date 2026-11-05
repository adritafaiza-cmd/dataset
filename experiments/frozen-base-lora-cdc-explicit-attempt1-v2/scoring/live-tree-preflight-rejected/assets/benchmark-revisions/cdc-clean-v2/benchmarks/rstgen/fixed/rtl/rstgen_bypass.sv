// Copyright 2018 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// RDC-safe reset synchronizer. The test-mode bypass mux is removed from the
// reset path so test_mode_i cannot glitch rst_no / init_no.

module rstgen_bypass #(
    parameter int unsigned NumRegs = 4
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic rst_test_mode_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic [NumRegs-1:0] synch_regs_q;
    logic test_mode_q;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            synch_regs_q <= '0;
        else
            synch_regs_q <= {synch_regs_q[NumRegs-2:0], 1'b1};
    end

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            test_mode_q <= 1'b0;
        else
            test_mode_q <= test_mode_i;
    end

    assign rst_no  = synch_regs_q[NumRegs-1];
    assign init_no = synch_regs_q[NumRegs-1];

    // Keep unused ports in the netlist so the interface stays compatible.
    wire unused_test = test_mode_q ^ rst_test_mode_ni;

endmodule
