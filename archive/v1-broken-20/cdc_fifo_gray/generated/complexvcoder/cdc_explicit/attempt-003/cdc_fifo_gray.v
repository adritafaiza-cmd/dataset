module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
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

    // Define internal signals
    localparam FIFO_DEPTH = 1 << LOG_DEPTH;
    reg [WIDTH-1:0] src_fifo [0:FIFO_DEPTH-1];
    reg [LOG_DEPTH:0] src_wr_ptr, src_rd_ptr;
    reg [LOG_DEPTH:0] dst_wr_ptr, dst_rd_ptr;
    reg [LOG_DEPTH:0] src_full, src_empty;
    reg [LOG_DEPTH:0] dst_full, dst_empty;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_rd_ptr <= 0;
        end else begin
            if (src_valid_i && src_ready_o && !src_full) begin
                src_fifo[src_wr_ptr] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1;
            end
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_full <= 0;
        end else begin
            src_full <= (src_wr_ptr == src_rd_ptr + FIFO_DEPTH);
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_empty <= 1;
        end else begin
            src_empty <= (src_wr_ptr == src_rd_ptr);
        end
    end

    assign src_ready_o = !src_full;

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
        end else begin
            if (dst_valid_o && dst_ready_i && !dst_empty) begin
                dst_rd_ptr <= dst_rd_ptr + 1;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_full <= 0;
        end else begin
            dst_full <= (dst_wr_ptr == dst_rd_ptr + FIFO_DEPTH);
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_empty <= 1;
        end else begin
            dst_empty <= (dst_wr_ptr == dst_rd_ptr);
        end
    end

    assign dst_data_o = src_fifo[dst_rd_ptr];
    assign dst_valid_o = !dst_empty;

endmodule
