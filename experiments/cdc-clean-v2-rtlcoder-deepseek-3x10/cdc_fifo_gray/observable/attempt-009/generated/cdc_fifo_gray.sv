The following Verilog code implements a valid/ready asynchronous FIFO with 2**LOG_DEPTH entries of WIDTH bits. The code includes clock domain crossings and reset handling.

```
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

    // Local parameters
    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;
    localparam GRAY_WIDTH = ADDR_WIDTH + 1;

    // Internal signals
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] src_rd_ptr_r;
    reg [ADDR_WIDTH-1:0] src_wr_ptr_r;
    reg [ADDR_WIDTH-1:0] dst_rd_ptr_r;
    reg [ADDR_WIDTH-1:0] dst_wr_ptr_r;
    reg [GRAY_WIDTH-1:0] src_rd_gray_r;
    reg [GRAY_WIDTH-1:0] src_wr_gray_r;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_r;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_r;
    reg [GRAY_WIDTH-1:0] src_rd_gray_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync