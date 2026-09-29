Please act as a professional Verilog designer.

Implement a valid/ready asynchronous FIFO with 2**LOG_DEPTH entries of WIDTH bits.

Module name:
    cdc_fifo_2phase

Language:
    Verilog-2001

Clocks:
    src_clk_i: Independent asynchronous clock (async to dst_clk_i). No fixed frequency or phase relationship.
    dst_clk_i: Independent asynchronous clock (async to src_clk_i).

Resets:
    src_rst_ni: active-low.
    dst_rst_ni: active-low.

Input ports:
    src_rst_ni: Active-low source-domain reset.
    src_clk_i: Source-domain clock.
    src_data_i: Source payload.
    src_valid_i: Source valid.
    dst_rst_ni: Active-low destination-domain reset.
    dst_clk_i: Destination-domain clock.
    dst_ready_i: Destination ready.

Output ports:
    src_ready_o: Source ready.
    dst_data_o: Destination payload.
    dst_valid_o: Destination valid.

Parameters:
    WIDTH: Payload width in bits.
    LOG_DEPTH: Log2 of the number of FIFO entries.

Behavior:
    - Accept source beats when src_valid_i and src_ready_o are high.
    - Deliver destination beats in order when dst_valid_o and dst_ready_i are high.
    - src_ready_o must be low when the FIFO cannot accept another item.
    - After reset the FIFO is empty and dest is idle.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);
