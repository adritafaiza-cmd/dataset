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

    localparam DEPTH = 1 << LOG_DEPTH;

    reg [WIDTH-1:0] fifo [DEPTH-1:0];
    reg [LOG_DEPTH-1:0] wr_ptr, rd_ptr;
    reg [LOG_DEPTH-1:0] gray_wr_ptr, gray_rd_ptr;
    reg [LOG_DEPTH-1:0] sync_wr_ptr, sync_rd_ptr;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    assign src_ready_o = (gray_wr_ptr != (gray_rd_ptr + 1'b1)) || (dst_valid_o && dst_ready_i);
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            wr_ptr <= 0;
            gray_wr_ptr <= 0;
        end else if (src_valid_i && src_ready_o) begin
            fifo[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1'b1;
            gray_wr_ptr <= (wr_ptr[LOG_DEPTH-1:1] + 1'b1) ^ (wr_ptr[LOG_DEPTH-2:0] + 1'b1);
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            rd_ptr <= 0;
            gray_rd_ptr <= 0;
            sync_wr_ptr <= 0;
            sync_rd_ptr <= 0;
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
        end else begin
            if (dst_valid_o && dst_ready_i) begin
                dst_valid_reg <= 0;
            end
            if (dst_ready_i && (gray_wr_ptr != (gray_rd_ptr + 1'b1))) begin
                dst_data_reg <= fifo[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
                gray_rd_ptr <= (rd_ptr[LOG_DEPTH-1:1] + 1'b1) ^ (rd_ptr[LOG_DEPTH-2:0] + 1'b1);
                dst_valid_reg <= 1'b1;
            end
        end
    end

    always @(posedge dst_clk_i) begin
        sync_wr_ptr[0] <= gray_wr_ptr[0];
        sync_wr_ptr[1] <= sync_wr_ptr[0] ^ gray_wr_ptr[1];
        sync_wr_ptr[2] <= sync_wr_ptr[1] ^ gray_wr_ptr[2];
        sync_wr_ptr[3] <= sync_wr_ptr[2] ^ gray_wr_ptr[3];
        sync_wr_ptr[4] <= sync_wr_ptr[3] ^ gray_wr_ptr[4];
    end

endmodule
