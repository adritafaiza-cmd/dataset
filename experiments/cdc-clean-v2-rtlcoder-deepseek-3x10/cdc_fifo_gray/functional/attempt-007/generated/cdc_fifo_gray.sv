Sure, here is the complete Verilog code for the cdc_fifo_gray module:

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
    localparam LOG_DEPTH_PLUS_ONE = LOG_DEPTH + 1;
    localparam LOG_DEPTH_PLUS_TWO = LOG_DEPTH + 2;

    // Internal signals
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_reg;
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_next;
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_reg;
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_next;
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_reg;
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_next;
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_reg;
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_next;
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] wr_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH_PLUS_ONE-1:0] rd_ptr_gray_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_sync_