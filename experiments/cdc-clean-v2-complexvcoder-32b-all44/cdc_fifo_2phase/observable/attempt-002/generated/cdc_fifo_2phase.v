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
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [WIDTH-1:0] mem [DEPTH-1:0];

    // Source domain signals
    reg [ADDR_WIDTH:0] src_wr_ptr, src_wr_ptr_gray, src_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] src_rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] src_wr_ptr_gray_next;
    reg src_full;

    // Destination domain signals
    reg [ADDR_WIDTH:0] dst_rd_ptr, dst_rd_ptr_gray, dst_rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] dst_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray_next;
    reg dst_empty;

    // Gray counter for source write pointer
    gray_counter #(.WIDTH(ADDR_WIDTH+1)) gray_counter_src_wr (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .count_o(src_wr_ptr_gray)
    );

    // Gray counter for destination read pointer
    gray_counter #(.WIDTH(ADDR_WIDTH+1)) gray_counter_dst_rd (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .count_o(dst_rd_ptr_gray)
    );

    // Synchronizers
    sync_bit sync_src_wr_ptr_gray (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .d_i(src_wr_ptr_gray),
        .q_o(src_wr_ptr_gray_sync)
    );

    sync_bit sync_dst_rd_ptr_gray (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .d_i(dst_rd_ptr_gray),
        .q_o(dst_rd_ptr_gray_sync)
    );

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
        end else begin
            if (src_ready_o && src_valid_i) begin
                src_wr_ptr <= src_wr_ptr + 1;
                mem[src_wr_ptr[ADDR_WIDTH-1:0]] <= src_data_i;
            end
        end
    end

    assign src_wr_ptr_gray_next = (src_wr_ptr + 1) ^ src_wr_ptr;
    assign src_full = (src_wr_ptr_gray_next == src_rd_ptr_gray_sync);

    assign src_ready_o = !src_full;

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
        end else begin
            if (dst_valid_o && dst_ready_i) begin
                dst_rd_ptr <= dst_rd_ptr + 1;
            end
        end
    end

    assign dst_rd_ptr_gray_next = (dst_rd_ptr + 1) ^ dst_rd_ptr;
    assign dst_empty = (dst_wr_ptr_gray_sync == dst_rd_ptr_gray_next);

    assign dst_valid_o = !dst_empty;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_data_o <= mem[dst_rd_ptr[ADDR_WIDTH-1:0]];
        end
    end

endmodule

module gray_counter #(
    parameter WIDTH = 4
)(
    input                  rst_ni,
    input                  clk_i,
    output reg [WIDTH-1:0] count_o
);

    reg [WIDTH-1:0] count_d;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count_o <= 0;
        end else begin
            count_o <= count_d;
        end
    end

    always @(*) begin
        count_d = count_o + 1;
    end

endmodule

module sync_bit #(
    parameter STAGES = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  d_i,
    output reg             q_o
);

    genvar i;
    reg q_int [STAGES-1:0];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            q_int <= 0;
        end else begin
            q_int[0] <= d_i;
            for (i = 1; i < STAGES; i = i + 1) begin
                q_int[i] <= q_int[i-1];
            end
        end
    end

    assign q_o = q_int[STAGES-1];

endmodule
