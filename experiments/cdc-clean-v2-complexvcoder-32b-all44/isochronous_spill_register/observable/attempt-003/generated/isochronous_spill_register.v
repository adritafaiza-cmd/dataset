module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output [WIDTH-1:0] dst_data_o
);

    async_fifo #(
        .WIDTH(WIDTH)
    ) fifo_inst (
        .clk_wr    (src_clk_i),
        .rst_wr_ni (src_rst_ni),
        .valid_wr  (src_valid_i),
        .ready_wr  (src_ready_o),
        .data_wr   (src_data_i),
        .clk_rd    (dst_clk_i),
        .rst_rd_ni (dst_rst_ni),
        .valid_rd  (dst_valid_o),
        .ready_rd  (dst_ready_i),
        .data_rd   (dst_data_o)
    );

endmodule

module async_fifo #(
    parameter WIDTH = 8
)(
    input              clk_wr,
    input              rst_wr_ni,
    input              valid_wr,
    output             ready_wr,
    input  [WIDTH-1:0] data_wr,
    input              clk_rd,
    input              rst_rd_ni,
    output             valid_rd,
    input              ready_rd,
    output [WIDTH-1:0] data_rd
);

    reg [WIDTH-1:0] mem [0:1];
    reg [1:0] wr_ptr;
    reg [1:0] rd_ptr;
    wire full;
    wire empty;

    always @(posedge clk_wr or negedge rst_wr_ni) begin
        if (!rst_wr_ni) begin
            wr_ptr <= 2'b00;
        end else if (valid_wr && !full) begin
            mem[wr_ptr] <= data_wr;
            wr_ptr <= wr_ptr + 1;
        end
    end

    always @(posedge clk_rd or negedge rst_rd_ni) begin
        if (!rst_rd_ni) begin
            rd_ptr <= 2'b00;
        end else if (valid_rd && ready_rd) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    assign full = (wr_ptr[1] != rd_ptr[1]) && (wr_ptr[0] == rd_ptr[0]);
    assign empty = (wr_ptr == rd_ptr);
    assign valid_rd = !empty;
    assign ready_wr = !full;
    assign data_rd = mem[rd_ptr];

endmodule
