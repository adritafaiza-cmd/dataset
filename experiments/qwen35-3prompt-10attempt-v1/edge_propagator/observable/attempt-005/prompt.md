Please act as a professional Verilog designer.

Implement a pulse/edge propagator between asynchronous clocks.

clk_tx_i and clk_rx_i are independent clocks. Please take care of any clock-domain crossings between them. The resets are active-low.

Carry an input event to the receiving side as one event, without duplicating it or leaving a stale event after reset.

Give me the complete SystemVerilog code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);
