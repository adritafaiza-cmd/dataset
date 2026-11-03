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
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] src_rd_ptr_sync;
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Destination domain
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] dst_wr_ptr_sync;
    reg [WIDTH-1:0] dst_data_reg;
    reg             dst_valid_reg;

    // Gray code conversion
    function [PTR_W-1:0] bin2gray;
        input [PTR_W-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Source domain: write pointer and memory
    wire src_full = (src_wr_ptr == src_rd_ptr_sync) && (src_wr_ptr[PTR_W-1] != src_rd_ptr_sync[PTR_W-1]);
    wire src_can_write = src_valid_i && !src_full;

    assign src_ready_o = !src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
        end else if (src_can_write) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1'b1;
        end
    end

    // Gray code of write pointer for CDC
    wire [PTR_W-1:0] src_wr_ptr_gray = bin2gray(src_wr_ptr);

    // Synchronize write pointer gray to destination domain
    reg [PTR_W-1:0] dst_wr_ptr_gray_sync [0:SYNC_STAGES-1];

    integer i;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                dst_wr_ptr_gray_sync[i] <= {PTR_W{1'b0}};
        end else begin
            dst_wr_ptr_gray_sync[0] <= src_wr_ptr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                dst_wr_ptr_gray_sync[i] <= dst_wr_ptr_gray_sync[i-1];
        end
    end

    // Convert synchronized gray to binary in destination domain
    function [PTR_W-1:0] gray2bin;
        input [PTR_W-1:0] gray;
        integer j;
        begin
            gray2bin[PTR_W-1] = gray[PTR_W-1];
            for (j = PTR_W-2; j >= 0; j = j - 1)
                gray2bin[j] = gray2bin[j+1] ^ gray[j];
        end
    endfunction

    wire [PTR_W-1:0] dst_wr_ptr_bin = gray2bin(dst_wr_ptr_gray_sync[SYNC_STAGES-1]);

    // Destination domain: read pointer and output
    wire dst_empty = (dst_rd_ptr == dst_wr_ptr_bin);
    wire dst_can_read = dst_ready_i && !dst_empty;

    assign dst_valid_o = !dst_empty;
    assign dst_data_o  = mem[dst_rd_ptr[LOG_DEPTH-1:0]];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
        end else if (dst_can_read) begin
            dst_rd_ptr <= dst_rd_ptr + 1'b1;
        end
    end

    // Gray code of read pointer for CDC
    wire [PTR_W-1:0] dst_rd_ptr_gray = bin2gray(dst_rd_ptr);

    // Synchronize read pointer gray to source domain
    reg [PTR_W-1:0] src_rd_ptr_gray_sync [0:SYNC_STAGES-1];

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                src_rd_ptr_gray_sync[i] <= {PTR_W{1'b0}};
        end else begin
            src_rd_ptr_gray_sync[0] <= dst_rd_ptr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                src_rd_ptr_gray_sync[i] <= src_rd_ptr_gray_sync[i-1];
        end
    end

    // Convert synchronized gray to binary in source domain
    wire [PTR_W-1:0] src_rd_ptr_bin = gray2bin(src_rd_ptr_gray_sync[SYNC_STAGES-1]);

    // Update the synchronized read pointer in source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_sync <= {PTR_W{1'b0}};
        end else begin
            src_rd_ptr_sync <= src_rd_ptr_bin;
        end
    end

endmodule
