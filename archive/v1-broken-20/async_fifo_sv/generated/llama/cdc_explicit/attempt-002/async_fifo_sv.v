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
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    reg [ADDR_WIDTH:0] wcount;

    // Read Domain
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] rptr_gray;
    reg [ADDR_WIDTH-1:0] rptr_gray_sync;
    reg [ADDR_WIDTH:0] rcount;

    // Synchronization
    reg [SYNC_STAGES-1:0] wptr_sync;
    reg [SYNC_STAGES-1:0] rptr_sync;

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
            wcount <= wcount + 1;
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
            rcount <= rcount - 1;
        end
    end

    // Synchronization
    always @(posedge wclk) begin
        wptr_sync[0] <= wptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    always @(posedge rclk) begin
        rptr_sync[0] <= rptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_sync[i] <= rptr_sync[i-1];
        end
    end

    // Data Write
    always @(posedge wclk) begin
        if (winc && ~wfull) begin
            mem[wptr] <= wdata;
        end
    end

    // Data Read
    always @(posedge rclk) begin
        if (rinc && ~rempty) begin
            rdata <= mem[rptr];
        end
    end

    // Full and Empty Flags
    assign wfull = (wcount == (2**ADDR_WIDTH));
    assign rempty = (rcount == 0);

    // Debug Outputs
    assign waddr = wptr;
    assign raddr = rptr;

    // Gray Encoding
    function [ADDR_WIDTH-1:0] gray_encode(input [ADDR_WIDTH-1:0] bin);
        gray_encode = (bin >> 1) ^ bin;
    endfunction

endmodule
