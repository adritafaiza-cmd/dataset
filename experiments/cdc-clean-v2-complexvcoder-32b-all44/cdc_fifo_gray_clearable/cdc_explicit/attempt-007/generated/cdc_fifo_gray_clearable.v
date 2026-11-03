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
    wire [LOG_DEPTH:0] src_gray_out;
    wire [LOG_DEPTH:0] src_gray_out_r;
    wire [LOG_DEPTH:0] dst_gray_in;
    wire [LOG_DEPTH:0] dst_gray_in_r;
    wire               dst_clear_sync;
    wire               dst_clear_sync_r;
    reg  [LOG_DEPTH:0] src_ptr;
    reg  [LOG_DEPTH:0] src_ptr_gray;
    reg  [LOG_DEPTH:0] dst_ptr;
    reg  [LOG_DEPTH:0] dst_ptr_gray;
    reg  [LOG_DEPTH:0] src_gray_cnt;
    reg  [LOG_DEPTH:0] dst_gray_cnt;
    reg                src_full;
    reg                src_empty;
    reg                dst_full;
    reg                dst_empty;
    reg  [WIDTH-1:0] fifo_memory [0:(1<<LOG_DEPTH)-1];
    reg                src_write_en;
    reg                dst_read_en;
    reg                src_clear_pending;
    reg                dst_clear_pending;

    // Gray code counters for source and destination
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_src_counter (
        .clk       (src_clk_i),
        .rst_ni    (src_rst_ni),
        .clear_i   (src_clear_i),
        .gray_o    (src_gray_out),
        .gray_o_r  (src_gray_out_r)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_dst_counter (
        .clk       (dst_clk_i),
        .rst_ni    (dst_rst_ni),
        .clear_i   (dst_clear_sync),
        .gray_o    (dst_gray_in),
        .gray_o_r  (dst_gray_in_r)
    );

    // Synchronizers for Gray codes and clear signal
    sync_register sync_gray (
        .clk_i     (src_clk_i),
        .rst_ni_i  (src_rst_ni),
        .data_i    (src_gray_out),
        .clk_o     (dst_clk_i),
        .rst_ni_o  (dst_rst_ni),
        .data_o    (dst_gray_in)
    );

    sync_register sync_gray_r (
        .clk_i     (src_clk_i),
        .rst_ni_i  (src_rst_ni),
        .data_i    (src_gray_out_r),
        .clk_o     (dst_clk_i),
        .rst_ni_o  (dst_rst_ni),
        .data_o    (dst_gray_in_r)
    );

    sync_register sync_clear (
        .clk_i     (src_clk_i),
        .rst_ni_i  (src_rst_ni),
        .data_i    (src_clear_i),
        .clk_o     (dst_clk_i),
        .rst_ni_o  (dst_rst_ni),
        .data_o    (dst_clear_sync)
    );

    sync_register sync_clear_r (
        .clk_i     (src_clk_i),
        .rst_ni_i  (src_rst_ni),
        .data_i    (src_clear_i),
        .clk_o     (dst_clk_i),
        .rst_ni_o  (dst_rst_ni),
        .data_o    (dst_clear_sync_r)
    );

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= 0;
            src_ptr_gray <= 0;
            src_gray_cnt <= 0;
            src_full <= 0;
            src_empty <= 1;
            src_clear_pending <= 0;
        end else begin
            if (src_clear_i) begin
                src_ptr <= 0;
                src_ptr_gray <= 0;
                src_gray_cnt <= 0;
                src_full <= 0;
                src_empty <= 1;
                src_clear_pending <= 1;
            end else begin
                if (src_write_en) begin
                    src_ptr <= src_ptr + 1;
                    src_ptr_gray <= src_ptr_gray + 1;
                    src_gray_cnt <= src_gray_cnt + 1;
                    if (src_gray_cnt == (1 << LOG_DEPTH) - 1) begin
                        src_full <= 1;
                    end
                    if (src_empty) begin
                        src_empty <= 0;
                    end
                end else if (src_read_en) begin
                    if (src_full) begin
                        src_full <= 0;
                    end
                end
            end
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_memory[src_ptr] <= 0;
        end else if (src_write_en) begin
            fifo_memory[src_ptr] <= src_data_i;
        end
    end

    assign src_ready_o = !src_full;
    assign src_write_en = src_valid_i & src_ready_o;

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= 0;
            dst_ptr_gray <= 0;
            dst_gray_cnt <= 0;
            dst_full <= 0;
            dst_empty <= 1;
            dst_clear_pending <= 0;
        end else begin
            if (dst_clear_sync) begin
                dst_ptr <= 0;
                dst_ptr_gray <= 0;
                dst_gray_cnt <= 0;
                dst_full <= 0;
                dst_empty <= 1;
                dst_clear_pending <= 1;
            end else begin
                if (dst_read_en) begin
                    dst_ptr <= dst_ptr + 1;
                    dst_ptr_gray <= dst_ptr_gray + 1;
                    dst_gray_cnt <= dst_gray_cnt + 1;
                    if (dst_gray_cnt == (1 << LOG_DEPTH) - 1) begin
                        dst_empty <= 1;
                    end
                    if (dst_full) begin
                        dst_full <= 0;
                    end
                end else if (src_write_en) begin
                    if (dst_empty) begin
                        dst_empty <= 0;
                    end
                end
            end
        end
    end

    assign dst_read_en = dst_valid_o & dst_ready_i;
    assign dst_data_o = fifo_memory[dst_ptr];
    assign dst_valid_o = !dst_empty & !dst_clear_sync;

    // Clear pending signals
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 0;
        end else if (src_clear_i) begin
            src_clear_pending <= 1;
        end else if (src_empty) begin
            src_clear_pending <= 0;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 0;
        end else if (dst_clear_sync) begin
            dst_clear_pending <= 1;
        end else if (dst_empty) begin
            dst_clear_pending <= 0;
        end
    end

    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_ni,
    input                  clear_i,
    output [LOG_DEPTH:0] gray_o,
    output [LOG_DEPTH:0] gray_o_r
);

    reg [LOG_DEPTH:0] counter;
    reg [LOG_DEPTH:0] gray_code;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            counter <= 0;
            gray_code <= 0;
        end else if (clear_i) begin
            counter <= 0;
            gray_code <= 0;
        end else begin
            counter <= counter + 1;
            gray_code <= (counter >> 1) ^ counter;
        end
    end

    assign gray_o = gray_code;
    assign gray_o_r = gray_code;

endmodule

module sync_register (
    input                  clk_i,
    input                  rst_ni_i,
    input                  data_i,
    input                  clk_o,
    input                  rst_ni_o,
    output reg             data_o
);

    reg sync_reg;

    always @(posedge clk_i or negedge rst_ni_i) begin
        if (!rst_ni_i) begin
            sync_reg <= 0;
        end else begin
            sync_reg <= data_i;
        end
    end

    always @(posedge clk_o or negedge rst_ni_o) begin
        if (!rst_ni_o) begin
            data_o <= 0;
        end else begin
            data_o <= sync_reg;
        end
    end

endmodule
