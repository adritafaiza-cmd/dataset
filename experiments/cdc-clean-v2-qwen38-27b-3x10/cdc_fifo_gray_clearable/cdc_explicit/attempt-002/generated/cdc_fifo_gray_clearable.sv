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
    reg [PTR_W-1:0] src_rd_ptr_gray_sync [0:SYNC_STAGES-1];
    reg [PTR_W-1:0] src_rd_ptr_gray_sync_next;
    reg src_clear_pending;
    reg src_clear_done;

    // Destination domain
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] dst_wr_ptr_gray;
    reg [PTR_W-1:0] dst_wr_ptr_gray_sync [0:SYNC_STAGES-1];
    reg [PTR_W-1:0] dst_wr_ptr_gray_sync_next;
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

    // Source domain logic
    wire [PTR_W-1:0] src_rd_ptr_gray_synced = src_rd_ptr_gray_sync[SYNC_STAGES-1];
    wire [PTR_W-1:0] src_rd_ptr_bin_synced;
    wire src_full;
    wire src_can_write;

    // Convert gray to binary for comparison
    reg [PTR_W-1:0] gray_to_bin;
    integer i;
    always @* begin
        gray_to_bin[PTR_W-1] = src_rd_ptr_gray_synced[PTR_W-1];
        for (i = PTR_W-2; i >= 0; i = i - 1)
            gray_to_bin[i] = gray_to_bin[i+1] ^ src_rd_ptr_gray_synced[i];
    end
    assign src_rd_ptr_bin_synced = gray_to_bin;

    assign src_full = (src_wr_ptr == src_rd_ptr_bin_synced) && 
                      (src_wr_ptr[PTR_W-1] != src_rd_ptr_bin_synced[PTR_W-1]);
    // Actually, for a FIFO with LOG_DEPTH+1 bits, full when:
    // MSB differs and lower bits are equal
    assign src_full = (src_wr_ptr[PTR_W-1] != src_rd_ptr_bin_synced[PTR_W-1]) && 
                      (src_wr_ptr[PTR_W-2:0] == src_rd_ptr_bin_synced[PTR_W-2:0]);

    assign src_can_write = src_valid_i && !src_full && !src_clear_pending;
    assign src_ready_o = !src_full && !src_clear_pending;

    // Source write
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
            src_clear_pending <= 1'b0;
            src_clear_done <= 1'b0;
        end else begin
            if (src_clear_i && !src_clear_pending) begin
                src_clear_pending <= 1'b1;
                src_clear_done <= 1'b0;
            end else if (src_clear_pending) begin
                // Wait for destination to acknowledge clear
                if (dst_clear_done) begin
                    src_clear_pending <= 1'b0;
                    src_clear_done <= 1'b1;
                    src_wr_ptr <= {PTR_W{1'b0}};
                end
            end else if (src_can_write) begin
                mem[src_wr_ptr[PTR_W-2:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1'b1;
            end
        end
    end

    // Synchronize source read pointer gray to destination
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_rd_ptr_gray_sync[0] <= {PTR_W{1'b0}};
            src_rd_ptr_gray_sync[1] <= {PTR_W{1'b0}};
            src_rd_ptr_gray_sync[2] <= {PTR_W{1'b0}};
        end else begin
            src_rd_ptr_gray_sync[0] <= src_rd_ptr_gray;
            src_rd_ptr_gray_sync[1] <= src_rd_ptr_gray_sync[0];
            src_rd_ptr_gray_sync[2] <= src_rd_ptr_gray_sync[1];
        end
    end

    // Destination domain logic
    wire [PTR_W-1:0] dst_wr_ptr_gray_synced = dst_wr_ptr_gray_sync[SYNC_STAGES-1];
    wire [PTR_W-1:0] dst_wr_ptr_bin_synced;
    wire dst_empty;
    wire dst_can_read;

    // Convert gray to binary
    reg [PTR_W-1:0] gray_to_bin_dst;
    always @* begin
        gray_to_bin_dst[PTR_W-1] = dst_wr_ptr_gray_synced[PTR_W-1];
        for (i = PTR_W-2; i >= 0; i = i - 1)
            gray_to_bin_dst[i] = gray_to_bin_dst[i+1] ^ dst_wr_ptr_gray_synced[i];
    end
    assign dst_wr_ptr_bin_synced = gray_to_bin_dst;

    assign dst_empty = (dst_rd_ptr == dst_wr_ptr_bin_synced);
    assign dst_can_read = dst_valid_reg && dst_ready_i && !dst_clear_pending;

    // Destination read and output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_clear_pending <= 1'b0;
            dst_clear_done <= 1'b0;
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_clear_i && !dst_clear_pending) begin
                dst_clear_pending <= 1'b1;
                dst_clear_done <= 1'b0;
                dst_valid_reg <= 1'b0;
            end else if (dst_clear_pending) begin
                // Wait for source to acknowledge clear
                if (src_clear_done) begin
                    dst_clear_pending <= 1'b0;
                    dst_clear_done <= 1'b1;
                    dst_rd_ptr <= {PTR_W{1'b0}};
                    dst_valid_reg <= 1'b0;
                end
            end else if (dst_can_read) begin
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
                dst_valid_reg <= 1'b0;
            end else if (!dst_valid_reg && !dst_empty) begin
                dst_data_reg <= mem[dst_rd_ptr[PTR_W-2:0]];
                dst_valid_reg <= 1'b1;
            end
        end
    end

    // Synchronize destination write pointer gray to source
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_wr_ptr_gray_sync[0] <= {PTR_W{1'b0}};
            dst_wr_ptr_gray_sync[1] <= {PTR_W{1'b0}};
            dst_wr_ptr_gray_sync[2] <= {PTR_W{1'b0}};
        end else begin
            dst_wr_ptr_gray_sync[0] <= dst_wr_ptr_gray;
            dst_wr_ptr_gray_sync[1] <= dst_wr_ptr_gray_sync[0];
            dst_wr_ptr_gray_sync[2] <= dst_wr_ptr_gray_sync[1];
        end
    end

    // Update gray pointers
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_rd_ptr_gray <= {PTR_W{1'b0}};
        else
            src_rd_ptr_gray <= bin2gray(src_rd_ptr_bin_synced);
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_wr_ptr_gray <= {PTR_W{1'b0}};
        else
            dst_wr_ptr_gray <= bin2gray(dst_wr_ptr_bin_synced);
    end

    // Clear pending outputs
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
