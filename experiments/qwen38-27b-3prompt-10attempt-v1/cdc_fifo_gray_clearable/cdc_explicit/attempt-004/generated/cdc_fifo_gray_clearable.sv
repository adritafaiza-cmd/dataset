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
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [GRAY_WIDTH-1:0] src_wr_gray;
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync [0:SYNC_STAGES-1];
    reg [GRAY_WIDTH-1:0] src_rd_gray_sync_next;
    reg src_clear_pending;
    reg src_clear_done;

    // Destination domain
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [GRAY_WIDTH-1:0] dst_rd_gray;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync [0:SYNC_STAGES-1];
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync_next;
    reg dst_clear_pending;
    reg dst_clear_done;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // Gray code conversion
    function [GRAY_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

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
    wire [PTR_WIDTH-1:0] src_rd_ptr_sync = gray2bin(src_rd_gray_sync[SYNC_STAGES-1]);
    wire [PTR_WIDTH-1:0] src_wr_ptr_next = src_wr_ptr + 1'b1;
    wire [GRAY_WIDTH-1:0] src_wr_gray_next = bin2gray(src_wr_ptr_next);

    wire src_full = (src_wr_ptr[PTR_WIDTH-1:1] == src_rd_ptr_sync[PTR_WIDTH-1:1]) &&
                    (src_wr_ptr[0] != src_rd_ptr_sync[0]);
    wire src_empty = (src_wr_ptr == src_rd_ptr_sync);

    wire src_can_write = src_valid_i && !src_full && !src_clear_pending;
    wire src_ready = !src_full && !src_clear_pending;

    // Destination domain logic
    wire [PTR_WIDTH-1:0] dst_wr_ptr_sync = gray2bin(dst_wr_gray_sync[SYNC_STAGES-1]);
    wire [PTR_WIDTH-1:0] dst_rd_ptr_next = dst_rd_ptr + 1'b1;
    wire [GRAY_WIDTH-1:0] dst_rd_gray_next = bin2gray(dst_rd_ptr_next);

    wire dst_full = (dst_rd_ptr[PTR_WIDTH-1:1] == dst_wr_ptr_sync[PTR_WIDTH-1:1]) &&
                    (dst_rd_ptr[0] != dst_wr_ptr_sync[0]);
    wire dst_empty = (dst_rd_ptr == dst_wr_ptr_sync);

    wire dst_can_read = dst_valid_reg && dst_ready_i && !dst_clear_pending;
    wire dst_valid = dst_valid_reg;

    // Source clear pending logic
    // Clear is pending until the destination side has also cleared and the FIFO is empty
    // We need to coordinate: when src_clear_i is asserted, we stop writing, 
    // and we need to wait until dst_clear_pending is deasserted and FIFO is empty.
    // But dst_clear_pending is in dst domain. We need to synchronize it back to src.
    
    // Let's use a simpler approach: 
    // When src_clear_i is asserted, src_clear_pending goes high.
    // We stop accepting writes.
    // We also need to clear the destination side.
    // The clear is complete when both sides have cleared and the FIFO is empty.
    
    // For simplicity and safety, let's define:
    // src_clear_pending is high from when src_clear_i is first seen until the FIFO is empty 
    // and dst_clear_pending (synchronized back) is low.
    
    // We need to sync dst_clear_pending back to src domain.
    reg [SYNC_STAGES-1:0] dst_clear_pending_sync;
    
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_clear_pending_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_clear_pending_sync[0] <= dst_clear_pending;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_clear_pending_sync[i] <= dst_clear_pending_sync[i-1];
        end
    end

    wire dst_clear_pending_synced = dst_clear_pending_sync[SYNC_STAGES-1];

    // src_clear_pending: high when src_clear_i is active or when we're waiting for clear to complete
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 1'b0;
            src_clear_done <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending <= 1'b1;
                src_clear_done <= 1'b0;
            end else if (src_clear_pending) begin
                // Clear is complete when FIFO is empty and dst_clear_pending is deasserted
                if (src_empty && !dst_clear_pending_synced) begin
                    src_clear_pending <= 1'b0;
                    src_clear_done <= 1'b1;
                end
            end else begin
                src_clear_done <= 1'b0;
            end
        end
    end

    // Destination clear pending logic
    // dst_clear_pending is high when dst_clear_i is active or when waiting for src_clear_pending to deassert
    reg [SYNC_STAGES-1:0] src_clear_pending_sync;
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_clear_pending_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            src_clear_pending_sync[0] <= src_clear_pending;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_clear_pending_sync[i] <= src_clear_pending_sync[i-1];
        end
    end

    wire src_clear_pending_synced = src_clear_pending_sync[SYNC_STAGES-1];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 1'b0;
            dst_clear_done <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending <= 1'b1;
                dst_clear_done <= 1'b0;
            end else if (dst_clear_pending) begin
                // Clear is complete when FIFO is empty and src_clear_pending is deasserted
                if (dst_empty && !src_clear_pending_synced) begin
                    dst_clear_pending <= 1'b0;
                    dst_clear_done <= 1'b1;
                end
            end else begin
                dst_clear_done <= 1'b0;
            end
        end
    end

    // Source write pointer and memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_wr_gray <= {GRAY_WIDTH{1'b0}};
        end else begin
            if (src_can_write) begin
                mem[src_wr_ptr[PTR_WIDTH-1:1]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr_next;
                src_wr_gray <= src_wr_gray_next;
            end else if (src_clear_i || src_clear_pending) begin
                // On clear, reset pointers to zero
                src_wr_ptr <= {PTR_WIDTH{1'b0}};
                src_wr_gray <= {GRAY_WIDTH{1'b0}};
            end
        end
    end

    // Source read gray synchronizer
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_gray_sync[0] <= {GRAY_WIDTH{1'b0}};
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_rd_gray_sync[i] <= {GRAY_WIDTH{1'b0}};
        end else begin
            src_rd_gray_sync[0] <= dst_rd_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_rd_gray_sync[i] <= src_rd_gray_sync[i-1];
        end
    end

    // Destination read pointer and data
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_gray <= {GRAY_WIDTH{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_can_read) begin
                dst_rd_ptr <= dst_rd_ptr_next;
                dst_rd_gray <= dst_rd_gray_next;
                dst_valid_reg <= 1'b0;
            end else if (dst_clear_i || dst_clear_pending) begin
                // On clear, reset pointers and valid
                dst_rd_ptr <= {PTR_WIDTH{1'b0}};
                dst_rd_gray <= {GRAY_WIDTH{1'b0}};
                dst_valid_reg <= 1'b0;
            end else if (!dst_empty && !dst_valid_reg) begin
                // Load data from memory
                dst_data_reg <= mem[dst_rd_ptr[PTR_WIDTH-1:1]];
                dst_valid_reg <= 1'b1;
            end
        end
    end

    // Destination write gray synchronizer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_gray_sync[0] <= {GRAY_WIDTH{1'b0}};
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_wr_gray_sync[i] <= {GRAY_WIDTH{1'b0}};
        end else begin
            dst_wr_gray_sync[0] <= src_wr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_wr_gray_sync[i] <= dst_wr_gray_sync[i-1];
        end
    end

    // Outputs
    assign src_ready_o = src_ready;
    assign src_clear_pending_o = src_clear_pending;
    assign dst_valid_o = dst_valid;
    assign dst_data_o = dst_data_reg;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
