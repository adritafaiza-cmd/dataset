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

    // Gray code conversion functions
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

    // Source domain signals
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [PTR_WIDTH-1:0] src_rd_ptr_gray;
    reg [PTR_WIDTH-1:0] src_rd_ptr_gray_sync1;
    reg [PTR_WIDTH-1:0] src_rd_ptr_gray_sync2;

    // Destination domain signals
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [PTR_WIDTH-1:0] dst_wr_ptr_gray;
    reg [PTR_WIDTH-1:0] dst_wr_ptr_gray_sync1;
    reg [PTR_WIDTH-1:0] dst_wr_ptr_gray_sync2;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // Source domain: write pointer and memory write
    wire [PTR_WIDTH-1:0] src_wr_ptr_gray = bin2gray(src_wr_ptr);
    wire [PTR_WIDTH-1:0] src_rd_ptr_bin = gray2bin(src_rd_ptr_gray_sync2);
    wire src_full = (src_wr_ptr_gray == src_rd_ptr_gray_sync2) &&
                    (src_wr_ptr[PTR_WIDTH-1] != src_rd_ptr_bin[PTR_WIDTH-1]);
    wire src_can_write = src_valid_i && !src_full;

    assign src_ready_o = !src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (src_can_write) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1'b1;
        end
    end

    // Source domain: synchronize destination read pointer gray
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            src_rd_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            src_rd_ptr_gray_sync1 <= dst_rd_ptr_gray;
            src_rd_ptr_gray_sync2 <= src_rd_ptr_gray_sync1;
        end
    end

    // Destination domain: read pointer and output
    wire [PTR_WIDTH-1:0] dst_rd_ptr_gray = bin2gray(dst_rd_ptr);
    wire [PTR_WIDTH-1:0] dst_wr_ptr_bin = gray2bin(dst_wr_ptr_gray_sync2);
    wire dst_empty = (dst_rd_ptr_gray == dst_wr_ptr_gray_sync2) &&
                     (dst_rd_ptr[PTR_WIDTH-1] == dst_wr_ptr_bin[PTR_WIDTH-1]);
    wire dst_can_read = dst_valid_reg && dst_ready_i;

    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_can_read) begin
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
                dst_valid_reg <= 1'b0;
            end else if (!dst_empty && !dst_valid_reg) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_valid_reg <= 1'b1;
            end
        end
    end

    // Destination domain: synchronize source write pointer gray
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            dst_wr_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            dst_wr_ptr_gray_sync1 <= src_wr_ptr_gray;
            dst_wr_ptr_gray_sync2 <= dst_wr_ptr_gray_sync1;
        end
    end

endmodule
