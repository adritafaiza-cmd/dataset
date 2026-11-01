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

    // Source domain signals
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray;
    reg [PTR_WIDTH-1:0] src_rd_ptr_gray_synced;
    reg [PTR_WIDTH-1:0] src_rd_ptr_gray_synced_reg;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg src_clear_pending;
    reg [SYNC_STAGES-1:0] src_clear_sync;

    // Destination domain signals
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray;
    reg [PTR_WIDTH-1:0] dst_wr_ptr_gray_synced;
    reg [PTR_WIDTH-1:0] dst_wr_ptr_gray_synced_reg;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg dst_clear_pending;
    reg [SYNC_STAGES-1:0] dst_clear_sync;

    // Helper function: binary to gray
    function [PTR_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Helper function: gray to binary
    function [PTR_WIDTH-1:0] gray2bin;
        input [PTR_WIDTH-1:0] gray;
        integer i;
        begin
            gray2bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Source domain: write pointer and gray conversion
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else if (src_clear_i) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else if (src_valid_i && src_ready_o) begin
            src_wr_ptr <= src_wr_ptr + 1'b1;
            src_wr_ptr_gray <= bin2gray(src_wr_ptr + 1'b1);
        end
    end

    // Source domain: read pointer gray synchronized from destination
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray_synced <= {PTR_WIDTH{1'b0}};
            src_rd_ptr_gray_synced_reg <= {PTR_WIDTH{1'b0}};
        end else begin
            src_rd_ptr_gray_synced <= src_rd_ptr_gray_synced_reg;
            src_rd_ptr_gray_synced_reg <= dst_rd_ptr_gray;
        end
    end

    // Source domain: clear synchronization
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 1'b0;
            src_clear_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
            if (src_clear_i)
                src_clear_pending <= 1'b1;
            else if (src_clear_sync[SYNC_STAGES-1])
                src_clear_pending <= 1'b0;
        end
    end

    // Source domain: ready signal
    wire src_full = (src_wr_ptr_gray == src_rd_ptr_gray_synced) && 
                    (src_wr_ptr[PTR_WIDTH-1] != src_rd_ptr_gray_synced[PTR_WIDTH-1]);
    // Actually, for Gray code FIFO, full condition is:
    // wr_gray == rd_gray_synced AND wr_ptr[MSB] != rd_gray_synced[MSB-1]
    // Let me use the standard approach:
    // Full when: (wr_gray == rd_gray_synced) && (wr_ptr[MSB] != rd_gray_synced[MSB-1])
    // But we need to be careful. Let me use the common method:
    // Convert synced gray to binary and compare with write pointer
    wire [PTR_WIDTH-1:0] src_rd_ptr_bin_synced = gray2bin(src_rd_ptr_gray_synced);
    wire src_full = (src_wr_ptr == src_rd_ptr_bin_synced + DEPTH);
    // Actually simpler: full when (wr_ptr - rd_ptr) == DEPTH
    // Since pointers wrap, we can check:
    wire src_full = (src_wr_ptr[PTR_WIDTH-1] != src_rd_ptr_bin_synced[PTR_WIDTH-1]) &&
                    (src_wr_ptr[PTR_WIDTH-2:0] == src_rd_ptr_bin_synced[PTR_WIDTH-2:0]);

    assign src_ready_o = !src_full && !src_clear_pending;

    // Source domain: write to memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            // No reset for memory, but we can leave it
        end else if (src_valid_i && src_ready_o) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // Destination domain: read pointer and gray conversion
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else if (dst_clear_i) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else if (dst_valid_reg && dst_ready_i) begin
            dst_rd_ptr <= dst_rd_ptr + 1'b1;
            dst_rd_ptr_gray <= bin2gray(dst_rd_ptr + 1'b1);
        end
    end

    // Destination domain: write pointer gray synchronized from source
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray_synced <= {PTR_WIDTH{1'b0}};
            dst_wr_ptr_gray_synced_reg <= {PTR_WIDTH{1'b0}};
        end else begin
            dst_wr_ptr_gray_synced <= dst_wr_ptr_gray_synced_reg;
            dst_wr_ptr_gray_synced_reg <= src_wr_ptr_gray;
        end
    end

    // Destination domain: clear synchronization
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 1'b0;
            dst_clear_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
            if (dst_clear_i)
                dst_clear_pending <= 1'b1;
            else if (dst_clear_sync[SYNC_STAGES-1])
                dst_clear_pending <= 1'b0;
        end
    end

    // Destination domain: empty check
    wire [PTR_WIDTH-1:0] dst_wr_ptr_bin_synced = gray2bin(dst_wr_ptr_gray_synced);
    wire dst_empty = (dst_rd_ptr == dst_wr_ptr_bin_synced);

    // Destination domain: read from memory and register output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else if (dst_clear_i) begin
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else if (!dst_empty && !dst_valid_reg) begin
            dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
            dst_valid_reg <= 1'b1;
        end else if (dst_valid_reg && dst_ready_i) begin
            dst_valid_reg <= 1'b0;
        end
    end

    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg && !dst_clear_pending;
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
