// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Antonio Pullini <pullinia@iis.ee.ethz.ch>

module sync_wedge #(
    parameter STAGES = 2
) (
    input clk_i,
    input rst_ni,
    input en_i,
    input serial_i,
    output r_edge_o,
    output f_edge_o,
    output serial_o
);

    wire clk;
    wire serial;
    reg  serial_q;

    assign serial_o = serial_q;
    assign f_edge_o = (~serial) & serial_q;
    assign r_edge_o = serial & (~serial_q);

    sync #(
        .STAGES(STAGES)
    ) i_sync (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .serial_i(serial_i),
        .serial_o(serial)
    );

    pulp_clock_gating i_pulp_clock_gating (
        .clk_i(clk_i),
        .en_i(en_i),
        .test_en_i(1'b0),
        .clk_o(clk)
    );

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni)
            serial_q <= 1'b0;
        else if (en_i)
            serial_q <= serial;
    end

endmodule