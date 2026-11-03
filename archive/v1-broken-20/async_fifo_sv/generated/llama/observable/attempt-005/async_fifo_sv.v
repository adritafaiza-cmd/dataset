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

reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];

reg [ADDR_WIDTH-1:0] wptr, rptr;
reg [ADDR_WIDTH:0] wcnt, rcnt;

reg [ADDR_WIDTH:0] sync_wcnt [SYNC_STAGES-1:0];

always @(posedge wclk or negedge wrst_n) begin
    if (~wrst_n) begin
        wptr <= 0;
        wcnt <= 0;
    end else if (winc && ~wfull) begin
        mem[wptr] <= wdata;
        wptr <= wptr + 1;
        wcnt <= wcnt + 1;
    end
end

always @(posedge wclk) begin
    sync_wcnt[0] <= wcnt;
    for (int i = 1; i < SYNC_STAGES; i++) begin
        sync_wcnt[i] <= sync_wcnt[i-1];
    end
end

assign wfull = (wcnt == (2**ADDR_WIDTH));

always @(posedge rclk or negedge rrst_n) begin
    if (~rrst_n) begin
        rptr <= 0;
        rcnt <= 0;
    end else if (rinc && ~rempty) begin
        rptr <= rptr + 1;
        rcnt <= rcnt - 1;
    end
end

assign rempty = (rcnt == 0);
assign rdata = mem[rptr];

always @(posedge rclk) begin
    if (~rempty) begin
        raddr <= rptr;
    end else begin
        raddr <= 0;
    end
end

assign waddr = wptr;

endmodule
