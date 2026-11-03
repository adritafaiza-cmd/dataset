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

    // Source domain signals
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [GRAY_WIDTH-1:0] src_wr_ptr_gray;
    reg [GRAY_WIDTH-1:0] src_rd_ptr_gray_sync;
    reg [GRAY_WIDTH-1:0] src_rd_ptr_gray_sync_next;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg src_clear_pending;
    reg src_clear_active;

    // Destination domain signals
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [GRAY_WIDTH-1:0] dst_rd_ptr_gray;
    reg [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync;
    reg [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync_next;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg dst_clear_pending;
    reg dst_clear_active;

    // Synchronizer stages for source read pointer gray (to source domain)
    reg [GRAY_WIDTH-1:0] src_rd_ptr_gray_sync_stage [0:SYNC_STAGES-1];

    // Synchronizer stages for destination write pointer gray (to destination domain)
    reg [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync_stage [0:SYNC_STAGES-1];

    // Convert binary to gray
    function [GRAY_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Convert gray to binary
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
    wire src_full = (src_wr_ptr_gray == src_rd_ptr_gray_sync);
    wire src_can_write = src_valid_i && src_ready_o && !src_clear_active;
    wire src_ready = !src_full && !src_clear_active;

    assign src_ready_o = src_ready;
    assign src_clear_pending_o = src_clear_pending;

    // Source clear logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 1'b0;
            src_clear_active <= 1'b0;
        end else begin
            if (src_clear_i && !src_clear_pending) begin
                src_clear_pending <= 1'b1;
                src_clear_active <= 1'b1;
            end else if (src_clear_pending) begin
                // Wait until destination side also clears and pointers are reset
                // We'll handle the completion when both sides are cleared
                if (dst_clear_pending_sync) begin
                    src_clear_pending <= 1'b0;
                    src_clear_active <= 1'b0;
                end
            end
        end
    end

    // Synchronize dst_clear_pending to source domain
    reg [SYNC_STAGES-1:0] dst_clear_pending_sync_stage;
    wire dst_clear_pending_sync = dst_clear_pending_sync_stage[SYNC_STAGES-1];

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_clear_pending_sync_stage <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_clear_pending_sync_stage[0] <= dst_clear_pending;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_clear_pending_sync_stage[i] <= dst_clear_pending_sync_stage[i-1];
        end
    end

    // Source write pointer and memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
        end else begin
            if (src_clear_active) begin
                src_wr_ptr <= {PTR_WIDTH{1'b0}};
                src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
            end else if (src_can_write) begin
                mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1'b1;
                src_wr_ptr_gray <= src_wr_ptr_gray_next;
            end
        end
    end

    // Synchronize source write pointer gray to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray_sync_stage[0] <= {GRAY_WIDTH{1'b0}};
        end else begin
            dst_wr_ptr_gray_sync_stage[0] <= src_wr_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_wr_ptr_gray_sync_stage[i] <= dst_wr_ptr_gray_sync_stage[i-1];
        end
    end

    assign dst_wr_ptr_gray_sync = dst_wr_ptr_gray_sync_stage[SYNC_STAGES-1];

    // Destination domain logic
    wire dst_rd_ptr_gray_next = bin2gray(dst_rd_ptr + 1'b1);
    wire dst_empty = (dst_rd_ptr_gray == dst_wr_ptr_gray_sync);
    wire dst_can_read = dst_valid_reg && dst_ready_i && !dst_clear_active;
    wire dst_ready_internal = !dst_empty && !dst_clear_active;

    assign dst_valid_o = dst_valid_reg;
    assign dst_data_o = dst_data_reg;
    assign dst_clear_pending_o = dst_clear_pending;

    // Destination clear logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 1'b0;
            dst_clear_active <= 1'b0;
        end else begin
            if (dst_clear_i && !dst_clear_pending) begin
                dst_clear_pending <= 1'b1;
                dst_clear_active <= 1'b1;
            end else if (dst_clear_pending) begin
                // Wait until source side also clears
                if (src_clear_pending_sync) begin
                    dst_clear_pending <= 1'b0;
                    dst_clear_active <= 1'b0;
                end
            end
        end
    end

    // Synchronize src_clear_pending to destination domain
    reg [SYNC_STAGES-1:0] src_clear_pending_sync_stage;
    wire src_clear_pending_sync = src_clear_pending_sync_stage[SYNC_STAGES-1];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_clear_pending_sync_stage <= {SYNC_STAGES{1'b0}};
        end else begin
            src_clear_pending_sync_stage[0] <= src_clear_pending;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_clear_pending_sync_stage[i] <= src_clear_pending_sync_stage[i-1];
        end
    end

    // Destination read pointer and output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray <= {GRAY_WIDTH{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_clear_active) begin
                dst_rd_ptr <= {PTR_WIDTH{1'b0}};
                dst_rd_ptr_gray <= {GRAY_WIDTH{1'b0}};
                dst_data_reg <= {WIDTH{1'b0}};
                dst_valid_reg <= 1'b0;
            end else begin
                // Check if we can present a new word
                if (!dst_valid_reg && !dst_empty) begin
                    dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                    dst_valid_reg <= 1'b1;
                end else if (dst_valid_reg && dst_ready_i) begin
                    dst_rd_ptr <= dst_rd_ptr + 1'b1;
                    dst_rd_ptr_gray <= dst_rd_ptr_gray_next;
                    dst_valid_reg <= 1'b0;
                end
            end
        end
    end

    // Synchronize destination read pointer gray to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray_sync_stage[0] <= {GRAY_WIDTH{1'b0}};
        end else begin
            src_rd_ptr_gray_sync_stage[0] <= dst_rd_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_rd_ptr_gray_sync_stage[i] <= src_rd_ptr_gray_sync_stage[i-1];
        end
    end

    assign src_rd_ptr_gray_sync = src_rd_ptr_gray_sync_stage[SYNC_STAGES-1];

endmodule
