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

    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] wptr_sync;
    reg [ADDR_WIDTH-1:0] rptr_sync;
    reg [DATA_WIDTH-1:0] fifo [2**ADDR_WIDTH-1:0];
    reg [ADDR_WIDTH:0] wcount;
    reg [ADDR_WIDTH:0] rcount;
    reg [ADDR_WIDTH:0] wcount_sync;
    reg [ADDR_WIDTH:0] rcount_sync;
    reg wfull_reg;
    reg rempty_reg;

    assign wfull = wfull_reg;
    assign rempty = rempty_reg;
    assign waddr = {wcount[ADDR_WIDTH], wptr};
    assign raddr = {rcount[ADDR_WIDTH], rptr};

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wcount <= 0;
            wfull_reg <= 0;
        end else if (winc && ~wfull_reg) begin
            fifo[wptr] <= wdata;
            wptr <= wptr + 1;
            wcount <= wcount + 1;
            if (wcount == (2**ADDR_WIDTH - 1)) begin
                wfull_reg <= 1;
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rcount <= 0;
            rempty_reg <= 1;
        end else if (rinc && ~rempty_reg) begin
            rdata <= fifo[rptr];
            rptr <= rptr + 1;
            rcount <= rcount - 1;
            if (rcount == 0) begin
                rempty_reg <= 1;
            end
        end
    end

    // CDC for wptr
    reg [SYNC_STAGES-1:0] wptr_sync_reg [ADDR_WIDTH-1:0];
    always @(posedge rclk) begin
        wptr_sync_reg[0] <= wptr;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_sync_reg[i] <= wptr_sync_reg[i-1];
        end
        wptr_sync <= wptr_sync_reg[SYNC_STAGES-1];
    end

    // CDC for rptr
    reg [SYNC_STAGES-1:0] rptr_sync_reg [ADDR_WIDTH-1:0];
    always @(posedge wclk) begin
        rptr_sync_reg[0] <= rptr;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_sync_reg[i] <= rptr_sync_reg[i-1];
        end
        rptr_sync <= rptr_sync_reg[SYNC_STAGES-1];
    end

    // CDC for wcount
    reg [SYNC_STAGES-1:0] wcount_sync_reg [ADDR_WIDTH:0];
    always @(posedge rclk) begin
        wcount_sync_reg[0] <= wcount;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wcount_sync_reg[i] <= wcount_sync_reg[i-1];
        end
        wcount_sync <= wcount_sync_reg[SYNC_STAGES-1];
    end

    // CDC for rcount
    reg [SYNC_STAGES-1:0] rcount_sync_reg [ADDR_WIDTH:0];
    always @(posedge wclk) begin
        rcount_sync_reg[0] <= rcount;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rcount_sync_reg[i] <= rcount_sync_reg[i-1];
        end
        rcount_sync <= rcount_sync_reg[SYNC_STAGES-1];
    end

    // Update rempty
    always @(posedge rclk) begin
        if (~rrst_n) begin
            rempty_reg <= 1;
        end else if (wcount_sync[ADDR_WIDTH] != rcount[ADDR_WIDTH] || wptr_sync != rptr) begin
            rempty_reg <= 0;
        end
    end

    // Update wfull
    always @(posedge wclk) begin
        if (~wrst_n) begin
            wfull_reg <= 0;
        end else if (wcount[ADDR_WIDTH] != rcount_sync[ADDR_WIDTH] && wcount == (2**ADDR_WIDTH - 1)) begin
            wfull_reg <= 1;
        end else if (wcount[ADDR_WIDTH] != rcount_sync[ADDR_WIDTH] && wptr == rptr_sync) begin
            wfull_reg <= 0;
        end
    end

endmodule
