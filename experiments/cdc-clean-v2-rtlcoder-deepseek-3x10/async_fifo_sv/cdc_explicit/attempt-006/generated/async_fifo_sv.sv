Here is the complete Verilog code for the asynchronous FIFO module:

```
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire                    winc,
    input  wire [DATA_WIDTH-1:0]   wdata,
    output wire                    wfull,
    output wire [ADDR_WIDTH:0]     waddr,
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire                    rinc,
    output wire [DATA_WIDTH-1:0]   rdata,
    output wire                    rempty,
    output wire [ADDR_WIDTH:0]     raddr
);

    // Internal signals
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] wptr_next;
    reg [ADDR_WIDTH-1:0] rptr_next;
    reg [ADDR_WIDTH-1:0] wptr_sync [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] wptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH-1:0] rptr_sync_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next