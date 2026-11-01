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
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] src_rd_ptr;
    reg [GRAY_W-1:0] src_wr_gray;
    reg [GRAY_W-1:0] src_rd_gray;
    reg src_clear_pending;
    reg src_clear_sync;

    // Destination domain
    reg [PTR_W-1:0] dst_wr_ptr;
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [GRAY_W-1:0] dst_wr_gray;
    reg [GRAY_W-1:0] dst_rd_gray;
    reg dst_clear_pending;
    reg dst_clear_sync;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // Synchronizers for write pointer (src -> dst)
    reg [GRAY_W-1:0] src_wr_gray_sync [0:SYNC_STAGES-1];

    // Synchronizers for read pointer (dst -> src)
    reg [GRAY_W-1:0] dst_rd_gray_sync [0:SYNC_STAGES-1];

    // Synchronizers for clear pending (src -> dst)
    reg src_clear_pending_sync [0:SYNC_STAGES-1];

    // Synchronizers for clear pending (dst -> src)
    reg dst_clear_pending_sync [0:SYNC_STAGES-1];

    // Synchronizers for clear request (dst -> src)
    reg dst_clear_sync_req [0:SYNC_STAGES-1];

    // Synchronizers for clear request (src -> dst)
    reg src_clear_sync_req [0:SYNC_STAGES-1];

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
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
            src_rd_ptr <= {PTR_W{1'b0}};
            src_wr_gray <= {GRAY_W{1'b0}};
            src_rd_gray <= {GRAY_W{1'b0}};
            src_clear_pending <= 1'b0;
            src_clear_sync <= 1'b0;
        end else begin
            // Handle clear
            if (src_clear_i || dst_clear_sync_req[SYNC_STAGES-1]) begin
                src_clear_pending <= 1'b1;
                src_clear_sync <= 1'b1;
            end else if (src_clear_pending) begin
                // Wait for destination to also be clear
                if (dst_clear_pending_sync[SYNC_STAGES-1]) begin
                    src_clear_pending <= 1'b0;
                    src_clear_sync <= 1'b0;
                    src_wr_ptr <= {PTR_W{1'b0}};
                    src_rd_ptr <= {PTR_W{1'b0}};
                    src_wr_gray <= {GRAY_W{1'b0}};
                    src_rd_gray <= {GRAY_W{1'b0}};
                end
            end

            // Normal operation
            if (!src_clear_pending && !dst_clear_pending_sync[SYNC_STAGES-1]) begin
                if (src_valid_i && src_ready_o) begin
                    mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                    src_wr_ptr <= src_wr_ptr + 1'b1;
                    src_wr_gray <= bin2gray(src_wr_ptr + 1'b1);
                end
            end

            // Update read pointer from destination
            if (!src_clear_pending && !dst_clear_pending_sync[SYNC_STAGES-1]) begin
                src_rd_ptr <= gray2bin(dst_rd_gray_sync[SYNC_STAGES-1]);
                src_rd_gray <= dst_rd_gray_sync[SYNC_STAGES-1];
            end
        end
    end

    // Source ready
    assign src_ready_o = !src_clear_pending && 
                         !dst_clear_pending_sync[SYNC_STAGES-1] &&
                         (src_wr_ptr != src_rd_ptr);

    // Source clear pending output
    assign src_clear_pending_o = src_clear_pending;

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr <= {PTR_W{1'b0}};
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_wr_gray <= {GRAY_W{1'b0}};
            dst_rd_gray <= {GRAY_W{1'b0}};
            dst_clear_pending <= 1'b0;
            dst_clear_sync <= 1'b0;
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            // Handle clear
            if (dst_clear_i || src_clear_sync_req[SYNC_STAGES-1]) begin
                dst_clear_pending <= 1'b1;
                dst_clear_sync <= 1'b1;
            end else if (dst_clear_pending) begin
                // Wait for source to also be clear
                if (src_clear_pending_sync[SYNC_STAGES-1]) begin
                    dst_clear_pending <= 1'b0;
                    dst_clear_sync <= 1'b0;
                    dst_wr_ptr <= {PTR_W{1'b0}};
                    dst_rd_ptr <= {PTR_W{1'b0}};
                    dst_wr_gray <= {GRAY_W{1'b0}};
                    dst_rd_gray <= {GRAY_W{1'b0}};
                    dst_valid_reg <= 1'b0;
                end
            end

            // Normal operation
            if (!dst_clear_pending && !src_clear_pending_sync[SYNC_STAGES-1]) begin
                // Read from FIFO
                if (dst_valid_reg && dst_ready_i) begin
                    dst_rd_ptr <= dst_rd_ptr + 1'b1;
                    dst_rd_gray <= bin2gray(dst_rd_ptr + 1'b1);
                    dst_valid_reg <= 1'b0;
                end

                // Write to FIFO (from source)
                if (src_wr_gray_sync[SYNC_STAGES-1] != dst_wr_gray) begin
                    dst_data_reg <= mem[src_wr_gray_sync[SYNC_STAGES-1][LOG_DEPTH-1:0]];
                    dst_valid_reg <= 1'b1;
                    dst_wr_ptr <= dst_wr_ptr + 1'b1;
                    dst_wr_gray <= bin2gray(dst_wr_ptr + 1'b1);
                end
            end
        end
    end

    // Destination valid output
    assign dst_valid_o = dst_valid_reg;

    // Destination data output
    assign dst_data_o = dst_data_reg;

    // Destination clear pending output
    assign dst_clear_pending_o = dst_clear_pending;

    // Synchronizer for src_wr_gray (src -> dst)
    integer i;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                src_wr_gray_sync[i] <= {GRAY_W{1'b0}};
        end else begin
            src_wr_gray_sync[0] <= src_wr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                src_wr_gray_sync[i] <= src_wr_gray_sync[i-1];
        end
    end

    // Synchronizer for dst_rd_gray (dst -> src)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                dst_rd_gray_sync[i] <= {GRAY_W{1'b0}};
        end else begin
            dst_rd_gray_sync[0] <= dst_rd_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                dst_rd_gray_sync[i] <= dst_rd_gray_sync[i-1];
        end
    end

    // Synchronizer for src_clear_pending (src -> dst)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                src_clear_pending_sync[i] <= 1'b0;
        end else begin
            src_clear_pending_sync[0] <= src_clear_pending;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                src_clear_pending_sync[i] <= src_clear_pending_sync[i-1];
        end
    end

    // Synchronizer for dst_clear_pending (dst -> src)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                dst_clear_pending_sync[i] <= 1'b0;
        end else begin
            dst_clear_pending_sync[0] <= dst_clear_pending;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                dst_clear_pending_sync[i] <= dst_clear_pending_sync[i-1];
        end
    end

    // Synchronizer for dst_clear request (dst -> src)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                dst_clear_sync_req[i] <= 1'b0;
        end else begin
            dst_clear_sync_req[0] <= dst_clear_i;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                dst_clear_sync_req[i] <= dst_clear_sync_req[i-1];
        end
    end

    // Synchronizer for src_clear request (src -> dst)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                src_clear_sync_req[i] <= 1'b0;
        end else begin
            src_clear_sync_req[0] <= src_clear_i;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                src_clear_sync_req[i] <= src_clear_sync_req[i-1];
        end
    end

endmodule
