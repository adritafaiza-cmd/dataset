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
wire [PTR_WIDTH-1:0] wptr_gray;
wire [PTR_WIDTH-1:0] wgraynext;
reg [PTR_WIDTH-1:0] rptr_gray_sync1, rptr_gray_sync;

// Read domain signals
reg [PTR_WIDTH-1:0] rptr_bin;
wire [PTR_WIDTH-1:0] rptr_gray;
reg [PTR_WIDTH-1:0] wptr_gray_sync1, wptr_gray_sync;

// Memory
reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH)-1];

// Write pointer logic
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        wptr_bin <= 0;
    end else begin
        if (src_valid_i && src_ready_o) begin
            wptr_bin <= wptr_bin + 1;
        end
    end
end

// Convert to gray code
assign wptr_gray = (wptr_bin >> 1) ^ wptr_bin;

// Next write pointer's gray code
assign wgraynext = ((wptr_bin + 1) >> 1) ^ (wptr_bin + 1);

// Synchronize read pointer's gray to write domain
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        rptr_gray_sync1 <= 0;
        rptr_gray_sync <= 0;
    end else begin
        rptr_gray_sync1 <= rptr_gray;
        rptr_gray_sync <= rptr_gray_sync1;
    end
end

// Full condition
wire full;
assign full = (wgraynext == { ~rptr_gray_sync[PTR_WIDTH-1 : PTR_WIDTH-2], rptr_gray_sync[PTR_WIDTH-3 :0] });

// src_ready_o is !full
assign src_ready_o = !full;

// Memory write
always @(posedge src_clk_i) begin
    if (src_valid_i && src_ready_o) begin
        mem[wptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
    end
end

// Read pointer logic
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        rptr_bin <= 0;
    end else begin
        if (dst_valid_o && dst_ready_i) begin
            rptr_bin <= rptr_bin + 1;
        end
    end
end

// Convert read pointer to gray code
assign rptr_gray = (rptr_bin >> 1) ^ rptr_bin;

// Synchronize write pointer's gray to read domain
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        wptr_gray_sync1 <= 0;
        wptr_gray_sync <= 0;
    end else begin
        wptr_gray_sync1 <= wptr_gray;
        wptr_gray_sync <= wptr_gray_sync1;
    end
end

// Empty condition
wire empty;
assign empty = (rptr_gray == wptr_gray_sync);

// dst_valid_o is !empty
assign dst_valid_o = !empty;

// Memory read
assign dst_data_o = mem[rptr_bin[LOG_DEPTH-1:0]];

endmodule
