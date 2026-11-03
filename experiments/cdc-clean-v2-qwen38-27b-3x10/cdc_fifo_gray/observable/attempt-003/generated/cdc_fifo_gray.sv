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
    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // Source side
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [PTR_WIDTH-1:0] src_rd_ptr_sync;

    // Destination side
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [PTR_WIDTH-1:0] dst_wr_ptr_sync;

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

    // Source side: write pointer in binary and gray
    wire [PTR_WIDTH-1:0] src_wr_ptr_gray = bin2gray(src_wr_ptr);

    // Destination side: read pointer in binary and gray
    wire [PTR_WIDTH-1:0] dst_rd_ptr_gray = bin2gray(dst_rd_ptr);

    // Synchronize source write pointer gray to destination domain
    reg [PTR_WIDTH-1:0] dst_wr_ptr_sync_reg [0:SYNC_STAGES-1];
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_sync_reg[0] <= {PTR_WIDTH{1'b0}};
            dst_wr_ptr_sync_reg[1] <= {PTR_WIDTH{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    dst_wr_ptr_sync_reg[i] <= {PTR_WIDTH{1'b0}};
            end
        end else begin
            dst_wr_ptr_sync_reg[0] <= src_wr_ptr_gray;
            dst_wr_ptr_sync_reg[1] <= dst_wr_ptr_sync_reg[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    dst_wr_ptr_sync_reg[i] <= dst_wr_ptr_sync_reg[i-1];
            end
        end
    end

    assign dst_wr_ptr_sync = dst_wr_ptr_sync_reg[SYNC_STAGES-1];

    // Synchronize destination read pointer gray to source domain
    reg [PTR_WIDTH-1:0] src_rd_ptr_sync_reg [0:SYNC_STAGES-1];
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_sync_reg[0] <= {PTR_WIDTH{1'b0}};
            src_rd_ptr_sync_reg[1] <= {PTR_WIDTH{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    src_rd_ptr_sync_reg[i] <= {PTR_WIDTH{1'b0}};
            end
        end else begin
            src_rd_ptr_sync_reg[0] <= dst_rd_ptr_gray;
            src_rd_ptr_sync_reg[1] <= src_rd_ptr_sync_reg[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    src_rd_ptr_sync_reg[i] <= src_rd_ptr_sync_reg[i-1];
            end
        end
    end

    assign src_rd_ptr_sync = src_rd_ptr_sync_reg[SYNC_STAGES-1];

    // Convert synchronized gray pointers back to binary
    wire [PTR_WIDTH-1:0] dst_wr_ptr_bin = gray2bin(dst_wr_ptr_sync);
    wire [PTR_WIDTH-1:0] src_rd_ptr_bin = gray2bin(src_rd_ptr_sync);

    // Full condition: write pointer has lapped read pointer by DEPTH
    // In binary, full when upper bits match and lower bits differ by DEPTH
    // For a FIFO of size 2^LOG_DEPTH, full when:
    // src_wr_ptr[LOG_DEPTH:1] == src_rd_ptr_bin[LOG_DEPTH:1] && src_wr_ptr[0] != src_rd_ptr_bin[0]
    wire src_full = (src_wr_ptr[PTR_WIDTH-1:1] == src_rd_ptr_bin[PTR_WIDTH-1:1]) &&
                    (src_wr_ptr[0] != src_rd_ptr_bin[0]);

    // Empty condition: read pointer equals write pointer
    wire dst_empty = (dst_rd_ptr == dst_wr_ptr_bin);

    // Source ready: not full
    assign src_ready_o = ~src_full;

    // Destination valid: not empty
    assign dst_valid_o = ~dst_empty;

    // Write to memory on source clock
    wire src_write = src_valid_i & src_ready_o;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
        else if (src_write)
            src_wr_ptr <= src_wr_ptr + 1'b1;
    end

    always @(posedge src_clk_i) begin
        if (src_write)
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
    end

    // Read from memory on destination clock
    wire dst_read = dst_valid_o & dst_ready_i;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
        else if (dst_read)
            dst_rd_ptr <= dst_rd_ptr + 1'b1;
    end

    // Output data: read from memory at current read pointer
    assign dst_data_o = mem[dst_rd_ptr[LOG_DEPTH-1:0]];

endmodule
