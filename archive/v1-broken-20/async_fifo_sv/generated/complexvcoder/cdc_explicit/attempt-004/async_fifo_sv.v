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
    wire [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
    reg [ADDR_WIDTH-1:0] wptr, rptr;
    reg wfull_int, rempty_int;

    // Write domain
    fifo_sync #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_sync_w (
        .clk(wclk),
        .rst_n(wrst_n),
        .wrst_n(winc),
        .wdata(wdata),
        .wfull(wfull_int),
        .waddr(waddr)
    );

    // Read domain
    fifo_sync #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_sync_r (
        .clk(rclk),
        .rst_n(rrst_n),
        .wrst_n(rinc),
        .rdata(rdata),
        .rempty(rempty_int),
        .raddr(raddr)
    );

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (winc && !wfull_int) begin
            wptr <= wptr + 1;
        end
    end

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rinc && !rempty_int) begin
            rptr <= rptr + 1;
        end
    end

    // Full and empty flags
    assign wfull = wfull_int;
    assign rempty = rempty_int;

    // FIFO full logic
    assign wfull_int = (wptr == rptr) && (winc & !wfull_int);

    // FIFO empty logic
    assign rempty_int = (wptr == rptr) && (rinc & !rempty_int);

endmodule

module fifo_sync #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    wrst_n,
    input  wire [DATA_WIDTH-1:0]   wdata,
    output reg [DATA_WIDTH-1:0]   rdata,
    output reg                    wfull,
    output reg [ADDR_WIDTH:0]     waddr
);

    // Internal signals
    reg [ADDR_WIDTH:0] wptr_sync, rptr_sync;
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // Write pointer synchronization
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr_sync <= 0;
        end else if (!wrst_n) begin
            wptr_sync <= wptr_sync + 1;
        end
    end

    // Read pointer synchronization
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rptr_sync <= 0;
        end else if (!wrst_n) begin
            rptr_sync <= rptr_sync + 1;
        end
    end

    // FIFO full logic
    assign wfull = (wptr_sync == rptr_sync) && (!wrst_n);

    // FIFO data output
    assign rdata = mem[rptr_sync];

endmodule
