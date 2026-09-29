module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

localparam DEPTH = 1 << LOG_DEPTH;

// Source domain signals
reg [LOG_DEPTH:0] src_wr_ptr, src_rd_ptr_synced;
reg [LOG_DEPTH:0] src_wr_ptr_gray;
reg [LOG_DEPTH:0] dst_rd_ptr_gray_synced [SYNC_STAGES:0];
wire empty;

// Destination domain signals
reg [LOG_DEPTH:0] dst_rd_ptr, dst_wr_ptr_synced;
reg [LOG_DEPTH:0] dst_rd_ptr_gray;
reg [LOG_DEPTH:0] src_wr_ptr_gray_synced [SYNC_STAGES:0];
wire full;

// Memory
reg [WIDTH-1:0] mem [0:DEPTH-1];

// Gray code conversion
function [LOG_DEPTH:0] gray_encode(input [LOG_DEPTH:0] bin);
    gray_encode = (bin >> 1) ^ bin;
endfunction

function [LOG_DEPTH:0] gray_decode(input [LOG_DEPTH:0] gray);
    reg [LOG_DEPTH:0] bin;
    integer i;
    begin
        bin[LOG_DEPTH] = gray[LOG_DEPTH];
        for (i = LOG_DEPTH-1; i >=0; i=i-1)
            bin[i] = bin[i+1] ^ gray[i];
        gray_decode = bin;
    end
endfunction

// Clear synchronization
reg [SYNC_STAGES:0] dst_clear_sync;
reg [SYNC_STAGES:0] src_clear_sync_dst;
wire src_clear_synced = dst_clear_sync[SYNC_STAGES];
wire dst_clear_synced = src_clear_sync_dst[SYNC_STAGES];

// Synchronize dst_clear to source domain
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) dst_clear_sync <= 0;
    else begin
        dst_clear_sync[0] <= dst_clear_i;
        for (int i=1; i<=SYNC_STAGES; i++) dst_clear_sync[i] <= dst_clear_sync[i-1];
    end
end

// Synchronize src_clear to destination domain
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) src_clear_sync_dst <= 0;
    else begin
        src_clear_sync_dst[0] <= src_clear_i;
        for (int i=1; i<=SYNC_STAGES; i++) src_clear_sync_dst[i] <= src_clear_sync_dst[i-1];
    end
end

// Source domain write pointer
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_wr_ptr <= 0;
        src_wr_ptr_gray <= 0;
    end else if (src_clear_synced) begin
        src_wr_ptr <= 0;
        src_wr_ptr_gray <= 0;
    end else if (src_valid_i && src_ready_o) begin
        src_wr_ptr <= src_wr_ptr + 1;
        src_wr_ptr_gray <= gray_encode(src_wr_ptr + 1);
    end
end

// Destination domain read pointer
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_rd_ptr <= 0;
        dst_rd_ptr_gray <= 0;
    end else if (dst_clear_synced) begin
        dst_rd_ptr <= 0;
        dst_rd_ptr_gray <= 0;
    end else if (dst_valid_o && dst_ready_i) begin
        dst_rd_ptr <= dst_rd_ptr + 1;
        dst_rd_ptr_gray <= gray_encode(dst_rd_ptr + 1);
    end
end

// Synchronize read pointer to source domain
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) dst_rd_ptr_gray_synced[0] <= 0;
    else begin
        dst_rd_ptr_gray_synced[0] <= dst_rd_ptr_gray;
        for (int i=1; i<=SYNC_STAGES; i++) dst_rd_ptr_gray_synced[i] <= dst_rd_ptr_gray_synced[i-1];
    end
end

// Synchronize write pointer to destination domain
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) src_wr_ptr_gray_synced[0] <= 0;
    else begin
        src_wr_ptr_gray_synced[0] <= src_wr_ptr_gray;
        for (int i=1; i<=SYNC_STAGES; i++) src_wr_ptr_gray_synced[i] <= src_wr_ptr_gray_synced[i-1];
    end
end

// Memory write
always @(posedge src_clk_i) begin
    if (src_valid_i && src_ready_o)
        mem[gray_decode(src_wr_ptr_gray)] <= src_data_i;
end

// Memory read
assign dst_data_o = mem[gray_decode(dst_rd_ptr_gray)];

// Full and empty conditions
assign empty = (src_wr_ptr == gray_decode(dst_rd_ptr_gray_synced));
assign full = (gray_decode(src_wr_ptr_gray) - gray_decode(src_wr_ptr_gray_synced)) >= DEPTH;

// Valid/ready assignments
assign src_ready_o = !full && !src_clear_synced;
assign dst_valid_o = !empty;

// Pending signals
reg src_clear_pending, dst_clear_pending;

// Source pending
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) src_clear_pending <= 0;
    else begin
        if (src_clear_synced) src_clear_pending <= 1;
        else if (empty) src_clear_pending <= 0;
    end
end
assign src_clear_pending_o = src_clear_pending;

// Destination pending
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) dst_clear_pending <= 0;
    else begin
        if (dst_clear_synced) dst_clear_pending <= 1;
        else if (empty) dst_clear_pending <= 0;
    end
end
assign dst_clear_pending_o = dst_clear_pending;

endmodule
