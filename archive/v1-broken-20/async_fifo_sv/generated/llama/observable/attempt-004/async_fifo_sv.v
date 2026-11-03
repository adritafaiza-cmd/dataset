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

reg [ADDR_WIDTH:0] wptr, rptr;
reg [ADDR_WIDTH:0] wptr_sync, rptr_sync;

reg [ADDR_WIDTH:0] wptr_gray, rptr_gray;
reg [ADDR_WIDTH:0] wptr_gray_sync, rptr_gray_sync;

assign wfull = (wptr_gray[ADDR_WIDTH] ^ rptr_gray[ADDR_WIDTH]) && (wptr_gray[ADDR_WIDTH-1:0] == rptr_gray[ADDR_WIDTH-1:0]);

always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
        wptr <= 0;
        wptr_gray <= 0;
    end else if (winc &&!wfull) begin
        wptr <= wptr + 1;
        wptr_gray <= (wptr_gray[ADDR_WIDTH-1:0] + 1) ^ (wptr_gray[ADDR_WIDTH-1:0] >> 1);
        mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end
end

always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
        rptr <= 0;
        rptr_gray <= 0;
    end else if (rinc &&!rempty) begin
        rptr <= rptr + 1;
        rptr_gray <= (rptr_gray[ADDR_WIDTH-1:0] + 1) ^ (rptr_gray[ADDR_WIDTH-1:0] >> 1);
    end
end

always @(posedge wclk) begin
    wptr_sync <= wptr;
    wptr_gray_sync <= wptr_gray;
end

always @(posedge rclk) begin
    rptr_sync <= rptr;
    rptr_gray_sync <= rptr_gray;
end

reg [SYNC_STAGES-1:0] wptr_sync_reg;
reg [SYNC_STAGES-1:0] rptr_sync_reg;

always @(posedge rclk) begin
    wptr_sync_reg[0] <= wptr_sync;
    for (int i = 1; i < SYNC_STAGES; i++) begin
        wptr_sync_reg[i] <= wptr_sync_reg[i-1];
    end
end

always @(posedge wclk) begin
    rptr_sync_reg[0] <= rptr_sync;
    for (int i = 1; i < SYNC_STAGES; i++) begin
        rptr_sync_reg[i] <= rptr_sync_reg[i-1];
    end
end

assign rempty = (rptr_gray[ADDR_WIDTH] ^ wptr_sync_reg[SYNC_STAGES-1][ADDR_WIDTH]) || (rptr_gray[ADDR_WIDTH-1:0]!= wptr_sync_reg[SYNC_STAGES-1][ADDR_WIDTH-1:0]);

always @(posedge rclk) begin
    rdata <= mem[rptr[ADDR_WIDTH-1:0]];
end

assign waddr = wptr;
assign raddr = rptr;

endmodule
