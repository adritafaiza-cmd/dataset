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
    reg [WIDTH-1:0]         mem [0:(1<<LOG_DEPTH)-1];
    reg [LOG_DEPTH:0]       wr_ptr;
    reg [LOG_DEPTH:0]       rd_ptr;
    reg                     full;
    reg                     empty;

    // Clock domain crossing for write pointer
    reg [LOG_DEPTH:0]       wr_ptr_sync;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            wr_ptr_sync <= 0;
        end else begin
            wr_ptr <= wr_ptr + src_valid_i & ~full;
            wr_ptr_sync <= wr_ptr;
        end
    end

    // Clock domain crossing for read pointer
    reg [LOG_DEPTH:0]       rd_ptr_sync;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            rd_ptr_sync <= 0;
        end else begin
            rd_ptr <= rd_ptr + dst_valid_o & ~dst_ready_i;
            rd_ptr_sync <= rd_ptr;
        end
    end

    // Synchronous FIFO logic
    assign full = (wr_ptr_sync == rd_ptr_sync) & (src_valid_i & ~dst_ready_i);
    assign empty = (wr_ptr_sync == rd_ptr_sync) & ~(src_valid_i | dst_ready_i);

    // Clock domain crossing for data output
    reg [WIDTH-1:0]         data_out;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            data_out <= 0;
        end else begin
            data_out <= mem[rd_ptr_sync];
        end
    end

    // Assign outputs
    assign dst_data_o = data_out;
    assign dst_valid_o = ~empty & dst_ready_i;
    assign src_ready_o = ~full;

endmodule
