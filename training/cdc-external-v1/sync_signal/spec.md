Please act as a professional Verilog designer.

Implement Synchronize an asynchronous vector through a configurable pipeline into a destination clock.

Module name:
    sync_signal

Language:
    Verilog

Clocks:
    clk: Clock input for a source, destination, or sample domain.

Resets:
    No reset port is declared; preserve the source initialization and reset behavior.

Input ports:
    signals: Synchronized output or status.
    clk: Clock input for a source, destination, or sample domain.
    in: Input payload or control crossing.

Output ports:
    out: Synchronized output or status.

Parameters:
    Preserve each source parameter and its stated width or pipeline effect.

Behavior:
    - Preserve the level_sync crossing mechanism and keep every asynchronous signal synchronized before it is consumed.
    - Maintain the source-defined pipeline, toggle, payload, and sampling relationships without introducing a second crossing path.
    - Preserve the source reset or initialization behavior exactly.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module sync_signal #(
    parameter WIDTH=1, // width of the input and output signals
    parameter N=2 // depth of synchronizer
)(
    input wire clk,
    input wire [WIDTH-1:0] in,
    output wire [WIDTH-1:0] out
);
