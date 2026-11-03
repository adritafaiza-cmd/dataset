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

    // Internal signals
    wire [LOG_DEPTH:0] src_gray_count;
    wire [LOG_DEPTH:0] dst_gray_count;
    reg  [LOG_DEPTH:0] src_gray_count_synced;
    reg  [LOG_DEPTH:0] dst_gray_count_synced;
    reg  [WIDTH-1:0] fifo_mem [0:(1<<LOG_DEPTH)-1];
    reg  [LOG_DEPTH-1:0] write_ptr;
    reg  [LOG_DEPTH-1:0] read_ptr;
    reg                  src_ready;
    reg                  dst_valid;
    reg  [WIDTH-1:0] dst_data;

    // Gray counters for CDC
    cdc_gray_counter #(.LOG_DEPTH(LOG_DEPTH)) src_gray_counter_inst (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .count(src_gray_count)
    );

    cdc_gray_counter #(.LOG_DEPTH(LOG_DEPTH)) dst_gray_counter_inst (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .count(dst_gray_count)
    );

    // Synchronize counters
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_gray_count_synced <= {(LOG_DEPTH+1){1'b0}};
        end else begin
            src_gray_count_synced <= src_gray_count;
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_gray_count_synced <= {(LOG_DEPTH+1){1'b0}};
        end else begin
            dst_gray_count_synced <= dst_gray_count;
        end
    end

    // Calculate pointers
    assign write_ptr = src_gray_count_synced[LOG_DEPTH-1:0];
    assign read_ptr = dst_gray_count_synced[LOG_DEPTH-1:0];

    // FIFO write logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready <= 1'b1;
        end else if (src_valid_i && src_ready) begin
            fifo_mem[write_ptr] <= src_data_i;
            src_ready <= (write_ptr != (dst_gray_count_synced[LOG_DEPTH-1:0] - 1'b1));
        end
    end

    assign src_ready_o = src_ready;

    // FIFO read logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid <= 1'b0;
            dst_data <= {(WIDTH){1'b0}};
        end else if (dst_ready_i && dst_valid) begin
            dst_valid <= (read_ptr != src_gray_count_synced[LOG_DEPTH-1:0]);
        end else if (!dst_valid && (read_ptr != src_gray_count_synced[LOG_DEPTH-1:0])) begin
            dst_data <= fifo_mem[read_ptr];
            dst_valid <= 1'b1;
        end
    end

    assign dst_data_o = dst_data;
    assign dst_valid_o = dst_valid;

endmodule

module cdc_gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_ni,
    output [LOG_DEPTH:0] count
);

    reg [LOG_DEPTH:0] binary_count;
    reg [LOG_DEPTH:0] gray_count;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            binary_count <= {(LOG_DEPTH+1){1'b0}};
            gray_count <= {(LOG_DEPTH+1){1'b0}};
        end else begin
            binary_count <= binary_count + 1;
            gray_count <= (binary_count >> 1) ^ binary_count;
        end
    end

    assign count = gray_count;

endmodule
