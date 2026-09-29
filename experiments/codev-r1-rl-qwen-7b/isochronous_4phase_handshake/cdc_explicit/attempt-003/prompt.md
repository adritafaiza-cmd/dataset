Please act as a professional Verilog designer.

Implement a four-phase valid/ready handshake between related clocks.

Module name:
    isochronous_4phase_handshake

Language:
    Verilog-2001

Clocks:
    src_clk_i: Related (integer-ratio) clock with dst_clk_i.
    dst_clk_i: Related (integer-ratio) clock with src_clk_i.

Resets:
    src_rst_ni: active-low.
    dst_rst_ni: active-low.

Input ports:
    src_clk_i: Source-domain clock.
    src_rst_ni: Active-low source-domain reset.
    src_valid_i: Source valid.
    dst_clk_i: Destination-domain clock.
    dst_rst_ni: Active-low destination-domain reset.
    dst_ready_i: Destination ready.

Output ports:
    src_ready_o: Source ready.
    dst_valid_o: Destination valid.

Parameters:
    None.

Behavior:
    - Implement a four-phase valid/ready handshake with no data payload.
    - src_ready_o and dst_valid_o must follow four-phase order.
    - After reset both sides are idle.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module isochronous_4phase_handshake (
    input  src_clk_i,
    input  src_rst_ni,
    input  src_valid_i,
    output src_ready_o,
    input  dst_clk_i,
    input  dst_rst_ni,
    output dst_valid_o,
    input  dst_ready_i
);
