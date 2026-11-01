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
    localparam PTR_WIDTH = LOG_DEPTH + 1;
    localparam GRAY_WIDTH = LOG_DEPTH + 1;

    // Source domain
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [GRAY_WIDTH-1:0] src_wr_ptr_gray;
    reg [GRAY_WIDTH-1:0] src_rd_ptr_gray_sync;
    reg [GRAY_WIDTH-1:0] src_rd_ptr_gray_sync_next;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg src_clear_pending;
    reg src_clear_active;

    // Destination domain
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [GRAY_WIDTH-1:0] dst_rd_ptr_gray;
    reg [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync_next;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg dst_clear_pending;
    reg dst_clear_active;

    // Synchronizer registers for source read pointer gray
    reg [GRAY_WIDTH-1:0] src_rd_ptr_gray_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for destination write pointer gray
    reg [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync_r [0:SYNC_STAGES-1];

    // Binary to Gray conversion
    function [GRAY_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Gray to Binary conversion
    function [PTR_WIDTH-1:0] gray2bin;
        input [GRAY_WIDTH-1:0] gray;
        reg [PTR_WIDTH-1:0] bin;
        integer i;
        begin
            bin[GRAY_WIDTH-1] = gray[GRAY_WIDTH-1];
            for (i = GRAY_WIDTH-2; i >= 0; i = i - 1)
                bin[i] = bin[i+1] ^ gray[i];
            gray2bin = bin;
        end
    endfunction

    // Source domain logic
    wire src_wr_ptr_gray_next = bin2gray(src_wr_ptr + 1'b1);
    wire src_full = (src_wr_ptr_gray == src_rd_ptr_gray_sync_next) &&
                    (src_wr_ptr[LOG_DEPTH] != src_rd_ptr_gray_sync_next[LOG_DEPTH]);
    wire src_empty = (src_wr_ptr_gray == src_rd_ptr_gray_sync_next);
    wire src_can_write = src_valid_i && !src_full && !src_clear_active && src_rst_ni;

    // Destination domain logic
    wire dst_rd_ptr_gray_next = bin2gray(dst_rd_ptr + 1'b1);
    wire dst_empty = (dst_rd_ptr_gray == dst_wr_ptr_gray_sync_next);
    wire dst_can_read = dst_valid_reg && dst_ready_i && !dst_clear_active && dst_rst_ni;

    // Source clear pending logic
    // Clear is pending until the FIFO is empty and no in-flight data
    wire src_clear_done = src_empty && !src_clear_active;

    // Destination clear pending logic
    wire dst_clear_done = dst_empty && !dst_valid_reg && !dst_clear_active;

    // Source domain always block
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
            src_clear_pending <= 1'b0;
            src_clear_active <= 1'b0;
        end else begin
            // Handle clear request
            if (src_clear_i && !src_clear_active) begin
                src_clear_active <= 1'b1;
                src_clear_pending <= 1'b1;
            end

            // If clear is active, wait until FIFO is empty
            if (src_clear_active) begin
                if (src_empty) begin
                    src_clear_active <= 1'b0;
                    src_clear_pending <= 1'b0;
                    // Reset pointers
                    src_wr_ptr <= {PTR_WIDTH{1'b0}};
                    src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
                end
            end else begin
                // Normal operation
                if (src_can_write) begin
                    mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                    src_wr_ptr <= src_wr_ptr + 1'b1;
                    src_wr_ptr_gray <= src_wr_ptr_gray_next;
                end
            end
        end
    end

    // Source read pointer gray synchronizer
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray_sync_r[0] <= {GRAY_WIDTH{1'b0}};
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_rd_ptr_gray_sync_r[i] <= {GRAY_WIDTH{1'b0}};
        end else begin
            src_rd_ptr_gray_sync_r[0] <= dst_rd_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_rd_ptr_gray_sync_r[i] <= src_rd_ptr_gray_sync_r[i-1];
        end
    end

    assign src_rd_ptr_gray_sync_next = src_rd_ptr_gray_sync_r[SYNC_STAGES-1];
    assign src_ready_o = !src_full && !src_clear_active && src_rst_ni;
    assign src_clear_pending_o = src_clear_pending;

    // Destination domain always block
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray <= {GRAY_WIDTH{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
            dst_clear_pending <= 1'b0;
            dst_clear_active <= 1'b0;
        end else begin
            // Handle clear request
            if (dst_clear_i && !dst_clear_active) begin
                dst_clear_active <= 1'b1;
                dst_clear_pending <= 1'b1;
                dst_valid_reg <= 1'b0;
            end

            // If clear is active, wait until FIFO is empty and no valid data
            if (dst_clear_active) begin
                if (dst_empty && !dst_valid_reg) begin
                    dst_clear_active <= 1'b0;
                    dst_clear_pending <= 1'b0;
                    // Reset pointers
                    dst_rd_ptr <= {PTR_WIDTH{1'b0}};
                    dst_rd_ptr_gray <= {GRAY_WIDTH{1'b0}};
                end
            end else begin
                // Normal operation
                if (dst_can_read) begin
                    dst_rd_ptr <= dst_rd_ptr + 1'b1;
                    dst_rd_ptr_gray <= dst_rd_ptr_gray_next;
                    dst_valid_reg <= 1'b0;
                end else if (!dst_empty && !dst_valid_reg) begin
                    dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                    dst_valid_reg <= 1'b1;
                end
            end
        end
    end

    // Destination write pointer gray synchronizer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray_sync_r[0] <= {GRAY_WIDTH{1'b0}};
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_wr_ptr_gray_sync_r[i] <= {GRAY_WIDTH{1'b0}};
        end else begin
            dst_wr_ptr_gray_sync_r[0] <= src_wr_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_wr_ptr_gray_sync_r[i] <= dst_wr_ptr_gray_sync_r[i-1];
        end
    end

    assign dst_wr_ptr_gray_sync_next = dst_wr_ptr_gray_sync_r[SYNC_STAGES-1];
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
