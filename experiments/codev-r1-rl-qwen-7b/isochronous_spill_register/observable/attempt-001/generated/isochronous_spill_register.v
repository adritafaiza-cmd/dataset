module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output [WIDTH-1:0] dst_data_o
);

// FIFO memory
reg [WIDTH-1:0] mem [0:1];
reg [1:0] wptr, rptr;

// Synchronizers for pointers
reg [1:0] wptr_sync1, wptr_sync2;
reg [1:0] rptr_sync1, rptr_sync2;

// Full and empty conditions
wire full;
wire empty;

// Full when next write would make FIFO full (2 entries)
assign full = ( (wptr[1] != rptr_sync2[1]) && (wptr[0] == rptr_sync2[0]) );

// Empty when pointers are equal
assign empty = (wptr == rptr_sync2);

// Write pointer in src_clk domain
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        wptr <= 0;
    end else if (src_valid_i && src_ready_o) begin
        mem[wptr[0]] <= src_data_i;
        wptr <= wptr + 1;
    end
end

// Read pointer in dst_clk domain
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        rptr <= 0;
    end else if (dst_valid_o && dst_ready_i) begin
        rptr <= rptr + 1;
    end
end

// Synchronize write pointer to read domain
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        wptr_sync1 <= 0;
        wptr_sync2 <= 0;
    end else begin
        wptr_sync1 <= wptr;
        wptr_sync2 <= wptr_sync1;
    end
end

// Synchronize read pointer to write domain
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        rptr_sync1 <= 0;
        rptr_sync2 <= 0;
    end else begin
        rptr_sync1 <= rptr;
        rptr_sync2 <= rptr_sync1;
    end
end

// Assign outputs
assign src_ready_o = !full;
assign dst_valid_o = !empty;
assign dst_data_o = mem[rptr[0]];

endmodule
