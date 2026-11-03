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

    reg [WIDTH-1:0]         fifo [2**LOG_DEPTH-1:0];
    reg [LOG_DEPTH-1:0]    wr_ptr;
    reg [LOG_DEPTH-1:0]    rd_ptr;
    reg [LOG_DEPTH-1:0]    rd_ptr_gray;
    reg [LOG_DEPTH-1:0]    wr_ptr_gray;
    reg [LOG_DEPTH:0]      fill_level;
    reg [LOG_DEPTH:0]      fill_level_gray;
    reg                    src_ready;
    reg                    dst_valid;
    reg [WIDTH-1:0]         dst_data;

    assign src_ready_o = src_ready;
    assign dst_data_o = dst_data;
    assign dst_valid_o = dst_valid;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            fill_level <= 0;
        end else if (src_valid_i && src_ready) begin
            fifo[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1;
            fill_level <= fill_level + 1;
        end
    end

    always @(posedge src_clk_i) begin
        wr_ptr_gray <= wr_ptr;
        fill_level_gray <= fill_level;
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            dst_valid <= 0;
            dst_data <= 0;
        end else if (dst_valid && dst_ready_i) begin
            dst_valid <= 0;
            if (fill_level_gray > 0) begin
                dst_data <= fifo[rd_ptr];
                rd_ptr <= rd_ptr + 1;
            end
        end else if (fill_level_gray > 0 && !dst_valid) begin
            dst_data <= fifo[rd_ptr];
            rd_ptr <= rd_ptr + 1;
            dst_valid <= 1;
        end
    end

    always @(posedge dst_clk_i) begin
        rd_ptr_gray <= rd_ptr;
    end

    always @(posedge src_clk_i) begin
        src_ready <= (fill_level < (2**LOG_DEPTH));
    end

    always @(posedge dst_clk_i) begin
        if (fill_level_gray > 0) begin
            fill_level_gray <= fill_level_gray - 1;
        end
    end

endmodule
