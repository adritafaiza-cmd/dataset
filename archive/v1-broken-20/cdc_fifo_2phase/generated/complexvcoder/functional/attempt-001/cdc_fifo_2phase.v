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

    localparam FIFO_DEPTH = 1 << LOG_DEPTH;

    logic [WIDTH-1:0] fifo [0:FIFO_DEPTH-1];
    logic [LOG_DEPTH:0] wr_ptr, rd_ptr;
    logic [LOG_DEPTH:0] wr_ptr_gray, rd_ptr_gray;
    logic [LOG_DEPTH:0] wr_en, rd_en;
    logic [LOG_DEPTH:0] full_gray, empty_gray;

    // Gray code conversion for write pointer
    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);

    // Gray code conversion for read pointer
    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

    // FIFO full detection
    assign full_gray = wr_ptr_gray == (rd_ptr_gray - 1) % (FIFO_DEPTH + 1);

    // FIFO empty detection
    assign empty_gray = wr_ptr_gray == rd_ptr_gray;

    // Write enable logic
    assign wr_en = src_valid_i && src_ready_o && !full_gray;

    // Read enable logic
    assign rd_en = dst_ready_i && dst_valid_o && !empty_gray;

    // Write pointer update
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
        end else if (wr_en) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer update
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
        end else if (rd_en) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // FIFO data storage
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (int i = 0; i < FIFO_DEPTH; i = i + 1) begin
                fifo[i] <= 0;
            end
        end else if (wr_en) begin
            fifo[wr_ptr] <= src_data_i;
        end
    end

    // Output data and valid signal
    assign dst_data_o = fifo[rd_ptr];
    assign dst_valid_o = !empty_gray;

    // Source ready signal
    assign src_ready_o = !full_gray;

endmodule
