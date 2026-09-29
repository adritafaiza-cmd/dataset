module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input src_rst_ni,
    input src_clk_i,
    input [WIDTH-1:0] src_data_i,
    input src_valid_i,
    output src_ready_o,
    input dst_rst_ni,
    input dst_clk_i,
    output [WIDTH-1:0] dst_data_o,
    output dst_valid_o,
    input dst_ready_i
);

localparam PTR_WIDTH = LOG_DEPTH + 1;

// FIFO memory
reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH)-1];

// Write domain signals
reg [PTR_WIDTH-1:0] wptr_bin;
wire [PTR_WIDTH-1:0] wptr_gray;
reg [PTR_WIDTH-1:0] rptr_gray_sync1, rptr_gray_sync2;

// Read domain signals
reg [PTR_WIDTH-1:0] rptr_bin;
wire [PTR_WIDTH-1:0] rptr_gray;
reg [PTR_WIDTH-1:0] wptr_gray_sync1, wptr_gray_sync2;

// Gray to binary conversion function
function [PTR_WIDTH-1:0] gray2bin;
    input [PTR_WIDTH-1:0] gray;
    integer i;
    begin
        gray2bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
        for (i = PTR_WIDTH-2; i >= 0; i = i - 1)
            gray2bin[i] = gray2bin[i+1] ^ gray[i];
    end
endfunction

// Write domain logic
wire [PTR_WIDTH-1:0] rptr_bin_sync = gray2bin(rptr_gray_sync2);
wire full = ( (wptr_bin - rptr_bin_sync) >= (1 << LOG_DEPTH) );

assign src_ready_o = ~full;

// Update write pointer and Gray code
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        wptr_bin <= 0;
    end else if (src_valid_i && src_ready_o) begin
        wptr_bin <= wptr_bin + 1;
    end
end

assign wptr_gray = (wptr_bin >> 1) ^ wptr_bin;

// Synchronize read pointer's Gray code into write domain
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        rptr_gray_sync1 <= 0;
        rptr_gray_sync2 <= 0;
    end else begin
        rptr_gray_sync1 <= rptr_gray;
        rptr_gray_sync2 <= rptr_gray_sync1;
    end
end

// Memory write
always @(posedge src_clk_i) begin
    if (src_valid_i && src_ready_o) begin
        mem[wptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
    end
end

// Read domain logic
wire [PTR_WIDTH-1:0] wptr_bin_sync = gray2bin(wptr_gray_sync2);
wire empty = (rptr_bin == wptr_bin_sync);

assign dst_valid_o = ~empty;

// Update read pointer and Gray code
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        rptr_bin <= 0;
    end else if (dst_valid_o && dst_ready_i) begin
        rptr_bin <= rptr_bin + 1;
    end
end

assign rptr_gray = (rptr_bin >> 1) ^ rptr_bin;

// Synchronize write pointer's Gray code into read domain
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        wptr_gray_sync1 <= 0;
        wptr_gray_sync2 <= 0;
    end else begin
        wptr_gray_sync1 <= wptr_gray;
        wptr_gray_sync2 <= wptr_gray_sync1;
    end
end

// Data output
assign dst_data_o = mem[rptr_bin[LOG_DEPTH-1:0]];

endmodule
