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

    // Internal signals
    wire [LOG_DEPTH:0]     src_gray_cnt;
    wire [LOG_DEPTH:0]     src_bin_cnt;
    wire [LOG_DEPTH:0]     dst_gray_cnt;
    wire [LOG_DEPTH:0]     dst_bin_cnt;
    wire [LOG_DEPTH:0]     dst_sync_src_gray_cnt;
    wire [LOG_DEPTH:0]     src_sync_dst_gray_cnt;
    reg  [WIDTH-1:0]       fifo_mem [0:(1<<LOG_DEPTH)-1];
    reg  [LOG_DEPTH:0]     src_wptr_gray;
    reg  [LOG_DEPTH:0]     src_rptr_gray;
    reg  [LOG_DEPTH:0]     dst_wptr_gray;
    reg  [LOG_DEPTH:0]     dst_rptr_gray;
    reg  [LOG_DEPTH:0]     src_wptr_bin;
    reg  [LOG_DEPTH:0]     src_rptr_bin;
    reg  [LOG_DEPTH:0]     dst_wptr_bin;
    reg  [LOG_DEPTH:0]     dst_rptr_bin;
    reg                    src_full;
    reg                    src_empty;
    reg                    dst_full;
    reg                    dst_empty;
    reg                    src_ready;
    reg                    dst_valid;

    // Source Gray Counter
    async_gray_counter src_gray_counter (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .gray_cnt(src_gray_cnt),
        .bin_cnt(src_bin_cnt)
    );

    // Destination Gray Counter
    async_gray_counter dst_gray_counter (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .gray_cnt(dst_gray_cnt),
        .bin_cnt(dst_bin_cnt)
    );

    // Synchronize source gray counter to destination clock domain
    sync_register #(.WIDTH(LOG_DEPTH+1)) sync_src_gray_cnt (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_gray_cnt),
        .data_o(dst_sync_src_gray_cnt)
    );

    // Synchronize destination gray counter to source clock domain
    sync_register #(.WIDTH(LOG_DEPTH+1)) sync_dst_gray_cnt (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(dst_gray_cnt),
        .data_o(src_sync_dst_gray_cnt)
    );

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wptr_gray <= 0;
            src_rptr_gray <= 0;
            src_full <= 0;
            src_empty <= 1;
        end else begin
            src_full <= (src_wptr_gray == {src_gray_cnt[LOG_DEPTH], ~src_gray_cnt[LOG_DEPTH-1:0]});
            src_empty <= (src_wptr_gray == src_rptr_gray);

            if (src_ready && src_valid_i) begin
                fifo_mem[src_wptr_bin] <= src_data_i;
                src_wptr_gray <= src_wptr_gray + 1;
                src_wptr_bin <= src_wptr_bin + 1;
            end
        end
    end

    // Source ready logic
    always @(*) begin
        src_ready = ~src_full;
    end

    // Source ready output
    assign src_ready_o = src_ready;

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wptr_gray <= 0;
            dst_rptr_gray <= 0;
            dst_full <= 0;
            dst_empty <= 1;
        end else begin
            dst_full <= (dst_wptr_gray == {dst_gray_cnt[LOG_DEPTH], ~dst_gray_cnt[LOG_DEPTH-1:0]});
            dst_empty <= (dst_wptr_gray == dst_rptr_gray);

            if (dst_valid && dst_ready_i) begin
                dst_rptr_gray <= dst_rptr_gray + 1;
                dst_rptr_bin <= dst_rptr_bin + 1;
            end
        end
    end

    // Destination valid logic
    always @(*) begin
        dst_valid = ~dst_empty;
    end

    // Destination valid output
    assign dst_valid_o = dst_valid;

    // Destination data output
    assign dst_data_o = fifo_mem[dst_rptr_bin];

endmodule

module async_gray_counter (
    input                  clk_i,
    input                  rst_ni,
    output [LOG_DEPTH:0]   gray_cnt,
    output [LOG_DEPTH:0]   bin_cnt
);

    reg [LOG_DEPTH:0] counter;
    reg [LOG_DEPTH:0] gray_counter;

    // Binary counter
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    // Gray code conversion
    assign gray_counter = (counter >> 1) ^ counter;

    // Outputs
    assign gray_cnt = gray_counter;
    assign bin_cnt = counter;

endmodule

module sync_register #(
    parameter WIDTH = 4
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     data_i,
    output [WIDTH-1:0]     data_o
);

    reg [WIDTH-1:0] sync_reg [0:SYNC_STAGES];

    // Synchronization register chain
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg[0] <= 0;
            sync_reg[1] <= 0;
            // Additional stages if needed
            for (integer i = 2; i < SYNC_STAGES; i = i + 1)
                sync_reg[i] <= 0;
        end else begin
            sync_reg[0] <= data_i;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                sync_reg[i] <= sync_reg[i-1];
        end
    end

    // Output assignment
    assign data_o = sync_reg[SYNC_STAGES-1];

endmodule
