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

    localparam DEPTH = 1 << ADDR_WIDTH;

    // Write domain
    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] wptr_gray;
    reg [ADDR_WIDTH:0] rptr_gray_sync;
    reg [ADDR_WIDTH:0] rptr_gray_sync_next;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Read domain
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] rptr_gray;
    reg [ADDR_WIDTH:0] wptr_gray_sync;
    reg [ADDR_WIDTH:0] wptr_gray_sync_next;
    reg [DATA_WIDTH-1:0] rdata_reg;

    // Binary to Gray conversion
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        begin
            bin2gray = (bin >> 1) ^ bin;
        end
    endfunction

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            rptr_gray_sync <= 0;
            rptr_gray_sync_next <= 0;
        end else begin
            // Synchronize read pointer gray code
            rptr_gray_sync_next <= rptr_gray_sync;
            rptr_gray_sync <= rptr_gray;

            // Write data
            if (winc && !wfull) begin
                mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
                wptr <= wptr + 1;
            end

            // Update gray code pointer
            wptr_gray <= bin2gray(wptr + (winc && !wfull ? 1 : 0));
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            wptr_gray_sync <= 0;
            wptr_gray_sync_next <= 0;
            rdata_reg <= 0;
        end else begin
            // Synchronize write pointer gray code
            wptr_gray_sync_next <= wptr_gray_sync;
            wptr_gray_sync <= wptr_gray;

            // Read data
            if (rinc && !rempty) begin
                rdata_reg <= mem[rptr[ADDR_WIDTH-1:0]];
                rptr <= rptr + 1;
            end

            // Update gray code pointer
            rptr_gray <= bin2gray(rptr + (rinc && !rempty ? 1 : 0));
        end
    end

    // Full condition: write pointer gray code equals read pointer gray code with MSB different
    assign wfull = (wptr_gray == rptr_gray_sync) && (wptr[ADDR_WIDTH] != rptr_gray_sync[ADDR_WIDTH]);

    // Empty condition: read pointer gray code equals write pointer gray code
    assign rempty = (rptr_gray == wptr_gray_sync);

    // Outputs
    assign waddr = wptr;
    assign raddr = rptr;
    assign rdata = rdata_reg;

endmodule
