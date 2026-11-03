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

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    logic [WIDTH-1:0] src_fifo [0:DEPTH-1];
    logic [ADDR_WIDTH-1:0] src_head, src_tail;
    logic [ADDR_WIDTH-1:0] src_read_ptr, src_write_ptr;
    logic src_full, src_empty;
    logic src_read_en, src_write_en;

    logic [WIDTH-1:0] dst_fifo [0:DEPTH-1];
    logic [ADDR_WIDTH-1:0] dst_head, dst_tail;
    logic [ADDR_WIDTH-1:0] dst_read_ptr, dst_write_ptr;
    logic dst_full, dst_empty;
    logic dst_read_en, dst_write_en;

    logic [WIDTH-1:0] src_gray, dst_gray;
    logic [WIDTH-1:0] src_gray_sync, dst_gray_sync;

    logic src_clear_pending, dst_clear_pending;

    // Gray code generator for address comparison
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray <= 0;
        end else begin
            src_gray <= src_gray + 1;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray <= 0;
        end else begin
            dst_gray <= dst_gray + 1;
        end
    end

    // Synchronizers for Gray code
    logic [WIDTH-1:0] src_gray_sync_reg [0:SYNC_STAGES-1];
    logic [WIDTH-1:0] dst_gray_sync_reg [0:SYNC_STAGES-1];

    generate
        if (SYNC_STAGES > 0) begin
            generate
                for (genvar i = 0; i < SYNC_STAGES; i++) begin : sync_gray
                    always_ff @(posedge src_clk_i) begin
                        src_gray_sync_reg[i] <= src_gray;
                    end
                    always_ff @(posedge dst_clk_i) begin
                        dst_gray_sync_reg[i] <= dst_gray;
                    end
                end
            endgenerate
            assign src_gray_sync = src_gray_sync_reg[SYNC_STAGES-1];
            assign dst_gray_sync = dst_gray_sync_reg[SYNC_STAGES-1];
        end else begin
            assign src_gray_sync = src_gray;
            assign dst_gray_sync = dst_gray;
        end
    endgenerate

    // FIFO logic
    assign src_read_ptr = src_head;
    assign src_write_ptr = src_tail;
    assign src_full = (src_write_ptr == src_read_ptr) && (src_gray_sync != src_gray);
    assign src_empty = (src_write_ptr == src_read_ptr) && (src_gray_sync == src_gray);

    assign dst_read_ptr = dst_head;
    assign dst_write_ptr = dst_tail;
    assign dst_full = (dst_write_ptr == dst_read_ptr) && (dst_gray_sync != dst_gray);
    assign dst_empty = (dst_write_ptr == dst_read_ptr) && (dst_gray_sync == dst_gray);

    assign src_ready_o = !src_full;
    assign dst_valid_o = !dst_empty;

    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_head <= 0;
        end else if (src_valid_i && src_ready_o && !src_clear_i) begin
            src_fifo[src_write_ptr] <= src_data_i;
            src_write_ptr <= src_write_ptr + 1;
        end else if (src_clear_i) begin
            src_head <= 0;
            src_tail <= 0;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_head <= 0;
        end else if (dst_ready_i && dst_valid_o && !dst_clear_i) begin
            dst_data_o <= dst_fifo[dst_read_ptr];
            dst_read_ptr <= dst_read_ptr + 1;
        end else if (dst_clear_i) begin
            dst_head <= 0;
            dst_tail <= 0;
        end
    end

    // Clear pending logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 0;
        end else if (src_clear_i) begin
            src_clear_pending <= 1;
        end else if (!src_empty) begin
            src_clear_pending <= 0;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 0;
        end else if (dst_clear_i) begin
            dst_clear_pending <= 1;
        end else if (!dst_full) begin
            dst_clear_pending <= 0;
        end
    end

    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
