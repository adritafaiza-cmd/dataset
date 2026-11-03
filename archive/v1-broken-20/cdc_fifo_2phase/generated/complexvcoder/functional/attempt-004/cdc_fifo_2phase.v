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
    logic [LOG_DEPTH-1:0] wr_ptr;
    logic [LOG_DEPTH-1:0] rd_ptr;
    logic [LOG_DEPTH-1:0] cnt;
    logic full;
    logic empty;

    // FIFO core
    logic [WIDTH-1:0] fifo_mem [0:2**LOG_DEPTH-1];
    logic wr_en;
    logic rd_en;

    // Write enable logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read enable logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Write enable signal
    assign wr_en = src_valid_i && src_ready_o && !full;

    // Read enable signal
    assign rd_en = dst_ready_i && !empty;

    // FIFO full and empty flags
    assign full = (wr_ptr == rd_ptr && !empty) || (wr_ptr == rd_ptr + 2**LOG_DEPTH);
    assign empty = (wr_ptr == rd_ptr);

    // FIFO memory access
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_mem[wr_ptr] <= 0;
        end else if (wr_en && !full) begin
            fifo_mem[wr_ptr] <= src_data_i;
        end
    end

    // Destination output
    assign dst_data_o = fifo_mem[rd_ptr];

    // Source ready signal
    assign src_ready_o = !full;

    // Destination valid signal
    assign dst_valid_o = !empty;

endmodule
