```systemverilog
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

    localparam ADDR_MASK = (1 << ADDR_WIDTH) - 1;
    localparam FIFO_DEPTH = 1 << ADDR_WIDTH;

    // Write domain signals
    reg [ADDR_WIDTH-1:0] w_ptr;
    reg [ADDR_WIDTH-1:0] w_cnt;
    reg [ADDR_WIDTH-1:0] w_full_cnt;
    reg [ADDR_WIDTH-1:0] w_empty_cnt;
    reg [DATA_WIDTH-1:0] w_data_reg;

    // Read domain signals
    reg [ADDR_WIDTH-1:0] r_ptr;
    reg [ADDR_WIDTH-1:0] r_cnt;
    reg [ADDR_WIDTH-1:0] r_full_cnt;
    reg [ADDR_WIDTH-1:0] r_empty_cnt;
    reg [DATA_WIDTH-1:0] r_data_reg;

    // Cross-domain pointers (gray coded)
    wire [ADDR_WIDTH-1:0] w_gray;
    wire [ADDR_WIDTH-1:0] r_gray;

    // Cross-domain pointers for full/empty detection
    wire [ADDR_WIDTH-1:0] w_full_gray;
    wire [ADDR_WIDTH-1:0] r_full_gray;

    // Cross-domain pointers for empty detection
    wire [ADDR_WIDTH-1:0] w_empty_gray;
    wire [ADDR_WIDTH-1:0] r_empty_gray;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for full/empty status
    wire [ADDR_WIDTH-1:0] w_full_ptr;
    wire [ADDR_WIDTH-1:0] r_full_ptr;

    // Cross-domain pointers for empty status
    wire [ADDR_WIDTH-1:0] w_empty_ptr;
    wire [ADDR_WIDTH-1:0] r_empty_ptr;

    // Cross-domain pointers for data
    wire [ADDR_WIDTH-1:0] w_data_ptr;
    wire [ADDR_WIDTH-1:0] r_data_ptr;

    // Cross-domain pointers for