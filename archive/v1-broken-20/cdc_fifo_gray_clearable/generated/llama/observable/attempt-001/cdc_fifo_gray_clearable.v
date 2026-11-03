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

reg [WIDTH-1:0] fifo[2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] src_ptr;
reg [LOG_DEPTH-1:0] dst_ptr;
reg [LOG_DEPTH:0] src_cnt;
reg [LOG_DEPTH:0] dst_cnt;
reg src_clear_pending;
reg dst_clear_pending;

reg [WIDTH-1:0] src_data_reg;
reg src_valid_reg;

reg [WIDTH-1:0] dst_data_reg;
reg dst_valid_reg;

wire src_full;
wire src_empty;
wire dst_full;
wire dst_empty;

assign src_full = (src_cnt == 2**LOG_DEPTH);
assign src_empty = (src_cnt == 0);
assign dst_full = (dst_cnt == 2**LOG_DEPTH);
assign dst_empty = (dst_cnt == 0);

assign src_ready_o = ~src_full;
assign dst_valid_o = ~dst_empty;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        src_ptr <= 0;
        src_cnt <= 0;
        src_clear_pending <= 0;
    end else if (src_clear_i) begin
        src_ptr <= 0;
        src_cnt <= 0;
        src_clear_pending <= 0;
    end else if (src_valid_i && ~src_full) begin
        fifo[src_ptr] <= src_data_i;
        src_ptr <= src_ptr + 1;
        src_cnt <= src_cnt + 1;
    end else if (~src_empty && src_ready_o) begin
        src_cnt <= src_cnt - 1;
    end
end

always @(posedge src_clk_i) begin
    if (src_clear_i) begin
        src_clear_pending <= 1;
    end else if (src_valid_i && ~src_full) begin
        src_clear_pending <= 0;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_ptr <= 0;
        dst_cnt <= 0;
        dst_clear_pending <= 0;
    end else if (dst_clear_i) begin
        dst_ptr <= 0;
        dst_cnt <= 0;
        dst_clear_pending <= 0;
    end else if (~dst_empty && dst_ready_i) begin
        dst_cnt <= dst_cnt - 1;
    end
end

always @(posedge dst_clk_i) begin
    if (dst_clear_i) begin
        dst_clear_pending <= 1;
    end else if (~dst_empty && dst_ready_i) begin
        dst_clear_pending <= 0;
    end
end

reg [LOG_DEPTH-1:0] gray_src_ptr;
reg [LOG_DEPTH-1:0] gray_dst_ptr;

always @(posedge src_clk_i) begin
    gray_src_ptr <= src_ptr;
end

always @(posedge dst_clk_i) begin
    gray_dst_ptr <= dst_ptr;
end

reg [SYNC_STAGES-1:0] src_clear_sync;
reg [SYNC_STAGES-1:0] dst_clear_sync;

always @(posedge dst_clk_i) begin
    src_clear_sync[0] <= src_clear_i;
    for (genvar i = 1; i < SYNC_STAGES; i++) begin
        src_clear_sync[i] <= src_clear_sync[i-1];
    end
end

always @(posedge src_clk_i) begin
    dst_clear_sync[0] <= dst_clear_i;
    for (genvar i = 1; i < SYNC_STAGES; i++) begin
        dst_clear_sync[i] <= dst_clear_sync[i-1];
    end
end

always @(posedge dst_clk_i) begin
    if (src_clear_sync[SYNC_STAGES-1]) begin
        dst_ptr <= 0;
        dst_cnt <= 0;
    end else if (~dst_empty && dst_ready_i) begin
        dst_data_reg <= fifo[dst_ptr];
        dst_valid_reg <= 1;
        dst_ptr <= dst_ptr + 1;
    end else begin
        dst_valid_reg <= 0;
    end
end

always @(posedge src_clk_i) begin
    if (dst_clear_sync[SYNC_STAGES-1]) begin
        src_ptr <= 0;
        src_cnt <= 0;
    end
end

assign dst_data_o = dst_data_reg;
assign src_clear_pending_o = src_clear_pending;
assign dst_clear_pending_o = dst_clear_pending;

endmodule
