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
    wire [LOG_DEPTH:0]     src_gray_o;
    wire [LOG_DEPTH:0]     dst_gray_o;
    wire [LOG_DEPTH:0]     gray_src_to_dst;
    wire [LOG_DEPTH:0]     gray_dst_to_src;
    wire                   src_clear_to_dst;
    wire                   dst_clear_to_src;
    reg  [LOG_DEPTH:0]     src_fifo_ptr;
    reg  [LOG_DEPTH:0]     dst_fifo_ptr;
    reg  [WIDTH-1:0]       fifo_mem [0:(2**LOG_DEPTH)-1];
    reg                    src_fifo_full;
    reg                    src_fifo_empty;
    reg                    dst_fifo_full;
    reg                    dst_fifo_empty;
    reg  [WIDTH-1:0]       dst_data_reg;

    // Gray code counters
    gray_counter gray_src (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .clear_i(src_clear_i),
        .gray_o(src_gray_o)
    );

    gray_counter gray_dst (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .clear_i(dst_clear_i),
        .gray_o(dst_gray_o)
    );

    // Synchronizers
    sync_register #(LOG_DEPTH+1) sync_gray_src_to_dst (
        .src_clk_i(src_clk_i),
        .dst_clk_i(dst_clk_i),
        .data_i(src_gray_o),
        .data_o(gray_src_to_dst)
    );

    sync_register #(LOG_DEPTH+1) sync_gray_dst_to_src (
        .src_clk_i(dst_clk_i),
        .dst_clk_i(src_clk_i),
        .data_i(dst_gray_o),
        .data_o(gray_dst_to_src)
    );

    sync_register #1 sync_src_clear_to_dst (
        .src_clk_i(src_clk_i),
        .dst_clk_i(dst_clk_i),
        .data_i(src_clear_i),
        .data_o(src_clear_to_dst)
    );

    sync_register #1 sync_dst_clear_to_src (
        .src_clk_i(dst_clk_i),
        .dst_clk_i(src_clk_i),
        .data_i(dst_clear_i),
        .data_o(dst_clear_to_src)
    );

    // FIFO control logic on source side
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_fifo_ptr <= 0;
            src_fifo_full <= 0;
            src_fifo_empty <= 1;
        end else if (src_clear_i) begin
            src_fifo_ptr <= 0;
            src_fifo_full <= 0;
            src_fifo_empty <= 1;
        end else begin
            if (src_valid_i && src_ready_o) begin
                fifo_mem[src_fifo_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_fifo_ptr <= src_fifo_ptr + 1;
                src_fifo_full <= (src_fifo_ptr[LOG_DEPTH-1:0] == gray_dst_to_src[LOG_DEPTH-1:0] - 1);
                src_fifo_empty <= 0;
            end else if (src_fifo_ptr[LOG_DEPTH-1:0] == gray_dst_to_src[LOG_DEPTH-1:0]) begin
                src_fifo_empty <= 1;
            end
        end
    end

    // FIFO control logic on destination side
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_fifo_ptr <= 0;
            dst_fifo_full <= 0;
            dst_fifo_empty <= 1;
        end else if (dst_clear_i) begin
            dst_fifo_ptr <= 0;
            dst_fifo_full <= 0;
            dst_fifo_empty <= 1;
        end else begin
            if (dst_valid_o && dst_ready_i) begin
                dst_fifo_ptr <= dst_fifo_ptr + 1;
                dst_fifo_full <= 0;
                dst_fifo_empty <= (dst_fifo_ptr[LOG_DEPTH-1:0] == gray_src_to_dst[LOG_DEPTH-1:0]);
            end else if (dst_fifo_ptr[LOG_DEPTH-1:0] == gray_src_to_dst[LOG_DEPTH-1:0] - 1) begin
                dst_fifo_full <= 1;
            end
        end
    end

    // FIFO read logic on destination side
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= 0;
            dst_valid_o <= 0;
        end else if (dst_clear_i) begin
            dst_data_reg <= 0;
            dst_valid_o <= 0;
        end else begin
            if (dst_valid_o && dst_ready_i) begin
                dst_valid_o <= 0;
            end else if (dst_fifo_ptr[LOG_DEPTH-1:0] != gray_src_to_dst[LOG_DEPTH-1:0]) begin
                dst_data_reg <= fifo_mem[dst_fifo_ptr[LOG_DEPTH-1:0]];
                dst_valid_o <= 1;
            end
        end
    end

    // Ready and valid signals
    assign src_ready_o = ~src_fifo_full & ~src_clear_i;
    assign dst_valid_o = ~dst_fifo_empty & ~dst_clear_i;

    // Clear pending signals
    assign src_clear_pending_o = src_clear_i;
    assign dst_clear_pending_o = dst_clear_i;

endmodule

module gray_counter (
    input  rst_ni,
    input  clk_i,
    input  clear_i,
    output [LOG_DEPTH:0] gray_o
);

    reg [LOG_DEPTH:0] counter;
    reg [LOG_DEPTH:0] gray;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni || clear_i) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end

    assign gray_o = (counter >> 1) ^ counter;

endmodule

module sync_register #(parameter WIDTH = 1) (
    input  src_clk_i,
    input  dst_clk_i,
    input  [WIDTH-1:0] data_i,
    output [WIDTH-1:0] data_o
);

    reg [WIDTH-1:0] reg1;
    reg [WIDTH-1:0] reg2;

    always @(posedge src_clk_i) begin
        reg1 <= data_i;
    end

    always @(posedge dst_clk_i) begin
        reg2 <= reg1;
    end

    assign data_o = reg2;

endmodule
