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

    fifo_gray_code #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) gray_code_fifo (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_ready_o),
        .rst_no(dst_rst_ni),
        .clk_o(dst_clk_i),
        .data_o(dst_data_o),
        .valid_o(dst_valid_o),
        .ready_i(dst_ready_i)
    );

endmodule

module fifo_gray_code #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input  [WIDTH-1:0]     data_i,
    input                  valid_i,
    output                 ready_o,
    input                  rst_no,
    input                  clk_o,
    output [WIDTH-1:0]     data_o,
    output                 valid_o,
    input                  ready_i
);

    localparam DEPTH = 2**LOG_DEPTH;
    localparam PTR_WIDTH = LOG_DEPTH + 1;

    reg [WIDTH-1:0] mem [0:DEPTH-1];

    reg [PTR_WIDTH-1:0] gray_wr_ptr;
    reg [PTR_WIDTH-1:0] gray_rd_ptr;

    reg [PTR_WIDTH-1:0] gray_rd_ptr_gray_i;

    reg [PTR_WIDTH-1:0] bin_wr_ptr;
    reg [PTR_WIDTH-1:0] bin_rd_ptr;

    reg wr_full;
    reg rd_empty;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gray_wr_ptr <= 0;
            bin_wr_ptr <= 0;
            wr_full <= 0;
        end else if (valid_i && !wr_full) begin
            mem[bin_wr_ptr[PTR_WIDTH-2:0]] <= data_i;
            gray_wr_ptr <= next_gray_wr_ptr;
            bin_wr_ptr <= next_bin_wr_ptr;
            wr_full <= (next_gray_wr_ptr == {gray_rd_ptr_gray_i[PTR_WIDTH-1], ~gray_rd_ptr_gray_i[PTR_WIDTH-2:0]});
        end
    end

    always @(posedge clk_o or negedge rst_no) begin
        if (!rst_no) begin
            gray_rd_ptr <= 0;
            bin_rd_ptr <= 0;
            rd_empty <= 1;
            gray_rd_ptr_gray_i <= 0;
        end else if (ready_i && !rd_empty) begin
            gray_rd_ptr <= next_gray_rd_ptr;
            bin_rd_ptr <= next_bin_rd_ptr;
            rd_empty <= (next_gray_rd_ptr == gray_wr_ptr);
        end
        gray_rd_ptr_gray_i <= gray_rd_ptr;
    end

    assign next_gray_wr_ptr = (gray_wr_ptr + 1) ^ gray_wr_ptr;
    assign next_bin_wr_ptr = bin_wr_ptr + 1;

    assign next_gray_rd_ptr = (gray_rd_ptr + 1) ^ gray_rd_ptr;
    assign next_bin_rd_ptr = bin_rd_ptr + 1;

    assign ready_o = !wr_full;
    assign valid_o = !rd_empty;

    assign data_o = mem[bin_rd_ptr[PTR_WIDTH-2:0]];

endmodule
