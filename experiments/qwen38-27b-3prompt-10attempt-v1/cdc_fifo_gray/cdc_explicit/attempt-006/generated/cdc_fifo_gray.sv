module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam PTR_W = LOG_DEPTH + 1;

    // Source domain
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] dst_rd_ptr_src_sync;

    // Destination domain
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] src_wr_ptr_dst_sync;
    reg [WIDTH-1:0] dst_data_reg;
    reg             dst_valid_reg;

    // Synchronizer registers for source write pointer to destination domain
    reg [PTR_W-1:0] src_wr_ptr_sync [0:SYNC_STAGES-1];
    // Synchronizer registers for destination read pointer to source domain
    reg [PTR_W-1:0] dst_rd_ptr_sync [0:SYNC_STAGES-1];

    // Source domain logic
    wire src_wr_en = src_valid_i & src_ready_o;
    wire [PTR_W-1:0] src_wr_ptr_next = src_wr_ptr + 1'b1;

    // Full condition: write pointer has lapped read pointer by DEPTH
    // In gray code, full when MSB differs and rest are equal
    // But we use binary pointers for comparison, converted to gray for CDC
    // Actually, let's use gray code pointers for CDC and binary for local logic

    // Let's use binary pointers internally and convert to gray for crossing
    // Gray code: gray = binary ^ (binary >> 1)

    function [PTR_W-1:0] bin2gray;
        input [PTR_W-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

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

    // Gray code pointers for CDC
    wire [PTR_W-1:0] src_wr_ptr_gray = bin2gray(src_wr_ptr);
    wire [PTR_W-1:0] dst_rd_ptr_gray = bin2gray(dst_rd_ptr);

    // Synchronizer for src_wr_ptr_gray to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_sync[0] <= {PTR_W{1'b0}};
            src_wr_ptr_sync[1] <= {PTR_W{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    src_wr_ptr_sync[i] <= {PTR_W{1'b0}};
            end
        end else begin
            src_wr_ptr_sync[0] <= src_wr_ptr_gray;
            src_wr_ptr_sync[1] <= src_wr_ptr_sync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    src_wr_ptr_sync[i] <= src_wr_ptr_sync[i-1];
            end
        end
    end

    // Synchronizer for dst_rd_ptr_gray to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_sync[0] <= {PTR_W{1'b0}};
            dst_rd_ptr_sync[1] <= {PTR_W{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    dst_rd_ptr_sync[i] <= {PTR_W{1'b0}};
            end
        end else begin
            dst_rd_ptr_sync[0] <= dst_rd_ptr_gray;
            dst_rd_ptr_sync[1] <= dst_rd_ptr_sync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    dst_rd_ptr_sync[i] <= dst_rd_ptr_sync[i-1];
            end
        end
    end

    // Convert synchronized gray pointers back to binary
    wire [PTR_W-1:0] dst_rd_ptr_src_bin = gray2bin(dst_rd_ptr_sync[SYNC_STAGES-1]);
    wire [PTR_W-1:0] src_wr_ptr_dst_bin = gray2bin(src_wr_ptr_sync[SYNC_STAGES-1]);

    // Source domain: full condition
    // FIFO is full when write pointer has advanced DEPTH entries beyond read pointer
    // In binary: full when (src_wr_ptr - dst_rd_ptr_src_bin) == DEPTH
    // Since pointers are PTR_W bits (LOG_DEPTH+1), we can check:
    // full when upper bit differs and lower LOG_DEPTH bits are equal
    wire src_full = (src_wr_ptr[PTR_W-1] != dst_rd_ptr_src_bin[PTR_W-1]) &&
                    (src_wr_ptr[PTR_W-2:0] == dst_rd_ptr_src_bin[PTR_W-2:0]);

    assign src_ready_o = ~src_full;

    // Source domain: write to memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
        end else if (src_wr_en) begin
            mem[src_wr_ptr[PTR_W-2:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr_next;
        end
    end

    // Destination domain: empty condition
    // FIFO is empty when write pointer equals read pointer
    wire dst_empty = (src_wr_ptr_dst_bin == dst_rd_ptr);

    // Destination domain: read from memory
    wire dst_rd_en = dst_valid_reg & dst_ready_i;
    wire [PTR_W-1:0] dst_rd_ptr_next = dst_rd_ptr + 1'b1;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_rd_en) begin
                dst_rd_ptr <= dst_rd_ptr_next;
                dst_valid_reg <= ~dst_empty;
            end else if (!dst_valid_reg && !dst_empty) begin
                dst_data_reg <= mem[dst_rd_ptr[PTR_W-2:0]];
                dst_valid_reg <= 1'b1;
            end
        end
    end

    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
