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
    wire [LOG_DEPTH-1:0] src_gray_counter;
    wire [LOG_DEPTH-1:0] dst_gray_counter;
    wire [LOG_DEPTH-1:0] src_bin_counter;
    wire [LOG_DEPTH-1:0] dst_bin_counter;
    wire                 src_wr_en;
    wire                 dst_rd_en;
    wire                 src_full;
    wire                 src_empty;
    wire                 dst_full;
    wire                 dst_empty;
    wire                 sync_src_empty;
    wire                 sync_dst_empty;
    wire                 sync_src_full;
    wire                 sync_dst_full;
    wire [WIDTH-1:0]     memory_rd_data;

    // FIFO core
    async_fifo_core #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_core (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_data_i(src_data_i),
        .src_valid_i(src_valid_i),
        .src_ready_o(src_ready_o),
        .dst_rst_ni(dst_rst_ni),
        .dst_clk_i(dst_clk_i),
        .dst_data_o(dst_data_o),
        .dst_valid_o(dst_valid_o),
        .dst_ready_i(dst_ready_i)
    );

endmodule

module async_fifo_core #(
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
    reg [LOG_DEPTH-1:0]    src_gray_counter;
    reg [LOG_DEPTH-1:0]    dst_gray_counter;
    wire [LOG_DEPTH-1:0]   src_bin_counter;
    wire [LOG_DEPTH-1:0]   dst_bin_counter;
    reg                    src_wr_en;
    reg                    dst_rd_en;
    wire                   src_full;
    wire                   src_empty;
    wire                   dst_full;
    wire                   dst_empty;
    wire                   sync_src_empty;
    wire                   sync_dst_empty;
    wire                   sync_src_full;
    wire                   sync_dst_full;
    wire [WIDTH-1:0]       memory_rd_data;

    // Gray counters
    cdc_gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) gray_counter_src (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .en(src_wr_en),
        .gray_o(src_gray_counter)
    );

    cdc_gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) gray_counter_dst (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .en(dst_rd_en),
        .gray_o(dst_gray_counter)
    );

    // Gray to binary converters
    cdc_gray_to_bin #(
        .LOG_DEPTH(LOG_DEPTH)
    ) gray_to_bin_src (
        .gray_i(dst_gray_counter),
        .clk_i(src_clk_i),
        .bin_o(src_bin_counter)
    );

    cdc_gray_to_bin #(
        .LOG_DEPTH(LOG_DEPTH)
    ) gray_to_bin_dst (
        .gray_i(src_gray_counter),
        .clk_i(dst_clk_i),
        .bin_o(dst_bin_counter)
    );

    // Synchronization bits
    cdc_sync_bit sync_src_empty_inst (
        .d_i(src_empty),
        .clk_i(dst_clk_i),
        .d_o(sync_src_empty)
    );

    cdc_sync_bit sync_dst_empty_inst (
        .d_i(dst_empty),
        .clk_i(src_clk_i),
        .d_o(sync_dst_empty)
    );

    cdc_sync_bit sync_src_full_inst (
        .d_i(src_full),
        .clk_i(dst_clk_i),
        .d_o(sync_src_full)
    );

    cdc_sync_bit sync_dst_full_inst (
        .d_i(dst_full),
        .clk_i(src_clk_i),
        .d_o(sync_dst_full)
    );

    // FIFO memory
    memory #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) memory_inst (
        .wr_en(src_wr_en),
        .wr_addr(src_bin_counter),
        .wr_data(src_data_i),
        .rd_en(dst_rd_en),
        .rd_addr(dst_bin_counter),
        .rd_data(memory_rd_data)
    );

    // FIFO control logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_en <= 1'b0;
        end else begin
            src_wr_en <= src_valid_i & ~sync_src_full;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_en <= 1'b0;
        end else begin
            dst_rd_en <= dst_ready_i & ~sync_dst_empty;
        end
    end

    // FIFO status flags
    assign src_full = (src_bin_counter == (dst_bin_counter + 1)) & ~dst_empty;
    assign src_empty = (src_gray_counter == dst_gray_counter);
    assign dst_full = (dst_bin_counter == (src_bin_counter + 1)) & ~src_empty;
    assign dst_empty = (src_gray_counter == dst_gray_counter);

    // Ready and valid signals
    assign src_ready_o = ~src_full;
    assign dst_valid_o = ~dst_empty;
    assign dst_data_o = memory_rd_data;

endmodule

module cdc_gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  en,
    output [LOG_DEPTH-1:0] gray_o
);

    reg [LOG_DEPTH-1:0] gray;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gray <= {LOG_DEPTH{1'b0}};
        end else if (en) begin
            gray <= gray + 1;
        end
    end

    assign gray_o = gray ^ (gray >> 1);

endmodule

module cdc_gray_to_bin #(
    parameter LOG_DEPTH = 3
)(
    input  [LOG_DEPTH-1:0] gray_i,
    input                  clk_i,
    output [LOG_DEPTH-1:0] bin_o
);

    reg [LOG_DEPTH-1:0] bin;

    always @(posedge clk_i) begin
        bin[0] <= gray_i[0];
        for (integer i = 1; i < LOG_DEPTH; i = i + 1) begin
            bin[i] <= bin[i-1] ^ gray_i[i];
        end
    end

    assign bin_o = bin;

endmodule

module cdc_sync_bit (
    input  d_i,
    input  clk_i,
    output d_o
);

    reg d_sync1;
    reg d_sync2;

    always @(posedge clk_i) begin
        d_sync1 <= d_i;
        d_sync2 <= d_sync1;
    end

    assign d_o = d_sync2;

endmodule

module memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  wr_en,
    input  [LOG_DEPTH-1:0] wr_addr,
    input  [WIDTH-1:0]     wr_data,
    input                  rd_en,
    input  [LOG_DEPTH-1:0] rd_addr,
    output [WIDTH-1:0]     rd_data
);

    reg [WIDTH-1:0] mem [0:(1<<LOG_DEPTH)-1];

    always @(posedge wr_en) begin
        mem[wr_addr] <= wr_data;
    end

    always @(posedge rd_en) begin
        rd_data <= mem[rd_addr];
    end

endmodule
