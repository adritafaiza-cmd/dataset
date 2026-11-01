Please act as a professional Verilog designer.

Implement a destination-clock reset-release synchronizer.

Module name:
    areset_sync

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
    STAGES: Implementation depth parameter. Choose a safe crossing yourself.

Behavior:
    - sync_rst_o asserts with async_rst_i and deasserts only in clk.
    - STAGES is the release-pipeline depth.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);
