module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Internal signals
    reg [LOG_DEPTH:0]      src_gray_w;
    reg [LOG_DEPTH:0]      dst_gray_w_sync;
    reg [LOG_DEPTH:0]      dst_bin_w_sync;
    reg [LOG_DEPTH:0]      dst_gray_r;
    reg [LOG_DEPTH:0]      src_gray_r_sync;
    reg [LOG_DEPTH:0]      src_bin_r_sync;
    reg                    write_enable;
    reg                    read_enable;
    reg [LOG_DEPTH:0]      write_ptr;
    reg [LOG_DEPTH:0]      read_ptr;
    reg                    full;
    reg                    empty;

    // FIFO memory
    reg [WIDTH-1:0]        fifo_mem [0:(1 << LOG_DEPTH) - 1];

    // Write enable generation
    assign write_enable = src_valid_i & ~full & ~src_clear_i;

    // Read enable generation
    assign read_enable = dst_ready_i & ~empty & ~dst_clear_i;

    // Source clear pending output
    assign src_clear_pending_o = src_clear_i | full;

    // Destination clear pending output
    assign dst_clear_pending_o = dst_clear_i | empty;

    // Source ready output
    assign src_ready_o = ~full;

    // Destination valid output
    assign dst_valid_o = ~empty;

    // FIFO memory write
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            write_ptr <= 0;
        end else if (write_enable) begin
            fifo_mem[write_ptr] <= src_data_i;
            write_ptr <= write_ptr + 1;
        end else if (src_clear_i) begin
            write_ptr <= 0;
        end
    end

    // FIFO memory read
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_ptr <= 0;
        end else if (read_enable) begin
            read_ptr <= read_ptr + 1;
        end else if (dst_clear_i) begin
            read_ptr <= 0;
        end
    end

    // FIFO data output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else if (read_enable) begin
            dst_data_o <= fifo_mem[read_ptr];
        end else if (dst_clear_i) begin
            dst_data_o <= 0;
        end
    end

    // Full flag generation
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            full <= 0;
        end else begin
            full <= (write_ptr == {1'b1, dst_bin_w_sync[LOG_DEPTH:1]});
        end
    end

    // Empty flag generation
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            empty <= 1;
        end else begin
            empty <= (read_ptr == {1'b0, src_bin_r_sync[LOG_DEPTH:1]});
        end
    end

    // Gray counters and synchronizers
    gray_counter src_gray_counter (
        .clk    (src_clk_i),
        .rst_n  (src_rst_ni),
        .clear  (src_clear_i),
        .enable (write_enable),
        .gray   (src_gray_w)
    );

    gray_counter dst_gray_counter (
        .clk    (dst_clk_i),
        .rst_n  (dst_rst_ni),
        .clear  (dst_clear_i),
        .enable (read_enable),
        .gray   (dst_gray_r)
    );

    synchronizer src_gray_sync (
        .clk     (dst_clk_i),
        .rst_n   (dst_rst_ni),
        .async_in(src_gray_w),
        .sync_out(dst_gray_w_sync)
    );

    synchronizer dst_gray_sync (
        .clk     (src_clk_i),
        .rst_n   (src_rst_ni),
        .async_in(dst_gray_r),
        .sync_out(src_gray_r_sync)
    );

    gray_to_bin src_gray_to_bin (
        .gray(dst_gray_w_sync),
        .bin (dst_bin_w_sync)
    );

    gray_to_bin dst_gray_to_bin (
        .gray(src_gray_r_sync),
        .bin (src_bin_r_sync)
    );

endmodule

module gray_counter (
    input                  clk,
    input                  rst_n,
    input                  clear,
    input                  enable,
    output reg [LOG_DEPTH:0] gray
);

    reg [LOG_DEPTH:0] bin;
    reg [LOG_DEPTH:0] next_bin;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            bin <= 0;
        end else if (enable) begin
            bin <= next_bin;
        end
    end

    always @(*) begin
        next_bin = bin + 1;
        gray = bin ^ (bin >> 1);
    end

endmodule

module gray_to_bin (
    input  [LOG_DEPTH:0] gray,
    output [LOG_DEPTH:0] bin
);

    reg [LOG_DEPTH:0] shifted_gray;

    always @(*) begin
        shifted_gray = gray >> 1;
        bin = gray ^ shifted_gray;
    end

endmodule

module synchronizer #(
    parameter LOG_DEPTH = 3
)(
    input  clk,
    input  rst_n,
    input  [LOG_DEPTH:0] async_in,
    output [LOG_DEPTH:0] sync_out
);

    reg [LOG_DEPTH:0] stage1;
    reg [LOG_DEPTH:0] stage2;
    reg [LOG_DEPTH:0] stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1 <= 0;
            stage2 <= 0;
            stage3 <= 0;
        end else begin
            stage1 <= async_in;
            stage2 <= stage1;
            stage3 <= stage2;
        end
    end

    assign sync_out = stage3;

endmodule
