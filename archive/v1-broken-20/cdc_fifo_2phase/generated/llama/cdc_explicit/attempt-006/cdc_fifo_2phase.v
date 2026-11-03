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
    reg [LOG_DEPTH-1:0]    gray_wr_ptr;
    reg [LOG_DEPTH-1:0]    gray_rd_ptr;
    reg [LOG_DEPTH:0]      fill_level;
    reg [LOG_DEPTH:0]      gray_fill_level;
    reg                    src_ready;
    reg                    dst_valid;
    reg [WIDTH-1:0]        dst_data;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            wr_ptr <= 0;
            gray_wr_ptr <= 0;
            fill_level <= 0;
        end else if (src_valid_i && src_ready) begin
            fifo[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1;
            gray_wr_ptr <= gray_wr_ptr + 1;
            fill_level <= fill_level + 1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            rd_ptr <= 0;
            gray_rd_ptr <= 0;
            dst_valid <= 0;
            dst_data <= 0;
        end else if (dst_valid && dst_ready_i) begin
            dst_valid <= 0;
            if (fill_level > 0) begin
                dst_data <= fifo[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                gray_rd_ptr <= gray_rd_ptr + 1;
                fill_level <= fill_level - 1;
                dst_valid <= 1;
            end
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            src_ready <= 1;
        end else if (src_valid_i && src_ready) begin
            if (fill_level == 2**LOG_DEPTH - 1) begin
                src_ready <= 0;
            end
        end else if (~src_valid_i && !src_ready) begin
            if (fill_level < 2**LOG_DEPTH - 1) begin
                src_ready <= 1;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            gray_rd_ptr <= 0;
            gray_fill_level <= 0;
        end else begin
            gray_rd_ptr <= {gray_rd_ptr[LOG_DEPTH-2:0], rd_ptr[LOG_DEPTH-1]};
            gray_fill_level <= {gray_fill_level[LOG_DEPTH-1:1], fill_level[0]};
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            gray_wr_ptr <= 0;
            gray_fill_level <= 0;
        end else begin
            gray_wr_ptr <= {gray_wr_ptr[LOG_DEPTH-2:0], wr_ptr[LOG_DEPTH-1]};
            gray_fill_level <= {gray_fill_level[LOG_DEPTH-1:1], fill_level[0]};
        end
    end

    assign src_ready_o = src_ready;
    assign dst_data_o = dst_data;
    assign dst_valid_o = dst_valid;

endmodule
