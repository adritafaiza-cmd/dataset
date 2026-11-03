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

    // Source domain signals
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] src_wr_ptr_gray;
    reg [PTR_W-1:0] dst_rd_ptr_gray_synced;
    reg [PTR_W-1:0] dst_rd_ptr_gray_synced_d1;
    reg [PTR_W-1:0] dst_rd_ptr_gray_synced_d2;
    reg [PTR_W-1:0] dst_rd_ptr_gray_synced_d3;
    reg src_clear_pending;
    reg src_clear_pending_d1;
    reg src_clear_pending_d2;
    reg src_clear_pending_d3;

    // Destination domain signals
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] dst_rd_ptr_gray;
    reg [PTR_W-1:0] src_wr_ptr_gray_synced;
    reg [PTR_W-1:0] src_wr_ptr_gray_synced_d1;
    reg [PTR_W-1:0] src_wr_ptr_gray_synced_d2;
    reg [PTR_W-1:0] src_wr_ptr_gray_synced_d3;
    reg dst_clear_pending;
    reg dst_clear_pending_d1;
    reg dst_clear_pending_d2;
    reg dst_clear_pending_d3;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // Binary to Gray conversion
    function [PTR_W-1:0] bin2gray;
        input [PTR_W-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Gray to Binary conversion
    function [PTR_W-1:0] gray2bin;
        input [PTR_W-1:0] gray;
        reg [PTR_W-1:0] bin;
        integer i;
        begin
            bin[PTR_W-1] = gray[PTR_W-1];
            for (i = PTR_W-2; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            gray2bin = bin;
        end
    endfunction

    // Source domain: write pointer and memory
    wire src_wr_en = src_valid_i & src_ready_o & ~src_clear_pending;
    wire [PTR_W-1:0] src_wr_ptr_next = src_wr_ptr + 1'b1;
    wire [PTR_W-1:0] src_wr_ptr_gray_next = bin2gray(src_wr_ptr_next);

    // Source domain: read pointer synced from destination
    wire [PTR_W-1:0] src_wr_ptr_gray_synced = dst_rd_ptr_gray_synced_d3;
    wire [PTR_W-1:0] src_wr_ptr_gray_synced_bin = gray2bin(src_wr_ptr_gray_synced);

    // Source domain: full detection
    wire src_full = (src_wr_ptr[PTR_W-1] == src_wr_ptr_gray_synced_bin[PTR_W-1]) &&
                    (src_wr_ptr[LOG_DEPTH-1:0] == src_wr_ptr_gray_synced_bin[LOG_DEPTH-1:0]) &&
                    (src_wr_ptr[PTR_W-1] != src_wr_ptr_gray_synced_bin[PTR_W-1] ||
                     src_wr_ptr[LOG_DEPTH-1:0] != src_wr_ptr_gray_synced_bin[LOG_DEPTH-1:0]);
    
    // Correct full detection: full when write pointer has wrapped around and caught up to read pointer
    // In Gray code, full when MSB differs and rest are same
    wire src_full_correct = (src_wr_ptr_gray[PTR_W-1] != src_wr_ptr_gray_synced[PTR_W-1]) &&
                            (src_wr_ptr_gray[LOG_DEPTH-1:0] == src_wr_ptr_gray_synced[LOG_DEPTH-1:0]);

    // Source ready: not full and not in clear pending
    assign src_ready_o = ~src_full_correct & ~src_clear_pending;

    // Source clear pending logic
    // When src_clear_i is asserted, we need to wait until the clear propagates
    // and the FIFO is empty from the source perspective
    wire src_clear_active = src_clear_i | src_clear_pending;
    
    // Source domain: write pointer update
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
            src_wr_ptr_gray <= {PTR_W{1'b0}};
            src_clear_pending <= 1'b0;
            src_clear_pending_d1 <= 1'b0;
            src_clear_pending_d2 <= 1'b0;
            src_clear_pending_d3 <= 1'b0;
        end else begin
            // Update clear pending chain
            src_clear_pending_d1 <= src_clear_i;
            src_clear_pending_d2 <= src_clear_pending_d1;
            src_clear_pending_d3 <= src_clear_pending_d2;
            
            if (src_clear_i) begin
                src_clear_pending <= 1'b1;
                src_wr_ptr <= {PTR_W{1'b0}};
                src_wr_ptr_gray <= {PTR_W{1'b0}};
            end else if (src_clear_pending) begin
                // Wait until the clear has propagated to destination side
                // and the write pointer is back to zero
                if (src_wr_ptr == {PTR_W{1'b0}} && src_clear_pending_d3) begin
                    src_clear_pending <= 1'b0;
                end
            end else begin
                if (src_wr_en) begin
                    src_wr_ptr <= src_wr_ptr_next;
                    src_wr_ptr_gray <= src_wr_ptr_gray_next;
                end
            end
        end
    end

    // Source domain: memory write
    always @(posedge src_clk_i) begin
        if (src_wr_en) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // Source domain: synchronize destination read pointer gray
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_gray_synced <= {PTR_W{1'b0}};
            dst_rd_ptr_gray_synced_d1 <= {PTR_W{1'b0}};
            dst_rd_ptr_gray_synced_d2 <= {PTR_W{1'b0}};
            dst_rd_ptr_gray_synced_d3 <= {PTR_W{1'b0}};
        end else begin
            dst_rd_ptr_gray_synced <= dst_rd_ptr_gray;
            dst_rd_ptr_gray_synced_d1 <= dst_rd_ptr_gray_synced;
            dst_rd_ptr_gray_synced_d2 <= dst_rd_ptr_gray_synced_d1;
            dst_rd_ptr_gray_synced_d3 <= dst_rd_ptr_gray_synced_d2;
        end
    end

    assign src_clear_pending_o = src_clear_pending;

    // Destination domain: read pointer and output
    wire dst_rd_en = dst_valid_reg & dst_ready_i & ~dst_clear_pending;
    wire [PTR_W-1:0] dst_rd_ptr_next = dst_rd_ptr + 1'b1;
    wire [PTR_W-1:0] dst_rd_ptr_gray_next = bin2gray(dst_rd_ptr_next);

    // Destination domain: write pointer synced from source
    wire [PTR_W-1:0] dst_wr_ptr_gray_synced = src_wr_ptr_gray_synced_d3;
    wire [PTR_W-1:0] dst_wr_ptr_gray_synced_bin = gray2bin(dst_wr_ptr_gray_synced);

    // Destination domain: empty detection
    wire dst_empty_correct = (dst_rd_ptr_gray == dst_wr_ptr_gray_synced);

    // Destination clear pending logic
    wire dst_clear_active = dst_clear_i | dst_clear_pending;

    // Destination domain: read pointer update
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_rd_ptr_gray <= {PTR_W{1'b0}};
            dst_clear_pending <= 1'b0;
            dst_clear_pending_d1 <= 1'b0;
            dst_clear_pending_d2 <= 1'b0;
            dst_clear_pending_d3 <= 1'b0;
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            // Update clear pending chain
            dst_clear_pending_d1 <= dst_clear_i;
            dst_clear_pending_d2 <= dst_clear_pending_d1;
            dst_clear_pending_d3 <= dst_clear_pending_d2;
            
            if (dst_clear_i) begin
                dst_clear_pending <= 1'b1;
                dst_rd_ptr <= {PTR_W{1'b0}};
                dst_rd_ptr_gray <= {PTR_W{1'b0}};
                dst_valid_reg <= 1'b0;
            end else if (dst_clear_pending) begin
                // Wait until the clear has propagated to source side
                // and the read pointer is back to zero
                if (dst_rd_ptr == {PTR_W{1'b0}} && dst_clear_pending_d3) begin
                    dst_clear_pending <= 1'b0;
                end
            end else begin
                if (dst_rd_en) begin
                    dst_rd_ptr <= dst_rd_ptr_next;
                    dst_rd_ptr_gray <= dst_rd_ptr_gray_next;
                    dst_valid_reg <= 1'b0;
                end else if (!dst_empty_correct && !dst_valid_reg) begin
                    // Load new data from memory
                    dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                    dst_valid_reg <= 1'b1;
                end
            end
        end
    end

    // Destination domain: synchronize source write pointer gray
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_gray_synced <= {PTR_W{1'b0}};
            src_wr_ptr_gray_synced_d1 <= {PTR_W{1'b0}};
            src_wr_ptr_gray_synced_d2 <= {PTR_W{1'b0}};
            src_wr_ptr_gray_synced_d3 <= {PTR_W{1'b0}};
        end else begin
            src_wr_ptr_gray_synced <= src_wr_ptr_gray;
            src_wr_ptr_gray_synced_d1 <= src_wr_ptr_gray_synced;
            src_wr_ptr_gray_synced_d2 <= src_wr_ptr_gray_synced_d1;
            src_wr_ptr_gray_synced_d3 <= src_wr_ptr_gray_synced_d2;
        end
    end

    assign dst_clear_pending_o = dst_clear_pending;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg & ~dst_clear_pending;

endmodule
