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
    reg [LOG_DEPTH:0]      src_gray_wr_ptr, src_gray_rd_ptr;
    reg [LOG_DEPTH:0]      dst_gray_wr_ptr, dst_gray_rd_ptr;
    reg [LOG_DEPTH:0]      src_bin_wr_ptr, src_bin_rd_ptr;
    reg [LOG_DEPTH:0]      dst_bin_wr_ptr, dst_bin_rd_ptr;
    reg [WIDTH-1:0]        mem [0:(1<<LOG_DEPTH)-1];
    reg                    src_fifo_full, src_fifo_empty;
    reg                    dst_fifo_full, dst_fifo_empty;
    reg                    src_fifo_wr_en, src_fifo_rd_en;
    reg                    dst_fifo_wr_en, dst_fifo_rd_en;
    reg                    src_ready_reg;
    reg                    dst_valid_reg;
    reg [WIDTH-1:0]        dst_data_reg;

    // Gray code to binary conversion
    function [LOG_DEPTH:0] gray_to_bin;
        input [LOG_DEPTH:0] gray;
        integer i;
        begin
            gray_to_bin = gray[LOG_DEPTH];
            for (i = LOG_DEPTH - 1; i >= 0; i = i - 1) begin
                gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
            end
        end
    endfunction

    // Binary to gray conversion
    function [LOG_DEPTH:0] bin_to_gray;
        input [LOG_DEPTH:0] bin;
        begin
            bin_to_gray = bin ^ (bin >> 1);
        end
    endfunction

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_wr_ptr <= 0;
            src_gray_rd_ptr <= 0;
        end else begin
            if (src_fifo_wr_en) begin
                src_gray_wr_ptr <= src_gray_wr_ptr + 1;
            end
            if (src_fifo_rd_en) begin
                src_gray_rd_ptr <= src_gray_rd_ptr + 1;
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_wr_ptr <= 0;
            dst_gray_rd_ptr <= 0;
        end else begin
            if (dst_fifo_wr_en) begin
                dst_gray_wr_ptr <= dst_gray_wr_ptr + 1;
            end
            if (dst_fifo_rd_en) begin
                dst_gray_rd_ptr <= dst_gray_rd_ptr + 1;
            end
        end
    end

    // Source domain control logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_fifo_full <= 0;
            src_fifo_empty <= 1;
        end else begin
            src_fifo_full <= (src_gray_wr_ptr[LOG_DEPTH] != src_gray_rd_ptr[LOG_DEPTH]) && (src_gray_wr_ptr[LOG_DEPTH-1:0] == src_gray_rd_ptr[LOG_DEPTH-1:0]);
            src_fifo_empty <= (src_gray_wr_ptr == src_gray_rd_ptr);
        end
    end

    // Destination domain control logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_fifo_full <= 0;
            dst_fifo_empty <= 1;
        end else begin
            dst_fifo_full <= (dst_gray_wr_ptr[LOG_DEPTH] != dst_gray_rd_ptr[LOG_DEPTH]) && (dst_gray_wr_ptr[LOG_DEPTH-1:0] == dst_gray_rd_ptr[LOG_DEPTH-1:0]);
            dst_fifo_empty <= (dst_gray_wr_ptr == dst_gray_rd_ptr);
        end
    end

    // Source domain write enable
    assign src_fifo_wr_en = src_valid_i & src_ready_o & ~src_fifo_full;

    // Source domain read enable
    assign src_fifo_rd_en = ~src_fifo_empty;

    // Source domain ready output
    assign src_ready_o = ~src_fifo_full;

    // Destination domain write enable
    assign dst_fifo_wr_en = ~dst_fifo_empty;

    // Destination domain read enable
    assign dst_fifo_rd_en = dst_valid_o & dst_ready_i;

    // Destination domain valid output
    assign dst_valid_o = ~dst_fifo_empty;

    // Memory write
    always @(posedge src_clk_i) begin
        if (src_fifo_wr_en) begin
            mem[src_bin_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // Memory read
    always @(posedge dst_clk_i) begin
        if (dst_fifo_wr_en) begin
            src_bin_wr_ptr <= gray_to_bin(src_gray_wr_ptr);
            dst_bin_wr_ptr <= src_bin_wr_ptr;
        end
        if (dst_fifo_rd_en) begin
            dst_bin_rd_ptr <= gray_to_bin(dst_gray_rd_ptr);
            dst_data_reg <= mem[dst_bin_rd_ptr[LOG_DEPTH-1:0]];
            dst_valid_reg <= 1;
        end else if (dst_ready_i) begin
            dst_valid_reg <= 0;
        end
    end

    // Destination domain data output
    assign dst_data_o = dst_data_reg;

endmodule
