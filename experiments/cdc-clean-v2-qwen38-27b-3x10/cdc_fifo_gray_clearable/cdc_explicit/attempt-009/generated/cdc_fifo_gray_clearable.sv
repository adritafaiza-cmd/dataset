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
    localparam PTR_W = LOG_DEPTH + 1;

    // Source domain
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] src_rd_ptr_gray;
    reg [PTR_W-1:0] src_rd_ptr_gray_sync;
    reg [PTR_W-1:0] src_rd_ptr_gray_sync2;
    reg [PTR_W-1:0] src_rd_ptr_gray_sync3;
    reg src_clear_pending;
    reg src_clear_done;

    // Destination domain
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] dst_wr_ptr_gray;
    reg [PTR_W-1:0] dst_wr_ptr_gray_sync;
    reg [PTR_W-1:0] dst_wr_ptr_gray_sync2;
    reg [PTR_W-1:0] dst_wr_ptr_gray_sync3;
    reg dst_clear_pending;
    reg dst_clear_done;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // Gray code conversion
    function [PTR_W-1:0] bin2gray;
        input [PTR_W-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Source domain: write pointer and memory
    wire src_wr_en = src_valid_i & src_ready_o & ~src_clear_pending;
    wire [PTR_W-1:0] src_wr_ptr_next = src_wr_ptr + 1'b1;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
            src_clear_pending <= 1'b0;
            src_clear_done <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending <= 1'b1;
                src_clear_done <= 1'b0;
            end else if (src_clear_pending) begin
                // Wait for destination to acknowledge clear
                if (dst_clear_done) begin
                    src_clear_pending <= 1'b0;
                    src_clear_done <= 1'b1;
                end
            end
            if (src_wr_en) begin
                mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr_next;
            end
        end
    end

    // Source domain: synchronize destination read pointer (gray)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray_sync <= {PTR_W{1'b0}};
            src_rd_ptr_gray_sync2 <= {PTR_W{1'b0}};
            src_rd_ptr_gray_sync3 <= {PTR_W{1'b0}};
        end else begin
            src_rd_ptr_gray_sync <= dst_rd_ptr_gray;
            src_rd_ptr_gray_sync2 <= src_rd_ptr_gray_sync;
            src_rd_ptr_gray_sync3 <= src_rd_ptr_gray_sync2;
        end
    end

    // Source ready: FIFO not full and not clearing
    wire [PTR_W-1:0] src_rd_ptr_bin_sync = src_rd_ptr_gray_sync3 ^ (src_rd_ptr_gray_sync3 >> 1);
    wire src_full = (src_wr_ptr == src_rd_ptr_bin_sync) && (src_wr_ptr[PTR_W-1] != src_rd_ptr_bin_sync[PTR_W-1]);
    assign src_ready_o = ~src_full & ~src_clear_pending;
    assign src_clear_pending_o = src_clear_pending;

    // Destination domain: read pointer and output
    wire dst_rd_en = dst_valid_reg & dst_ready_i & ~dst_clear_pending;
    wire [PTR_W-1:0] dst_rd_ptr_next = dst_rd_ptr + 1'b1;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_clear_pending <= 1'b0;
            dst_clear_done <= 1'b0;
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending <= 1'b1;
                dst_clear_done <= 1'b0;
                dst_valid_reg <= 1'b0;
            end else if (dst_clear_pending) begin
                // Wait for source to acknowledge clear
                if (src_clear_done) begin
                    dst_clear_pending <= 1'b0;
                    dst_clear_done <= 1'b1;
                end
            end
            if (dst_rd_en) begin
                dst_rd_ptr <= dst_rd_ptr_next;
                dst_valid_reg <= 1'b0;
            end
        end
    end

    // Destination domain: synchronize source write pointer (gray)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray_sync <= {PTR_W{1'b0}};
            dst_wr_ptr_gray_sync2 <= {PTR_W{1'b0}};
            dst_wr_ptr_gray_sync3 <= {PTR_W{1'b0}};
        end else begin
            dst_wr_ptr_gray_sync <= src_wr_ptr_gray;
            dst_wr_ptr_gray_sync2 <= dst_wr_ptr_gray_sync;
            dst_wr_ptr_gray_sync3 <= dst_wr_ptr_gray_sync2;
        end
    end

    // Destination: check if FIFO is not empty
    wire [PTR_W-1:0] dst_wr_ptr_bin_sync = dst_wr_ptr_gray_sync3 ^ (dst_wr_ptr_gray_sync3 >> 1);
    wire dst_empty = (dst_rd_ptr == dst_wr_ptr_bin_sync);

    // Destination: load data when not empty and not valid
    wire dst_load_en = ~dst_empty & ~dst_valid_reg & ~dst_clear_pending;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_clear_i || dst_clear_pending) begin
                dst_valid_reg <= 1'b0;
            end else if (dst_load_en) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_valid_reg <= 1'b1;
            end else if (dst_rd_en) begin
                dst_valid_reg <= 1'b0;
            end
        end
    end

    // Gray code pointers for CDC
    assign src_wr_ptr_gray = bin2gray(src_wr_ptr);
    assign dst_rd_ptr_gray = bin2gray(dst_rd_ptr);

    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg & ~dst_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
