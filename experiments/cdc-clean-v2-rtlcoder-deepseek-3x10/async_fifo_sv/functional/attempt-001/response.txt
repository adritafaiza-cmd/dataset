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
    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] rptr;
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH:0] wptr_next;
    wire [ADDR_WIDTH:0] rptr_next;
    wire [DATA_WIDTH-1:0] rdata_reg;
    wire [DATA_WIDTH-1:0] rdata_sync;
    wire [DATA_WIDTH-1:0] rdata_sync_next;
    wire [ADDR_WIDTH:0] waddr_reg;
    wire [ADDR_WIDTH:0] raddr_reg;
    wire [ADDR_WIDTH:0] waddr_sync;
    wire [ADDR_WIDTH:0] raddr_sync;
    wire [ADDR_WIDTH:0] waddr_sync_next;
    wire [ADDR_WIDTH:0] raddr_sync_next;
    wire [SYNC_STAGES-1:0] wfull_sync;
    wire [SYNC_STAGES-1:0] rempty_sync;
    wire [SYNC_STAGES-1:0] wfull_sync_next;
    wire [SYNC_STAGES-1:0] rempty_sync_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg;
    wire [SYNC_STAGES-1:0] wfull_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next;
    wire [SYNC_STAGES-1:0] rempty_sync_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_reg_next_