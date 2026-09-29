module async_fifo #(
    parameter DSIZE = 8,
    parameter ASIZE = 4,
    parameter FALLTHROUGH = "TRUE"
) (
    input wire wclk,
    input wire wrst_n,
    input wire winc,
    input wire [DSIZE-1:0] wdata,
    output wire wfull,
    output wire awfull,
    input wire rclk,
    input wire rrst_n,
    input wire rinc,
    output wire [DSIZE-1:0] rdata,
    output wire rempty,
    output wire arempty
);

localparam ADDR_WIDTH = ASIZE;

// Pointers and Gray codes
reg [ADDR_WIDTH:0] wptr_bin, rptr_bin;
wire [ADDR_WIDTH:0] wptr_gray, rptr_gray;
reg [ADDR_WIDTH:0] rptr_gray_sync1, rptr_gray_sync2;
reg [ADDR_WIDTH:0] wptr_gray_sync1, wptr_gray_sync2;

// Synchronized pointers in binary
wire [ADDR_WIDTH:0] rptr_bin_sync, wptr_bin_sync;

// Memory
reg [DSIZE-1:0] mem [0:(1 << ADDR_WIDTH)-1];

// Write domain logic
wire wfull_next = (wptr_bin - rptr_bin_sync) >= (1 << ADDR_WIDTH);
wire awfull_next = (wptr_bin - rptr_bin_sync) >= ((1 << ADDR_WIDTH) - 1);

// Read domain logic
wire rempty_next = (wptr_bin_sync == rptr_bin);
wire arempty_next = (wptr_bin_sync - rptr_bin) <= 1;

// Convert binary to Gray code
function [ADDR_WIDTH:0] bin2gray(input [ADDR_WIDTH:0] bin);
    bin2gray = bin ^ (bin >> 1);
endfunction

// Convert Gray code to binary
function [ADDR_WIDTH:0] gray2bin(input [ADDR_WIDTH:0] gray);
    reg [ADDR_WIDTH:0] bin;
    integer i;
    begin
        bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
        for (i = ADDR_WIDTH-1; i >= 0; i = i - 1)
            bin[i] = bin[i+1] ^ gray[i];
        gray2bin = bin;
    end
endfunction

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

assign rptr_bin_sync = gray2bin(rptr_gray_sync2);

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

assign wptr_bin_sync = gray2bin(wptr_gray_sync2);

// Gray code conversions
assign wptr_gray = bin2gray(wptr_bin);
assign rptr_gray = bin2gray(rptr_bin);

// Full and empty assignments
assign wfull = wfull_next;
assign awfull = awfull_next;
assign rempty = rempty_next;
assign arempty = arempty_next;

// Write pointer update
always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
        wptr_bin <= 0;
    end else if (winc && !wfull) begin
        wptr_bin <= wptr_bin + 1;
        mem[wptr_bin[ADDR_WIDTH-1:0]] <= wdata;
    end
end

// Read pointer update
always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
        rptr_bin <= 0;
    end else if (rinc && !rempty) begin
        rptr_bin <= rptr_bin + 1;
    end
end

// Read data logic
generate
    if (FALLTHROUGH == "TRUE") begin
        assign rdata = mem[rptr_bin[ADDR_WIDTH-1:0]];
    end else begin
        reg [DSIZE-1:0] rdata_reg;
        always @(posedge rclk or negedge rrst_n) begin
            if (!rrst_n) begin
                rdata_reg <= 0;
            end else if (rinc && !rempty) begin
                rdata_reg <= mem[rptr_bin[ADDR_WIDTH-1:0]];
            end
        end
        assign rdata = rdata_reg;
    end
endgenerate

endmodule
