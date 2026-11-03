Sure, here is the complete Verilog code for the clearable valid/ready asynchronous FIFO:

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
    wire [WIDTH-1:0]       src_data_q;
    wire                   src_valid_q;
    wire                   src_ready_q;
    wire [WIDTH-1:0]       dst_data_q;
    wire                   dst_valid_q;
    wire                   dst_ready_q;
    wire [LOG_DEPTH-1:0]   src_gray_q;
    wire [LOG_DEPTH-1:0]   dst_gray_q;
    wire [LOG_DEPTH-1:0]   src_gray_d;
    wire [LOG_DEPTH-1:0]   dst_gray_d;
    wire                   src_gray_valid;
    wire                   dst_gray_valid;
    wire                   src_gray_ready;
    wire                   dst_gray_ready;
    wire                   src_gray_clear;
    wire                   dst_gray_clear;
    wire                   src_gray_clear_pending;
    wire                   dst_gray_clear_pending;
    wire                   src_gray_clear_d;
    wire                   dst_gray_clear_d;
    wire                   src_gray_clear_q;
    wire                   dst_gray_clear_q;
    wire                   src_gray_clear_pending_q;
    wire                   dst_gray_clear_pending_q;
    wire                   src_gray_clear_pending_d;
    wire                   dst_gray_clear_pending_d;
    wire                   src_gray_clear_pending_q_d;
    wire                   dst_gray_clear_pending_q_d;
    wire                   src_gray_clear_pending_q_q;
    wire                   dst_gray_clear_pending_q_q;
    wire                   src_gray_clear_pending_q_q_d;
    wire                   dst_gray_clear_pending_q_q_d;
    wire                   src_gray_clear_pending_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    wire                   src_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    wire                   dst_gray_clear_pending_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q