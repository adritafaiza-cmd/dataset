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
    wire [LOG_DEPTH:0] gray_src_count;
    wire [LOG_DEPTH:0] gray_dst_count;
    wire [LOG_DEPTH:0] sync_src_gray;
    wire [LOG_DEPTH:0] sync_dst_gray;
    wire [LOG_DEPTH-1:0] src_bin_count;
    wire [LOG_DEPTH-1:0] dst_bin_count;
    wire src_wr_en;
    wire fifo_full;
    wire fifo_empty;

    // Gray counters
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_src_counter (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .wr_en(src_wr_en),
        .rd_en(1'b0),
        .sync_gray(sync_dst_gray),
        .gray_count(gray_src_count),
        .binary_count(src_bin_count)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_dst_counter (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .wr_en(1'b0),
        .rd_en(dst_ready_i & dst_valid_o),
        .sync_gray(sync_src_gray),
        .gray_count(gray_dst_count),
        .binary_count(dst_bin_count)
    );

    // Synchronizers
    sync_register #(.LOG_DEPTH(LOG_DEPTH)) sync_src_gray_reg (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .d(gray_src_count),
        .q(sync_src_gray)
    );

    sync_register #(.LOG_DEPTH(LOG_DEPTH)) sync_dst_gray_reg (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .d(gray_dst_count),
        .q(sync_dst_gray)
    );

    // FIFO memory
    fifo_memory #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_mem (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .wr_addr(src_bin_count),
        .wr_en(src_wr_en),
        .wr_data(src_data_i),
        .rd_addr(dst_bin_count),
        .rd_data(dst_data_o)
    );

    // FIFO control logic
    assign src_wr_en = src_valid_i & ~fifo_full;
    assign src_ready_o = ~fifo_full;

    // FIFO status signals
    assign fifo_full = (gray_src_count == {1'b1, sync_dst_gray[LOG_DEPTH-1:0]});
    assign fifo_empty = (gray_src_count == gray_dst_count);

    // Destination valid signal
    assign dst_valid_o = ~fifo_empty;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_ni,
    input                  wr_en,
    input                  rd_en,
    input  [LOG_DEPTH:0] sync_gray,
    output [LOG_DEPTH:0] gray_count,
    output [LOG_DEPTH-1:0] binary_count
);

    reg [LOG_DEPTH:0] count;
    reg [LOG_DEPTH:0] next_count;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            count <= '0;
        end else begin
            if (wr_en) begin
                count <= next_count;
            end else if (rd_en) begin
                count <= {count[LOG_DEPTH-1:0], ~count[LOG_DEPTH]};
            end else if (count != sync_gray) begin
                count <= sync_gray;
            end
        end
    end

    assign next_count = count + 1;
    assign gray_count = (count ^ (count >> 1));
    assign binary_count = count[LOG_DEPTH-1:0];

endmodule

module sync_register #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_ni,
    input  [LOG_DEPTH:0] d,
    output [LOG_DEPTH:0] q
);

    reg [LOG_DEPTH:0] q1;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            q1 <= '0;
            q <= '0;
        end else begin
            q1 <= d;
            q <= q1;
        end
    end

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_ni,
    input  [LOG_DEPTH-1:0] wr_addr,
    input                  wr_en,
    input  [WIDTH-1:0]     wr_data,
    input  [LOG_DEPTH-1:0] rd_addr,
    output [WIDTH-1:0]     rd_data
);

    reg [WIDTH-1:0] mem [0:(2**LOG_DEPTH)-1];

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            rd_data <= '0;
        end else begin
            rd_data <= mem[rd_addr];
            if (wr_en) begin
                mem[wr_addr] <= wr_data;
            end
        end
    end

endmodule
