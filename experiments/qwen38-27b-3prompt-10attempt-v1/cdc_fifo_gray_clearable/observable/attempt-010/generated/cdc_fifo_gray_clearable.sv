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
    reg src_clear_pending;

    // Destination domain
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [GRAY_WIDTH-1:0] dst_rd_gray;
    reg [GRAY_WIDTH-1:0] dst_wr_gray_sync [0:SYNC_STAGES-1];
    reg dst_clear_pending;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // Binary to Gray conversion
    function [GRAY_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Gray to binary conversion
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
    wire [GRAY_WIDTH-1:0] src_wr_gray_next = bin2gray(src_wr_ptr + 1'b1);
    wire [GRAY_WIDTH-1:0] src_rd_gray_synced = src_rd_gray_sync[SYNC_STAGES-1];
    wire [PTR_WIDTH-1:0] src_rd_ptr_synced = gray2bin(src_rd_gray_synced);
    wire src_full = (src_wr_gray == src_rd_gray_synced) && (src_wr_ptr[PTR_WIDTH-1] != src_rd_ptr_synced[PTR_WIDTH-1]);
    wire src_can_write = src_valid_i && !src_full && !src_clear_pending;

    // Destination domain logic
    wire [GRAY_WIDTH-1:0] dst_rd_gray_next = bin2gray(dst_rd_ptr + 1'b1);
    wire [GRAY_WIDTH-1:0] dst_wr_gray_synced = dst_wr_gray_sync[SYNC_STAGES-1];
    wire [PTR_WIDTH-1:0] dst_wr_ptr_synced = gray2bin(dst_wr_gray_synced);
    wire dst_empty = (dst_rd_gray == dst_wr_gray_synced);
    wire dst_can_read = dst_valid_reg && dst_ready_i && !dst_clear_pending;

    // Source clock domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_wr_gray <= {GRAY_WIDTH{1'b0}};
            src_clear_pending <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending <= 1'b1;
            end else if (src_clear_pending) begin
                // Wait for destination to acknowledge clear
                if (!dst_clear_pending_o) begin
                    src_clear_pending <= 1'b0;
                    src_wr_ptr <= {PTR_WIDTH{1'b0}};
                    src_wr_gray <= {GRAY_WIDTH{1'b0}};
                end
            end else if (src_can_write) begin
                mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1'b1;
                src_wr_gray <= src_wr_gray_next;
            end
        end
    end

    // Source clear pending output
    assign src_clear_pending_o = src_clear_pending;

    // Synchronize source write pointer Gray to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_gray_sync[0] <= {GRAY_WIDTH{1'b0}};
            dst_wr_gray_sync[1] <= {GRAY_WIDTH{1'b0}};
            dst_wr_gray_sync[2] <= {GRAY_WIDTH{1'b0}};
        end else begin
            dst_wr_gray_sync[0] <= src_wr_gray;
            dst_wr_gray_sync[1] <= dst_wr_gray_sync[0];
            dst_wr_gray_sync[2] <= dst_wr_gray_sync[1];
        end
    end

    // Synchronize destination read pointer Gray to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_gray_sync[0] <= {GRAY_WIDTH{1'b0}};
            src_rd_gray_sync[1] <= {GRAY_WIDTH{1'b0}};
            src_rd_gray_sync[2] <= {GRAY_WIDTH{1'b0}};
        end else begin
            src_rd_gray_sync[0] <= dst_rd_gray;
            src_rd_gray_sync[1] <= src_rd_gray_sync[0];
            src_rd_gray_sync[2] <= src_rd_gray_sync[1];
        end
    end

    // Destination clock domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_gray <= {GRAY_WIDTH{1'b0}};
            dst_clear_pending <= 1'b0;
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending <= 1'b1;
                dst_valid_reg <= 1'b0;
            end else if (dst_clear_pending) begin
                // Wait for source to acknowledge clear
                if (!src_clear_pending_o) begin
                    dst_clear_pending <= 1'b0;
                    dst_rd_ptr <= {PTR_WIDTH{1'b0}};
                    dst_rd_gray <= {GRAY_WIDTH{1'b0}};
                    dst_valid_reg <= 1'b0;
                end
            end else begin
                if (dst_can_read) begin
                    dst_rd_ptr <= dst_rd_ptr + 1'b1;
                    dst_rd_gray <= dst_rd_gray_next;
                    dst_valid_reg <= 1'b0;
                end else if (!dst_empty && !dst_valid_reg) begin
                    dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                    dst_valid_reg <= 1'b1;
                end
            end
        end
    end

    // Destination clear pending output
    assign dst_clear_pending_o = dst_clear_pending;

    // Outputs
    assign src_ready_o = !src_full && !src_clear_pending;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
