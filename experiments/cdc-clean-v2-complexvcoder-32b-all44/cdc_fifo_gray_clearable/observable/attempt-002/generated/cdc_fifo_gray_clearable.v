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
    wire [LOG_DEPTH:0] src_gray;
    wire [LOG_DEPTH:0] dst_gray;
    wire [LOG_DEPTH:0] synced_gray;
    wire synced_clear_src;
    wire synced_clear_dst;
    reg  [LOG_DEPTH-1:0] src_wr_ptr;
    reg  [LOG_DEPTH-1:0] src_rd_ptr;
    reg  [LOG_DEPTH-1:0] dst_wr_ptr;
    reg  [LOG_DEPTH-1:0] dst_rd_ptr;
    reg  [WIDTH-1:0]     src_mem [0:(1<<LOG_DEPTH)-1];
    reg  [WIDTH-1:0]     dst_mem [0:(1<<LOG_DEPTH)-1];
    wire [LOG_DEPTH:0] src_gray_next;
    wire [LOG_DEPTH:0] dst_gray_next;
    reg  src_clear_pending;
    reg  dst_clear_pending;

    // Gray counters
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .gray_o(src_gray),
        .gray_next_o(src_gray_next)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .gray_o(dst_gray),
        .gray_next_o(dst_gray_next)
    );

    // Synchronizers
    synchronizer #(.SYNC_STAGES(SYNC_STAGES), .WIDTH(LOG_DEPTH+1)) sync_gray (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .din_i(src_gray),
        .dout_o(synced_gray)
    );

    synchronizer #(.SYNC_STAGES(SYNC_STAGES), .WIDTH(1)) sync_clear_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .din_i(dst_clear_i),
        .dout_o(synced_clear_src)
    );

    synchronizer #(.SYNC_STAGES(SYNC_STAGES), .WIDTH(1)) sync_clear_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .din_i(src_clear_i),
        .dout_o(synced_clear_dst)
    );

    // Source side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_rd_ptr <= 0;
            src_gray <= 0;
            src_gray_next <= 0;
            src_clear_pending <= 0;
        end else begin
            if (src_clear_i) begin
                src_wr_ptr <= 0;
                src_rd_ptr <= 0;
                src_gray <= 0;
                src_gray_next <= 0;
                src_clear_pending <= 1;
            end else if (synced_clear_dst) begin
                src_wr_ptr <= 0;
                src_rd_ptr <= 0;
                src_gray <= 0;
                src_gray_next <= 0;
                src_clear_pending <= 0;
            end else if (src_valid_i && src_ready_o) begin
                src_mem[src_wr_ptr] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1;
            end
        end
    end

    assign src_ready_o = (src_wr_ptr != (src_rd_ptr + 1) % (1<<LOG_DEPTH));

    // Destination side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr <= 0;
            dst_rd_ptr <= 0;
            dst_gray <= 0;
            dst_gray_next <= 0;
            dst_clear_pending <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_wr_ptr <= 0;
                dst_rd_ptr <= 0;
                dst_gray <= 0;
                dst_gray_next <= 0;
                dst_clear_pending <= 1;
            end else if (synced_clear_src) begin
                dst_wr_ptr <= 0;
                dst_rd_ptr <= 0;
                dst_gray <= 0;
                dst_gray_next <= 0;
                dst_clear_pending <= 0;
            end else if (dst_valid_o && dst_ready_i) begin
                dst_rd_ptr <= dst_rd_ptr + 1;
            end
        end
    end

    assign dst_valid_o = (synced_gray != dst_gray);
    assign dst_data_o = dst_mem[dst_rd_ptr];
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    output [LOG_DEPTH:0] gray_o,
    output [LOG_DEPTH:0] gray_next_o
);

    reg  [LOG_DEPTH-1:0] binary_ptr;
    reg  [LOG_DEPTH-1:0] binary_ptr_next;
    wire [LOG_DEPTH:0] gray;
    wire [LOG_DEPTH:0] gray_next;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            binary_ptr <= 0;
            binary_ptr_next <= 0;
        end else if (clear_i) begin
            binary_ptr <= 0;
            binary_ptr_next <= 0;
        end else begin
            binary_ptr <= binary_ptr_next;
        end
    end

    assign binary_ptr_next = (binary_ptr + 1) % (1<<LOG_DEPTH);
    assign gray = {binary_ptr[LOG_DEPTH-1], binary_ptr[LOG_DEPTH-2:0] ^ binary_ptr[LOG_DEPTH-1:1]};
    assign gray_next = {binary_ptr_next[LOG_DEPTH-1], binary_ptr_next[LOG_DEPTH-2:0] ^ binary_ptr_next[LOG_DEPTH-1:1]};

    assign gray_o = gray;
    assign gray_next_o = gray_next;

endmodule

module synchronizer #(
    parameter SYNC_STAGES = 3,
    parameter WIDTH = 1
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     din_i,
    output [WIDTH-1:0]     dout_o
);

    reg [WIDTH-1:0] sync_reg [0:SYNC_STAGES-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= 0;
        end else begin
            sync_reg[0] <= din_i;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign dout_o = sync_reg[SYNC_STAGES-1];

endmodule
