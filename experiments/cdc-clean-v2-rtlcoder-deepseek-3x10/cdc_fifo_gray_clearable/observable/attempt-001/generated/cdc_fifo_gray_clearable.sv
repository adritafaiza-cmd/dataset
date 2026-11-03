Here is the complete Verilog-2001 code for the clearable valid/ready asynchronous FIFO. This code includes the necessary clock domain crossings and synchronization stages.

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

    // Gray code synchronization
    reg [LOG_DEPTH-1:0] src_gray_q, src_gray_d;
    reg [LOG_DEPTH-1:0] dst_gray_q, dst_gray_d;
    reg [LOG_DEPTH-1:0] src_gray_sync_q, dst_gray_sync_q;
    reg [LOG_DEPTH-1:0] src_gray_sync_d, dst_gray_sync_d;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_d, dst_gray_sync_q_d;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dd, dst_gray_sync_q_dd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddd, dst_gray_sync_q_ddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddd, dst_gray_sync_q_dddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddd, dst_gray_sync_q_ddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddd, dst_gray_sync_q_dddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddd, dst_gray_sync_q_ddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddd, dst_gray_sync_q_dddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddd, dst_gray_sync_q_ddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddd, dst_gray_sync_q_dddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddd, dst_gray_sync_q_ddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddd, dst_gray_sync_q_dddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddd, dst_gray_sync_q_ddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddd, dst_gray_sync_q_dddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddd, dst_gray_sync_q_ddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddd, dst_gray_sync_q_dddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, dst_gray_sync_q_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
    reg [LOG_DEPTH-1:0] src_gray_sync_q_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd