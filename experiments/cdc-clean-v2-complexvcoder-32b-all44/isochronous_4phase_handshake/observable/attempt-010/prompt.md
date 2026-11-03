Please act as a professional Verilog designer.

Implement a four-phase valid/ready handshake between related clocks.

src_clk_i and dst_clk_i are related clocks; please take care of signals crossing between them. The resets are active-low.

Provide a four-phase handshake between the related clocks. Avoid accepting or reporting a transfer that did not occur, including after reset.

Give me the complete Verilog-2001 code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

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
