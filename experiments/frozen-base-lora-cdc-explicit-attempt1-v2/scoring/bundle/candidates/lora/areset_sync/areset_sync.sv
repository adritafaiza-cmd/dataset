// =============================================================================
// Module: areset_sync
// =============================================================================
// Purpose:
//   Synchronizes the release of an asynchronous reset signal into the
//   destination clock domain.
//
// Description:
//   This module implements a reset synchronizer that ensures the reset
//   deassertion is synchronized to the destination clock domain. The reset
//   assertion is immediate (asynchronous), but the deassertion is
//   synchronized through a shift register of configurable depth.
//
//   The module uses a shift register approach where the reset signal is
//   propagated through multiple flip-flops. This ensures that the reset
//   release is properly synchronized and avoids metastability issues.
//
//   The reset is active-high. When async_rst_i is asserted, sync_rst_o
//   asserts immediately. When async_rst_i is deasserted, sync_rst_o
//   deasserts after STAGES clock cycles.
//
// Parameters:
//   STAGES: Number of synchronization stages (default: 2)
//
// Ports:
//   clk:         Clock input
//   async_rst_i: Asynchronous reset input (active-high)
//   sync_rst_o:  Synchronized reset output (active-high)
// =============================================================================

`include "areset_sync_defines.v"

module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    (* ASYNC_REG = "TRUE" *)
    reg [STAGES-1:0] rst_sync_r;

    initial begin
        rst_sync_r = {STAGES{1'b1}};
    end

    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i)
            rst_sync_r <= {STAGES{1'b1}};
        else
            rst_sync_r <= {rst_sync_r[STAGES-2:0], 1'b0};
    end

    assign sync_rst_o = rst_sync_r[STAGES-1];

endmodule