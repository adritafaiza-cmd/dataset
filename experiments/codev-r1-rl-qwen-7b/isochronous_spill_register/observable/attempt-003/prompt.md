Please act as a professional Verilog designer.

Implement a 2-deep valid/ready spill buffer between related clocks.

src_clk_i and dst_clk_i are related clocks; please take care of signals crossing between them. The resets are active-low.

Buffer a short rate mismatch between the related clocks. Deliver accepted data once in order and leave the destination idle after reset.

Give me the complete Verilog-2001 code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

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
