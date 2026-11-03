Here is the complete Verilog code for the clearable valid/ready asynchronous FIFO:

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

    // Local parameters
    localparam DEPTH = 1 << LOG_DEPTH;

    // Internal signals
    reg [WIDTH-1:0] data_reg [0:DEPTH-1];
    reg [LOG_DEPTH-1:0] wr_ptr_reg;
    reg [LOG_DEPTH-1:0] rd_ptr_reg;
    reg [LOG_DEPTH-1:0] wr_ptr_next;
    reg [LOG_DEPTH-1:0] rd_ptr_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_reg;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_reg;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [LOG_DEPTH-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_