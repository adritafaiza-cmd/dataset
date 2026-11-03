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
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [WIDTH-1:0] mem [DEPTH-1:0];

    // Source domain signals
    reg [ADDR_WIDTH:0] src_wr_ptr;
    reg [ADDR_WIDTH:0] src_rd_ptr_gray;
    reg [ADDR_WIDTH:0] src_wr_ptr_gray;

    // Destination domain signals
    reg [ADDR_WIDTH:0] dst_wr_ptr_gray;
    reg [ADDR_WIDTH:0] dst_rd_ptr;
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray;

    // Gray code conversion functions
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    function [ADDR_WIDTH:0] gray2bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        bin = gray;
        for (i = ADDR_WIDTH-1; i > 0; i = i - 1) begin
            bin[i-1] = bin[i] ^ bin[i-1];
        end
        gray2bin = bin;
    endfunction

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_wr_ptr_gray <= 0;
        end else if (src_valid_i && src_ready_o) begin
            mem[src_wr_ptr[ADDR_WIDTH-1:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1;
            src_wr_ptr_gray <= bin2gray(src_wr_ptr + 1);
        end
    end

    // Cross-domain transfer of write pointer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray <= 0;
        end else begin
            dst_wr_ptr_gray <= src_wr_ptr_gray;
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
            dst_rd_ptr_gray <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_rd_ptr <= dst_rd_ptr + 1;
            dst_rd_ptr_gray <= bin2gray(dst_rd_ptr + 1);
        end
    end

    // Cross-domain transfer of read pointer
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray <= 0;
        end else begin
            src_rd_ptr_gray <= dst_rd_ptr_gray;
        end
    end

    // Source ready signal
    assign src_ready_o = (src_wr_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1] != src_rd_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1]);

    // Destination valid signal
    assign dst_valid_o = (dst_wr_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1] != dst_rd_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1]);

    // Destination data output
    reg [WIDTH-1:0] dst_data_reg1;
    reg [WIDTH-1:0] dst_data_reg2;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg1 <= 0;
            dst_data_reg2 <= 0;
        end else if (dst_valid_o) begin
            dst_data_reg1 <= mem[dst_rd_ptr[ADDR_WIDTH-1:0]];
            dst_data_reg2 <= dst_data_reg1;
        end
    end

    assign dst_data_o = dst_data_reg2;

endmodule
