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

    // Write domain
    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] wptr_gray;
    reg [ADDR_WIDTH-1:0] wptr_bin;
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];

    // Read domain
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] rptr_gray;
    reg [ADDR_WIDTH-1:0] rptr_bin;
    reg [DATA_WIDTH-1:0] rdata_reg;

    // Synchronization signals
    reg [SYNC_STAGES-1:0] wptr_sync;
    reg [SYNC_STAGES-1:0] rptr_sync;

    // Reset logic
    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            wptr_bin <= 0;
            wfull <= 0;
        end else if (winc && ~wfull) begin
            wptr <= wptr + 1;
            wptr_gray <= gray_encode(wptr);
            wptr_bin <= bin_encode(wptr);
            mem[wptr_bin] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rptr_bin <= 0;
            rempty <= 1;
        end else if (rinc && ~rempty) begin
            rptr <= rptr + 1;
            rptr_gray <= gray_encode(rptr);
            rptr_bin <= bin_encode(rptr);
            rdata_reg <= mem[rptr_bin];
        end
    end

    // Synchronization logic
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

    // Output logic
    assign waddr = wptr_bin;
    assign raddr = rptr_bin;
    assign rdata = rdata_reg;
    assign wfull = (wptr_bin == (2**ADDR_WIDTH-1));
    assign rempty = (rptr_bin == wptr_bin);

    // Helper functions
    function [ADDR_WIDTH-1:0] gray_encode(input [ADDR_WIDTH-1:0] bin);
        gray_encode = (bin >> 1) ^ bin;
    endfunction

    function [ADDR_WIDTH-1:0] bin_encode(input [ADDR_WIDTH-1:0] gray);
        bin_encode = gray ^ (gray >> 1);
    endfunction

endmodule
