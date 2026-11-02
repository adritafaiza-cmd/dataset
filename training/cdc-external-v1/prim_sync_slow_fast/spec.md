Please act as a professional Verilog designer.

Implement a slow-to-fast data sampler that captures a stable slow-domain word when the fast domain observes a synchronized falling edge of the slow clock.

Module name:
    prim_sync_slow_fast

Language:
    SystemVerilog

Clocks:
    clk_slow_i: Slow-domain clock waveform sampled as data in the fast clock domain.
    clk_fast_i: Rising-edge sampling clock, substantially faster than clk_slow_i.

Resets:
    rst_fast_ni: active low; asynchronous assertion.

Input ports:
    clk_slow_i: Slow-domain clock waveform sampled as data in the fast clock domain.
    clk_fast_i: Rising-edge sampling clock, substantially faster than clk_slow_i.
    rst_fast_ni: Active-low asynchronous reset of all fast-domain state.
    wdata_i: Word originating in the slow domain, stable across the delayed fast-domain capture.

Output ports:
    rdata_o: Fast-domain registered copy of the most recently sampled word.

Parameters:
    Width: Number of bits sampled together from wdata_i into rdata_o; default 32.

Behavior:
    - Treat clk_slow_i as an asynchronous signal sampled by a two-stage synchronizer running on clk_fast_i; it does not directly clock a payload register in this module.
    - Remember the previous synchronized slow-clock level and recognize its high-to-low transition in the fast domain.
    - On a rising clk_fast_i edge with that falling-edge indication, capture the entire wdata_i word. Hold rdata_o unchanged on other fast-clock edges.
    - Require the slow producer to keep its word stable through the delayed sampling interval. Use a fast-to-slow frequency ratio of at least about ten to one as the intended operating assumption; this is not a general arbitrary-rate bus synchronizer.
    - Asynchronously clear the clock synchronizer, edge-history register, and sampled payload with the active-low rst_fast_ni. There is no separate slow-domain reset input.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module prim_sync_slow_fast #(
  parameter int unsigned Width = 32
) (
  input  logic             clk_slow_i,
  input  logic             clk_fast_i,
  input  logic             rst_fast_ni,
  input  logic [Width-1:0] wdata_i,    // Slow domain
  output logic [Width-1:0] rdata_o     // Fast domain
);
