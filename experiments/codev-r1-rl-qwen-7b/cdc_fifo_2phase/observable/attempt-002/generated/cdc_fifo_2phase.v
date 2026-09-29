module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

localparam PTR_WIDTH = LOG_DEPTH + 1;

// Write domain signals
reg [PTR_WIDTH-1:0] wptr_bin;
reg [PTR_WIDTH-1:0] wptr_gray;
reg [PTR_WIDTH-1:0] rptr_bin_sync1, rptr_bin_sync2;

// Read domain signals
reg [PTR_WIDTH-1:0] rptr_bin;
reg [PTR_WIDTH-1:0] rptr_gray;
reg [PTR_WIDTH-1:0] wptr_bin_sync1, wptr_bin_sync2;

// Memory
reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH)-1];

// Full and empty signals
wire full, empty;

// Gray to binary conversion function
function [PTR_WIDTH-1:0] gray2bin;
input [PTR_WIDTH-1:0] gray;
integer i;
begin
    gray2bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
    for (i = PTR_WIDTH-2; i >=0; i = i -1)
        gray2bin[i] = gray2bin[i+1] ^ gray[i];
end
endfunction

// Binary to Gray conversion function
function [PTR_WIDTH-1:0] bin2gray;
input [PTR_WIDTH-1:0] bin;
begin
    bin2gray = (bin >> 1) ^ bin;
end
endfunction

// Write pointer logic
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        wptr_bin <= 0;
        wptr_gray <= 0;
    end else begin
        if (src_valid_i && src_ready_o) begin
            wptr_bin <= wptr_bin + 1;
            wptr_gray <= bin2gray(wptr_bin + 1);
        end
    end
end

// Synchronize read pointer to write domain (Gray)
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        rptr_bin_sync1 <= 0;
        rptr_bin_sync2 <= 0;
    end else begin
        rptr_bin_sync1 <= rptr_gray;
        rptr_bin_sync2 <= rptr_bin_sync1;
    end
end

// Full condition
wire [PTR_WIDTH-1:0] rptr_bin_sync = gray2bin(rptr_bin_sync2);
assign full = ( (wptr_bin[PTR_WIDTH-1] != rptr_bin_sync[PTR_WIDTH-1]) &&
                (wptr_bin[PTR_WIDTH-2:0] == rptr_bin_sync[PTR_WIDTH-2:0]) );

// Read pointer logic
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        rptr_bin <= 0;
        rptr_gray <= 0;
    end else begin
        if (dst_valid_o && dst_ready_i) begin
            rptr_bin <= rptr_bin + 1;
            rptr_gray <= bin2gray(rptr_bin + 1);
        end
    end
end

// Synchronize write pointer to read domain (Gray)
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        wptr_bin_sync1 <= 0;
        wptr_bin_sync2 <= 0;
    end else begin
        wptr_bin_sync1 <= wptr_gray;
        wptr_bin_sync2 <= wptr_bin_sync1;
    end
end

// Convert synchronized write pointer to binary
wire [PTR_WIDTH-1:0] wptr_bin_sync = gray2bin(wptr_bin_sync2);

// Empty condition
assign empty = (rptr_bin == wptr_bin_sync);

// Memory write
always @(posedge src_clk_i) begin
    if (src_valid_i && src_ready_o)
        mem[wptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
end

// Memory read
assign dst_data_o = mem[rptr_bin[LOG_DEPTH-1:0]];

// Assign outputs
assign src_ready_o = ~full;
assign dst_valid_o = ~empty;

endmodule
