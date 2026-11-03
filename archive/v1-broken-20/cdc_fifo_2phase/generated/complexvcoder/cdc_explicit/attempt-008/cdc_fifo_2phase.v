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
    localparam FIFO_DEPTH = 2**LOG_DEPTH;
    logic [WIDTH-1:0] fifo [0:FIFO_DEPTH-1];
    logic [LOG_DEPTH:0] wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray;
    logic [LOG_DEPTH-1:0] cnt;
    logic wr_en, rd_en;
    logic [WIDTH-1:0] data_out;

    // Gray code for wr_ptr and rd_ptr
    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

    // Write enable
    assign wr_en = src_valid_i & src_ready_o & wr_ptr_gray != rd_ptr_gray;

    // Read enable
    assign rd_en = dst_ready_i & dst_valid_o & wr_ptr_gray != rd_ptr_gray;

    // FIFO write process
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
        end else if (wr_en) begin
            fifo[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // FIFO read process
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
        end else if (rd_en) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Counter for FIFO count
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            cnt <= 0;
        end else if (wr_en) begin
            cnt <= cnt + 1;
        end else if (rd_en) begin
            cnt <= cnt - 1;
        end
    end

    // Output assignment
    assign dst_data_o = fifo[rd_ptr];
    assign dst_valid_o = (cnt > 0) & dst_ready_i;

    // Source ready assignment
    assign src_ready_o = (cnt < FIFO_DEPTH);

endmodule
