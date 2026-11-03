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
    localparam GRAY_W = PTR_W;

    // Gray code conversion
    function [GRAY_W-1:0] bin2gray;
        input [PTR_W-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [PTR_W-1:0] gray2bin;
        input [GRAY_W-1:0] gray;
        integer i;
        begin
            gray2bin[GRAY_W-1] = gray[GRAY_W-1];
            for (i = GRAY_W-2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Source domain
    reg [PTR_W-1:0] src_wr_ptr;
    reg [GRAY_W-1:0] src_wr_gray;
    reg [GRAY_W-1:0] src_rd_gray_sync;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg src_clear_pending;

    // Destination domain
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [GRAY_W-1:0] dst_rd_gray;
    reg [GRAY_W-1:0] dst_wr_gray_sync;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg dst_clear_pending;

    // Synchronizer for src_wr_gray -> dst domain
    reg [SYNC_STAGES-1:0] src_wr_gray_sync;

    // Synchronizer for dst_rd_gray -> src domain
    reg [SYNC_STAGES-1:0] dst_rd_gray_sync;

    // Clear synchronization: src_clear -> dst domain
    reg [SYNC_STAGES-1:0] src_clear_sync;

    // Clear synchronization: dst_clear -> src domain
    reg [SYNC_STAGES-1:0] dst_clear_sync;

    // Source domain logic
    wire [GRAY_W-1:0] src_wr_gray_next = bin2gray(src_wr_ptr + 1'b1);
    wire [PTR_W-1:0] src_rd_ptr_sync = gray2bin(src_rd_gray_sync);
    wire src_full = (src_wr_ptr == src_rd_ptr_sync) && (src_wr_gray != src_rd_gray_sync);
    wire src_can_write = src_valid_i && !src_full && !src_clear_pending;

    // Destination domain logic
    wire [GRAY_W-1:0] dst_rd_gray_next = bin2gray(dst_rd_ptr + 1'b1);
    wire [PTR_W-1:0] dst_wr_ptr_sync = gray2bin(dst_wr_gray_sync);
    wire dst_empty = (dst_rd_ptr == dst_wr_ptr_sync) && (dst_rd_gray == dst_wr_gray_sync);
    wire dst_can_read = dst_valid_reg && dst_ready_i && !dst_clear_pending;

    // Source clock domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
            src_wr_gray <= {GRAY_W{1'b0}};
            src_rd_gray_sync <= {GRAY_W{1'b0}};
            src_clear_pending <= 1'b0;
        end else begin
            // Handle clear
            if (src_clear_i || dst_clear_sync[SYNC_STAGES-1]) begin
                src_clear_pending <= 1'b1;
            end else if (src_clear_pending) begin
                // Wait for dst to acknowledge clear
                if (!dst_clear_sync[SYNC_STAGES-1]) begin
                    src_clear_pending <= 1'b0;
                    src_wr_ptr <= {PTR_W{1'b0}};
                    src_wr_gray <= {GRAY_W{1'b0}};
                end
            end

            // Write data
            if (src_can_write) begin
                mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1'b1;
                src_wr_gray <= src_wr_gray_next;
            end

            // Synchronize dst_rd_gray
            src_rd_gray_sync <= dst_rd_gray_sync[SYNC_STAGES-1];
        end
    end

    // Synchronizer for dst_rd_gray -> src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_gray_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_rd_gray_sync[0] <= dst_rd_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_rd_gray_sync[i] <= dst_rd_gray_sync[i-1];
        end
    end

    // Synchronizer for dst_clear -> src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_clear_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_clear_sync[0] <= dst_clear_i;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_clear_sync[i] <= dst_clear_sync[i-1];
        end
    end

    // Destination clock domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_rd_gray <= {GRAY_W{1'b0}};
            dst_wr_gray_sync <= {GRAY_W{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
            dst_clear_pending <= 1'b0;
        end else begin
            // Handle clear
            if (dst_clear_i || src_clear_sync[SYNC_STAGES-1]) begin
                dst_clear_pending <= 1'b1;
            end else if (dst_clear_pending) begin
                // Wait for src to acknowledge clear
                if (!src_clear_sync[SYNC_STAGES-1]) begin
                    dst_clear_pending <= 1'b0;
                    dst_rd_ptr <= {PTR_W{1'b0}};
                    dst_rd_gray <= {GRAY_W{1'b0}};
                    dst_valid_reg <= 1'b0;
                end
            end

            // Read data
            if (dst_can_read) begin
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
                dst_rd_gray <= dst_rd_gray_next;
                dst_valid_reg <= 1'b0;
            end

            // Load new data if FIFO not empty and output not valid
            if (!dst_valid_reg && !dst_empty && !dst_clear_pending) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_valid_reg <= 1'b1;
            end

            // Synchronize src_wr_gray
            dst_wr_gray_sync <= src_wr_gray_sync[SYNC_STAGES-1];
        end
    end

    // Synchronizer for src_wr_gray -> dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_gray_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            src_wr_gray_sync[0] <= src_wr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_wr_gray_sync[i] <= src_wr_gray_sync[i-1];
        end
    end

    // Synchronizer for src_clear -> dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_clear_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            src_clear_sync[0] <= src_clear_i;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_clear_sync[i] <= src_clear_sync[i-1];
        end
    end

    // Outputs
    assign src_ready_o = !src_full && !src_clear_pending;
    assign src_clear_pending_o = src_clear_pending;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg && !dst_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
