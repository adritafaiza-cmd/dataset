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

    // Write Domain
    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] wptr_gray;
    reg [ADDR_WIDTH-1:0] wptr_gray_sync;
    reg [DATA_WIDTH-1:0] fifo [2**ADDR_WIDTH-1:0];
    reg [ADDR_WIDTH:0] wcount;

    // Read Domain
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] rptr_gray;
    reg [ADDR_WIDTH-1:0] rptr_gray_sync;
    reg [ADDR_WIDTH:0] rcount;

    // CDC
    reg [SYNC_STAGES-1:0] wptr_gray_sync_reg;
    reg [SYNC_STAGES-1:0] rptr_gray_sync_reg;

    // Reset
    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            wptr_gray_sync <= 0;
            wcount <= 0;
        end else if (winc && ~wfull) begin
            wptr <= wptr + 1;
            wptr_gray <= gray_encode(wptr);
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rptr_gray_sync <= 0;
            rcount <= 0;
        end else if (rinc && ~rempty) begin
            rptr <= rptr + 1;
            rptr_gray <= gray_encode(rptr);
        end
    end

    // Gray Encoding
    function [ADDR_WIDTH-1:0] gray_encode;
        input [ADDR_WIDTH-1:0] bin;
        reg [ADDR_WIDTH-1:0] gray;
        begin
            gray = bin ^ (bin >> 1);
            gray_encode = gray;
        end
    endfunction

    // CDC Synchronization
    always @(posedge wclk) begin
        wptr_gray_sync_reg[0] <= wptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_gray_sync_reg[i] <= wptr_gray_sync_reg[i-1];
        end
        wptr_gray_sync <= wptr_gray_sync_reg[SYNC_STAGES-1];
    end

    always @(posedge rclk) begin
        rptr_gray_sync_reg[0] <= rptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_gray_sync_reg[i] <= rptr_gray_sync_reg[i-1];
        end
        rptr_gray_sync <= rptr_gray_sync_reg[SYNC_STAGES-1];
    end

    // FIFO Write
    always @(posedge wclk) begin
        if (winc && ~wfull) begin
            fifo[wptr] <= wdata;
        end
    end

    // FIFO Read
    always @(posedge rclk) begin
        if (rinc && ~rempty) begin
            rdata <= fifo[rptr];
        end
    end

    // Full and Empty Flags
    always @(posedge wclk) begin
        wcount <= wcount + (winc && ~wfull) - (rinc && ~rempty);
    end

    always @(posedge rclk) begin
        rcount <= rcount + (rinc && ~rempty) - (winc && ~wfull);
    end

    assign wfull = (wcount == (2**ADDR_WIDTH-1));
    assign rempty = (rcount == 0);

    // Debug Outputs
    assign waddr = {wcount, wptr};
    assign raddr = {rcount, rptr};

endmodule
