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
    wire [LOG_DEPTH:0] gray_src_count;
    wire [LOG_DEPTH:0] gray_dst_count;
    wire [LOG_DEPTH:0] sync_gray_src_to_dst_o;
    wire [LOG_DEPTH:0] sync_gray_dst_to_src_o;
    wire [WIDTH-1:0] fifo_data_out;
    reg  src_clear_pending;
    reg  dst_clear_pending;

    // Gray code counters
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_src_counter (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .gray_count_o(gray_src_count)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_dst_counter (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .gray_count_o(gray_dst_count)
    );

    // Synchronize Gray code counters
    sync_gray_counter #(.LOG_DEPTH(LOG_DEPTH)) sync_gray_src_to_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .gray_count_i(gray_src_count),
        .gray_count_o(sync_gray_src_to_dst_o)
    );

    sync_gray_counter #(.LOG_DEPTH(LOG_DEPTH)) sync_gray_dst_to_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .gray_count_i(gray_dst_count),
        .gray_count_o(sync_gray_dst_to_src_o)
    );

    // FIFO memory
    fifo_memory #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_memory_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .write_addr_i(gray_src_count),
        .read_addr_i(sync_gray_dst_to_src_o),
        .data_i(src_data_i),
        .data_o(fifo_data_out)
    );

    // Source side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 1'b0;
            src_ready_o <= 1'b0;
        end else begin
            src_clear_pending <= src_clear_i;
            src_ready_o <= (gray_src_count != sync_gray_dst_to_src_o) & ~src_clear_i;
        end
    end

    // Destination side logic
    reg dst_valid_d;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 1'b0;
            dst_valid_o <= 1'b0;
            dst_valid_d <= 1'b0;
            dst_data_o <= {WIDTH{1'b0}};
        end else begin
            dst_clear_pending <= dst_clear_i;
            dst_valid_d <= (sync_gray_src_to_dst_o != gray_dst_count) & ~dst_clear_i;
            dst_valid_o <= dst_valid_d;
            if (dst_valid_d && dst_ready_i) begin
                dst_data_o <= fifo_data_out;
            end
        end
    end

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    output [LOG_DEPTH:0] gray_count_o
);

    reg [LOG_DEPTH:0] binary_count;
    reg [LOG_DEPTH:0] gray_count;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            binary_count <= {LOG_DEPTH+1{1'b0}};
            gray_count <= {LOG_DEPTH+1{1'b0}};
        end else if (clear_i) begin
            binary_count <= {LOG_DEPTH+1{1'b0}};
            gray_count <= {LOG_DEPTH+1{1'b0}};
        end else begin
            binary_count <= binary_count + 1;
            gray_count <= (binary_count >> 1) ^ binary_count;
        end
    end

    assign gray_count_o = gray_count;

endmodule

module sync_gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input  [LOG_DEPTH:0] gray_count_i,
    output [LOG_DEPTH:0] gray_count_o
);

    reg [LOG_DEPTH:0] sync_stages [SYNC_STAGES-1:0];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (integer i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_stages[i] <= {LOG_DEPTH+1{1'b0}};
            end
        end else begin
            sync_stages[0] <= gray_count_i;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stages[i] <= sync_stages[i-1];
            end
        end
    end

    assign gray_count_o = sync_stages[SYNC_STAGES-1];

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    input  [LOG_DEPTH:0] write_addr_i,
    input  [LOG_DEPTH:0] read_addr_i,
    input  [WIDTH-1:0]   data_i,
    output [WIDTH-1:0]   data_o
);

    reg [WIDTH-1:0] memory [0:(1<<(LOG_DEPTH+1))-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (integer i = 0; i < (1<<(LOG_DEPTH+1)); i = i + 1) begin
                memory[i] <= {WIDTH{1'b0}};
            end
        end else if (clear_i) begin
            for (integer i = 0; i < (1<<(LOG_DEPTH+1)); i = i + 1) begin
                memory[i] <= {WIDTH{1'b0}};
            end
        end else begin
            memory[write_addr_i] <= data_i;
        end
    end

    assign data_o = memory[read_addr_i];

endmodule
