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
    reg [LOG_DEPTH:0] src_wr_ptr_gray;
    reg [LOG_DEPTH:0] src_wr_ptr_bin;
    reg [LOG_DEPTH:0] dst_wr_ptr_gray;
    reg [LOG_DEPTH:0] dst_rd_ptr_gray;
    reg [LOG_DEPTH:0] dst_rd_ptr_bin;
    reg [LOG_DEPTH:0] src_rd_ptr_gray;
    reg               src_wr_en;
    reg               dst_rd_en;

    // Gray code counters
    gray_counter src_gray_counter (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .en_i(src_wr_en),
        .gray_o(src_wr_ptr_gray)
    );

    gray_counter dst_gray_counter (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .en_i(dst_rd_en),
        .gray_o(dst_rd_ptr_gray)
    );

    // Gray to binary converters
    gray_to_bin src_gray_to_bin (
        .gray_i(src_wr_ptr_gray),
        .bin_o(src_wr_ptr_bin)
    );

    gray_to_bin dst_gray_to_bin (
        .gray_i(dst_rd_ptr_gray),
        .bin_o(dst_rd_ptr_bin)
    );

    // Cross-domain synchronization
    cross_domain_sync src_to_dst_sync (
        .src_clk_i(src_clk_i),
        .dst_clk_i(dst_clk_i),
        .async_in(src_wr_ptr_gray),
        .sync_out(dst_wr_ptr_gray)
    );

    cross_domain_sync dst_to_src_sync (
        .src_clk_i(dst_clk_i),
        .dst_clk_i(src_clk_i),
        .async_in(dst_rd_ptr_gray),
        .sync_out(src_rd_ptr_gray)
    );

    // FIFO memory
    fifo_memory fifo_memory_inst (
        .clk_i(src_clk_i),
        .wr_en_i(src_wr_en),
        .wr_addr_i(src_wr_ptr_bin),
        .data_i(src_data_i),
        .rd_clk_i(dst_clk_i),
        .rd_en_i(dst_rd_en),
        .rd_addr_i(dst_rd_ptr_bin),
        .data_o(dst_data_o)
    );

    // Source write enable logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_en <= 1'b0;
        end else begin
            src_wr_en <= src_valid_i && (src_wr_ptr_bin != dst_wr_ptr_bin);
        end
    end

    // Destination read enable logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_en <= 1'b0;
        end else begin
            dst_rd_en <= dst_ready_i && (src_wr_ptr_bin != dst_rd_ptr_bin);
        end
    end

    // Source ready and destination valid
    assign src_ready_o = src_wr_en;
    assign dst_valid_o = (src_wr_ptr_bin != dst_rd_ptr_bin);

endmodule

module gray_counter (
    input clk_i,
    input rst_ni,
    input en_i,
    output reg [LOG_DEPTH:0] gray_o
);

    reg [LOG_DEPTH:0] count_bin;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count_bin <= 0;
            gray_o <= 0;
        end else if (en_i) begin
            count_bin <= count_bin + 1;
            gray_o <= (count_bin + 1) ^ count_bin;
        end
    end

endmodule

module gray_to_bin (
    input [LOG_DEPTH:0] gray_i,
    output reg [LOG_DEPTH:0] bin_o
);

    always @(*) begin
        bin_o[LOG_DEPTH] = gray_i[LOG_DEPTH];
        for (integer i = LOG_DEPTH - 1; i >= 0; i = i - 1) begin
            bin_o[i] = bin_o[i + 1] ^ gray_i[i];
        end
    end

endmodule

module cross_domain_sync #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input src_clk_i,
    input dst_clk_i,
    input [LOG_DEPTH:0] async_in,
    output reg [LOG_DEPTH:0] sync_out
);

    reg [LOG_DEPTH:0] sync_reg [SYNC_STAGES-1:0];

    always @(posedge src_clk_i) begin
        sync_reg[0] <= async_in;
        for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
            sync_reg[i] <= sync_reg[i - 1];
        end
    end

    always @(posedge dst_clk_i) begin
        sync_out <= sync_reg[SYNC_STAGES - 1];
    end

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input clk_i,
    input wr_en_i,
    input [LOG_DEPTH:0] wr_addr_i,
    input [WIDTH-1:0] data_i,
    input rd_clk_i,
    input rd_en_i,
    input [LOG_DEPTH:0] rd_addr_i,
    output reg [WIDTH-1:0] data_o
);

    reg [WIDTH-1:0] mem [0:(2**LOG_DEPTH) - 1];

    always @(posedge clk_i) begin
        if (wr_en_i) begin
            mem[wr_addr_i] <= data_i;
        end
    end

    always @(posedge rd_clk_i) begin
        if (rd_en_i) begin
            data_o <= mem[rd_addr_i];
        end
    end

endmodule
