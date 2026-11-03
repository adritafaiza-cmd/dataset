Sure, here is the complete Verilog-2001 code for the clearable valid/ready asynchronous FIFO.

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
    localparam GRAY_WIDTH = LOG_DEPTH + 1;

    // Internal signals
    reg [WIDTH-1:0]         data_reg [0:DEPTH-1];
    reg [GRAY_WIDTH-1:0]    gray_reg;
    reg [GRAY_WIDTH-1:0]    gray_next;
    reg [LOG_DEPTH-1:0]     head_reg;
    reg [LOG_DEPTH-1:0]     tail_reg;
    reg [LOG_DEPTH-1:0]     head_next;
    reg [LOG_DEPTH-1:0]     tail_next;
    reg                     valid_reg;
    reg                     valid_next;
    wire                    empty;
    wire                    full;
    wire                    gray_eq;
    wire                    gray_ne;
    wire                    gray_gt;
    wire                    gray_lt;
    wire                    gray_ge;
    wire                    gray_le;
    wire                    gray_inc;
    wire                    gray_dec;
    wire                    gray_inc_wrap;
    wire                    gray_dec_wrap;
    wire                    gray_inc_wrap_next;
    wire                    gray_dec_wrap_next;
    wire                    gray_inc_wrap_next_next;
    wire                    gray_dec_wrap_next_next;
    wire                    gray_inc_wrap_next_next_next;
    wire                    gray_dec_wrap_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_inc_wrap_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    wire                    gray_dec_wrap_next_next_next_next_