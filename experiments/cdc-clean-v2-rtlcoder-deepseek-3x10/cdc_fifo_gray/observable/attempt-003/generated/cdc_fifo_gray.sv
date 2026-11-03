Here is the complete Verilog-2001 code for the described module:

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

    // Internal signals
    reg [WIDTH-1:0] data_reg [0:(1<<LOG_DEPTH)-1];
    reg [LOG_DEPTH-1:0] wr_ptr_reg, wr_ptr_next;
    reg [LOG_DEPTH-1:0] rd_ptr_reg, rd_ptr_next;
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] rd_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0] wr_ptr_sync_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [0