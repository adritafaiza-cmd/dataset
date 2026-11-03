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
    reg [WIDTH-1:0] src_fifo_data [0:(2**LOG_DEPTH)-1];
    reg [LOG_DEPTH:0] src_fifo_wr_ptr, src_fifo_rd_ptr;
    reg [LOG_DEPTH:0] dst_fifo_wr_ptr, dst_fifo_rd_ptr;
    reg src_fifo_full, src_fifo_empty;
    reg dst_fifo_full, dst_fifo_empty;

    // Source FIFO
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_fifo_wr_ptr <= 0;
            src_fifo_rd_ptr <= 0;
            src_fifo_full <= 0;
            src_fifo_empty <= 1;
        end else begin
            if (!src_fifo_full && src_valid_i && src_ready_o) begin
                src_fifo_data[src_fifo_wr_ptr] <= src_data_i;
                src_fifo_wr_ptr <= src_fifo_wr_ptr + 1;
                if (src_fifo_wr_ptr == (2**LOG_DEPTH)-1) begin
                    src_fifo_full <= 1;
                end
            end
            if (src_fifo_empty && src_fifo_ready_o) begin
                src_fifo_rd_ptr <= src_fifo_rd_ptr + 1;
                if (src_fifo_rd_ptr == (2**LOG_DEPTH)-1) begin
                    src_fifo_empty <= 0;
                end
            end
        end
    end

    assign src_ready_o = !src_fifo_full && src_valid_i;

    // Destination FIFO
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_fifo_wr_ptr <= 0;
            dst_fifo_rd_ptr <= 0;
            dst_fifo_full <= 0;
            dst_fifo_empty <= 1;
        end else begin
            if (!dst_fifo_full && dst_ready_i && dst_valid_o) begin
                dst_fifo_data[dst_fifo_wr_ptr] <= src_fifo_data[dst_fifo_rd_ptr];
                dst_fifo_wr_ptr <= dst_fifo_wr_ptr + 1;
                dst_fifo_rd_ptr <= dst_fifo_rd_ptr + 1;
                if (dst_fifo_wr_ptr == (2**LOG_DEPTH)-1) begin
                    dst_fifo_full <= 1;
                end
                if (dst_fifo_rd_ptr == (2**LOG_DEPTH)-1) begin
                    dst_fifo_empty <= 0;
                end
            end
        end
    end

    assign dst_valid_o = !dst_fifo_empty;

endmodule
