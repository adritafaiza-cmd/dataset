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

    reg [WIDTH-1:0]             fifo_mem [DEPTH-1:0];
    reg [$clog2(DEPTH)-1:0]     wr_ptr, rd_ptr;
    reg [$clog2(DEPTH)-1:0]     wr_ptr_gray, rd_ptr_gray;
    reg [$clog2(DEPTH)-1:0]     wr_ptr_gray_sync, rd_ptr_gray_sync;
    reg                         full, empty;
    reg                         src_valid_sync, dst_ready_sync;
    reg                         dst_valid_reg;

    assign src_ready_o = ~full & src_valid_sync;
    assign dst_valid_o = dst_valid_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
            full <= 0;
            src_valid_sync <= 0;
        end else begin
            if (src_valid_i & ~full) begin
                fifo_mem[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == DEPTH - 1) begin
                    full <= 1;
                end
            end
            if (src_valid_i & src_ready_o) begin
                wr_ptr_gray <= wr_ptr;
            end
            src_valid_sync <= src_valid_i;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            empty <= 1;
            dst_valid_reg <= 0;
            dst_data_o <= 0;
        end else begin
            if (dst_ready_i & ~empty) begin
                dst_data_o <= fifo_mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == DEPTH - 1) begin
                    empty <= 1;
                end
                dst_valid_reg <= 1;
            end else if (~dst_ready_i & dst_valid_reg) begin
                dst_valid_reg <= 0;
            end
            if (dst_ready_i & dst_valid_reg) begin
                rd_ptr_gray <= rd_ptr;
            end
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            full <= 0;
        end else if (wr_ptr_gray_sync == rd_ptr_gray_sync + 1) begin
            full <= 1;
        end else if (wr_ptr_gray_sync == 0 & rd_ptr_gray_sync == DEPTH - 1) begin
            full <= 1;
        end else begin
            full <= 0;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            empty <= 1;
        end else if (rd_ptr_gray_sync == wr_ptr_gray_sync) begin
            empty <= 1;
        end else begin
            empty <= 0;
        end
    end

endmodule
