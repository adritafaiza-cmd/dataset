Here is the complete Verilog code for the cdc_fifo_gray module:

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
    localparam GRAY_WIDTH = LOG_DEPTH + 1;

    // Internal signals
    reg [ADDR_WIDTH-1:0] wr_ptr_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_d;
    reg [GRAY_WIDTH-1:0] wr_gray_q;
    reg [GRAY_WIDTH-1:0] wr_gray_d;
    reg [GRAY_WIDTH-1:0] rd_gray_q;
    reg [GRAY_WIDTH-1:0] rd_gray_d;
    reg [WIDTH-1:0] data_q [DEPTH-1:0];
    reg [WIDTH-1:0] data_d [DEPTH-1:0];
    reg [ADDR_WIDTH-1:0] wr_ptr_gray;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [ADDR_WIDTH-1:0] wr_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [ADDR_WIDTH-1:0] rd_ptr_gray_q_q_q_q_q_q_q_q_q_q_q_q_q_q