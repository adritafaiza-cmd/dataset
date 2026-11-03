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
    reg [ADDR_WIDTH:0]             wptr_gray, rptr_gray;
    wire [ADDR_WIDTH:0]            wptr_gray_next, rptr_gray_next;
    reg [SYNC_STAGES-1:0]          wptr_sync_reg;
    reg [SYNC_STAGES-1:0]          rptr_sync_reg;
    wire                           wfull_int, rempty_int;

    assign wfull = wfull_int;
    assign rempty = rempty_int;

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
        end else if (winc && ~wfull_int) begin
            wptr <= wptr + 1;
            wptr_gray <= (wptr + 1) ^ ((wptr + 1) >> 1);
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
        end else if (rinc && ~rempty_int) begin
            rptr <= rptr + 1;
            rptr_gray <= (rptr + 1) ^ ((rptr + 1) >> 1);
        end
    end

    always @(posedge wclk) begin
        if (winc && ~wfull_int) begin
            mem[wptr] <= wdata;
        end
    end

    always @(posedge rclk) begin
        rdata <= mem[rptr];
    end

    assign wfull_int = (wptr_gray[ADDR_WIDTH] ^ wptr_sync[ADDR_WIDTH]) || 
                       ((wptr_gray[ADDR_WIDTH-1:0] == wptr_sync[ADDR_WIDTH-1:0]) && 
                        (wptr_gray[ADDR_WIDTH] == wptr_sync[ADDR_WIDTH]));

    assign rempty_int = (rptr_gray[ADDR_WIDTH] ^ rptr_sync[ADDR_WIDTH]) || 
                        ((rptr_gray[ADDR_WIDTH-1:0] == rptr_sync[ADDR_WIDTH-1:0]) && 
                         (rptr_gray[ADDR_WIDTH] == rptr_sync[ADDR_WIDTH] && rptr == wptr_sync));

    always @(posedge rclk) begin
        wptr_sync_reg[0] <= wptr_gray[ADDR_WIDTH];
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_sync_reg[i] <= wptr_sync_reg[i-1];
        end
        wptr_sync <= {wptr_sync_reg[SYNC_STAGES-1], wptr_sync_reg[SYNC_STAGES-2:0]};
    end

    always @(posedge wclk) begin
        rptr_sync_reg[0] <= rptr_gray[ADDR_WIDTH];
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_sync_reg[i] <= rptr_sync_reg[i-1];
        end
        rptr_sync <= {rptr_sync_reg[SYNC_STAGES-1], rptr_sync_reg[SYNC_STAGES-2:0]};
    end

    assign waddr = wptr;
    assign raddr = rptr;

endmodule
