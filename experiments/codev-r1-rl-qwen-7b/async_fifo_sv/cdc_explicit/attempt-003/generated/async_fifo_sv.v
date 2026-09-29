module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
) (
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

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH)-1];

    // Write domain signals
    reg [ADDR_WIDTH:0] wptr_bin;
    reg [ADDR_WIDTH:0] wptr_gray;
    wire [ADDR_WIDTH:0] wbin_next;
    wire [ADDR_WIDTH:0] wgraynext;
    wire winc_effective;

    // Read domain signals
    reg [ADDR_WIDTH:0] rptr_bin;
    reg [ADDR_WIDTH:0] rptr_gray;
    wire [ADDR_WIDTH:0] rbin_next;
    wire [ADDR_WIDTH:0] rgraynext;
    wire rinc_effective;

    // Synchronization registers
    reg [ADDR_WIDTH:0] rptr_gray_sync1, rptr_gray_sync2;
    reg [ADDR_WIDTH:0] wptr_gray_sync1, wptr_gray_sync2;

    // Full and empty flags
    wire full, empty;

    // Binary to gray conversion function
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        begin
            bin2gray = (bin >> 1) ^ bin;
        end
    endfunction

    // Write pointer logic
    assign winc_effective = winc && !full;
    assign wbin_next = wptr_bin + winc_effective;
    assign wgraynext = bin2gray(wbin_next);

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin <= 0;
            wptr_gray <= 0;
        end else begin
            wptr_bin <= wbin_next;
            wptr_gray <= wgraynext;
        end
    end

    // Read pointer logic
    assign rinc_effective = rinc && !empty;
    assign rbin_next = rptr_bin + rinc_effective;
    assign rgraynext = bin2gray(rbin_next);

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin <= 0;
            rptr_gray <= 0;
        end else begin
            rptr_bin <= rbin_next;
            rptr_gray <= rgraynext;
        end
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync1 <= 0;
            rptr_gray_sync2 <= 0;
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync1 <= 0;
            wptr_gray_sync2 <= 0;
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    // Full condition
    assign full = (wgraynext == { ~rptr_gray_sync2[ADDR_WIDTH], ~rptr_gray_sync2[ADDR_WIDTH-1], rptr_gray_sync2[ADDR_WIDTH-2:0] });

    // Empty condition
    assign empty = (rptr_gray == wptr_gray_sync2);

    // Write data to memory
    always @(posedge wclk) begin
        if (winc_effective) begin
            mem[wptr_bin[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    // Read data from memory
    assign rdata = mem[rptr_bin[ADDR_WIDTH-1:0]];

    // Assign outputs
    assign wfull = full;
    assign rempty = empty;

    // Assign debug pointers
    assign waddr = wptr_bin;
    assign raddr = rptr_bin;

endmodule
