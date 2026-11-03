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

    wire [LOG_DEPTH:0]     src_wptr_gray;
    wire [LOG_DEPTH:0]     dst_rptr_gray;
    wire [LOG_DEPTH:0]     src_wptr_sync;
    wire [LOG_DEPTH:0]     dst_rptr_sync;
    wire [LOG_DEPTH-1:0]   src_wptr_bin_sync;
    wire [LOG_DEPTH-1:0]   dst_rptr_bin_sync;

    sync_gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    src_gray_counter (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .binary_i(src_wptr_bin_sync),
        .gray_o(src_wptr_gray),
        .async_i(1'b0) // Not used in this instance
    );

    sync_gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    dst_gray_counter (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .binary_i(dst_rptr_bin_sync),
        .gray_o(dst_rptr_gray),
        .async_i(1'b0) // Not used in this instance
    );

    sync_gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    src_gray_counter_sync (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .binary_i(1'b0), // Not used in this instance
        .gray_o(src_wptr_sync),
        .async_i(src_wptr_gray)
    );

    sync_gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    dst_gray_counter_sync (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .binary_i(1'b0), // Not used in this instance
        .gray_o(dst_rptr_sync),
        .async_i(dst_rptr_gray)
    );

    sync_binary_counter #(.LOG_DEPTH(LOG_DEPTH))
    src_binary_counter_sync (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .async_i(src_wptr_sync),
        .binary_o(src_wptr_bin_sync)
    );

    sync_binary_counter #(.LOG_DEPTH(LOG_DEPTH))
    dst_binary_counter_sync (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .async_i(dst_rptr_sync),
        .binary_o(dst_rptr_bin_sync)
    );

    fifo_memory #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH))
    fifo_memory (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_data_i(src_data_i),
        .src_valid_i(src_valid_i),
        .src_ready_o(src_ready_o),
        .src_wptr_i(src_wptr_bin_sync),
        .dst_rst_ni(dst_rst_ni),
        .dst_clk_i(dst_clk_i),
        .dst_rptr_i(dst_rptr_bin_sync),
        .dst_data_o(dst_data_o),
        .dst_valid_o(dst_valid_o),
        .dst_ready_i(dst_ready_i)
    );

endmodule

module sync_gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input  [LOG_DEPTH-1:0] binary_i,
    output [LOG_DEPTH:0]   gray_o,
    input  [LOG_DEPTH:0]   async_i
);

    reg [LOG_DEPTH:0] gray_reg [0:SYNC_STAGES];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gray_reg[0] <= 0;
        end else begin
            gray_reg[0] <= {binary_i[LOG_DEPTH-1], binary_i[LOG_DEPTH-1:1] ^ binary_i[LOG_DEPTH-2:0]};
        end
    end

    generate
        genvar i;
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            always @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    gray_reg[i] <= 0;
                end else begin
                    gray_reg[i] <= gray_reg[i-1];
                end
            end
        end
    endgenerate

    assign gray_o = gray_reg[SYNC_STAGES-1];

endmodule

module sync_binary_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input  [LOG_DEPTH:0]   async_i,
    output [LOG_DEPTH-1:0] binary_o
);

    reg [LOG_DEPTH:0] gray_sync [0:SYNC_STAGES];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gray_sync[0] <= 0;
        end else begin
            gray_sync[0] <= async_i;
        end
    end

    generate
        genvar i;
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            always @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    gray_sync[i] <= 0;
                end else begin
                    gray_sync[i] <= gray_sync[i-1];
                end
            end
        end
    endgenerate

    wire [LOG_DEPTH-1:0] gray_binary;
    assign gray_binary = gray_sync[SYNC_STAGES-1][LOG_DEPTH-1:0];

    always @(*) begin
        binary_o = gray_binary[LOG_DEPTH-1];
        for (int i = LOG_DEPTH-2; i >= 0; i = i - 1) begin
            binary_o[i] = gray_binary[i] ^ binary_o[i+1];
        end
    end

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input  [LOG_DEPTH-1:0] src_wptr_i,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input  [LOG_DEPTH-1:0] dst_rptr_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    reg [WIDTH-1:0] fifo_mem [0:(2**LOG_DEPTH)-1];
    reg [LOG_DEPTH:0] src_wptr_gray;
    reg [LOG_DEPTH:0] dst_rptr_gray;
    reg [LOG_DEPTH:0] src_wptr_gray_sync;
    reg [LOG_DEPTH:0] dst_rptr_gray_sync;
    reg [LOG_DEPTH:0] src_wptr_gray_sync2;
    reg [LOG_DEPTH:0] dst_rptr_gray_sync2;
    reg [LOG_DEPTH-1:0] src_wptr_bin_sync;
    reg [LOG_DEPTH-1:0] dst_rptr_bin_sync;
    reg [LOG_DEPTH:0] src_full;
    reg [LOG_DEPTH:0] dst_empty;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wptr_gray <= 0;
        end else if (src_ready_o && src_valid_i) begin
            src_wptr_gray <= src_wptr_gray + 1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rptr_gray <= 0;
        end else if (dst_ready_i && dst_valid_o) begin
            dst_rptr_gray <= dst_rptr_gray + 1;
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wptr_gray_sync <= 0;
        end else begin
            src_wptr_gray_sync <= src_wptr_gray;
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wptr_gray_sync2 <= 0;
        end else begin
            src_wptr_gray_sync2 <= src_wptr_gray_sync;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rptr_gray_sync <= 0;
        end else begin
            dst_rptr_gray_sync <= dst_rptr_gray;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rptr_gray_sync2 <= 0;
        end else begin
            dst_rptr_gray_sync2 <= dst_rptr_gray_sync;
        end
    end

    wire [LOG_DEPTH-1:0] gray_binary_src;
    wire [LOG_DEPTH-1:0] gray_binary_dst;

    always @(*) begin
        gray_binary_src = src_wptr_gray_sync2[LOG_DEPTH-1:0];
        src_wptr_bin_sync = gray_binary_src[LOG_DEPTH-1];
        for (int i = LOG_DEPTH-2; i >= 0; i = i - 1) begin
            src_wptr_bin_sync[i] = gray_binary_src[i] ^ src_wptr_bin_sync[i+1];
        end
    end

    always @(*) begin
        gray_binary_dst = dst_rptr_gray_sync2[LOG_DEPTH-1:0];
        dst_rptr_bin_sync = gray_binary_dst[LOG_DEPTH-1];
        for (int i = LOG_DEPTH-2; i >= 0; i = i - 1) begin
            dst_rptr_bin_sync[i] = gray_binary_dst[i] ^ dst_rptr_bin_sync[i+1];
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_mem <= '{default: 0};
        end else if (src_ready_o && src_valid_i) begin
            fifo_mem[src_wptr_bin_sync] <= src_data_i;
        end
    end

    assign src_full = src_wptr_gray_sync2 - dst_rptr_gray_sync2 == 2**LOG_DEPTH;
    assign src_ready_o = !src_full;

    assign dst_data_o = fifo_mem[dst_rptr_bin_sync];
    assign dst_empty = src_wptr_gray_sync2 == dst_rptr_gray_sync2;
    assign dst_valid_o = !dst_empty;

endmodule
