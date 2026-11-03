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

    reg [WIDTH-1:0] fifo[DEPTH-1:0];
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH)-1:0] wr_ptr_gray, rd_ptr_gray;
    reg [$clog2(DEPTH)-1:0] wr_ptr_sync, rd_ptr_sync;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    assign src_ready_o = (wr_ptr - rd_ptr) < (DEPTH - 1);
    assign dst_valid_o = dst_valid_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (src_valid_i && src_ready_o) begin
            fifo[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= wr_ptr_gray + 1;
        end
        wr_ptr_gray <= {wr_ptr_gray[$high(wr_ptr_gray)-1:1], wr_ptr_gray[0]};
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            rd_ptr_sync <= 0;
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
        end else begin
            rd_ptr_sync <= rd_ptr_gray;
            if (dst_ready_i && dst_valid_reg) begin
                rd_ptr <= rd_ptr + 1;
                dst_valid_reg <= (rd_ptr != wr_ptr_sync);
            end
            if (dst_valid_reg) begin
                dst_data_reg <= fifo[rd_ptr];
            end
            rd_ptr_gray <= {rd_ptr_gray[$high(rd_ptr_gray)-1:1], rd_ptr_gray[0]};
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr_sync <= 0;
        end else begin
            wr_ptr_sync <= wr_ptr_gray;
        end
    end

    always @(posedge dst_clk_i) begin
        dst_data_o <= dst_data_reg;
    end

endmodule
