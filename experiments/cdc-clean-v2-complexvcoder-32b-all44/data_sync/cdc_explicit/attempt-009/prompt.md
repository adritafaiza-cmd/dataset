Please act as a professional Verilog designer.

Implement a multi-bit destination-clock data synchronizer.

Module name:
    data_sync

Language:
    Verilog-2001

Clocks:
    clk: Single clock.

Resets:
    rstn: active-low.

Input ports:
    clk: Clock.
    rstn: Active-low reset.
    din: See Behavior.
    dready_i: Handshake ready.

Output ports:
    dout: See Behavior.
    dready_o: Handshake ready.

Parameters:
    STAGES: Implementation depth parameter. Choose a safe crossing yourself.
    DWIDTH: See Behavior.

Behavior:
    - When dready_i indicates a new source value, present a coherent dout and pulse dready_o in clk.
    - Do not tear multi-bit dout.
    - After reset, dready_o is low.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module data_sync #(
    parameter STAGES = 2,
    parameter DWIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    input                  dready_i,
    output reg [DWIDTH-1:0] dout,
    output reg             dready_o
);
