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
    reg [LOG_DEPTH:0] src_gray, dst_gray, src_gray_synced, dst_gray_synced;
    reg [LOG_DEPTH:0] src_bin, dst_bin, src_bin_next, dst_bin_next;
    reg src_full, src_empty, dst_full, dst_empty;
    reg src_clear_active, dst_clear_active;
    reg [WIDTH-1:0] mem [(1<<LOG_DEPTH)-1:0];

    // Gray counter for source
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_active),
        .bin_in(src_bin_next),
        .gray_in(),
        .bin_out(src_bin),
        .gray_out(src_gray)
    );

    // Gray counter for destination
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_active),
        .bin_in(dst_bin_next),
        .gray_in(),
        .bin_out(dst_bin),
        .gray_out(dst_gray)
    );

    // Asynchronous register for source to destination
    async_register #(.WIDTH(LOG_DEPTH+1)) async_reg_src_to_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(src_gray),
        .data_o(src_gray_synced)
    );

    // Asynchronous register for destination to source
    async_register #(.WIDTH(LOG_DEPTH+1)) async_reg_dst_to_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(dst_gray),
        .data_o(dst_gray_synced)
    );

    // Source side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_active <= 0;
            src_clear_pending_o <= 0;
            src_bin <= 0;
            src_gray <= 0;
        end else begin
            if (src_clear_i) begin
                src_clear_active <= 1;
                src_clear_pending_o <= 1;
                src_bin <= 0;
                src_gray <= 0;
            end else if (src_clear_active) begin
                if (src_gray_synced == src_gray) begin
                    src_clear_active <= 0;
                    src_clear_pending_o <= 0;
                end
            end else begin
                if (src_valid_i && src_ready_o) begin
                    mem[src_bin] <= src_data_i;
                    src_bin_next <= src_bin + 1;
                end
                src_bin <= src_bin_next;
            end
        end
    end

    // Destination side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_active <= 0;
            dst_clear_pending_o <= 0;
            dst_bin <= 0;
            dst_gray <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_active <= 1;
                dst_clear_pending_o <= 1;
                dst_bin <= 0;
                dst_gray <= 0;
            end else if (dst_clear_active) begin
                if (dst_gray_synced == dst_gray) begin
                    dst_clear_active <= 0;
                    dst_clear_pending_o <= 0;
                end
            end else begin
                if (dst_ready_i && dst_valid_o) begin
                    dst_bin_next <= dst_bin + 1;
                end
                dst_bin <= dst_bin_next;
            end
        end
    end

    // Calculate full and empty flags
    assign src_full = (src_bin_next == dst_gray_synced);
    assign src_empty = (src_gray == dst_gray_synced);
    assign dst_full = (dst_bin_next == src_gray_synced);
    assign dst_empty = (dst_gray == src_gray_synced);

    // Source ready and destination valid signals
    assign src_ready_o = src_empty || !src_valid_i;
    assign dst_valid_o = !dst_empty;

    // Destination data output
    assign dst_data_o = mem[dst_bin];

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    input  [LOG_DEPTH:0] bin_in,
    input  [LOG_DEPTH:0] gray_in,
    output [LOG_DEPTH:0] bin_out,
    output [LOG_DEPTH:0] gray_out
);

    reg [LOG_DEPTH:0] gray, bin;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gray <= 0;
            bin <= 0;
        end else if (clear_i) begin
            gray <= 0;
            bin <= 0;
        end else begin
            bin <= bin_in;
            gray <= (bin_in >> 1) ^ bin_in;
        end
    end

    assign bin_out = bin;
    assign gray_out = gray;

endmodule

module async_register #(
    parameter WIDTH = 4
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0] data_i,
    output [WIDTH-1:0] data_o
);

    reg [WIDTH-1:0] data_reg;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : sync_stages
            reg stage;
            always @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    stage <= 0;
                end else begin
                    if (i == 0) begin
                        stage <= data_i[i];
                    end else begin
                        stage <= sync_stages[i-1].stage;
                    end
                end
            end
            assign data_o[i] = sync_stages[WIDTH-1].stage;
        end
    endgenerate

endmodule
