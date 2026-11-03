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
    reg [LOG_DEPTH:0] src_wr_ptr, src_wr_ptr_gray, src_wr_ptr_gray_sync, src_wr_ptr_sync;
    reg [LOG_DEPTH:0] dst_rd_ptr, dst_rd_ptr_gray, dst_rd_ptr_gray_sync, dst_rd_ptr_sync;
    reg [WIDTH-1:0] fifo_mem [0:(1<<LOG_DEPTH)-1];
    reg src_full, dst_empty;
    reg dst_valid_reg;

    // Gray code conversion function
    function [LOG_DEPTH:0] bin2gray;
        input [LOG_DEPTH:0] bin;
        bin2gray = (bin >> 1) ^ bin;
    endfunction

    // Gray code to binary conversion function
    function [LOG_DEPTH:0] gray2bin;
        input [LOG_DEPTH:0] gray;
        integer i;
        reg [LOG_DEPTH:0] bin;
        bin = gray;
        for (i = LOG_DEPTH-1; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        gray2bin = bin;
    endfunction

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_wr_ptr_gray <= 0;
            src_wr_ptr_gray_sync <= 0;
        end else begin
            src_wr_ptr_gray <= bin2gray(src_wr_ptr);
            if (src_valid_i && src_ready_o) begin
                src_wr_ptr <= src_wr_ptr + 1;
                fifo_mem[src_wr_ptr] <= src_data_i;
            end
        end
    end

    // Synchronize src_wr_ptr_gray to dst_clk_i
    cdc_sync_gray #(LOG_DEPTH+1) sync_src_wr_ptr_gray (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .d_i(src_wr_ptr_gray),
        .q_o(src_wr_ptr_gray_sync)
    );

    // Convert synchronized src_wr_ptr_gray_sync to binary
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_sync <= 0;
        end else begin
            src_wr_ptr_sync <= gray2bin(src_wr_ptr_gray_sync);
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
            dst_rd_ptr_gray <= 0;
            dst_rd_ptr_gray_sync <= 0;
        end else begin
            dst_rd_ptr_gray <= bin2gray(dst_rd_ptr);
            if (dst_ready_i && dst_valid_o) begin
                dst_rd_ptr <= dst_rd_ptr + 1;
            end
        end
    end

    // Synchronize dst_rd_ptr_gray to src_clk_i
    cdc_sync_gray #(LOG_DEPTH+1) sync_dst_rd_ptr_gray (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .d_i(dst_rd_ptr_gray),
        .q_o(dst_rd_ptr_gray_sync)
    );

    // Convert synchronized dst_rd_ptr_gray_sync to binary
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_sync <= 0;
        end else begin
            dst_rd_ptr_sync <= gray2bin(dst_rd_ptr_gray_sync);
        end
    end

    // Calculate src_full and src_ready_o
    assign src_full = (src_wr_ptr + 1) == dst_rd_ptr_gray_sync;
    assign src_ready_o = ~src_full;

    // Calculate dst_empty and dst_valid_o
    assign dst_empty = src_wr_ptr_gray_sync == dst_rd_ptr;
    assign dst_valid_o = ~dst_empty;

    // Assign output data
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
            dst_valid_reg <= 0;
        end else begin
            if (dst_ready_i && dst_valid_o) begin
                dst_data_o <= fifo_mem[dst_rd_ptr];
                dst_valid_reg <= 1;
            end else if (dst_ready_i) begin
                dst_valid_reg <= 0;
            end
        end
    end

endmodule

// Gray code synchronizer module
module cdc_sync_gray #(
    parameter WIDTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     d_i,
    output [WIDTH-1:0]     q_o
);

    reg [WIDTH-1:0] meta, sync;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            meta <= 0;
            sync <= 0;
        end else begin
            meta <= d_i;
            sync <= meta;
        end
    end

    assign q_o = sync;

endmodule
