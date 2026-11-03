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

reg [WIDTH-1:0] src_fifo [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] src_wr_ptr;
reg [LOG_DEPTH-1:0] src_rd_ptr;
reg [LOG_DEPTH:0] src_count;
reg src_clear_pending;

reg [WIDTH-1:0] dst_fifo [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] dst_wr_ptr;
reg [LOG_DEPTH-1:0] dst_rd_ptr;
reg [LOG_DEPTH:0] dst_count;
reg dst_clear_pending;

reg [WIDTH-1:0] gray_data;
reg [WIDTH-1:0] sync_data [SYNC_STAGES-1:0];

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_wr_ptr <= 0;
        src_rd_ptr <= 0;
        src_count <= 0;
        src_clear_pending <= 0;
    end else if (src_clear_i) begin
        src_wr_ptr <= 0;
        src_rd_ptr <= 0;
        src_count <= 0;
        src_clear_pending <= 0;
    end else if (src_valid_i && src_ready_o) begin
        src_fifo[src_wr_ptr] <= src_data_i;
        src_wr_ptr <= src_wr_ptr + 1;
        src_count <= src_count + 1;
    end else if (src_count > 0 && !src_ready_o) begin
        src_rd_ptr <= src_rd_ptr + 1;
        src_count <= src_count - 1;
    end
end

always @(posedge src_clk_i) begin
    src_ready_o <= (src_count < 2**LOG_DEPTH);
    src_clear_pending_o <= src_clear_pending;
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_wr_ptr <= 0;
        dst_rd_ptr <= 0;
        dst_count <= 0;
        dst_clear_pending <= 0;
    end else if (dst_clear_i) begin
        dst_wr_ptr <= 0;
        dst_rd_ptr <= 0;
        dst_count <= 0;
        dst_clear_pending <= 0;
    end else if (dst_count < 2**LOG_DEPTH && gray_data != 0) begin
        dst_fifo[dst_wr_ptr] <= gray_data;
        dst_wr_ptr <= dst_wr_ptr + 1;
        dst_count <= dst_count + 1;
    end else if (dst_count > 0 && dst_ready_i) begin
        dst_rd_ptr <= dst_rd_ptr + 1;
        dst_count <= dst_count - 1;
    end
end

always @(posedge dst_clk_i) begin
    dst_valid_o <= (dst_count > 0);
    dst_data_o <= dst_fifo[dst_rd_ptr];
    dst_clear_pending_o <= dst_clear_pending;
end

always @(posedge src_clk_i) begin
    if (src_clear_i) begin
        gray_data <= 0;
    end else if (src_valid_i && src_ready_o) begin
        gray_data <= src_data_i;
    end
end

always @(posedge src_clk_i) begin
    sync_data[0] <= gray_data;
end

generate
    for (genvar i = 1; i < SYNC_STAGES; i++) begin
        always @(posedge dst_clk_i) begin
            sync_data[i] <= sync_data[i-1];
        end
    end
endgenerate

always @(posedge dst_clk_i) begin
    gray_data <= sync_data[SYNC_STAGES-1];
end

endmodule
