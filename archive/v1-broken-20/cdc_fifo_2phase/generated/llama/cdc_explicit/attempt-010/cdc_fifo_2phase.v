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

// FIFO memory
reg [WIDTH-1:0] fifo_mem [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] wr_ptr, rd_ptr;
reg [LOG_DEPTH:0]  cnt;

// Gray counters
reg [LOG_DEPTH:0]  gray_wr_ptr, gray_rd_ptr;
reg [LOG_DEPTH:0]  sync_gray_rd_ptr [1:0];

// Source domain logic
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        wr_ptr <= 0;
        gray_wr_ptr <= 0;
        cnt <= 0;
        src_ready_o <= 1'b1;
    end else begin
        if (src_valid_i && src_ready_o) begin
            fifo_mem[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1;
            gray_wr_ptr <= (wr_ptr >> 1) + (wr_ptr & 1);
            cnt <= cnt + 1;
        end
        if (cnt == 2**LOG_DEPTH) begin
            src_ready_o <= 1'b0;
        end else begin
            src_ready_o <= 1'b1;
        end
    end
end

// Destination domain logic
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        rd_ptr <= 0;
        gray_rd_ptr <= 0;
        sync_gray_rd_ptr[0] <= 0;
        sync_gray_rd_ptr[1] <= 0;
        dst_valid_o <= 1'b0;
        dst_data_o <= 0;
    end else begin
        sync_gray_rd_ptr[0] <= gray_wr_ptr;
        sync_gray_rd_ptr[1] <= sync_gray_rd_ptr[0];
        gray_rd_ptr <= sync_gray_rd_ptr[1];
        if (dst_ready_i && dst_valid_o) begin
            rd_ptr <= rd_ptr + 1;
            gray_rd_ptr <= (rd_ptr >> 1) + (rd_ptr & 1);
            cnt <= cnt - 1;
            dst_valid_o <= 1'b0;
        end
        if (cnt > 0 && ~dst_valid_o) begin
            dst_data_o <= fifo_mem[rd_ptr];
            dst_valid_o <= 1'b1;
        end
    end
end

// Count logic
always @(posedge src_clk_i or posedge dst_clk_i or negedge src_rst_ni or negedge dst_rst_ni) begin
    if (~src_rst_ni || ~dst_rst_ni) begin
        cnt <= 0;
    end
end

endmodule
