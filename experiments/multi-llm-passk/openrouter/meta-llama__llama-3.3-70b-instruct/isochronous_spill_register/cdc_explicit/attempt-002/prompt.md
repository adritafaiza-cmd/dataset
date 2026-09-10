Please act as a professional Verilog designer.

Implement a 2-deep valid/ready spill buffer between related clocks.

Module name:
    isochronous_spill_register

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
    src_data_i: Source payload.
    dst_clk_i: Destination-domain clock.
    dst_rst_ni: Active-low destination-domain reset.
    dst_ready_i: Destination ready.

Output ports:
    src_ready_o: Source ready.
    dst_valid_o: Destination valid.
    dst_data_o: Destination payload.

Parameters:
    WIDTH: Payload width in bits.

Behavior:
    - Every accepted source beat appears exactly once at the destination, in order.
    - The buffer absorbs a short rate mismatch between the related clocks.
    - After reset dest is idle.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output [WIDTH-1:0] dst_data_o
);
