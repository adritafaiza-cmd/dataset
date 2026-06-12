// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Description: This module is a reset synchronizer with a dedicated reset bypass pin for testmode reset.
// Pro Tip: The wise Dr. Schaffner recommends at least 4 registers!

module rstgen_bypass #(
    parameter NumRegs = 4
) (
    input  clk_i,
    input  rst_ni,
    input  rst_test_mode_ni,
    input  test_mode_i,
    output rst_no,
    output init_no
);

    wire rst_n;
    wire rst_no_mux;
    wire init_no_mux;

    reg [NumRegs-1:0] synch_regs_q;

    assign rst_no  = rst_no_mux;
    assign init_no = init_no_mux;

    tc_clk_mux2 i_tc_clk_mux2_rst_n (
        .clk0_i    (rst_ni),
        .clk1_i    (rst_test_mode_ni),
        .clk_sel_i (test_mode_i),
        .clk_o     (rst_n)
    );

    tc_clk_mux2 i_tc_clk_mux2_rst_no (
        .clk0_i    (synch_regs_q[NumRegs-1]),
        .clk1_i    (rst_test_mode_ni),
        .clk_sel_i (test_mode_i),
        .clk_o     (rst_no_mux)
    );

    tc_clk_mux2 i_tc_clk_mux2_init_no (
        .clk0_i    (synch_regs_q[NumRegs-1]),
        .clk1_i    (1'b1),
        .clk_sel_i (test_mode_i),
        .clk_o     (init_no_mux)
    );

    always @(posedge clk_i or negedge rst_n) begin
        if (!rst_n)
            synch_regs_q <= {NumRegs{1'b0}};
        else
            synch_regs_q <= {synch_regs_q[NumRegs-2:0], 1'b1};
    end

endmodule