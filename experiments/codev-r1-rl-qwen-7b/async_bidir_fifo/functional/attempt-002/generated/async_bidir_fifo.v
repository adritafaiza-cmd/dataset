module async_bidir_fifo #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
) (
    // a side
    input wire              a_clk,
    input wire              a_rst_n,
    input wire              a_winc,
    input wire [DSIZE-1:0]  a_wdata,
    input wire              a_rinc,
    output wire [DSIZE-1:0] a_rdata,
    output wire             a_full,
    output wire             a_afull,
    output wire             a_empty,
    output wire             a_aempty,
    input wire              a_dir,
    // b side
    input wire              b_clk,
    input wire              b_rst_n,
    input wire              b_winc,
    input wire [DSIZE-1:0]  b_wdata,
    input wire              b_rinc,
    output wire [DSIZE-1:0] b_rdata,
    output wire             b_full,
    output wire             b_afull,
    output wire             b_empty,
    output wire             b_aempty,
    input wire              b_dir
);

localparam FIFO_DEPTH = 1 << ASIZE;
localparam PTR_WIDTH = ASIZE + 1;

// Memory
reg [DSIZE-1:0] mem [0:FIFO_DEPTH-1];

// Pointers and Gray code
reg [PTR_WIDTH-1:0] wptr_a, rptr_a; // a side pointers
reg [PTR_WIDTH-1:0] wptr_b, rptr_b; // b side pointers

// Convert binary to gray
function [PTR_WIDTH-1:0] bin2gray;
input [PTR_WIDTH-1:0] bin;
begin
    bin2gray = bin ^ (bin >> 1);
end
endfunction

// Convert gray to binary
function [PTR_WIDTH-1:0] gray2bin;
input [PTR_WIDTH-1:0] gray;
reg [PTR_WIDTH-1:0] bin;
integer i;
begin
    bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
    for (i = PTR_WIDTH-2; i >=0; i=i-1)
        bin[i] = bin[i+1] ^ gray[i];
    gray2bin = bin;
end
endfunction

// a_clk domain logic
reg [PTR_WIDTH-1:0] wptr_a_bin, rptr_a_bin;
reg [PTR_WIDTH-1:0] wptr_a_gray, rptr_a_gray;

always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
        wptr_a_bin <= 0;
        rptr_a_bin <= 0;
        wptr_a_gray <= 0;
        rptr_a_gray <= 0;
    end else begin
        // Handle writes from a side
        if (a_dir && a_winc && !a_full) begin
            mem[wptr_a_bin[PTR_WIDTH-2:0]] <= a_wdata;
            wptr_a_bin <= wptr_a_bin + 1;
            wptr_a_gray <= bin2gray(wptr_a_bin + 1);
        end

        // Handle reads from b side
        if (b_dir && b_rinc && !b_empty) begin
            rptr_a_bin <= rptr_a_bin + 1;
            rptr_a_gray <= bin2gray(rptr_a_bin + 1);
        end
    end
end

// b_clk domain logic
reg [PTR_WIDTH-1:0] wptr_b_bin, rptr_b_bin;
reg [PTR_WIDTH-1:0] wptr_b_gray, rptr_b_gray;

always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
        wptr_b_bin <= 0;
        rptr_b_bin <= 0;
        wptr_b_gray <= 0;
        rptr_b_gray <= 0;
    end else begin
        // Handle writes from b side
        if (b_dir && b_winc && !b_full) begin
            mem[wptr_b_bin[PTR_WIDTH-2:0]] <= b_wdata;
            wptr_b_bin <= wptr_b_bin + 1;
            wptr_b_gray <= bin2gray(wptr_b_bin + 1);
        end

        // Handle reads from a side
        if (a_dir && a_rinc && !a_empty) begin
            rptr_b_bin <= rptr_b_bin + 1;
            rptr_b_gray <= bin2gray(rptr_b_bin + 1);
        end
    end
end

// Synchronize pointers across domains
reg [PTR_WIDTH-1:0] wptr_a_sync_b [2:0];
reg [PTR_WIDTH-1:0] rptr_a_sync_b [2:0];
reg [PTR_WIDTH-1:0] wptr_b_sync_a [2:0];
reg [PTR_WIDTH-1:0] rptr_b_sync_a [2:0];

always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
        wptr_a_sync_b[0] <= 0;
        wptr_a_sync_b[1] <= 0;
        rptr_a_sync_b[0] <= 0;
        rptr_a_sync_b[1] <= 0;
    end else begin
        wptr_a_sync_b[0] <= wptr_a_gray;
        wptr_a_sync_b[1] <= wptr_a_sync_b[0];
        rptr_a_sync_b[0] <= rptr_a_gray;
        rptr_a_sync_b[1] <= rptr_a_sync_b[0];
    end
end

always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
        wptr_b_sync_a[0] <= 0;
        wptr_b_sync_a[1] <= 0;
        rptr_b_sync_a[0] <= 0;
        rptr_b_sync_a[1] <= 0;
    end else begin
        wptr_b_sync_a[0] <= wptr_b_gray;
        wptr_b_sync_a[1] <= wptr_b_sync_a[0];
        rptr_b_sync_a[0] <= rptr_b_gray;
        rptr_b_sync_a[1] <= rptr_b_sync_a[0];
    end
end

// Full and empty conditions
wire [PTR_WIDTH-1:0] wptr_a_bin_sync = gray2bin(wptr_b_sync_a[1]);
wire [PTR_WIDTH-1:0] rptr_a_bin_sync = gray2bin(rptr_b_sync_a[1]);
assign a_full = (wptr_a_bin_sync - rptr_a_bin) >= FIFO_DEPTH;
assign a_empty = (rptr_a_bin == wptr_a_bin_sync);

wire [PTR_WIDTH-1:0] wptr_b_bin_sync = gray2bin(wptr_a_sync_b[1]);
wire [PTR_WIDTH-1:0] rptr_b_bin_sync = gray2bin(rptr_a_sync_b[1]);
assign b_full = (wptr_b_bin_sync - rptr_b_bin) >= FIFO_DEPTH;
assign b_empty = (rptr_b_bin == wptr_b_bin_sync);

// Almost full and empty (same as full and empty if not FALLTHROUGH)
assign a_afull = a_full;
assign a_aempty = a_empty;
assign b_afull = b_full;
assign b_aempty = b_empty;

// Read data
assign a_rdata = mem[rptr_a_bin[PTR_WIDTH-2:0]];
assign b_rdata = mem[rptr_b_bin[PTR_WIDTH-2:0]];

endmodule
