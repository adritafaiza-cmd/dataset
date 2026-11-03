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
reg [LOG_DEPTH:0] src_cnt;
reg src_full;
reg src_empty;

reg [WIDTH-1:0] dst_fifo [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] dst_wr_ptr;
reg [LOG_DEPTH-1:0] dst_rd_ptr;
reg [LOG_DEPTH:0] dst_cnt;
reg dst_full;
reg dst_empty;

reg [WIDTH-1:0] dst_data_reg;
reg dst_valid_reg;

reg [LOG_DEPTH-1:0] gray_src_wr_ptr;
reg [LOG_DEPTH-1:0] gray_src_rd_ptr;
reg [LOG_DEPTH-1:0] gray_dst_wr_ptr;
reg [LOG_DEPTH-1:0] gray_dst_rd_ptr;

reg [SYNC_STAGES-1:0] src_clear_sync;
reg [SYNC_STAGES-1:0] dst_clear_sync;

reg src_clear_pending;
reg dst_clear_pending;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        src_wr_ptr <= 0;
        src_rd_ptr <= 0;
        src_cnt <= 0;
        src_full <= 0;
        src_empty <= 1;
        src_clear_pending <= 0;
    end else if (src_clear_i) begin
        src_wr_ptr <= 0;
        src_rd_ptr <= 0;
        src_cnt <= 0;
        src_full <= 0;
        src_empty <= 1;
        src_clear_pending <= 0;
    end else begin
        if (src_valid_i && ~src_full) begin
            src_fifo[src_wr_ptr] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1;
            src_cnt <= src_cnt + 1;
            if (src_cnt == 2**LOG_DEPTH - 1) begin
                src_full <= 1;
            end
        end
        if (dst_valid_o && dst_ready_i && ~src_empty) begin
            src_rd_ptr <= src_rd_ptr + 1;
            src_cnt <= src_cnt - 1;
            if (src_cnt == 0) begin
                src_empty <= 1;
            end
        end
        if (src_valid_i && ~src_full) begin
            src_clear_pending <= 1;
        end else if (~src_valid_i || src_full) begin
            src_clear_pending <= 0;
        end
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_wr_ptr <= 0;
        dst_rd_ptr <= 0;
        dst_cnt <= 0;
        dst_full <= 0;
        dst_empty <= 1;
        dst_clear_pending <= 0;
        dst_data_reg <= 0;
        dst_valid_reg <= 0;
    end else if (dst_clear_i) begin
        dst_wr_ptr <= 0;
        dst_rd_ptr <= 0;
        dst_cnt <= 0;
        dst_full <= 0;
        dst_empty <= 1;
        dst_clear_pending <= 0;
        dst_data_reg <= 0;
        dst_valid_reg <= 0;
    end else begin
        if (dst_valid_o && dst_ready_i && ~dst_empty) begin
            dst_rd_ptr <= dst_rd_ptr + 1;
            dst_cnt <= dst_cnt - 1;
            if (dst_cnt == 0) begin
                dst_empty <= 1;
            end
        end
        if (dst_valid_o && ~dst_empty) begin
            dst_data_reg <= dst_fifo[dst_rd_ptr];
            dst_valid_reg <= 1;
        end else begin
            dst_valid_reg <= 0;
        end
        if (dst_valid_o && dst_ready_i && ~dst_empty) begin
            dst_clear_pending <= 1;
        end else if (~dst_valid_o || dst_empty) begin
            dst_clear_pending <= 0;
        end
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        gray_src_wr_ptr <= 0;
        gray_src_rd_ptr <= 0;
    end else if (src_clear_i) begin
        gray_src_wr_ptr <= 0;
        gray_src_rd_ptr <= 0;
    end else begin
        gray_src_wr_ptr <= src_wr_ptr;
        gray_src_rd_ptr <= src_rd_ptr;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        gray_dst_wr_ptr <= 0;
        gray_dst_rd_ptr <= 0;
    end else if (dst_clear_i) begin
        gray_dst_wr_ptr <= 0;
        gray_dst_rd_ptr <= 0;
    end else begin
        gray_dst_wr_ptr <= dst_wr_ptr;
        gray_dst_rd_ptr <= dst_rd_ptr;
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        src_clear_sync <= 0;
    end else begin
        src_clear_sync[0] <= dst_clear_i;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            src_clear_sync[i] <= src_clear_sync[i-1];
        end
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_clear_sync <= 0;
    end else begin
        dst_clear_sync[0] <= src_clear_i;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            dst_clear_sync[i] <= dst_clear_sync[i-1];
        end
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_fifo <= 0;
    end else if (dst_clear_i) begin
        dst_fifo <= 0;
    end else if (src_valid_i && ~src_full && ~src_clear_i) begin
        dst_fifo[gray_src_wr_ptr] <= src_data_i;
    end
end

assign src_ready_o = ~src_full && ~src_clear_i;
assign dst_data_o = dst_data_reg;
assign dst_valid_o = dst_valid_reg;
assign src_clear_pending_o = src_clear_pending;
assign dst_clear_pending_o = dst_clear_pending;

endmodule
