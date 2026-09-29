module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
) (
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
reg [PTR_WIDTH-1:0] wr_ptr;
reg [PTR_WIDTH-1:0] wr_ptr_gray;
reg [PTR_WIDTH-1:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;

// Read domain signals
reg [PTR_WIDTH-1:0] rd_ptr;
reg [PTR_WIDTH-1:0] rd_ptr_gray;
reg [PTR_WIDTH-1:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;

// Memory
reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH)-1];

// Write domain logic
wire wr_en = src_valid_i && src_ready_o;

wire [PTR_WIDTH-1:0] wr_ptr_next = wr_ptr + wr_en;
wire [PTR_WIDTH-1:0] wr_ptr_next_gray = wr_ptr_next ^ (wr_ptr_next >> 1);

// Full condition
wire full;
assign full = (wr_ptr_next_gray == { ~rd_ptr_gray_sync2[PTR_WIDTH-1 -: 2], rd_ptr_gray_sync2[PTR_WIDTH-3 :0] });

// Synchronize read pointer's gray to write domain
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        rd_ptr_gray_sync1 <= 0;
        rd_ptr_gray_sync2 <= 0;
    end else begin
        rd_ptr_gray_sync1 <= rd_ptr_gray;
        rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    end
end

// Update write pointer and memory
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        wr_ptr <= 0;
        wr_ptr_gray <= 0;
    end else if (wr_en) begin
        wr_ptr <= wr_ptr_next;
        wr_ptr_gray <= wr_ptr_next_gray;
    end
end

// Memory write
always @(posedge src_clk_i) begin
    if (wr_en) begin
        mem[wr_ptr[PTR_WIDTH-2:0]] <= src_data_i;
    end
end

// Assign src_ready_o
assign src_ready_o = !full;

// Read domain logic
wire rd_en = dst_ready_i && dst_valid_o;

wire [PTR_WIDTH-1:0] rd_ptr_next = rd_ptr + rd_en;
wire [PTR_WIDTH-1:0] rd_ptr_next_gray = rd_ptr_next ^ (rd_ptr_next >> 1);

// Empty condition
wire empty;
assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);

// Synchronize write pointer's gray to read domain
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        wr_ptr_gray_sync1 <= 0;
        wr_ptr_gray_sync2 <= 0;
    end else begin
        wr_ptr_gray_sync1 <= wr_ptr_gray;
        wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    end
end

// Update read pointer
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        rd_ptr <= 0;
        rd_ptr_gray <= 0;
    end else if (rd_en) begin
        rd_ptr <= rd_ptr_next;
        rd_ptr_gray <= rd_ptr_next_gray;
    end
end

// Memory read
assign dst_data_o = mem[rd_ptr[PTR_WIDTH-2:0]];

// Assign dst_valid_o
assign dst_valid_o = !empty;

endmodule
