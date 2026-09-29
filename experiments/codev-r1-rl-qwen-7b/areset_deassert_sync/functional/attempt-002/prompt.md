Please act as a professional Verilog designer.

Implement a destination-clock reset-release synchronizer.

Module name:
    areset_deassert_sync

Language:
    Verilog-2001

Clocks:
    clk: Single clock.

Resets:
    async_rst_i: reset.

Input ports:
    clk: Clock.
    async_rst_i: Reset reset.

Output ports:
    sync_rst_o: Reset reset.

Parameters:
    CHAINS: Implementation depth parameter. Choose a safe crossing yourself.
    RST_POL: 1 means async_rst_i is active-high.

Behavior:
    - sync_rst_o must follow assertion of async_rst_i immediately.
    - sync_rst_o may release only after clk has observed a safe deassert.
    - CHAINS is the release-pipeline depth. RST_POL is 1 for active-high async_rst_i.
    - After a completed release, sync_rst_o is inactive.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);
