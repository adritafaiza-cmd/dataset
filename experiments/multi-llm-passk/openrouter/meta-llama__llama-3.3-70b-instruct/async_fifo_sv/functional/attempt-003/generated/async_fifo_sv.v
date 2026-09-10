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

    reg [ADDR_WIDTH-1:0] wptr, rptr;
    reg [ADDR_WIDTH-1:0] wptr_sync, rptr_sync;
    reg [DATA_WIDTH-1:0] fifo [2**ADDR_WIDTH-1:0];
    reg [ADDR_WIDTH:0] wcount, rcount;
    reg wfull_reg, rempty_reg;

    assign wfull = wfull_reg;
    assign rempty = rempty_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wcount <= 0;
            wfull_reg <= 0;
        end else if (winc && ~wfull_reg) begin
            fifo[wptr] <= wdata;
            wptr <= wptr + 1;
            wcount <= wcount + 1;
            if (wcount == 2**ADDR_WIDTH - 1) begin
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
            rcount <= rcount + 1;
            if (rcount == 1) begin
                rempty_reg <= 0;
            end
            if (rcount == 2**ADDR_WIDTH) begin
                rcount <= 0;
                rempty_reg <= 1;
            end
        end
    end

    always @(posedge wclk) begin
        waddr <= wptr;
    end

    always @(posedge rclk) begin
        raddr <= rptr;
    end

    // Synchronize wptr to rclk domain
    reg [SYNC_STAGES-1:0] wptr_sync_reg;
    always @(posedge rclk) begin
        wptr_sync_reg[0] <= wptr;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_sync_reg[i] <= wptr_sync_reg[i-1];
        end
        wptr_sync <= wptr_sync_reg[SYNC_STAGES-1];
    end

    // Synchronize rptr to wclk domain
    reg [SYNC_STAGES-1:0] rptr_sync_reg;
    always @(posedge wclk) begin
        rptr_sync_reg[0] <= rptr;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_sync_reg[i] <= rptr_sync_reg[i-1];
        end
        rptr_sync <= rptr_sync_reg[SYNC_STAGES-1];
    end

    // Update wfull and rempty based on synchronized pointers
    always @(posedge wclk) begin
        if (wptr_sync == wptr && wcount == 2**ADDR_WIDTH - 1) begin
            wfull_reg <= 1;
        end else if (wptr_sync != wptr) begin
            wfull_reg <= 0;
        end
    end

    always @(posedge rclk) begin
        if (rptr_sync == rptr && rcount == 0) begin
            rempty_reg <= 1;
        end else if (rptr_sync != rptr) begin
            rempty_reg <= 0;
        end
    end

endmodule
