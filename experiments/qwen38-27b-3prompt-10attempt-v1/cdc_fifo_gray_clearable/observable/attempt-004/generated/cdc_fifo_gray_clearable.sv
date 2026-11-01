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
    reg [GRAY_WIDTH-1:0] src_wr_ptr_gray;
    reg [GRAY_WIDTH-1:0] src_rd_ptr_gray_sync [0:SYNC_STAGES-1];
    reg [GRAY_WIDTH-1:0] src_clear_sync [0:SYNC_STAGES-1];
    reg src_clear_pending;

    // Destination domain
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [GRAY_WIDTH-1:0] dst_rd_ptr_gray;
    reg [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync [0:SYNC_STAGES-1];
    reg [GRAY_WIDTH-1:0] dst_clear_sync [0:SYNC_STAGES-1];
    reg dst_clear_pending;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // Helper: binary to gray
    function [GRAY_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Helper: gray to binary
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
    wire [GRAY_WIDTH-1:0] src_rd_ptr_gray_synced = src_rd_ptr_gray_sync[SYNC_STAGES-1];
    wire [PTR_WIDTH-1:0] src_rd_ptr_bin = gray2bin(src_rd_ptr_gray_synced);
    wire [PTR_WIDTH-1:0] src_wr_ptr_gray_next = bin2gray(src_wr_ptr + 1);
    wire src_full = (src_wr_ptr_gray == src_rd_ptr_gray_synced) &&
                    (src_wr_ptr[LOG_DEPTH-1:0] != src_rd_ptr_bin[LOG_DEPTH-1:0]);
    wire src_can_write = src_valid_i && !src_full && !src_clear_pending;
    wire src_ready = !src_full && !src_clear_pending;

    // Destination domain logic
    wire [GRAY_WIDTH-1:0] dst_wr_ptr_gray_synced = dst_wr_ptr_gray_sync[SYNC_STAGES-1];
    wire [PTR_WIDTH-1:0] dst_wr_ptr_bin = gray2bin(dst_wr_ptr_gray_synced);
    wire [PTR_WIDTH-1:0] dst_rd_ptr_gray_next = bin2gray(dst_rd_ptr + 1);
    wire dst_empty = (dst_rd_ptr_gray == dst_wr_ptr_gray_synced) &&
                     (dst_rd_ptr[LOG_DEPTH-1:0] == dst_wr_ptr_bin[LOG_DEPTH-1:0]);
    wire dst_can_read = dst_valid_reg && dst_ready_i && !dst_clear_pending;
    wire dst_valid = dst_valid_reg;

    // Source clock domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
            src_clear_pending <= 1'b0;
            src_clear_sync[0] <= 1'b0;
            src_clear_sync[1] <= 1'b0;
            src_clear_sync[2] <= 1'b0;
            src_rd_ptr_gray_sync[0] <= {GRAY_WIDTH{1'b0}};
            src_rd_ptr_gray_sync[1] <= {GRAY_WIDTH{1'b0}};
            src_rd_ptr_gray_sync[2] <= {GRAY_WIDTH{1'b0}};
        end else begin
            // Synchronize dst clear into src domain
            src_clear_sync[0] <= dst_clear_sync[SYNC_STAGES-1];
            src_clear_sync[1] <= src_clear_sync[0];
            src_clear_sync[2] <= src_clear_sync[1];

            // Synchronize dst rd ptr gray into src domain
            src_rd_ptr_gray_sync[0] <= dst_rd_ptr_gray;
            src_rd_ptr_gray_sync[1] <= src_rd_ptr_gray_sync[0];
            src_rd_ptr_gray_sync[2] <= src_rd_ptr_gray_sync[1];

            // Handle clear
            if (src_clear_i || src_clear_sync[2]) begin
                src_clear_pending <= 1'b1;
                src_wr_ptr <= {PTR_WIDTH{1'b0}};
                src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
            end else if (src_clear_pending) begin
                // Wait until dst side has also cleared
                if (src_clear_sync[2] == 1'b0) begin
                    // Check if dst has cleared by seeing if dst_wr_ptr_gray is 0
                    // Actually, we need to know when dst clear is done.
                    // The dst_clear_pending will be cleared when dst sees src_clear_synced.
                    // We can clear src_clear_pending when we see that dst has processed the clear.
                    // A simpler approach: clear pending when the clear signal has propagated back.
                    // But we don't have a direct "dst cleared" signal.
                    // Let's use a different approach: both sides clear their pointers when they see the clear.
                    // src_clear_pending is set when src_clear_i or dst_clear_synced.
                    // It should be cleared when the other side has also cleared.
                    // We can detect this by checking if the other side's pointer is 0 and the clear is no longer active.
                    // Actually, let's just clear src_clear_pending when src_clear_i is deasserted and dst_clear_synced is deasserted.
                    if (!src_clear_i && !src_clear_sync[2]) begin
                        src_clear_pending <= 1'b0;
                    end
                end
            end

            // Write to memory
            if (src_can_write) begin
                mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1'b1;
                src_wr_ptr_gray <= src_wr_ptr_gray_next;
            end
        end
    end

    assign src_clear_pending_o = src_clear_pending;

    // Destination clock domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray <= {GRAY_WIDTH{1'b0}};
            dst_clear_pending <= 1'b0;
            dst_clear_sync[0] <= 1'b0;
            dst_clear_sync[1] <= 1'b0;
            dst_clear_sync[2] <= 1'b0;
            dst_wr_ptr_gray_sync[0] <= {GRAY_WIDTH{1'b0}};
            dst_wr_ptr_gray_sync[1] <= {GRAY_WIDTH{1'b0}};
            dst_wr_ptr_gray_sync[2] <= {GRAY_WIDTH{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            // Synchronize src clear into dst domain
            dst_clear_sync[0] <= src_clear_sync[SYNC_STAGES-1];
            dst_clear_sync[1] <= dst_clear_sync[0];
            dst_clear_sync[2] <= dst_clear_sync[1];

            // Synchronize src wr ptr gray into dst domain
            dst_wr_ptr_gray_sync[0] <= src_wr_ptr_gray;
            dst_wr_ptr_gray_sync[1] <= dst_wr_ptr_gray_sync[0];
            dst_wr_ptr_gray_sync[2] <= dst_wr_ptr_gray_sync[1];

            // Handle clear
            if (dst_clear_i || dst_clear_sync[2]) begin
                dst_clear_pending <= 1'b1;
                dst_rd_ptr <= {PTR_WIDTH{1'b0}};
                dst_rd_ptr_gray <= {GRAY_WIDTH{1'b0}};
                dst_valid_reg <= 1'b0;
            end else if (dst_clear_pending) begin
                if (!dst_clear_i && !dst_clear_sync[2]) begin
                    dst_clear_pending <= 1'b0;
                end
            end

            // Read from memory
            if (dst_can_read) begin
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
                dst_rd_ptr_gray <= dst_rd_ptr_gray_next;
                dst_valid_reg <= 1'b0;
            end else if (!dst_valid_reg && !dst_empty && !dst_clear_pending) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_valid_reg <= 1'b1;
            end
        end
    end

    assign dst_clear_pending_o = dst_clear_pending;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid;
    assign src_ready_o = src_ready;

endmodule
