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

    // Internal signals
    wire [LOG_DEPTH:0] wr_ptr_gray_src;
    wire [LOG_DEPTH:0] wr_ptr_gray_dst;
    wire [LOG_DEPTH:0] wr_ptr_bin_src;
    wire [LOG_DEPTH:0] wr_ptr_bin_dst;
    wire [LOG_DEPTH:0] rd_ptr_gray_dst;
    wire [LOG_DEPTH:0] rd_ptr_gray_src;
    wire [LOG_DEPTH:0] rd_ptr_bin_dst;
    wire [LOG_DEPTH:0] rd_ptr_bin_src;
    wire [WIDTH-1:0]   fifo_data;
    wire               full;
    wire               empty;

    // Gray code counters
    gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    gray_counter_src (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .en_i(src_valid_i & src_ready_o),
        .gray_o(wr_ptr_gray_src)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    gray_counter_dst_wr (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .en_i(1'b1),
        .gray_i(wr_ptr_gray_src),
        .gray_o(wr_ptr_gray_dst)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    gray_counter_dst_rd (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .en_i(dst_valid_o & dst_ready_i),
        .gray_o(rd_ptr_gray_dst)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    gray_counter_src_rd (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .en_i(1'b1),
        .gray_i(rd_ptr_gray_dst),
        .gray_o(rd_ptr_gray_src)
    );

    // Binary conversion
    binary_counter #(.LOG_DEPTH(LOG_DEPTH))
    binary_counter_wr_src (
        .gray_i(wr_ptr_gray_src),
        .bin_o(wr_ptr_bin_src)
    );

    binary_counter #(.LOG_DEPTH(LOG_DEPTH))
    binary_counter_wr_dst (
        .gray_i(wr_ptr_gray_dst),
        .bin_o(wr_ptr_bin_dst)
    );

    binary_counter #(.LOG_DEPTH(LOG_DEPTH))
    binary_counter_rd_dst (
        .gray_i(rd_ptr_gray_dst),
        .bin_o(rd_ptr_bin_dst)
    );

    binary_counter #(.LOG_DEPTH(LOG_DEPTH))
    binary_counter_rd_src (
        .gray_i(rd_ptr_gray_src),
        .bin_o(rd_ptr_bin_src)
    );

    // FIFO memory
    fifo_memory #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH))
    fifo_memory_inst (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .wr_en_i(src_valid_i & src_ready_o),
        .wr_addr_i(wr_ptr_bin_src),
        .wr_data_i(src_data_i),
        .rd_addr_i(rd_ptr_bin_dst),
        .rd_data_o(fifo_data)
    );

    // Full and empty flags
    assign full = (wr_ptr_bin_src == {1'b0, rd_ptr_bin_src[LOG_DEPTH-1:0] + 1'b1});
    assign empty = (wr_ptr_bin_src == rd_ptr_bin_src);

    // Ready and valid signals
    assign src_ready_o = ~full;
    assign dst_valid_o = ~empty;
    assign dst_data_o = fifo_data;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  en_i,
    input  [LOG_DEPTH:0]   gray_i,
    output [LOG_DEPTH:0]   gray_o
);

    reg [LOG_DEPTH:0] count;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count <= {LOG_DEPTH+1{1'b0}};
        end else if (en_i) begin
            count <= count + 1;
        end
    end

    assign gray_o = (count >> 1) ^ count;

endmodule

module binary_counter #(
    parameter LOG_DEPTH = 3
)(
    input  [LOG_DEPTH:0]   gray_i,
    output [LOG_DEPTH:0]   bin_o
);

    assign bin_o = gray_to_bin(gray_i);

    function [LOG_DEPTH:0] gray_to_bin;
        input [LOG_DEPTH:0] gray;
        integer i;
        begin
            gray_to_bin[0] = gray[0];
            for (i = 1; i <= LOG_DEPTH; i = i + 1) begin
                gray_to_bin[i] = gray_to_bin[i-1] ^ gray[i];
            end
        end
    endfunction

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  wr_en_i,
    input  [LOG_DEPTH:0]   wr_addr_i,
    input  [WIDTH-1:0]     wr_data_i,
    input  [LOG_DEPTH:0]   rd_addr_i,
    output [WIDTH-1:0]     rd_data_o
);

    reg [WIDTH-1:0] memory [0:(2**LOG_DEPTH)-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (integer i = 0; i < 2**LOG_DEPTH; i = i + 1) begin
                memory[i] <= {WIDTH{1'b0}};
            end
        end else if (wr_en_i) begin
            memory[wr_addr_i] <= wr_data_i;
        end
    end

    assign rd_data_o = memory[rd_addr_i];

endmodule
