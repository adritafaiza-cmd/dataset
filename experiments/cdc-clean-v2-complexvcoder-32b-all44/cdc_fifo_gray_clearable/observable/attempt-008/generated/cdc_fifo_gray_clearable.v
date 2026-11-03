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

    localparam DEPTH = 1 << LOG_DEPTH;

    // Source side signals
    reg [LOG_DEPTH:0] src_wptr_gray;
    reg [LOG_DEPTH:0] src_wptr_gray_next;
    reg [LOG_DEPTH:0] src_rptr_gray_sync;
    reg [WIDTH-1:0] fifo_memory [DEPTH-1:0];
    reg src_full;
    reg src_clear;

    // Destination side signals
    reg [LOG_DEPTH:0] dst_rptr_gray;
    reg [LOG_DEPTH:0] dst_rptr_gray_sync;
    reg [LOG_DEPTH:0] dst_wptr_gray_sync;
    reg dst_empty;
    reg dst_clear;

    // Gray counter for source
    gray_counter src_gray_counter (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .gray_i(src_wptr_gray_next),
        .gray_o(src_wptr_gray)
    );

    // Gray counter for destination
    gray_counter dst_gray_counter (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .gray_i(dst_rptr_gray),
        .gray_o(dst_rptr_gray)
    );

    // Synchronizer for source write pointer
    synchronizer #(.WIDTH(LOG_DEPTH+1)) wptr_gray_sync (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .async_i(src_wptr_gray),
        .sync_o(dst_wptr_gray_sync)
    );

    // Synchronizer for destination read pointer
    synchronizer #(.WIDTH(LOG_DEPTH+1)) rptr_gray_sync (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .async_i(dst_rptr_gray),
        .sync_o(src_rptr_gray_sync)
    );

    // Source side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wptr_gray <= 0;
            src_wptr_gray_next <= 0;
            src_clear <= 0;
        end else begin
            src_clear <= src_clear_i;
            if (src_clear_i) begin
                src_wptr_gray <= 0;
                src_wptr_gray_next <= 0;
            end else if (!src_full && src_valid_i) begin
                src_wptr_gray_next <= src_wptr_gray + 1;
            end
        end
    end

    // Calculate full flag
    assign src_full = (src_wptr_gray_next == {~dst_wptr_gray_sync[LOG_DEPTH], dst_wptr_gray_sync[LOG_DEPTH-1:0] + 1});

    // Source ready output
    assign src_ready_o = !src_full;

    // Source clear pending output
    assign src_clear_pending_o = src_clear;

    // Destination side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rptr_gray <= 0;
            dst_clear <= 0;
        end else begin
            dst_clear <= dst_clear_i;
            if (dst_clear_i) begin
                dst_rptr_gray <= 0;
            end else if (!dst_empty && dst_ready_i) begin
                dst_rptr_gray <= dst_rptr_gray + 1;
            end
        end
    end

    // Calculate empty flag
    assign dst_empty = (src_wptr_gray_sync == dst_rptr_gray);

    // Destination valid output
    assign dst_valid_o = !dst_empty;

    // Destination clear pending output
    assign dst_clear_pending_o = dst_clear;

    // FIFO memory read and write
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_memory <= '{default:0};
        end else if (!src_full && src_valid_i) begin
            fifo_memory[src_wptr_gray[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else if (!dst_empty && dst_ready_i) begin
            dst_data_o <= fifo_memory[dst_rptr_gray[LOG_DEPTH-1:0]];
        end
    end

endmodule

module gray_counter (
    input                  rst_ni,
    input                  clk_i,
    input  [LOG_DEPTH:0]   gray_i,
    output [LOG_DEPTH:0]   gray_o
);

    reg [LOG_DEPTH:0] gray_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gray_reg <= 0;
        end else begin
            gray_reg <= gray_i;
        end
    end

    assign gray_o = gray_reg;

endmodule

module synchronizer #(
    parameter WIDTH = 4
)(
    input                  rst_ni,
    input                  clk_i,
    input  [WIDTH-1:0]   async_i,
    output [WIDTH-1:0]   sync_o
);

    reg [WIDTH-1:0] sync_reg1;
    reg [WIDTH-1:0] sync_reg2;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg1 <= 0;
            sync_reg2 <= 0;
        end else begin
            sync_reg1 <= async_i;
            sync_reg2 <= sync_reg1;
        end
    end

    assign sync_o = sync_reg2;

endmodule
