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

    // Source domain
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_src;
    wire [PTR_WIDTH-1:0] dst_rd_ptr_src_sync;

    // Destination domain
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [PTR_WIDTH-1:0] src_wr_ptr_dst;
    wire [PTR_WIDTH-1:0] src_wr_ptr_dst_sync;

    // Gray code conversion
    function [PTR_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

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
    wire src_wr_gray = bin2gray(src_wr_ptr);
    wire src_wr_gray_sync = src_wr_ptr_dst_sync; // This is actually dst_rd_ptr in src domain

    // Let me restructure properly

    // Source domain signals
    reg [PTR_WIDTH-1:0] src_wr_ptr_r;
    wire [PTR_WIDTH-1:0] src_wr_ptr_gray = bin2gray(src_wr_ptr_r);

    // Destination read pointer synchronized to source domain
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync1;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync2;
    wire [PTR_WIDTH-1:0] dst_rd_ptr_src = gray2bin(dst_rd_ptr_gray_sync2);

    // Destination domain signals
    reg [PTR_WIDTH-1:0] dst_rd_ptr_r;
    wire [PTR_WIDTH-1:0] dst_rd_ptr_gray = bin2gray(dst_rd_ptr_r);

    // Source write pointer synchronized to destination domain
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_sync1;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_sync2;
    wire [PTR_WIDTH-1:0] src_wr_ptr_dst = gray2bin(src_wr_ptr_gray_sync2);

    // Source domain: FIFO full check
    wire src_full = (src_wr_ptr_r[PTR_WIDTH-1] != dst_rd_ptr_src[PTR_WIDTH-1]) &&
                    (src_wr_ptr_r[PTR_WIDTH-2:0] == dst_rd_ptr_src[PTR_WIDTH-2:0]);

    // Destination domain: FIFO empty check
    wire dst_empty = (dst_rd_ptr_r == src_wr_ptr_dst);

    // Source ready
    assign src_ready_o = ~src_full;

    // Source domain: write to memory
    wire src_write = src_valid_i & src_ready_o;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_wr_ptr_r <= {PTR_WIDTH{1'b0}};
        else if (src_write)
            src_wr_ptr_r <= src_wr_ptr_r + 1'b1;
    end

    always @(posedge src_clk_i) begin
        if (src_write)
            mem[src_wr_ptr_r[LOG_DEPTH-1:0]] <= src_data_i;
    end

    // Synchronize dst_rd_ptr_gray to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            dst_rd_ptr_gray_sync1 <= dst_rd_ptr_gray;
            dst_rd_ptr_gray_sync2 <= dst_rd_ptr_gray_sync1;
        end
    end

    // Synchronize src_wr_ptr_gray to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            src_wr_ptr_gray_sync1 <= src_wr_ptr_gray;
            src_wr_ptr_gray_sync2 <= src_wr_ptr_gray_sync1;
        end
    end

    // Destination domain: read from memory
    wire dst_read = dst_valid_o & dst_ready_i;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_rd_ptr_r <= {PTR_WIDTH{1'b0}};
        else if (dst_read)
            dst_rd_ptr_r <= dst_rd_ptr_r + 1'b1;
    end

    // Destination output
    reg [WIDTH-1:0] dst_data_r;
    reg dst_valid_r;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_r <= {WIDTH{1'b0}};
            dst_valid_r <= 1'b0;
        end else begin
            if (!dst_empty) begin
                dst_data_r <= mem[dst_rd_ptr_r[LOG_DEPTH-1:0]];
                dst_valid_r <= 1'b1;
            end else begin
                dst_valid_r <= 1'b0;
            end
        end
    end

    assign dst_data_o = dst_data_r;
    assign dst_valid_o = dst_valid_r;

endmodule
