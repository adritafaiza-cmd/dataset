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
    reg src_clear_done;

    // Destination domain
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [GRAY_WIDTH-1:0] dst_rd_ptr_gray;
    reg [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync_next;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg dst_clear_pending;
    reg dst_clear_active;
    reg dst_clear_done;

    // Synchronizer for source read pointer gray (in source domain)
    reg [SYNC_STAGES-1:0] src_rd_ptr_gray_sync_stages;

    // Synchronizer for destination write pointer gray (in destination domain)
    reg [SYNC_STAGES-1:0] dst_wr_ptr_gray_sync_stages;

    // Clear request synchronizers
    // Source clear request to destination domain
    reg [SYNC_STAGES-1:0] src_clear_to_dst_sync;
    // Destination clear request to source domain
    reg [SYNC_STAGES-1:0] dst_clear_to_src_sync;

    // Clear pending synchronizers (to ensure both sides know clear is done)
    // Source clear done to destination domain
    reg [SYNC_STAGES-1:0] src_clear_done_to_dst_sync;
    // Destination clear done to source domain
    reg [SYNC_STAGES-1:0] dst_clear_done_to_src_sync;

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
        integer i;
        begin
            gray2bin[GRAY_WIDTH-1] = gray[GRAY_WIDTH-1];
            for (i = GRAY_WIDTH-2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Source domain logic
    wire src_wr_ptr_gray_next = bin2gray(src_wr_ptr + 1'b1);
    wire src_can_write = (src_wr_ptr_gray != src_rd_ptr_gray_sync) && !src_clear_active;
    wire src_write = src_valid_i && src_ready_o && !src_clear_active;

    // Destination domain logic
    wire dst_rd_ptr_gray_next = bin2gray(dst_rd_ptr + 1'b1);
    wire dst_can_read = (dst_rd_ptr_gray != dst_wr_ptr_gray_sync) && !dst_clear_active;
    wire dst_read = dst_valid_reg && dst_ready_i && !dst_clear_active;

    // Source ready
    assign src_ready_o = src_can_write;

    // Destination valid
    assign dst_valid_o = dst_valid_reg;

    // Destination data
    assign dst_data_o = dst_data_reg;

    // Clear pending outputs
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

    // Source domain: write pointer and memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
            src_clear_pending <= 1'b0;
            src_clear_active <= 1'b0;
            src_clear_done <= 1'b0;
        end else begin
            if (src_clear_i && !src_clear_active) begin
                // Start clear
                src_clear_active <= 1'b1;
                src_clear_pending <= 1'b1;
                src_clear_done <= 1'b0;
            end else if (src_clear_active) begin
                // Wait for destination to confirm clear done
                if (dst_clear_done_to_src_sync[SYNC_STAGES-1]) begin
                    src_clear_active <= 1'b0;
                    src_clear_pending <= 1'b0;
                    src_clear_done <= 1'b1;
                    // Reset pointers
                    src_wr_ptr <= {PTR_WIDTH{1'b0}};
                    src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
                end
            end else begin
                if (src_write) begin
                    mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                    src_wr_ptr <= src_wr_ptr + 1'b1;
                    src_wr_ptr_gray <= src_wr_ptr_gray_next;
                end
            end
        end
    end

    // Source domain: synchronizer for destination read pointer gray
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray_sync_stages <= {SYNC_STAGES{1'b0}};
        end else begin
            src_rd_ptr_gray_sync_stages[0] <= dst_rd_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_rd_ptr_gray_sync_stages[i] <= src_rd_ptr_gray_sync_stages[i-1];
        end
    end
    assign src_rd_ptr_gray_sync = src_rd_ptr_gray_sync_stages[SYNC_STAGES-1];

    // Source domain: synchronizer for destination clear done
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_clear_done_to_src_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_clear_done_to_src_sync[0] <= dst_clear_done;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_clear_done_to_src_sync[i] <= dst_clear_done_to_src_sync[i-1];
        end
    end

    // Source domain: synchronizer for destination clear request
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_clear_to_src_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_clear_to_src_sync[0] <= dst_clear_i;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_clear_to_src_sync[i] <= dst_clear_to_src_sync[i-1];
        end
    end

    // Destination domain: read pointer and output register
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray <= {GRAY_WIDTH{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
            dst_clear_pending <= 1'b0;
            dst_clear_active <= 1'b0;
            dst_clear_done <= 1'b0;
        end else begin
            if (dst_clear_i && !dst_clear_active) begin
                // Start clear
                dst_clear_active <= 1'b1;
                dst_clear_pending <= 1'b1;
                dst_clear_done <= 1'b0;
                dst_valid_reg <= 1'b0;
            end else if (dst_clear_active) begin
                // Wait for source to confirm clear done
                if (src_clear_done_to_dst_sync[SYNC_STAGES-1]) begin
                    dst_clear_active <= 1'b0;
                    dst_clear_pending <= 1'b0;
                    dst_clear_done <= 1'b1;
                    // Reset pointers
                    dst_rd_ptr <= {PTR_WIDTH{1'b0}};
                    dst_rd_ptr_gray <= {GRAY_WIDTH{1'b0}};
                    dst_valid_reg <= 1'b0;
                end
            end else begin
                if (dst_read) begin
                    dst_rd_ptr <= dst_rd_ptr + 1'b1;
                    dst_rd_ptr_gray <= dst_rd_ptr_gray_next;
                    dst_valid_reg <= 1'b0;
                end else if (dst_can_read && !dst_valid_reg) begin
                    // Load data from memory
                    dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                    dst_valid_reg <= 1'b1;
                end
            end
        end
    end

    // Destination domain: synchronizer for source write pointer gray
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray_sync_stages <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_wr_ptr_gray_sync_stages[0] <= src_wr_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_wr_ptr_gray_sync_stages[i] <= dst_wr_ptr_gray_sync_stages[i-1];
        end
    end
    assign dst_wr_ptr_gray_sync = dst_wr_ptr_gray_sync_stages[SYNC_STAGES-1];

    // Destination domain: synchronizer for source clear done
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_clear_done_to_dst_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            src_clear_done_to_dst_sync[0] <= src_clear_done;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_clear_done_to_dst_sync[i] <= src_clear_done_to_dst_sync[i-1];
        end
    end

    // Destination domain: synchronizer for source clear request
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_clear_to_dst_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            src_clear_to_dst_sync[0] <= src_clear_i;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_clear_to_dst_sync[i] <= src_clear_to_dst_sync[i-1];
        end
    end

endmodule
