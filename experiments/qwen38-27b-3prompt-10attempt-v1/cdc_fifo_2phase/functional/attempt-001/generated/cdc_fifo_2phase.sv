module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
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
    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // Source domain signals
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_src;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_src_d1;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_src_d2;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_src_d3;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_src_d4;

    // Destination domain signals
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [PTR_WIDTH-1:0] src_wr_ptr_dst;
    reg [PTR_WIDTH-1:0] src_wr_ptr_dst_d1;
    reg [PTR_WIDTH-1:0] src_wr_ptr_dst_d2;
    reg [PTR_WIDTH-1:0] src_wr_ptr_dst_d3;
    reg [PTR_WIDTH-1:0] src_wr_ptr_dst_d4;

    // Source domain: write pointer and read pointer (synchronized)
    wire src_wr_en = src_valid_i & src_ready_o;
    wire src_full = (src_wr_ptr[LOG_WIDTH-1:0] == dst_rd_ptr_src_d4[LOG_WIDTH-1:0]) &&
                    (src_wr_ptr[LOG_WIDTH] != dst_rd_ptr_src_d4[LOG_WIDTH]);

    // Actually, let's use the standard Gray code approach for CDC
    // But the problem says "2phase" which might imply a simpler approach.
    // Let me re-read: "valid/ready asynchronous FIFO with 2**LOG_DEPTH entries"
    // The "2phase" in the name might refer to the two-phase handshake or just be a name.
    // Let's implement a standard async FIFO with Gray code pointers.

    // Let me restart with a cleaner implementation using Gray code pointers.

    // Source domain
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_src;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_src_d1;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_src_d2;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_src_d3;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_src_d4;

    // Destination domain
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_dst;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_dst_d1;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_dst_d2;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_dst_d3;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_dst_d4;

    // Binary to Gray conversion
    function [PTR_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Gray to Binary conversion
    function [PTR_WIDTH-1:0] gray2bin;
        input [PTR_WIDTH-1:0] gray;
        reg [PTR_WIDTH-1:0] bin;
        integer i;
        begin
            bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            gray2bin = bin;
        end
    endfunction

    // Source domain: write pointer
    reg [PTR_WIDTH-1:0] src_wr_ptr_bin;
    wire [PTR_WIDTH-1:0] src_wr_ptr_gray_next = bin2gray(src_wr_ptr_bin + 1);

    // Destination domain: read pointer
    reg [PTR_WIDTH-1:0] dst_rd_ptr_bin;
    wire [PTR_WIDTH-1:0] dst_rd_ptr_gray_next = bin2gray(dst_rd_ptr_bin + 1);

    // Source domain: synchronized read pointer (from destination)
    wire [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync = dst_rd_ptr_gray_src_d4;
    wire [PTR_WIDTH-1:0] dst_rd_ptr_bin_sync = gray2bin(dst_rd_ptr_gray_sync);

    // Destination domain: synchronized write pointer (from source)
    wire [PTR_WIDTH-1:0] src_wr_ptr_gray_sync = src_wr_ptr_gray_dst_d4;
    wire [PTR_WIDTH-1:0] src_wr_ptr_bin_sync = gray2bin(src_wr_ptr_gray_sync);

    // Full condition (source domain)
    wire src_full = (src_wr_ptr_bin[LOG_WIDTH-1:0] == dst_rd_ptr_bin_sync[LOG_WIDTH-1:0]) &&
                    (src_wr_ptr_bin[LOG_WIDTH] != dst_rd_ptr_bin_sync[LOG_WIDTH]);

    // Empty condition (destination domain)
    wire dst_empty = (dst_rd_ptr_bin[LOG_WIDTH-1:0] == src_wr_ptr_bin_sync[LOG_WIDTH-1:0]) &&
                     (dst_rd_ptr_bin[LOG_WIDTH] == src_wr_ptr_bin_sync[LOG_WIDTH]);

    // Source ready
    assign src_ready_o = ~src_full;

    // Destination valid
    assign dst_valid_o = dst_valid_reg;
    assign dst_data_o = dst_data_reg;

    // Source domain: write to memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_bin <= {PTR_WIDTH{1'b0}};
        end else if (src_valid_i & src_ready_o) begin
            mem[src_wr_ptr_bin[LOG_WIDTH-1:0]] <= src_data_i;
            src_wr_ptr_bin <= src_wr_ptr_bin + 1;
        end
    end

    // Source domain: synchronize destination read pointer
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_gray_src <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray_src_d1 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray_src_d2 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray_src_d3 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray_src_d4 <= {PTR_WIDTH{1'b0}};
        end else begin
            dst_rd_ptr_gray_src <= dst_rd_ptr_gray;
            dst_rd_ptr_gray_src_d1 <= dst_rd_ptr_gray_src;
            dst_rd_ptr_gray_src_d2 <= dst_rd_ptr_gray_src_d1;
            dst_rd_ptr_gray_src_d3 <= dst_rd_ptr_gray_src_d2;
            dst_rd_ptr_gray_src_d4 <= dst_rd_ptr_gray_src_d3;
        end
    end

    // Destination domain: read from memory
    wire dst_rd_en = dst_valid_reg & dst_ready_i;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_bin <= {PTR_WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
            dst_data_reg <= {WIDTH{1'b0}};
        end else begin
            if (dst_valid_reg & dst_ready_i) begin
                dst_valid_reg <= ~dst_empty;
                if (~dst_empty) begin
                    dst_data_reg <= mem[dst_rd_ptr_bin[LOG_WIDTH-1:0]];
                    dst_rd_ptr_bin <= dst_rd_ptr_bin + 1;
                end
            end else if (~dst_valid_reg & ~dst_empty) begin
                dst_valid_reg <= 1'b1;
                dst_data_reg <= mem[dst_rd_ptr_bin[LOG_WIDTH-1:0]];
                dst_rd_ptr_bin <= dst_rd_ptr_bin + 1;
            end
        end
    end

    // Destination domain: synchronize source write pointer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_gray_dst <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray_dst_d1 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray_dst_d2 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray_dst_d3 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray_dst_d4 <= {PTR_WIDTH{1'b0}};
        end else begin
            src_wr_ptr_gray_dst <= src_wr_ptr_gray;
            src_wr_ptr_gray_dst_d1 <= src_wr_ptr_gray_dst;
            src_wr_ptr_gray_dst_d2 <= src_wr_ptr_gray_dst_d1;
            src_wr_ptr_gray_dst_d3 <= src_wr_ptr_gray_dst_d2;
            src_wr_ptr_gray_dst_d4 <= src_wr_ptr_gray_dst_d3;
        end
    end

    // Source domain: generate Gray code write pointer
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else if (src_valid_i & src_ready_o) begin
            src_wr_ptr_gray <= src_wr_ptr_gray_next;
        end
    end

    // Destination domain: generate Gray code read pointer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else if (dst_valid_reg & dst_ready_i) begin
            dst_rd_ptr_gray <= dst_rd_ptr_gray_next;
        end
    end

endmodule
