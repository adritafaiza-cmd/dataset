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

    localparam DEPTH = 2**LOG_DEPTH;

    // Internal signals
    reg [LOG_DEPTH:0]      src_gray_cnt, dst_gray_cnt;
    reg [LOG_DEPTH:0]      src_gray_cnt_sync, dst_gray_cnt_sync;
    reg [LOG_DEPTH:0]      src_bin_cnt, dst_bin_cnt;
    reg [WIDTH-1:0]        fifo_mem [0:DEPTH-1];
    reg [LOG_DEPTH-1:0]    fifo_wr_ptr, fifo_rd_ptr;
    reg                    fifo_wr_en, fifo_rd_en;
    reg                    fifo_full, fifo_empty;

    // Gray code counters
    gray_counter #(.WIDTH(LOG_DEPTH+1)) gray_counter_src (
        .rst_ni    (src_rst_ni),
        .clk_i     (src_clk_i),
        .enable_i  (fifo_wr_en),
        .gray_cnt_o(src_gray_cnt)
    );

    gray_counter #(.WIDTH(LOG_DEPTH+1)) gray_counter_dst (
        .rst_ni    (dst_rst_ni),
        .clk_i     (dst_clk_i),
        .enable_i  (fifo_rd_en),
        .gray_cnt_o(dst_gray_cnt)
    );

    // Synchronize gray counters
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_gray_cnt_sync <= 0;
        end else begin
            src_gray_cnt_sync <= src_gray_cnt;
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_gray_cnt_sync <= 0;
        end else begin
            dst_gray_cnt_sync <= dst_gray_cnt;
        end
    end

    // Binary conversion
    always @(*) begin
        src_bin_cnt = src_gray_cnt ^ (src_gray_cnt >> 1);
        dst_bin_cnt = dst_gray_cnt ^ (dst_gray_cnt >> 1);
    end

    // FIFO pointers
    assign fifo_wr_ptr = src_bin_cnt[LOG_DEPTH-1:0];
    assign fifo_rd_ptr = dst_bin_cnt[LOG_DEPTH-1:0];

    // FIFO full and empty conditions
    assign fifo_full = (src_bin_cnt[LOG_DEPTH] != dst_bin_cnt_sync[LOG_DEPTH]) && (src_bin_cnt[LOG_DEPTH-1:0] == dst_bin_cnt_sync[LOG_DEPTH-1:0]);
    assign fifo_empty = (src_bin_cnt == dst_bin_cnt);

    // Write enable
    assign fifo_wr_en = src_valid_i && !fifo_full;

    // Read enable
    assign fifo_rd_en = dst_ready_i && !fifo_empty;

    // Source ready
    assign src_ready_o = !fifo_full;

    // Destination valid
    assign dst_valid_o = !fifo_empty;

    // FIFO memory write
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_mem <= '{default:0};
        end else if (fifo_wr_en) begin
            fifo_mem[fifo_wr_ptr] <= src_data_i;
        end
    end

    // FIFO memory read
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else if (fifo_rd_en) begin
            dst_data_o <= fifo_mem[fifo_rd_ptr];
        end
    end

endmodule

module gray_counter #(
    parameter WIDTH = 4
)(
    input                  rst_ni,
    input                  clk_i,
    input                  enable_i,
    output reg [WIDTH-1:0] gray_cnt_o
);

    reg [WIDTH-1:0] bin_cnt;

    // Reset and increment binary counter
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_cnt <= 0;
        end else if (enable_i) begin
            bin_cnt <= bin_cnt + 1;
        end
    end

    // Convert binary to gray code
    always @(*) begin
        gray_cnt_o = bin_cnt ^ (bin_cnt >> 1);
    end

endmodule
