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
    reg  [LOG_DEPTH:0]     src_gray_wr_ptr, src_gray_wr_ptr_sync;
    reg  [LOG_DEPTH:0]     src_gray_rd_ptr;
    reg  [LOG_DEPTH:0]     dst_gray_wr_ptr;
    reg  [LOG_DEPTH:0]     dst_gray_rd_ptr, dst_gray_rd_ptr_sync;
    reg  [LOG_DEPTH-1:0]   mem_wr_addr;
    reg  [LOG_DEPTH-1:0]   mem_rd_addr;
    reg  [WIDTH-1:0]       mem [0:(1<<LOG_DEPTH)-1];
    reg  [WIDTH-1:0]       mem_wr_data;
    reg                    mem_wr_en;
    reg  [WIDTH-1:0]       mem_rd_data;
    wire [LOG_DEPTH:0]     src_full, src_not_full;
    wire [LOG_DEPTH:0]     dst_empty, dst_not_empty;
    reg  [LOG_DEPTH:0]     src_gray_wr_ptr_next;
    reg  [LOG_DEPTH:0]     src_gray_rd_ptr_next;
    reg  [LOG_DEPTH:0]     dst_gray_wr_ptr_next;
    reg  [LOG_DEPTH:0]     dst_gray_rd_ptr_next;

    // Gray code counters
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) src_gray_counter (
        .clk        (src_clk_i),
        .rst_n      (src_rst_ni),
        .en         (src_valid_i & src_ready_o),
        .gray_code  (src_gray_wr_ptr_next)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) dst_gray_counter (
        .clk        (dst_clk_i),
        .rst_n      (dst_rst_ni),
        .en         (dst_valid_o & dst_ready_i),
        .gray_code  (dst_gray_rd_ptr_next)
    );

    // Synchronizers
    sync_gray #(.LOG_DEPTH(LOG_DEPTH)) wr_ptr_sync (
        .src_clk    (src_clk_i),
        .dst_clk    (dst_clk_i),
        .src_gray_code(src_gray_wr_ptr_next),
        .dst_gray_code(dst_gray_wr_ptr)
    );

    sync_gray #(.LOG_DEPTH(LOG_DEPTH)) rd_ptr_sync (
        .src_clk    (dst_clk_i),
        .dst_clk    (src_clk_i),
        .src_gray_code(dst_gray_rd_ptr_next),
        .dst_gray_code(src_gray_rd_ptr)
    );

    // Write address and enable
    assign mem_wr_addr = src_gray_wr_ptr[LOG_DEPTH-1:0];
    assign mem_wr_data = src_data_i;
    assign mem_wr_en = src_valid_i & src_ready_o;

    // Read address
    assign mem_rd_addr = dst_gray_rd_ptr[LOG_DEPTH-1:0];

    // Memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            mem <= '{default:0};
        end else if (mem_wr_en) begin
            mem[mem_wr_addr] <= mem_wr_data;
        end
    end

    // Read data
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            mem_rd_data <= 0;
        end else begin
            mem_rd_data <= mem[mem_rd_addr];
        end
    end

    // Output data and valid
    assign dst_data_o = mem_rd_data;
    assign dst_valid_o = !dst_empty;

    // Full and not full flags
    assign src_full = (src_gray_wr_ptr_next == {src_gray_rd_ptr[LOG_DEPTH], ~src_gray_rd_ptr[LOG_DEPTH-1:0]});
    assign src_not_full = ~src_full;

    // Empty and not empty flags
    assign dst_empty = (dst_gray_wr_ptr == dst_gray_rd_ptr);
    assign dst_not_empty = ~dst_empty;

    // Ready signal
    assign src_ready_o = src_not_full;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_n,
    input                  en,
    output [LOG_DEPTH:0]   gray_code
);

    reg [LOG_DEPTH:0] bin_count, next_bin_count;

    // Binary counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_count <= 0;
        end else if (en) begin
            bin_count <= next_bin_count;
        end
    end

    // Next binary count
    always @(*) begin
        next_bin_count = bin_count + 1;
    end

    // Convert binary to Gray code
    assign gray_code = (bin_count >> 1) ^ bin_count;

endmodule

module sync_gray #(
    parameter LOG_DEPTH = 3
)(
    input                  src_clk,
    input                  dst_clk,
    input  [LOG_DEPTH:0]   src_gray_code,
    output [LOG_DEPTH:0]   dst_gray_code
);

    reg [LOG_DEPTH:0] gray_code_sync [0:SYNC_STAGES-1];

    // Synchronize Gray code across clock domains
    always @(posedge src_clk) begin
        gray_code_sync[0] <= src_gray_code;
    end

    generate
        if (SYNC_STAGES > 1) begin
            genvar i;
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                always @(posedge src_clk) begin
                    gray_code_sync[i] <= gray_code_sync[i-1];
                end
            end
        end
    endgenerate

    always @(posedge dst_clk) begin
        dst_gray_code <= gray_code_sync[SYNC_STAGES-1];
    end

endmodule
