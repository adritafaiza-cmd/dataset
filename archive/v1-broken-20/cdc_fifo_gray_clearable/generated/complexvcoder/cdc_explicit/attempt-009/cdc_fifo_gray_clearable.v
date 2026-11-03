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

    localparam FIFO_DEPTH = 2**LOG_DEPTH;

    // Internal signals for FIFO
    logic [FIFO_DEPTH-1:0] mem [0:FIFO_DEPTH-1];
    logic [LOG_DEPTH:0] head, tail;
    logic full, empty;
    logic [LOG_DEPTH:0] head_gray, tail_gray;

    // Helper functions to convert between binary and Gray code
    function logic [LOG_DEPTH:0] binary_to_gray;
        input [LOG_DEPTH:0] binary;
        begin
            binary_to_gray = binary ^ (binary >> 1);
        end
    endfunction

    function logic [LOG_DEPTH:0] gray_to_binary;
        input [LOG_DEPTH:0] gray;
        begin
            for (int i = LOG_DEPTH; i > 0; i--)
                gray_to_binary[i] = gray[i] ^ gray[i-1];
        end
    endfunction

    // Clear logic
    logic clear_active_src, clear_active_dst;
    logic [LOG_DEPTH:0] clear_head_gray, clear_tail_gray;
    logic [LOG_DEPTH:0] clear_head_gray_sync, clear_tail_gray_sync;

    assign clear_active_src = src_clear_i & src_rst_ni;
    assign clear_active_dst = dst_clear_i & dst_rst_ni;

    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            clear_head_gray <= 0;
            clear_tail_gray <= 0;
        end else if (clear_active_src) begin
            clear_head_gray <= binary_to_gray(0);
            clear_tail_gray <= binary_to_gray(0);
        end else if (src_ready_o) begin
            clear_head_gray <= binary_to_gray(head);
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            clear_head_gray_sync <= 0;
            clear_tail_gray_sync <= 0;
        end else if (clear_active_dst) begin
            clear_head_gray_sync <= binary_to_gray(0);
            clear_tail_gray_sync <= binary_to_gray(0);
        end else if (dst_valid_o) begin
            clear_tail_gray_sync <= binary_to_gray(tail);
        end
    end

    assign src_clear_pending_o = clear_active_src;
    assign dst_clear_pending_o = clear_active_dst;

    // FIFO logic
    assign full = (tail_gray == head_gray) & (~empty);
    assign empty = (head_gray == tail_gray) & (full);

    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            head_gray <= 0;
            tail_gray <= 0;
        end else if (clear_active_src) begin
            head_gray <= clear_head_gray;
            tail_gray <= clear_tail_gray;
        end else if (src_valid_i && src_ready_o) begin
            mem[tail_gray] <= src_data_i;
            tail_gray <= tail_gray + 1;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            head_gray <= 0;
            tail_gray <= 0;
        end else if (clear_active_dst) begin
            head_gray <= clear_head_gray_sync;
            tail_gray <= clear_tail_gray_sync;
        end else if (dst_ready_i && dst_valid_o) begin
            head_gray <= head_gray + 1;
        end
    end

    // Output logic
    assign src_ready_o = !full;
    assign dst_valid_o = !empty;

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else if (dst_valid_o) begin
            dst_data_o <= mem[head_gray];
        end
    end

endmodule
