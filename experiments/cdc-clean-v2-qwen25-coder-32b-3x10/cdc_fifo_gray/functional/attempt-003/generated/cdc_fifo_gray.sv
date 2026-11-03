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
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [WIDTH-1:0] mem [DEPTH-1:0];

    reg [ADDR_WIDTH:0] src_wr_ptr_gray, src_wr_ptr_gray_nxt, src_wr_ptr_bin;
    reg [ADDR_WIDTH:0] src_rd_ptr_gray, src_rd_ptr_gray_nxt, src_rd_ptr_bin;
    reg [ADDR_WIDTH:0] dst_wr_ptr_gray, dst_wr_ptr_gray_nxt, dst_wr_ptr_bin;
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray, dst_rd_ptr_gray_nxt, dst_rd_ptr_bin;

    // Binary to Gray conversion
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary conversion
    function [ADDR_WIDTH:0] gray_to_bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        bin = gray;
        for (i = 1; i <= ADDR_WIDTH; i = i + 1) begin
            bin = bin ^ (bin >> i);
        end
        gray_to_bin = bin;
    endfunction

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_gray <= 0;
            src_wr_ptr_bin <= 0;
            src_rd_ptr_gray <= 0;
            src_rd_ptr_bin <= 0;
        end else begin
            src_wr_ptr_gray <= src_wr_ptr_gray_nxt;
            src_wr_ptr_bin <= gray_to_bin(src_wr_ptr_gray_nxt);
            src_rd_ptr_gray <= src_rd_ptr_gray_nxt;
            src_rd_ptr_bin <= gray_to_bin(src_rd_ptr_gray_nxt);
        end
    end

    always @(*) begin
        src_wr_ptr_gray_nxt = src_wr_ptr_gray;
        src_rd_ptr_gray_nxt = src_rd_ptr_gray;
        if (src_valid_i && src_ready_o) begin
            src_wr_ptr_gray_nxt = bin_to_gray(src_wr_ptr_bin + 1);
        end
        if (dst_valid_o && dst_ready_i) begin
            src_rd_ptr_gray_nxt = bin_to_gray(src_rd_ptr_bin + 1);
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray <= 0;
            dst_wr_ptr_bin <= 0;
            dst_rd_ptr_gray <= 0;
            dst_rd_ptr_bin <= 0;
        end else begin
            dst_wr_ptr_gray <= dst_wr_ptr_gray_nxt;
            dst_wr_ptr_bin <= gray_to_bin(dst_wr_ptr_gray_nxt);
            dst_rd_ptr_gray <= dst_rd_ptr_gray_nxt;
            dst_rd_ptr_bin <= gray_to_bin(dst_rd_ptr_gray_nxt);
        end
    end

    always @(*) begin
        dst_wr_ptr_gray_nxt = dst_wr_ptr_gray;
        dst_rd_ptr_gray_nxt = dst_rd_ptr_gray;
        if (src_valid_i && src_ready_o) begin
            dst_wr_ptr_gray_nxt = bin_to_gray(dst_wr_ptr_bin + 1);
        end
        if (dst_valid_o && dst_ready_i) begin
            dst_rd_ptr_gray_nxt = bin_to_gray(dst_rd_ptr_bin + 1);
        end
    end

    // Cross-domain synchronization for write pointer
    reg [ADDR_WIDTH:0] sync_wr_ptr_gray [SYNC_STAGES-1:0];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            sync_wr_ptr_gray <= {SYNC_STAGES{ADDR_WIDTH+1{1'b0}}};
        end else begin
            sync_wr_ptr_gray[0] <= src_wr_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_wr_ptr_gray[i] <= sync_wr_ptr_gray[i-1];
            end
        end
    end

    // Cross-domain synchronization for read pointer
    reg [ADDR_WIDTH:0] sync_rd_ptr_gray [SYNC_STAGES-1:0];

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            sync_rd_ptr_gray <= {SYNC_STAGES{ADDR_WIDTH+1{1'b0}}};
        end else begin
            sync_rd_ptr_gray[0] <= dst_rd_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_rd_ptr_gray[i] <= sync_rd_ptr_gray[i-1];
            end
        end
    end

    // Source ready signal
    assign src_ready_o = (src_wr_ptr_bin != gray_to_bin(sync_rd_ptr_gray[SYNC_STAGES-1]));

    // Destination valid signal
    assign dst_valid_o = (dst_wr_ptr_bin != gray_to_bin(sync_rd_ptr_gray[SYNC_STAGES-1]));

    // Write data to memory
    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o) begin
            mem[src_wr_ptr_bin[ADDR_WIDTH-1:0]] <= src_data_i;
        end
    end

    // Read data from memory
    always @(posedge dst_clk_i) begin
        if (dst_valid_o && dst_ready_i) begin
            dst_data_o <= mem[dst_rd_ptr_bin[ADDR_WIDTH-1:0]];
        end
    end

endmodule
