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
    reg  [LOG_DEPTH:0]     src_wr_ptr_gray;
    reg  [LOG_DEPTH:0]     src_wr_ptr_gray_synced;
    wire [LOG_DEPTH-1:0]   src_wr_ptr_bin;
    reg  [LOG_DEPTH:0]     dst_rd_ptr_gray;
    reg  [LOG_DEPTH:0]     dst_rd_ptr_gray_synced;
    wire [LOG_DEPTH-1:0]   dst_rd_ptr_bin;
    reg  [WIDTH-1:0]       fifo_mem [0:(1<<LOG_DEPTH)-1];
    wire                   src_full;
    wire                   dst_empty;

    // Gray code to binary conversion
    gray_to_bin #(LOG_DEPTH+1) src_gray_to_bin (
        .gray(src_wr_ptr_gray_synced),
        .bin(src_wr_ptr_bin)
    );

    gray_to_bin #(LOG_DEPTH+1) dst_gray_to_bin (
        .gray(dst_rd_ptr_gray_synced),
        .bin(dst_rd_ptr_bin)
    );

    // Binary to Gray code conversion and synchronization
    bin_to_gray #(LOG_DEPTH+1) src_bin_to_gray (
        .bin(src_wr_ptr_gray[LOG_DEPTH:0]),
        .gray(src_wr_ptr_gray[LOG_DEPTH:0])
    );

    bin_to_gray #(LOG_DEPTH+1) dst_bin_to_gray (
        .bin(dst_rd_ptr_gray[LOG_DEPTH:0]),
        .gray(dst_rd_ptr_gray[LOG_DEPTH:0])
    );

    // Cross-domain synchronization
    sync_gray_counter #(LOG_DEPTH+1) sync_src_to_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .gray_i(src_wr_ptr_gray),
        .gray_o(src_wr_ptr_gray_synced)
    );

    sync_gray_counter #(LOG_DEPTH+1) sync_dst_to_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .gray_i(dst_rd_ptr_gray),
        .gray_o(dst_rd_ptr_gray_synced)
    );

    // Full and empty flags
    assign src_full = (src_wr_ptr_bin + 1) == dst_rd_ptr_bin;
    assign dst_empty = src_wr_ptr_bin == dst_rd_ptr_bin;

    // Source-side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_gray <= 0;
        end else if (src_valid_i && !src_full) begin
            fifo_mem[src_wr_ptr_bin] <= src_data_i;
            src_wr_ptr_gray <= src_wr_ptr_gray + 1;
        end
    end

    assign src_ready_o = !src_full;

    // Destination-side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_gray <= 0;
            dst_data_o <= 0;
            dst_valid_o <= 0;
        end else if (!dst_empty && dst_ready_i) begin
            dst_data_o <= fifo_mem[dst_rd_ptr_bin];
            dst_valid_o <= 1;
            dst_rd_ptr_gray <= dst_rd_ptr_gray + 1;
        end else if (dst_ready_i) begin
            dst_valid_o <= 0;
        end
    end

endmodule

// Helper module: Gray to Binary conversion
module gray_to_bin #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] gray,
    output [WIDTH-1:0] bin
);
    assign bin[WIDTH-1] = gray[WIDTH-1];
    genvar i;
    generate
        for (i = WIDTH-2; i >= 0; i = i - 1) begin : gen_gray_to_bin
            assign bin[i] = gray[i] ^ bin[i+1];
        end
    endgenerate
endmodule

// Helper module: Binary to Gray conversion
module bin_to_gray #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] bin,
    output [WIDTH-1:0] gray
);
    assign gray[WIDTH-1] = bin[WIDTH-1];
    genvar i;
    generate
        for (i = WIDTH-2; i >= 0; i = i - 1) begin : gen_bin_to_gray
            assign gray[i] = bin[i] ^ bin[i+1];
        end
    endgenerate
endmodule

// Helper module: Gray counter synchronization
module sync_gray_counter #(
    parameter WIDTH = 4
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     gray_i,
    output [WIDTH-1:0]     gray_o
);
    reg  [WIDTH-1:0]     gray_synced_1;
    reg  [WIDTH-1:0]     gray_synced_2;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gray_synced_1 <= 0;
            gray_synced_2 <= 0;
        end else begin
            gray_synced_1 <= gray_i;
            gray_synced_2 <= gray_synced_1;
        end
    end

    assign gray_o = gray_synced_2;
endmodule
