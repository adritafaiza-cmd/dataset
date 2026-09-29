Please act as a professional Verilog designer.

Implement a pulse/edge propagator between asynchronous clocks.

Module name:
    edge_propagator

Language:
    SystemVerilog

Clocks:
    clk_tx_i: Independent asynchronous clock (async to clk_rx_i).
    clk_rx_i: Independent asynchronous clock (async to clk_tx_i).

Resets:
    rstn_tx_i: active-low.
    rstn_rx_i: active-low.

Input ports:
    clk_tx_i: Clock.
    rstn_tx_i: Active-low reset.
    edge_i: See Behavior.
    clk_rx_i: Clock.
    rstn_rx_i: Active-low reset.

Output ports:
    edge_o: See Behavior.

Parameters:
    None.

Behavior:
    - A pulse or edge on edge_i in the TX domain must produce one pulse on edge_o in the RX domain.
    - Do not lose or double-count isolated edges.
    - After reset, edge_o is low.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);
