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
    reg [ADDR_WIDTH:0]             wptr, rptr;
    reg [ADDR_WIDTH:0]             wptr_sync, rptr_sync;
    reg [ADDR_WIDTH:0]             wptr_gray, rptr_gray;
    reg [ADDR_WIDTH:0]             wptr_gray_sync, rptr_gray_sync;
    reg [SYNC_STAGES-1:0]          wptr_sync_reg, rptr_sync_reg;
    reg [SYNC_STAGES-1:0]          wptr_gray_sync_reg, rptr_gray_sync_reg;
    reg [ADDR_WIDTH:0]             waddr_reg, raddr_reg;
    reg [DATA_WIDTH-1:0]           rdata_reg;
    reg                           wfull_reg, rempty_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= '0;
            wptr_gray <= '0;
            wptr_sync_reg <= '0;
            wptr_gray_sync_reg <= '0;
        end else if (winc && ~wfull_reg) begin
            wptr <= wptr + 1;
            wptr_gray <= (wptr + 1) ^ ((wptr + 1) >> 1);
            mem[wptr] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= '0;
            rptr_gray <= '0;
            rptr_sync_reg <= '0;
            rptr_gray_sync_reg <= '0;
        end else if (rinc && ~rempty_reg) begin
            rptr <= rptr + 1;
            rptr_gray <= (rptr + 1) ^ ((rptr + 1) >> 1);
        end
    end

    always @(posedge wclk) begin
        wptr_sync_reg[0] <= wptr_gray[ADDR_WIDTH:1];
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_sync_reg[i] <= wptr_sync_reg[i-1];
        end
        wptr_sync <= {wptr_sync_reg[SYNC_STAGES-1], wptr_sync_reg[SYNC_STAGES-2:1]};
    end

    always @(posedge rclk) begin
        rptr_sync_reg[0] <= rptr_gray[ADDR_WIDTH:1];
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_sync_reg[i] <= rptr_sync_reg[i-1];
        end
        rptr_sync <= {rptr_sync_reg[SYNC_STAGES-1], rptr_sync_reg[SYNC_STAGES-2:1]};
    end

    always @(posedge wclk) begin
        wptr_gray_sync_reg[0] <= wptr_gray[ADDR_WIDTH:1];
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_gray_sync_reg[i] <= wptr_gray_sync_reg[i-1];
        end
        wptr_gray_sync <= {wptr_gray_sync_reg[SYNC_STAGES-1], wptr_gray_sync_reg[SYNC_STAGES-2:1]};
    end

    always @(posedge rclk) begin
        rptr_gray_sync_reg[0] <= rptr_gray[ADDR_WIDTH:1];
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_gray_sync_reg[i] <= rptr_gray_sync_reg[i-1];
        end
        rptr_gray_sync <= {rptr_gray_sync_reg[SYNC_STAGES-1], rptr_gray_sync_reg[SYNC_STAGES-2:1]};
    end

    always @(posedge rclk) begin
        rdata_reg <= mem[rptr];
    end

    always @(posedge wclk) begin
        waddr_reg <= wptr;
    end

    always @(posedge rclk) begin
        raddr_reg <= rptr;
    end

    always @(posedge wclk) begin
        wfull_reg <= (wptr_gray_sync == (rptr_sync ^ ((rptr_sync >> 1) ^ (1 << ADDR_WIDTH))));
    end

    always @(posedge rclk) begin
        rempty_reg <= (rptr_gray_sync == (wptr_sync ^ ((wptr_sync >> 1) ^ (1 << ADDR_WIDTH))));
    end

    assign wfull = wfull_reg;
    assign waddr = waddr_reg;
    assign rdata = rdata_reg;
    assign rempty = rempty_reg;
    assign raddr = raddr_reg;

endmodule
