The following Verilog code implements a valid/ready asynchronous FIFO with 2**LOG_DEPTH entries of WIDTH bits.

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
    localparam DATA_WIDTH = WIDTH;

    // Internal signals
    reg [ADDR_WIDTH-1:0] wr_ptr_r;
    reg [ADDR_WIDTH-1:0] rd_ptr_r;
    reg [DATA_WIDTH-1:0] fifo_r [0:DEPTH-1];
    reg [SYNC_STAGES-1:0] sync_r;
    reg [SYNC_STAGES-1:0] sync_d;
    reg [SYNC_STAGES-1:0] sync_q;
    reg [SYNC_STAGES-1:0] sync_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
    reg [SYNC_STAGES-1:0] sync_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_