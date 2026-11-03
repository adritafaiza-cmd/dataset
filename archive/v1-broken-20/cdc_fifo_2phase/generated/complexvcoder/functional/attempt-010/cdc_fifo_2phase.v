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
    localparam FIFO_SIZE = 2**LOG_DEPTH;
    logic [LOG_DEPTH-1:0] wr_ptr, rd_ptr;
    logic [LOG_DEPTH:0] count;
    logic [WIDTH-1:0] fifo [0:FIFO_SIZE-1];
    logic wr_en, rd_en;

    // Write pointer logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
        end else if (src_valid_i && src_ready_o && wr_en) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
        end else if (dst_valid_o && dst_ready_i && rd_en) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Write enable logic
    assign wr_en = src_valid_i && src_ready_o && (count < FIFO_SIZE);

    // Read enable logic
    assign rd_en = dst_valid_o && dst_ready_i && (count > 0);

    // Count logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            count <= 0;
        end else if (wr_en) begin
            count <= count + 1;
        end else if (rd_en) begin
            count <= count - 1;
        end
    end

    // FIFO memory
    assign fifo[wr_ptr] = src_data_i;

    // Destination output
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else if (rd_en) begin
            dst_data_o <= fifo[rd_ptr];
        end
    end

    // Source ready output
    assign src_ready_o = (count < FIFO_SIZE);

    // Destination valid output
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 0;
        end else if (rd_en) begin
            dst_valid_o <= 1;
        end else begin
            dst_valid_o <= 0;
        end
    end

endmodule
