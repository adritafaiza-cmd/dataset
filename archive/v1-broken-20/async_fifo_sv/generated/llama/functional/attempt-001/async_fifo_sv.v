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

    // Write domain logic
    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] wptr_gray;
    reg [ADDR_WIDTH-1:0] wptr_bin;
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            wfull <= 1'b0;
        end else if (winc && ~wfull) begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1;
            wptr_gray <= gray_encode(wptr);
        end
    end

    assign waddr = wptr;

    // Gray encoding function
    function [ADDR_WIDTH-1:0] gray_encode;
        input [ADDR_WIDTH-1:0] bin;
        reg [ADDR_WIDTH-1:0] gray;
        begin
            gray = bin ^ (bin >> 1);
            gray_encode = gray;
        end
    endfunction

    // Read domain logic
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] rptr_gray;
    reg [ADDR_WIDTH-1:0] rptr_bin;
    reg [DATA_WIDTH-1:0] rdata_reg;

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rempty <= 1'b1;
            rdata_reg <= 0;
        end else if (rinc && ~rempty) begin
            rdata_reg <= mem[rptr];
            rptr <= rptr + 1;
            rptr_gray <= gray_encode(rptr);
        end
    end

    assign rdata = rdata_reg;
    assign raddr = rptr;

    // Synchronization logic
    reg [SYNC_STAGES-1:0] wptr_sync;
    reg [SYNC_STAGES-1:0] rptr_sync;

    always @(posedge rclk) begin
        wptr_sync[0] <= wptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    always @(posedge wclk) begin
        rptr_sync[0] <= rptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_sync[i] <= rptr_sync[i-1];
        end
    end

    assign wfull = (wptr_gray == (rptr_sync[SYNC_STAGES-1] + 1));
    assign rempty = (rptr_gray == wptr_sync[SYNC_STAGES-1]);

endmodule
