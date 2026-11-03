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
reg [ADDR_WIDTH:0] wptr_sync;
reg [ADDR_WIDTH:0] rptr_sync;
reg [ADDR_WIDTH:0] wptr_gray, rptr_gray;
reg [ADDR_WIDTH:0] wptr_bin, rptr_bin;
reg wfull_reg, rempty_reg;
reg [DATA_WIDTH-1:0] rdata_reg;

always @(posedge wclk or negedge wrst_n) begin
    if (~wrst_n) begin
        wptr <= 0;
        wfull_reg <= 0;
    end else if (winc && ~wfull_reg) begin
        mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
        wptr <= wptr + 1;
    end
end

always @(posedge wclk) begin
    wfull_reg <= (wptr[ADDR_WIDTH:0] == {1'b1, {(ADDR_WIDTH-1){1'b0}}} && winc);
    waddr <= wptr;
end

always @(posedge rclk or negedge rrst_n) begin
    if (~rrst_n) begin
        rptr <= 0;
        rempty_reg <= 1;
    end else if (rinc && ~rempty_reg) begin
        rptr <= rptr + 1;
    end
end

always @(posedge rclk) begin
    rempty_reg <= (rptr[ADDR_WIDTH:0] == wptr_sync[ADDR_WIDTH:0]);
    raddr <= rptr;
    if (~rempty_reg) begin
        rdata_reg <= mem[rptr[ADDR_WIDTH-1:0]];
    end
end

assign rdata = rdata_reg;
assign rempty = rempty_reg;
assign wfull = wfull_reg;

// Gray code conversion
always @(posedge wclk) begin
    wptr_gray <= (wptr[ADDR_WIDTH:0] >> 1) ^ wptr[ADDR_WIDTH:0];
end

// Synchronization
reg [SYNC_STAGES-1:0] wptr_sync_reg;
always @(posedge rclk) begin
    wptr_sync_reg <= {wptr_sync_reg[SYNC_STAGES-2:0], wptr_gray[ADDR_WIDTH:0]};
end
assign wptr_sync = wptr_sync_reg[SYNC_STAGES-1];

// Binary conversion
always @(posedge rclk) begin
    rptr_bin <= (rptr[ADDR_WIDTH:0] >> 1) ^ rptr[ADDR_WIDTH:0];
    wptr_bin <= (wptr_sync[ADDR_WIDTH:0] >> 1) ^ wptr_sync[ADDR_WIDTH:0];
end

endmodule
