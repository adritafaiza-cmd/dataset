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

reg [WIDTH-1:0]             fifo[2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0]        src_ptr;
reg [LOG_DEPTH-1:0]        dst_ptr;
reg [LOG_DEPTH-1:0]        src_ptr_gray;
reg [LOG_DEPTH-1:0]        dst_ptr_gray;
reg [LOG_DEPTH-1:0]        src_ptr_sync[SYNC_STAGES-1:0];
reg [LOG_DEPTH-1:0]        dst_ptr_sync[SYNC_STAGES-1:0];
reg                       src_full;
reg                       dst_empty;
reg                       src_ready;
reg                       dst_valid;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
    end else begin
        if (src_valid_i && src_ready) begin
            fifo[src_ptr] <= src_data_i;
            src_ptr <= src_ptr + 1;
            src_ptr_gray <= src_ptr_gray + 1;
        end
    end
end

always @(posedge src_clk_i) begin
    src_ptr_gray <= src_ptr_gray ^ (src_ptr_gray >> 1);
end

always @(posedge src_clk_i) begin
    src_full <= (src_ptr == (2**LOG_DEPTH - 1)) && (dst_ptr != 0);
end

always @(posedge src_clk_i) begin
    src_ready <= !src_full;
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
    end else begin
        if (dst_valid && dst_ready_i) begin
            dst_ptr <= dst_ptr + 1;
            dst_ptr_gray <= dst_ptr_gray + 1;
        end
    end
end

always @(posedge dst_clk_i) begin
    dst_ptr_gray <= dst_ptr_gray ^ (dst_ptr_gray >> 1);
end

always @(posedge dst_clk_i) begin
    dst_empty <= (dst_ptr == 0);
end

always @(posedge dst_clk_i) begin
    dst_valid <= !dst_empty;
end

always @(posedge src_clk_i) begin
    src_ptr_sync[0] <= src_ptr_gray;
end

generate
    for (genvar i = 1; i < SYNC_STAGES; i++) begin
        always @(posedge dst_clk_i) begin
            src_ptr_sync[i] <= src_ptr_sync[i-1];
        end
    end
endgenerate

always @(posedge dst_clk_i) begin
    dst_ptr_sync[0] <= dst_ptr_gray;
end

generate
    for (genvar i = 1; i < SYNC_STAGES; i++) begin
        always @(posedge src_clk_i) begin
            dst_ptr_sync[i] <= dst_ptr_sync[i-1];
        end
    end
endgenerate

assign src_ready_o = src_ready;
assign dst_data_o = fifo[dst_ptr_sync[SYNC_STAGES-1]];
assign dst_valid_o = dst_valid;

endmodule
