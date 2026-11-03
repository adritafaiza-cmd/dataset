Here is the complete Verilog-2001 code for the clearable valid/ready asynchronous FIFO:

```
module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Internal signals
    wire [WIDTH-1:0]       src_data_gray;
    wire [WIDTH-1:0]       dst_data_gray;
    wire [WIDTH-1:0]       src_data_gray_sync;
    wire [WIDTH-1:0]       dst_data_gray_sync;
    wire [WIDTH-1:0]       src_data_gray_sync_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       src_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev;
    wire [WIDTH-1:0]       dst_data_gray_sync_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev_prev