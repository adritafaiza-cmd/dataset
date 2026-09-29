Please act as a professional Verilog designer.

Implement a single-bit destination-clock synchronizer.

Module name:
    sync

Language:
    SystemVerilog

Clocks:
    clk_i: Single clock.

Resets:
    rst_ni: active-low.

Input ports:
    clk_i: Clock.
    rst_ni: Active-low reset.
    serial_i: See Behavior.

Output ports:
    serial_o: See Behavior.

Parameters:
    STAGES: Implementation depth parameter. Choose a safe crossing yourself.
    ResetValue: Value of the synchronized bit after reset.

Behavior:
    - The top module name is sync.
    - serial_i is an asynchronous single-bit input. serial_o is that bit in clk_i.
    - STAGES is the pipeline depth.
    - After reset, serial_o equals ResetValue.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);
