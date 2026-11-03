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

localparam DEPTH = 2 ** LOG_DEPTH;

reg [WIDTH-1:0] mem [DEPTH-1:0];
reg [LOG_DEPTH-1:0] src_ptr, dst_ptr;
reg [LOG_DEPTH-1:0] src_ptr_gray, dst_ptr_gray;
reg [LOG_DEPTH-1:0] src_ptr_gray_sync, dst_ptr_gray_sync;
reg [LOG_DEPTH-1:0] src_cnt, dst_cnt;
reg src_empty, src_full;
reg dst_empty, dst_full;
reg src_valid_sync, dst_valid_sync;
reg [WIDTH-1:0] dst_data_sync;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
        src_cnt <= 0;
        src_empty <= 1;
        src_full <= 0;
    end else begin
        if (src_valid_i && src_ready_o) begin
            mem[src_ptr] <= src_data_i;
            src_ptr <= src_ptr + 1;
            src_cnt <= src_cnt + 1;
            if (src_cnt == DEPTH - 1) begin
                src_full <= 1;
            end
            if (src_cnt == 1) begin
                src_empty <= 0;
            end
        end
        if (src_empty) begin
            src_ptr <= 0;
            src_cnt <= 0;
        end
        if (src_full) begin
            src_cnt <= DEPTH - 1;
        end
        src_ptr_gray <= {src_ptr[LOG_DEPTH-1], src_ptr[LOG_DEPTH-2:0]};
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_cnt <= 0;
        dst_empty <= 1;
        dst_full <= 0;
    end else begin
        if (dst_valid_o && dst_ready_i) begin
            dst_ptr <= dst_ptr + 1;
            dst_cnt <= dst_cnt - 1;
            if (dst_cnt == 1) begin
                dst_empty <= 1;
            end
            if (dst_cnt == 0) begin
                dst_full <= 0;
            end
        end
        if (dst_empty) begin
            dst_ptr <= 0;
            dst_cnt <= 0;
        end
        if (dst_full) begin
            dst_cnt <= DEPTH - 1;
        end
        dst_ptr_gray <= {dst_ptr[LOG_DEPTH-1], dst_ptr[LOG_DEPTH-2:0]};
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ptr_gray_sync <= 0;
    end else begin
        src_ptr_gray_sync <= src_ptr_gray;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_ptr_gray_sync <= 0;
        dst_valid_sync <= 0;
        dst_data_sync <= 0;
    end else begin
        dst_ptr_gray_sync <= src_ptr_gray_sync;
        if (dst_valid_o && dst_ready_i) begin
            dst_valid_sync <= 0;
        end else if (dst_ptr_gray_sync!= dst_ptr_gray) begin
            dst_valid_sync <= 1;
            dst_data_sync <= mem[dst_ptr];
        end
    end
end

assign src_ready_o =!src_full;
assign dst_valid_o = dst_valid_sync;
assign dst_data_o = dst_data_sync;

assign src_empty = (src_cnt == 0);
assign src_full = (src_cnt == DEPTH - 1);
assign dst_empty = (dst_cnt == 0);
assign dst_full = (dst_cnt == DEPTH - 1);

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_cnt <= 0;
    end else if (src_valid_i && src_ready_o) begin
        src_cnt <= src_cnt + 1;
    end else if (dst_ptr_gray_sync!= src_ptr_gray_sync) begin
        src_cnt <= src_cnt - 1;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_cnt <= 0;
    end else if (dst_valid_o && dst_ready_i) begin
        dst_cnt <= dst_cnt - 1;
    end else if (src_ptr_gray_sync!= dst_ptr_gray_sync) begin
        dst_cnt <= dst_cnt + 1;
    end
end

endmodule
