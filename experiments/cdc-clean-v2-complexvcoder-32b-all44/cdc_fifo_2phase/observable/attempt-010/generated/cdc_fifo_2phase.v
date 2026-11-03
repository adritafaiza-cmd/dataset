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

    // Internal FIFO logic
    cdc_fifo_2phase_internal #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_internal (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_data_i(src_data_i),
        .src_valid_i(src_valid_i),
        .src_ready_o(src_ready_o),
        .dst_rst_ni(dst_rst_ni),
        .dst_clk_i(dst_clk_i),
        .dst_data_o(dst_data_o),
        .dst_valid_o(dst_valid_o),
        .dst_ready_i(dst_ready_i)
    );

endmodule

module cdc_fifo_2phase_internal #(
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

    localparam DEPTH = 2**LOG_DEPTH;

    reg [WIDTH-1:0] fifo_mem [0:DEPTH-1];
    reg [LOG_DEPTH:0] wr_ptr, rd_ptr;
    reg [LOG_DEPTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [LOG_DEPTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;
    reg fifo_full, fifo_empty;
    reg src_ready;
    reg dst_valid;
    reg [WIDTH-1:0] dst_data_reg;

    // Gray code conversion functions
    function [LOG_DEPTH:0] bin_to_gray;
        input [LOG_DEPTH:0] bin;
        bin_to_gray = (bin >> 1) ^ bin;
    endfunction

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
            src_ready <= 1;
            fifo_full <= 0;
        end else begin
            wr_ptr_gray <= bin_to_gray(wr_ptr);
            if (src_valid_i && src_ready) begin
                fifo_mem[wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
            end
            src_ready <= ~fifo_full;
            fifo_full <= (wr_ptr_gray_sync == {1'b1, rd_ptr_gray[LOG_DEPTH-1:0]});
        end
    end

    // Synchronize wr_ptr_gray to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            dst_valid <= 0;
            dst_data_reg <= 0;
            fifo_empty <= 1;
        end else begin
            rd_ptr_gray <= bin_to_gray(rd_ptr);
            if (dst_valid && dst_ready_i) begin
                rd_ptr <= rd_ptr + 1;
            end
            dst_valid <= ~fifo_empty;
            fifo_empty <= (rd_ptr_gray_sync == {1'b1, wr_ptr_gray[LOG_DEPTH-1:0]});
            if (dst_valid && dst_ready_i) begin
                dst_data_reg <= fifo_mem[rd_ptr[LOG_DEPTH-1:0]];
            end
        end
    end

    // Synchronize rd_ptr_gray to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // Assign output signals
    assign src_ready_o = src_ready;
    assign dst_valid_o = dst_valid;
    assign dst_data_o = dst_data_reg;

endmodule
