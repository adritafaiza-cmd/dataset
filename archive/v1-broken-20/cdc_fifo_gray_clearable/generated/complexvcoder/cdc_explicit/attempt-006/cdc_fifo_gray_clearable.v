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
    logic [LOG_DEPTH-1:0] src_ptr;
    logic [LOG_DEPTH-1:0] dst_ptr;
    logic [LOG_DEPTH-1:0] wr_ptr_gray;
    logic [LOG_DEPTH-1:0] rd_ptr_gray;
    logic [LOG_DEPTH-1:0] wr_ptr_gray_sync;
    logic [LOG_DEPTH-1:0] rd_ptr_gray_sync;
    logic [WIDTH-1:0] mem [2**LOG_DEPTH-1:0];
    logic full;
    logic empty;
    logic src_clear_active;
    logic dst_clear_active;
    logic src_clear_done;
    logic dst_clear_done;

    // Clear logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_active <= 1'b0;
            src_clear_done <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_active <= 1'b1;
                src_clear_done <= 1'b0;
            end else if (src_clear_active) begin
                if (src_ptr == dst_ptr) begin
                    src_clear_active <= 1'b0;
                    src_clear_done <= 1'b1;
                end
            end
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_active <= 1'b0;
            dst_clear_done <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_active <= 1'b1;
                dst_clear_done <= 1'b0;
            end else if (dst_clear_active) begin
                if (src_ptr == dst_ptr) begin
                    dst_clear_active <= 1'b0;
                    dst_clear_done <= 1'b1;
                end
            end
        end
    end

    // FIFO logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= 0;
        end else if (src_valid_i && src_ready_o && !src_clear_active) begin
            src_ptr <= (src_ptr + 1) % (2**LOG_DEPTH);
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= 0;
        end else if (dst_ready_i && !dst_clear_active) begin
            dst_ptr <= (dst_ptr + 1) % (2**LOG_DEPTH);
        end
    end

    // Gray code conversion for CDC
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr_gray <= 0;
        end else if (src_valid_i && src_ready_o && !src_clear_active) begin
            wr_ptr_gray <= src_ptr ^ (src_ptr >> 1);
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr_gray <= 0;
        end else if (dst_ready_i && !dst_clear_active) begin
            rd_ptr_gray <= dst_ptr ^ (dst_ptr >> 1);
        end
    end

    // Synchronization for CDC
    logic [SYNC_STAGES-1:0] wr_ptr_gray_sync_reg;
    logic [SYNC_STAGES-1:0] rd_ptr_gray_sync_reg;

    always_ff @(posedge src_clk_i) begin
        wr_ptr_gray_sync_reg <= wr_ptr_gray;
    end

    always_ff @(posedge src_clk_i) begin
        wr_ptr_gray_sync_reg <= wr_ptr_gray;
    end

    always_ff @(posedge dst_clk_i) begin
        rd_ptr_gray_sync_reg <= rd_ptr_gray;
    end

    always_ff @(posedge dst_clk_i) begin
        rd_ptr_gray_sync_reg <= rd_ptr_gray;
    end

    // Output logic
    assign src_ready_o = !full;
    assign dst_valid_o = !empty;
    assign src_clear_pending_o = src_clear_active;
    assign dst_clear_pending_o = dst_clear_active;

    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            mem <= 2**LOG_DEPTH'{0};
        end else if (src_valid_i && src_ready_o && !src_clear_active) begin
            mem[wr_ptr_gray] <= src_data_i;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            mem <= 2**LOG_DEPTH'{0};
        end else if (dst_ready_i && !dst_clear_active) begin
            dst_data_o <= mem[rd_ptr_gray];
        end
    end

    assign full = (src_ptr == ((dst_ptr + 1) % (2**LOG_DEPTH)));
    assign empty = (src_ptr == dst_ptr);

endmodule
