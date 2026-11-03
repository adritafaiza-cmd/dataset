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
    reg  [LOG_DEPTH:0]     src_gray_count;
    reg  [LOG_DEPTH:0]     dst_gray_count;
    reg  [LOG_DEPTH:0]     src_gray_count_synced;
    reg  [LOG_DEPTH:0]     dst_gray_count_synced;
    reg                    fifo_we;
    reg  [LOG_DEPTH:0]     fifo_wr_addr;
    reg  [WIDTH-1:0]       fifo_data_out;
    reg  [LOG_DEPTH:0]     fifo_rd_addr;
    reg  [LOG_DEPTH:0]     fifo_valid_count;

    // Instantiate the gray counters
    cdc_gray_counter_1 src_gray_counter (
        .clk_i  (src_clk_i),
        .rst_ni (src_rst_ni),
        .gray_o (src_gray_count)
    );

    cdc_gray_counter_1 dst_gray_counter (
        .clk_i  (dst_clk_i),
        .rst_ni (dst_rst_ni),
        .gray_o (dst_gray_count)
    );

    cdc_gray_counter_2 src_gray_counter_synced_inst (
        .clk_i  (dst_clk_i),
        .rst_ni (dst_rst_ni),
        .gray_i (src_gray_count),
        .gray_o (src_gray_count_synced)
    );

    cdc_gray_counter_2 dst_gray_counter_synced_inst (
        .clk_i  (src_clk_i),
        .rst_ni (src_rst_ni),
        .gray_i (dst_gray_count),
        .gray_o (dst_gray_count_synced)
    );

    // Instantiate the FIFO memory
    fifo_memory_1 fifo_mem (
        .clk_i  (src_clk_i),
        .rst_ni (src_rst_ni),
        .we_i   (fifo_we),
        .addr_i (fifo_wr_addr),
        .data_i (src_data_i),
        .data_o (fifo_data_out),
        .addr_o (fifo_rd_addr)
    );

    // Source side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_we <= 1'b0;
        end else begin
            fifo_we <= src_valid_i & src_ready_o;
        end
    end

    assign fifo_wr_addr = src_gray_count_synced;
    assign src_ready_o = (src_gray_count != dst_gray_count_synced);

    // Destination side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            fifo_valid_count <= {LOG_DEPTH+1{1'b0}};
        end else begin
            fifo_valid_count <= dst_gray_count;
        end
    end

    assign fifo_rd_addr = dst_gray_count_synced;
    assign dst_data_o = fifo_data_out;
    assign dst_valid_o = (fifo_valid_count != fifo_rd_addr);

endmodule

// Gray counter module for generating gray code
module cdc_gray_counter_1 (
    input  clk_i,
    input  rst_ni,
    output [LOG_DEPTH:0] gray_o
);

    reg [LOG_DEPTH:0] bin_count;
    reg [LOG_DEPTH:0] gray_count;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_count <= {LOG_DEPTH+1{1'b0}};
        end else begin
            bin_count <= bin_count + 1;
        end
    end

    assign gray_count = (bin_count >> 1) ^ bin_count;
    assign gray_o = gray_count;

endmodule

// Synchronized gray counter module for cross-domain synchronization
module cdc_gray_counter_2 (
    input  clk_i,
    input  rst_ni,
    input  [LOG_DEPTH:0] gray_i,
    output [LOG_DEPTH:0] gray_o
);

    reg [LOG_DEPTH:0] sync_gray_1;
    reg [LOG_DEPTH:0] sync_gray_2;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_gray_1 <= {LOG_DEPTH+1{1'b0}};
            sync_gray_2 <= {LOG_DEPTH+1{1'b0}};
        end else begin
            sync_gray_1 <= gray_i;
            sync_gray_2 <= sync_gray_1;
        end
    end

    assign gray_o = sync_gray_2;

endmodule

// FIFO memory module
module fifo_memory_1 #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  we_i,
    input  [LOG_DEPTH:0]   addr_i,
    input  [WIDTH-1:0]     data_i,
    output [WIDTH-1:0]     data_o,
    input  [LOG_DEPTH:0]   addr_o
);

    reg [WIDTH-1:0] memory [0:(2**(LOG_DEPTH+1)-1)];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            memory <= '{default:0};
        end else if (we_i) begin
            memory[addr_i] <= data_i;
        end
    end

    assign data_o = memory[addr_o];

endmodule
