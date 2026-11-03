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

    // Source domain signals
    reg [PTR_W-1:0] src_wr_ptr;
    reg [GRAY_W-1:0] src_wr_gray;
    reg [GRAY_W-1:0] src_rd_gray_sync;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg src_clear_pending;

    // Destination domain signals
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [GRAY_W-1:0] dst_rd_gray;
    reg [GRAY_W-1:0] dst_wr_gray_sync;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg dst_clear_pending;

    // Gray code conversion functions
    function [GRAY_W-1:0] bin2gray;
        input [PTR_W-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [PTR_W-1:0] gray2bin;
        input [GRAY_W-1:0] gray;
        reg [PTR_W-1:0] bin;
        integer i;
        begin
            bin[PTR_W-1] = gray[PTR_W-1];
            for (i = PTR_W-2; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            gray2bin = bin;
        end
    endfunction

    // Source domain: write pointer and Gray code
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
            src_wr_gray <= {GRAY_W{1'b0}};
            src_clear_pending <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending <= 1'b1;
            end else if (src_clear_pending) begin
                // Wait for destination to acknowledge clear
                // We'll handle this via synchronization
            end else begin
                if (src_valid_i && src_ready_o) begin
                    mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                    src_wr_ptr <= src_wr_ptr + 1'b1;
                    src_wr_gray <= bin2gray(src_wr_ptr + 1'b1);
                end
            end
        end
    end

    // Source domain: read pointer Gray code synchronized from destination
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_gray_sync <= {GRAY_W{1'b0}};
        end else begin
            src_rd_gray_sync <= dst_rd_gray;
        end
    end

    // Source domain: clear pending synchronization to destination
    // We need to synchronize src_clear_pending to dst domain
    reg [SYNC_STAGES-1:0] src_clear_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_clear_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_pending};
        end
    end

    // Destination domain: read pointer and Gray code
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_rd_gray <= {GRAY_W{1'b0}};
            dst_valid_reg <= 1'b0;
            dst_data_reg <= {WIDTH{1'b0}};
            dst_clear_pending <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending <= 1'b1;
            end else if (dst_clear_pending) begin
                // Wait for source to acknowledge clear
            end else begin
                if (dst_valid_reg && dst_ready_i) begin
                    dst_rd_ptr <= dst_rd_ptr + 1'b1;
                    dst_rd_gray <= bin2gray(dst_rd_ptr + 1'b1);
                    dst_valid_reg <= 1'b0;
                end
            end
        end
    end

    // Destination domain: write pointer Gray code synchronized from source
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_gray_sync <= {GRAY_W{1'b0}};
        end else begin
            dst_wr_gray_sync <= src_wr_gray;
        end
    end

    // Destination domain: clear pending synchronization to source
    reg [SYNC_STAGES-1:0] dst_clear_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_clear_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_pending};
        end
    end

    // Source domain: clear pending output
    assign src_clear_pending_o = src_clear_pending;

    // Destination domain: clear pending output
    assign dst_clear_pending_o = dst_clear_pending;

    // Source domain: ready signal
    wire [PTR_W-1:0] src_wr_ptr_bin = src_wr_ptr;
    wire [PTR_W-1:0] src_rd_ptr_bin = gray2bin(src_rd_gray_sync);
    wire src_full = (src_wr_ptr_bin == src_rd_ptr_bin) && 
                    (src_wr_ptr_bin[LOG_DEPTH] != src_rd_ptr_bin[LOG_DEPTH]);
    // Actually, for a FIFO of depth DEPTH, full when write pointer has lapped read pointer by DEPTH
    // Let's use the standard approach:
    wire src_full_correct = (src_wr_gray == src_rd_gray_sync) ? 1'b0 : 
                            (src_wr_ptr_bin[LOG_DEPTH] != src_rd_ptr_bin[LOG_DEPTH]) && 
                            (src_wr_ptr_bin[LOG_DEPTH-1:0] == src_rd_ptr_bin[LOG_DEPTH-1:0]);
    // Simpler: full when the MSB differs and the lower bits are equal
    wire src_full_simple = (src_wr_ptr_bin[LOG_DEPTH] != src_rd_ptr_bin[LOG_DEPTH]) && 
                           (src_wr_ptr_bin[LOG_DEPTH-1:0] == src_rd_ptr_bin[LOG_DEPTH-1:0]);
    assign src_ready_o = !src_full_simple && !src_clear_pending && !dst_clear_sync[SYNC_STAGES-1];

    // Destination domain: valid signal
    wire [PTR_W-1:0] dst_rd_ptr_bin = dst_rd_ptr;
    wire [PTR_W-1:0] dst_wr_ptr_bin = gray2bin(dst_wr_gray_sync);
    wire dst_empty_simple = (dst_rd_ptr_bin[LOG_DEPTH] != dst_wr_ptr_bin[LOG_DEPTH]) && 
                            (dst_rd_ptr_bin[LOG_DEPTH-1:0] == dst_wr_ptr_bin[LOG_DEPTH-1:0]);
    // Empty when pointers are equal
    wire dst_empty = (dst_rd_gray == dst_wr_gray_sync);
    assign dst_valid_o = dst_valid_reg && !dst_clear_pending && !src_clear_sync[SYNC_STAGES-1];

    // Destination domain: read data from memory when valid and ready
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= {WIDTH{1'b0}};
        end else begin
            if (dst_valid_reg && dst_ready_i) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
            end
        end
    end

    // Actually, we need to read the data when we're about to consume it
    // Let me restructure: read data combinationally or register it properly

    // Let's use a different approach: read data when valid is asserted
    // The data should be stable while valid is high

    // Reconsidering the design:
    // When dst_valid_reg is high, dst_data_o should be the data at dst_rd_ptr
    // We can read it combinationally or register it

    // Let's register the data when we detect a new item
    reg [WIDTH-1:0] dst_data_next;
    wire dst_has_data = !dst_empty && !dst_valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_clear_pending || src_clear_sync[SYNC_STAGES-1]) begin
                dst_valid_reg <= 1'b0;
            end else if (dst_valid_reg && dst_ready_i) begin
                dst_valid_reg <= 1'b0;
            end else if (!dst_valid_reg && !dst_empty) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_valid_reg <= 1'b1;
            end
        end
    end

    assign dst_data_o = dst_data_reg;

endmodule
