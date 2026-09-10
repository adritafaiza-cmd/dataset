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

    reg [WIDTH-1:0]         fifo[DEPTH-1:0];
    reg [LOG_DEPTH-1:0]     wr_ptr;
    reg [LOG_DEPTH-1:0]     rd_ptr;
    reg [LOG_DEPTH-1:0]     wr_ptr_gray;
    reg [LOG_DEPTH-1:0]     rd_ptr_gray;
    reg [LOG_DEPTH:0]       count;
    reg                     src_ready;
    reg                     dst_valid;

    assign src_ready_o = src_ready;
    assign dst_valid_o = dst_valid;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
            count <= 0;
            src_ready <= 1'b1;
        end else if (src_valid_i && src_ready) begin
            fifo[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= wr_ptr_gray + 1;
            count <= count + 1;
            if (count == DEPTH - 1) begin
                src_ready <= 1'b0;
            end
        end else if (!src_valid_i && src_ready && count > 0) begin
            count <= count;
            src_ready <= 1'b1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            dst_valid <= 1'b0;
            dst_data_o <= 0;
        end else if (dst_ready_i && dst_valid) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= rd_ptr_gray + 1;
            count <= count - 1;
            dst_valid <= (count > 1);
        end else if (dst_ready_i && !dst_valid && count > 0) begin
            dst_data_o <= fifo[rd_ptr];
            dst_valid <= 1'b1;
        end else if (!dst_ready_i && dst_valid) begin
            dst_valid <= 1'b1;
        end
    end

    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready) begin
            wr_ptr_gray <= wr_ptr_gray + 1;
        end
    end

    always @(posedge dst_clk_i) begin
        if (dst_ready_i && dst_valid) begin
            rd_ptr_gray <= rd_ptr_gray + 1;
        end
    end

    always @(posedge src_clk_i) begin
        if (wr_ptr_gray != rd_ptr_gray) begin
            src_ready <= (count < DEPTH);
        end else begin
            src_ready <= 1'b1;
        end
    end

    always @(posedge dst_clk_i) begin
        if (wr_ptr_gray != rd_ptr_gray) begin
            dst_valid <= (count > 0);
        end else begin
            dst_valid <= 1'b0;
        end
    end

endmodule
