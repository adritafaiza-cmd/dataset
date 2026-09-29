module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
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

// Pointers in binary
reg [PTR_WIDTH-1:0] wptr, rptr;

// Gray code pointers
reg [PTR_WIDTH-1:0] wptr_gray, rptr_gray;

// Synchronization registers
reg [PTR_WIDTH-1:0] rptr_gray_sync [SYNC_STAGES-1:0];
reg [PTR_WIDTH-1:0] wptr_gray_sync [SYNC_STAGES-1:0];

// Memory
reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH)-1];

// Write domain signals
wire full;
wire [PTR_WIDTH-1:0] wptr_next = wptr + (src_valid_i & src_ready_o);
wire [PTR_WIDTH-1:0] wptr_gray_next = (wptr_next >> 1) ^ wptr_next;

// Read domain signals
wire empty;
wire [PTR_WIDTH-1:0] rptr_next = rptr + (dst_valid_o & dst_ready_i);
wire [PTR_WIDTH-1:0] rptr_gray_next = (rptr_next >> 1) ^ rptr_next;

// Synchronization processes
generate
genvar i;
for (i=0; i < SYNC_STAGES; i=i+1) begin : gen_sync_wptr
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wptr_gray_sync[i] <= 0;
        end else begin
            wptr_gray_sync[i] <= wptr_gray;
        end
    end
end
endgenerate

generate
for (i=0; i < SYNC_STAGES; i=i+1) begin : gen_sync_rptr
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rptr_gray_sync[i] <= 0;
        end else begin
            rptr_gray_sync[i] <= rptr_gray;
        end
    end
end
endgenerate

// Full condition in write domain
assign full = ( (wptr_gray_next[PTR_WIDTH-1] != wptr_gray_sync[SYNC_STAGES-1][PTR_WIDTH-1]) &&
                (wptr_gray_next[PTR_WIDTH-2] != wptr_gray_sync[SYNC_STAGES-1][PTR_WIDTH-2]) &&
                (wptr_gray_next[PTR_WIDTH-3:0] == wptr_gray_sync[SYNC_STAGES-1][PTR_WIDTH-3:0]) );

// Empty condition in read domain
assign empty = (rptr_gray == wptr_gray_sync[SYNC_STAGES-1]);

// Write domain logic
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        wptr <= 0;
        wptr_gray <= 0;
    end else begin
        if (src_valid_i && src_ready_o) begin
            wptr <= wptr_next;
            mem[wptr[PTR_WIDTH-2 : 0]] <= src_data_i;
        end
        wptr_gray <= wptr_gray_next;
    end
end

// Read domain logic
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        rptr <= 0;
        rptr_gray <= 0;
    end else begin
        if (dst_valid_o && dst_ready_i) begin
            rptr <= rptr_next;
        end
        rptr_gray <= rptr_gray_next;
    end
end

// Assign outputs
assign src_ready_o = !full;
assign dst_valid_o = !empty;
assign dst_data_o = mem[rptr[PTR_WIDTH-2 : 0]];

endmodule
