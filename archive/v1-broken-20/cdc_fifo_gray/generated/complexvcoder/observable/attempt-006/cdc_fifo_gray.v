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
    logic [WIDTH-1:0] mem [2**LOG_DEPTH-1:0];
    logic [LOG_DEPTH-1:0] wr_ptr_gray, rd_ptr_gray, wr_ptr_gray_sync, rd_ptr_gray_sync;
    logic full, empty, full_sync, empty_sync;

    // Gray counter
    logic [LOG_DEPTH-1:0] gray_count;
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            gray_count <= 0;
        end else begin
            gray_count <= gray_count + src_valid_i;
        end
    end

    // Convert Gray to Binary for write pointer
    logic [LOG_DEPTH-1:0] wr_ptr_bin;
    always_comb begin
        wr_ptr_bin = 0;
        logic [LOG_DEPTH-1:0] mask = 1;
        for (int i = 0; i < LOG_DEPTH; i = i + 1) begin
            if (gray_count[i] ^ gray_count[i+1]) begin
                wr_ptr_bin = wr_ptr_bin | mask;
            end
            mask = mask << 1;
        end
    end

    // FIFO logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr_gray <= 0;
            rd_ptr_gray <= 0;
        end else if (src_valid_i && src_ready_o && !full) begin
            mem[wr_ptr_gray] <= src_data_i;
            wr_ptr_gray <= wr_ptr_gray + 1;
        end
    end

    assign full = wr_ptr_gray == rd_ptr_gray + 1;
    assign empty = wr_ptr_gray == rd_ptr_gray;

    // Convert Gray to Binary for read pointer
    logic [LOG_DEPTH-1:0] rd_ptr_bin;
    always_comb begin
        rd_ptr_bin = 0;
        logic [LOG_DEPTH-1:0] mask = 1;
        for (int i = 0; i < LOG_DEPTH; i = i + 1) begin
            if (rd_ptr_gray[i] ^ rd_ptr_gray[i+1]) begin
                rd_ptr_bin = rd_ptr_bin | mask;
            end
            mask = mask << 1;
        end
    end

    // Output logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_o <= 1;
        end else if (!full && src_valid_i) begin
            src_ready_o <= 0;
        end else if (dst_ready_i && !empty) begin
            src_ready_o <= 1;
        end
    end

    // Gray synchronization
    logic [WIDTH-1:0] data_gray_sync;
    logic valid_gray_sync;
    logic ready_gray_sync;

    sync_reg #(.WIDTH(WIDTH), .SYNC_STAGES(SYNC_STAGES)) sync_reg_inst (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .data_i(mem[rd_ptr_gray]),
        .valid_i(!empty),
        .ready_o(ready_gray_sync)
    );

    assign dst_data_o = data_gray_sync;
    assign dst_valid_o = valid_gray_sync;

    sync_reg #(.WIDTH(WIDTH), .SYNC_STAGES(SYNC_STAGES)) sync_reg_inst_2 (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .data_i(mem[rd_ptr_gray]),
        .valid_i(!empty),
        .ready_o(ready_gray_sync)
    );

    // Convert Gray to Binary for read pointer in destination clock domain
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr_gray_sync <= 0;
        end else if (ready_gray_sync && !empty) begin
            rd_ptr_gray_sync <= rd_ptr_gray_sync + 1;
        end
    end

    assign valid_gray_sync = !empty;
    assign dst_ready_i = !ready_gray_sync;

endmodule
