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

    reg [DATA_WIDTH-1:0]           mem [2**ADDR_WIDTH-1:0];
    reg [ADDR_WIDTH:0]             wptr, rptr, wptr_sync, rptr_sync;
    reg [ADDR_WIDTH:0]             wptr_gray, rptr_gray, wptr_sync_gray, rptr_sync_gray;
    reg [SYNC_STAGES-1:0]          wptr_sync_reg, rptr_sync_reg;
    reg [DATA_WIDTH-1:0]           rdata_reg;
    reg                            wfull_reg, rempty_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            wfull_reg <= 0;
        end else if (winc && ~wfull_reg) begin
            wptr <= wptr + 1;
            wptr_gray <= (wptr + 1) ^ ((wptr + 1) >> 1);
            mem[wptr] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rempty_reg <= 1;
            rdata_reg <= 0;
        end else if (rinc && ~rempty_reg) begin
            rptr <= rptr + 1;
            rptr_gray <= (rptr + 1) ^ ((rptr + 1) >> 1);
            rdata_reg <= mem[rptr];
            rempty_reg <= 0;
        end else if (~rempty_reg && rptr == wptr_sync) begin
            rempty_reg <= 1;
        end
    end

    always @(posedge wclk) begin
        wptr_sync_reg[0] <= wptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_sync_reg[i] <= wptr_sync_reg[i-1];
        end
        wptr_sync <= wptr_sync_reg[SYNC_STAGES-1];
        wptr_sync_gray <= wptr_sync ^ (wptr_sync >> 1);
    end

    always @(posedge rclk) begin
        rptr_sync_reg[0] <= rptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_sync_reg[i] <= rptr_sync_reg[i-1];
        end
        rptr_sync <= rptr_sync_reg[SYNC_STAGES-1];
        rptr_sync_gray <= rptr_sync ^ (rptr_sync >> 1);
    end

    assign wfull = (wptr_gray == (rptr_sync_gray + 1) ^ ((rptr_sync_gray + 1) >> 1));
    assign waddr = wptr;
    assign rdata = rdata_reg;
    assign rempty = rempty_reg;
    assign raddr = rptr;

endmodule
