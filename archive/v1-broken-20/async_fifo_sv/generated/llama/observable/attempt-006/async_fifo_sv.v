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

reg [ADDR_WIDTH:0] wptr, wptr_next, wptr_sync;
reg [ADDR_WIDTH:0] rptr, rptr_next, rptr_sync;

always @(posedge wclk or negedge wrst_n) begin
    if (~wrst_n) begin
        wptr <= '0;
    end else if (winc) begin
        wptr <= wptr_next;
    end
end

always @(*) begin
    wptr_next = wptr + 1;
    if (wptr == 2**ADDR_WIDTH - 1) begin
        wptr_next = '0;
    end
end

always @(posedge rclk or negedge rrst_n) begin
    if (~rrst_n) begin
        rptr <= '0;
    end else if (rinc) begin
        rptr <= rptr_next;
    end
end

always @(*) begin
    rptr_next = rptr + 1;
    if (rptr == 2**ADDR_WIDTH - 1) begin
        rptr_next = '0;
    end
end

always @(posedge wclk) begin
    if (winc) begin
        mem[wptr] <= wdata;
    end
end

always @(posedge rclk) begin
    rdata <= mem[rptr];
end

// Synchronize wptr to read clock domain
reg [ADDR_WIDTH:0] wptr_sync_reg [SYNC_STAGES-1:0];
always @(posedge rclk) begin
    wptr_sync_reg[0] <= wptr;
    for (int i = 1; i < SYNC_STAGES; i++) begin
        wptr_sync_reg[i] <= wptr_sync_reg[i-1];
    end
end
assign wptr_sync = wptr_sync_reg[SYNC_STAGES-1];

// Synchronize rptr to write clock domain
reg [ADDR_WIDTH:0] rptr_sync_reg [SYNC_STAGES-1:0];
always @(posedge wclk) begin
    rptr_sync_reg[0] <= rptr;
    for (int i = 1; i < SYNC_STAGES; i++) begin
        rptr_sync_reg[i] <= rptr_sync_reg[i-1];
    end
end
assign rptr_sync = rptr_sync_reg[SYNC_STAGES-1];

assign wfull = (wptr_next == rptr_sync);
assign rempty = (wptr_sync == rptr);
assign waddr = wptr;
assign raddr = rptr;

endmodule
