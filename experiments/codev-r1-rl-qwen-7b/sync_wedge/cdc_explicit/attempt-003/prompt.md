Please act as a professional Verilog designer.

Implement a destination-clock bit synchronizer with edge detect.

Module name:
    sync_wedge

Language:
    Verilog-2001

Clocks:
    clk_i: Single clock.

Resets:
    rst_ni: active-low.

Input ports:
    clk_i: Clock.
    rst_ni: Active-low reset.
    en_i: See Behavior.
    serial_i: See Behavior.

Output ports:
    r_edge_o: See Behavior.
    f_edge_o: See Behavior.
    serial_o: See Behavior.

Parameters:
    STAGES: Implementation depth parameter. Choose a safe crossing yourself.

Behavior:
    - serial_i is an asynchronous bit. serial_o is that bit in clk_i.
    - When en_i is high, r_edge_o / f_edge_o pulse for one cycle on rising / falling edges of the synchronized bit.
    - After reset, outputs are low.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

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
