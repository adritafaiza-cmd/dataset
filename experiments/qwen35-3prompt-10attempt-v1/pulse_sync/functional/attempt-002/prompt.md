Please act as a professional Verilog designer.

Implement a one-pulse-in, one-pulse-out crossing between asynchronous clocks.

Module name:
    pulse_sync

Language:
    Verilog-2001

Clocks:
    clk_a: Independent asynchronous clock (async to clk_b).
    clk_b: Independent asynchronous clock (async to clk_a).

Resets:
    rstn_a: active-low.
    rstn_b: active-low.

Input ports:
    clk_a: Clock.
    rstn_a: Active-low reset.
    clk_b: Clock.
    rstn_b: Active-low reset.
    pulseA_i: See Behavior.

Output ports:
    pulseB_o: See Behavior.
    busy_o: See Behavior.

Parameters:
    STAGES: Implementation depth parameter. Choose a safe crossing yourself.

Behavior:
    - A one-cycle pulse on pulseA_i in domain A must produce one pulse on pulseB_o in domain B.
    - busy_o is high while a pulse is in flight; ignore additional pulseA_i while busy.
    - After reset, pulseB_o and busy_o are low.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module pulse_sync #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  pulseA_i,
    output pulseB_o,
    output busy_o
);
