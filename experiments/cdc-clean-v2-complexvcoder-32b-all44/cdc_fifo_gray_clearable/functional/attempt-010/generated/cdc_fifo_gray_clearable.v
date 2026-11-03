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
    reg [LOG_DEPTH-1:0] src_gray_ptr;
    reg [LOG_DEPTH-1:0] src_bin_ptr;
    reg [LOG_DEPTH-1:0] dst_gray_ptr;
    reg [LOG_DEPTH-1:0] dst_bin_ptr;
    reg [LOG_DEPTH-1:0] gray_sync_src_to_dst;
    reg [LOG_DEPTH-1:0] gray_sync_dst_to_src;
    reg [WIDTH-1:0] src_fifo [0:(1<<LOG_DEPTH)-1];
    reg [0:(1<<LOG_DEPTH)-1] src_fifo_valid;
    reg src_clear_pending;
    reg dst_clear_pending;
    reg src_ready;
    reg dst_valid;
    reg [WIDTH-1:0] dst_data;

    // Gray counters
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) src_gray_counter (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .bin_ptr(src_bin_ptr),
        .gray_ptr(src_gray_ptr)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) dst_gray_counter (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .bin_ptr(dst_bin_ptr),
        .gray_ptr(dst_gray_ptr)
    );

    // Synchronizers
    sync_register #(.WIDTH(LOG_DEPTH)) sync_gray_src_to_dst (
        .src_clk(src_clk_i),
        .src_rst_ni(src_rst_ni),
        .src_data_i(src_gray_ptr),
        .dst_clk(dst_clk_i),
        .dst_rst_ni(dst_rst_ni),
        .dst_data_o(gray_sync_src_to_dst)
    );

    sync_register #(.WIDTH(LOG_DEPTH)) sync_gray_dst_to_src (
        .src_clk(dst_clk_i),
        .src_rst_ni(dst_rst_ni),
        .src_data_i(dst_gray_ptr),
        .dst_clk(src_clk_i),
        .dst_rst_ni(src_rst_ni),
        .dst_data_o(gray_sync_dst_to_src)
    );

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready <= 1'b1;
            src_clear_pending <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_ready <= 1'b1;
                src_clear_pending <= 1'b1;
            end else if (src_clear_pending) begin
                if (src_bin_ptr == gray_sync_dst_to_src) begin
                    src_ready <= 1'b1;
                    src_clear_pending <= 1'b0;
                end else begin
                    src_ready <= 1'b0;
                end
            end else if (src_ready && src_valid_i) begin
                src_fifo[src_bin_ptr] <= src_data_i;
                src_fifo_valid[src_bin_ptr] <= 1'b1;
                src_ready <= (src_bin_ptr + 1 != gray_sync_dst_to_src);
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid <= 1'b0;
            dst_clear_pending <= 1'b0;
            dst_data <= {WIDTH{1'b0}};
        end else begin
            if (dst_clear_i) begin
                dst_valid <= 1'b0;
                dst_clear_pending <= 1'b1;
            end else if (dst_clear_pending) begin
                if (dst_bin_ptr == gray_sync_src_to_dst) begin
                    dst_valid <= 1'b0;
                    dst_clear_pending <= 1'b0;
                end else begin
                    dst_valid <= 1'b0;
                end
            end else if (dst_valid && dst_ready_i) begin
                dst_valid <= 1'b0;
            end else if (!dst_valid && (dst_bin_ptr != gray_sync_src_to_dst) && src_fifo_valid[dst_bin_ptr]) begin
                dst_data <= src_fifo[dst_bin_ptr];
                dst_valid <= 1'b1;
                src_fifo_valid[dst_bin_ptr] <= 1'b0;
            end
        end
    end

    // Outputs
    assign src_clear_pending_o = src_clear_pending;
    assign src_ready_o = src_ready;
    assign dst_clear_pending_o = dst_clear_pending;
    assign dst_data_o = dst_data;
    assign dst_valid_o = dst_valid;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_ni,
    input                  clear_i,
    output [LOG_DEPTH-1:0] bin_ptr,
    output [LOG_DEPTH-1:0] gray_ptr
);

    // Internal signals
    reg [LOG_DEPTH-1:0] next_bin_ptr;
    reg [LOG_DEPTH-1:0] next_gray_ptr;

    // Binary counter logic
    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_ptr <= {LOG_DEPTH{1'b0}};
        end else if (clear_i) begin
            bin_ptr <= {LOG_DEPTH{1'b0}};
        end else begin
            bin_ptr <= next_bin_ptr;
        end
    end

    // Gray code conversion and next state logic
    always @(*) begin
        next_bin_ptr = bin_ptr + 1;
        next_gray_ptr = next_bin_ptr ^ (next_bin_ptr >> 1);
    end

    // Gray code output
    assign gray_ptr = next_gray_ptr;

endmodule

module sync_register #(
    parameter WIDTH = 3
)(
    input                  src_clk,
    input                  src_rst_ni,
    input  [WIDTH-1:0]     src_data_i,
    input                  dst_clk,
    input                  dst_rst_ni,
    output [WIDTH-1:0]     dst_data_o
);

    // Internal signals
    reg [WIDTH-1:0] sync_stages [0:SYNC_STAGES-1];

    // Synchronization stages
    always @(posedge src_clk or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            sync_stages[0] <= {WIDTH{1'b0}};
        end else begin
            sync_stages[0] <= src_data_i;
        end
    end

    // Additional stages
    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : gen_sync_stages
            always @(posedge src_clk or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    sync_stages[i] <= {WIDTH{1'b0}};
                end else begin
                    sync_stages[i] <= sync_stages[i-1];
                end
            end
        end
    endgenerate

    // Destination domain output
    always @(posedge dst_clk or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= {WIDTH{1'b0}};
        end else begin
            dst_data_o <= sync_stages[SYNC_STAGES-1];
        end
    end

endmodule
