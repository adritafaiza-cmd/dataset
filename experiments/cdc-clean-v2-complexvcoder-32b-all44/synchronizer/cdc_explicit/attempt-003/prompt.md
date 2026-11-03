Please act as a professional Verilog designer.

Implement a single-bit destination-clock synchronizer.

Module name:
    synchronizer

Language:
    Verilog-2001

Clocks:
    clk: Single clock.

Resets:
    rstn: active-low.

Input ports:
    clk: Clock.
    rstn: Active-low reset.
    async_sig_i: See Behavior.

Output ports:
    sync_sig_o: See Behavior.

Parameters:
    STAGES: Implementation depth parameter. Choose a safe crossing yourself.

Behavior:
    - async_sig_i is an asynchronous single-bit input. sync_sig_o is the synchronized bit.
    - STAGES is the pipeline depth.
    - After reset, sync_sig_o is low.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);
