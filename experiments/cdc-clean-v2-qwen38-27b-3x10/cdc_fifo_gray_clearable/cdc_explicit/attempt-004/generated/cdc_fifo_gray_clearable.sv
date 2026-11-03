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
    localparam GRAY_W = LOG_DEPTH + 1;

    // Source domain
    reg [PTR_W-1:0] src_wr_ptr;
    reg [GRAY_W-1:0] src_wr_ptr_gray;
    reg [GRAY_W-1:0] src_rd_ptr_gray_sync;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg src_clear_pending;
    reg src_clear_active;

    // Destination domain
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [GRAY_W-1:0] dst_rd_ptr_gray;
    reg [GRAY_W-1:0] dst_wr_ptr_gray_sync;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg dst_clear_pending;
    reg dst_clear_active;

    // Synchronizer for source write pointer gray to destination
    reg [GRAY_W-1:0] src_wr_ptr_gray_sync [0:SYNC_STAGES-1];
    // Synchronizer for destination read pointer gray to source
    reg [GRAY_W-1:0] dst_rd_ptr_gray_sync [0:SYNC_STAGES-1];

    // Clear synchronizers
    reg src_clear_sync [0:SYNC_STAGES-1];
    reg dst_clear_sync [0:SYNC_STAGES-1];

    // Binary to Gray conversion
    function [GRAY_W-1:0] bin2gray;
        input [PTR_W-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Gray to Binary conversion
    function [PTR_W-1:0] gray2bin;
        input [GRAY_W-1:0] gray;
        integer i;
        begin
            gray2bin[GRAY_W-1] = gray[GRAY_W-1];
            for (i = GRAY_W-2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Source domain logic
    wire src_wr_ptr_gray_next = bin2gray(src_wr_ptr + 1'b1);
    wire src_full = (src_wr_ptr_gray == src_rd_ptr_gray_sync[SYNC_STAGES-1]) &&
                    (src_wr_ptr[LOG_DEPTH-1:0] != src_rd_ptr_gray_sync[SYNC_STAGES-1][LOG_DEPTH-1:0]);
    wire src_empty = (src_wr_ptr_gray == src_rd_ptr_gray_sync[SYNC_STAGES-1]);
    wire src_can_write = src_valid_i && src_ready_o && !src_clear_active;
    wire src_ready = !src_full && !src_clear_active;

    // Destination domain logic
    wire dst_rd_ptr_gray_next = bin2gray(dst_rd_ptr + 1'b1);
    wire dst_empty = (dst_rd_ptr_gray == dst_wr_ptr_gray_sync[SYNC_STAGES-1]);
    wire dst_can_read = dst_valid_reg && dst_ready_i && !dst_clear_active;

    // Source clear pending logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 1'b0;
            src_clear_active <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending <= 1'b1;
                src_clear_active <= 1'b1;
            end else if (src_clear_pending && !src_clear_active) begin
                src_clear_pending <= 1'b0;
            end
        end
    end

    // Destination clear pending logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 1'b0;
            dst_clear_active <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending <= 1'b1;
                dst_clear_active <= 1'b1;
            end else if (dst_clear_pending && !dst_clear_active) begin
                dst_clear_pending <= 1'b0;
            end
        end
    end

    // Source write pointer
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
            src_wr_ptr_gray <= {GRAY_W{1'b0}};
        end else if (src_clear_active) begin
            src_wr_ptr <= {PTR_W{1'b0}};
            src_wr_ptr_gray <= {GRAY_W{1'b0}};
        end else if (src_can_write) begin
            src_wr_ptr <= src_wr_ptr + 1'b1;
            src_wr_ptr_gray <= src_wr_ptr_gray_next;
        end
    end

    // Memory write
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            // No action needed for memory
        end else if (src_can_write) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // Destination read pointer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_rd_ptr_gray <= {GRAY_W{1'b0}};
        end else if (dst_clear_active) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_rd_ptr_gray <= {GRAY_W{1'b0}};
        end else if (dst_can_read) begin
            dst_rd_ptr <= dst_rd_ptr + 1'b1;
            dst_rd_ptr_gray <= dst_rd_ptr_gray_next;
        end
    end

    // Destination data and valid
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else if (dst_clear_active) begin
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else if (dst_can_read) begin
            dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
            dst_valid_reg <= 1'b1;
        end else begin
            dst_valid_reg <= 1'b0;
        end
    end

    // Synchronizers
    integer i;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1) begin
                dst_rd_ptr_gray_sync[i] <= {GRAY_W{1'b0}};
                src_clear_sync[i] <= 1'b0;
            end
        end else begin
            dst_rd_ptr_gray_sync[0] <= dst_rd_ptr_gray;
            src_clear_sync[0] <= dst_clear_i;
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                dst_rd_ptr_gray_sync[i] <= dst_rd_ptr_gray_sync[i-1];
                src_clear_sync[i] <= src_clear_sync[i-1];
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1) begin
                src_wr_ptr_gray_sync[i] <= {GRAY_W{1'b0}};
                dst_clear_sync[i] <= 1'b0;
            end
        end else begin
            src_wr_ptr_gray_sync[0] <= src_wr_ptr_gray;
            dst_clear_sync[0] <= src_clear_i;
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                src_wr_ptr_gray_sync[i] <= src_wr_ptr_gray_sync[i-1];
                dst_clear_sync[i] <= dst_clear_sync[i-1];
            end
        end
    end

    // Clear active deactivation
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_active <= 1'b0;
        end else if (src_clear_active && src_clear_sync[SYNC_STAGES-1]) begin
            src_clear_active <= 1'b0;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_active <= 1'b0;
        end else if (dst_clear_active && dst_clear_sync[SYNC_STAGES-1]) begin
            dst_clear_active <= 1'b0;
        end
    end

    // Outputs
    assign src_ready_o = src_ready;
    assign src_clear_pending_o = src_clear_pending;
    assign dst_valid_o = dst_valid_reg;
    assign dst_data_o = dst_data_reg;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
