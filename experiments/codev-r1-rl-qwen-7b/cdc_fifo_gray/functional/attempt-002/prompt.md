Please act as a professional Verilog designer.

Implement a valid/ready asynchronous FIFO with 2**LOG_DEPTH entries of WIDTH bits.

Module name:
    cdc_fifo_gray

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
    SYNC_STAGES: Implementation depth parameter. Choose a safe crossing yourself.

Behavior:
    - Accept source beats when src_valid_i and src_ready_o are high.
    - Deliver destination beats in order.
    - Pointers and data that leave their clock domain must remain coherent.
    - SYNC_STAGES is an implementation parameter; choose a safe crossing yourself.
    - After reset the FIFO is empty.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
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
