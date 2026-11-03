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

    wire [LOG_DEPTH:0] src_gray_count;
    wire [LOG_DEPTH:0] dst_gray_count;
    wire [LOG_DEPTH:0] src_gray_sync;
    wire [LOG_DEPTH:0] dst_gray_sync;

    // Source gray counter
    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) src_gray_counter (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .en_i(src_valid_i & src_ready_o),
        .count_o(src_gray_count)
    );

    // Destination gray counter
    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_gray_counter (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .en_i(dst_valid_o & dst_ready_i),
        .count_o(dst_gray_count)
    );

    // Synchronize source gray count to destination domain
    cross_domain_sync #(
        .LOG_DEPTH(LOG_DEPTH)
    ) src_gray_sync_inst (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .async_i(src_gray_count),
        .sync_o(src_gray_sync)
    );

    // Synchronize destination gray count to source domain
    cross_domain_sync #(
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_gray_sync_inst (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .async_i(dst_gray_count),
        .sync_o(dst_gray_sync)
    );

    // FIFO memory
    fifo_memory #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_mem (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .wr_en_i(src_valid_i & src_ready_o),
        .wr_addr_i(src_gray_count),
        .wr_data_i(src_data_i),
        .rd_addr_i(dst_gray_sync),
        .rd_data_o(dst_data_o)
    );

    // Source ready logic
    assign src_ready_o = (src_gray_count != src_gray_sync);

    // Destination valid logic
    reg [SYNC_STAGES:0] valid_pipeline;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            valid_pipeline <= 0;
        end else begin
            valid_pipeline[0] <= (src_gray_sync != dst_gray_sync);
            valid_pipeline[SYNC_STAGES:1] <= valid_pipeline[SYNC_STAGES-1:0];
        end
    end

    assign dst_valid_o = valid_pipeline[SYNC_STAGES];

endmodule

// Gray counter module
module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  en_i,
    output [LOG_DEPTH:0] count_o
);

    reg [LOG_DEPTH:0] bin_count;
    reg [LOG_DEPTH:0] gray_count;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_count <= 0;
        end else if (en_i) begin
            bin_count <= bin_count + 1;
        end
    end

    assign gray_count = {bin_count[LOG_DEPTH], bin_count[LOG_DEPTH:1] ^ bin_count[LOG_DEPTH-1:0]};
    assign count_o = gray_count;

endmodule

// Cross-domain synchronization module
module cross_domain_sync #(
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input  [LOG_DEPTH:0] async_i,
    output [LOG_DEPTH:0] sync_o
);

    reg [LOG_DEPTH:0] sync_reg [SYNC_STAGES:0];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= 0;
        end else begin
            sync_reg[0] <= async_i;
            sync_reg[SYNC_STAGES:1] <= sync_reg[SYNC_STAGES-1:0];
        end
    end

    assign sync_o = sync_reg[SYNC_STAGES];

endmodule

// FIFO memory module
module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  wr_en_i,
    input  [LOG_DEPTH:0] wr_addr_i,
    input  [WIDTH-1:0]   wr_data_i,
    input  [LOG_DEPTH:0] rd_addr_i,
    output [WIDTH-1:0]   rd_data_o
);

    reg [WIDTH-1:0] memory [0:(1<<LOG_DEPTH)-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (integer i = 0; i < (1<<LOG_DEPTH); i = i + 1) begin
                memory[i] <= 0;
            end
        end else if (wr_en_i) begin
            memory[wr_addr_i] <= wr_data_i;
        end
    end

    assign rd_data_o = memory[rd_addr_i];

endmodule
