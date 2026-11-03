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

    // Internal signals
    reg [LOG_DEPTH:0] src_gray_wr_ptr, src_gray_rd_ptr, src_gray_wr_ptr_sync;
    reg [LOG_DEPTH:0] dst_gray_wr_ptr, dst_gray_rd_ptr, dst_gray_wr_ptr_sync;
    reg [LOG_DEPTH:0] src_bin_wr_ptr, src_bin_rd_ptr;
    reg [LOG_DEPTH:0] dst_bin_wr_ptr, dst_bin_rd_ptr;
    reg [WIDTH-1:0] fifo_mem [0:(1<<LOG_DEPTH)-1];
    reg src_full, src_empty, dst_full, dst_empty;
    reg src_wr_en, src_rd_en, dst_wr_en, dst_rd_en;

    // Two-stage synchronizer for src_gray_wr_ptr to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_wr_ptr_sync <= 0;
        end else begin
            dst_gray_wr_ptr_sync <= src_gray_wr_ptr;
        end
    end

    // Two-stage synchronizer for dst_gray_wr_ptr to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_wr_ptr_sync <= 0;
        end else begin
            src_gray_wr_ptr_sync <= dst_gray_wr_ptr;
        end
    end

    // Gray to binary conversion for src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_bin_wr_ptr <= 0;
        end else begin
            src_bin_wr_ptr <= src_gray_wr_ptr_sync ^ (src_gray_wr_ptr_sync >> 1);
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_bin_rd_ptr <= 0;
        end else begin
            src_bin_rd_ptr <= src_gray_rd_ptr ^ (src_gray_rd_ptr >> 1);
        end
    end

    // Gray to binary conversion for dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_bin_wr_ptr <= 0;
        end else begin
            dst_bin_wr_ptr <= dst_gray_wr_ptr_sync ^ (dst_gray_wr_ptr_sync >> 1);
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_bin_rd_ptr <= 0;
        end else begin
            dst_bin_rd_ptr <= dst_gray_rd_ptr ^ (dst_gray_rd_ptr >> 1);
        end
    end

    // Full and empty flags for src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_full <= 0;
            src_empty <= 1;
        end else begin
            src_full <= (src_bin_wr_ptr == {src_gray_rd_ptr[LOG_DEPTH], src_gray_rd_ptr[LOG_DEPTH-1:0] + 1'b1});
            src_empty <= (src_bin_wr_ptr == src_bin_rd_ptr);
        end
    end

    // Full and empty flags for dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_full <= 0;
            dst_empty <= 1;
        end else begin
            dst_full <= (dst_bin_wr_ptr == {dst_gray_rd_ptr[LOG_DEPTH], dst_gray_rd_ptr[LOG_DEPTH-1:0] + 1'b1});
            dst_empty <= (dst_bin_wr_ptr == dst_bin_rd_ptr);
        end
    end

    // Source ready output
    assign src_ready_o = ~src_full;

    // Source write enable and FIFO write
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_en <= 0;
        end else begin
            src_wr_en <= src_valid_i & src_ready_o;
        end
    end

    always @(posedge src_clk_i) begin
        if (src_wr_en) begin
            fifo_mem[src_bin_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // Source read enable and gray pointer increment
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_en <= 0;
            src_gray_rd_ptr <= 0;
        end else begin
            src_rd_en <= ~src_empty & (src_wr_en | ~src_empty);
            if (src_rd_en) begin
                src_gray_rd_ptr <= src_gray_rd_ptr + 1'b1;
            end
        end
    end

    // Destination valid output
    assign dst_valid_o = ~dst_empty;

    // Destination read enable and FIFO read
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_en <= 0;
            dst_data_o <= 0;
        end else begin
            dst_rd_en <= dst_valid_o & dst_ready_i;
            if (dst_rd_en) begin
                dst_data_o <= fifo_mem[dst_bin_rd_ptr[LOG_DEPTH-1:0]];
            end
        end
    end

    // Destination write enable and gray pointer increment
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_en <= 0;
            dst_gray_wr_ptr <= 0;
        end else begin
            dst_wr_en <= ~dst_full & (dst_rd_en | ~dst_full);
            if (dst_wr_en) begin
                dst_gray_wr_ptr <= dst_gray_wr_ptr + 1'b1;
            end
        end
    end

endmodule
