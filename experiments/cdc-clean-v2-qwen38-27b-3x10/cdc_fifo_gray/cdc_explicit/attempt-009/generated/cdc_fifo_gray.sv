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

    // Gray code conversion functions
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

    // Source domain
    reg [PTR_W-1:0] src_wr_ptr_bin;
    reg [PTR_W-1:0] src_wr_ptr_gray;
    reg [PTR_W-1:0] dst_rd_ptr_gray_synced;
    reg [PTR_W-1:0] dst_rd_ptr_bin_synced;

    // Destination domain
    reg [PTR_W-1:0] dst_rd_ptr_bin;
    reg [PTR_W-1:0] dst_rd_ptr_gray;
    reg [PTR_W-1:0] src_wr_ptr_gray_synced;
    reg [PTR_W-1:0] src_wr_ptr_bin_synced;

    // FIFO storage
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Synchronization registers for write pointer (src -> dst)
    reg [PTR_W-1:0] wr_ptr_sync [0:SYNC_STAGES-1];

    // Synchronization registers for read pointer (dst -> src)
    reg [PTR_W-1:0] rd_ptr_sync [0:SYNC_STAGES-1];

    // Destination pipeline stages for data
    reg [WIDTH-1:0] dst_data_pipe0;
    reg [WIDTH-1:0] dst_data_pipe1;
    reg             dst_valid_pipe0;
    reg             dst_valid_pipe1;

    // Source ready
    wire src_full;
    wire src_can_write;

    // Destination valid
    wire dst_can_read;

    // Compute full/empty conditions
    // Full: write pointer has lapped read pointer by DEPTH
    // In binary: (wr_ptr_bin - rd_ptr_bin) == DEPTH
    // Since pointers are PTR_W bits (LOG_DEPTH+1), we can check:
    // wr_ptr_bin[PTR_W-1:1] == rd_ptr_bin[PTR_W-1:1] && wr_ptr_bin[0] != rd_ptr_bin[0]
    // Actually simpler: full when (wr_ptr_bin - rd_ptr_bin) == DEPTH
    // Since DEPTH = 2^LOG_DEPTH, and pointers are LOG_DEPTH+1 bits:
    // full when upper LOG_DEPTH bits are equal and the MSB differs appropriately
    // Let's just do: full = (wr_ptr_bin[PTR_W-1:1] == rd_ptr_bin[PTR_W-1:1]) && (wr_ptr_bin[0] != rd_ptr_bin[0])
    // Wait, that's not quite right either. Let me think again.
    //
    // wr_ptr_bin and rd_ptr_bin are both PTR_W bits.
    // The FIFO is full when (wr_ptr_bin - rd_ptr_bin) mod (2*DEPTH) == DEPTH
    // Since we're using PTR_W = LOG_DEPTH+1 bits, the range is 0 to 2*DEPTH-1.
    // Full when the difference is exactly DEPTH.
    // This happens when the upper LOG_DEPTH bits are equal and the MSB (bit PTR_W-1) of wr is 1 and rd is 0, OR
    // more simply: full = (wr_ptr_bin[PTR_W-1:1] == rd_ptr_bin[PTR_W-1:1]) && (wr_ptr_bin[0] != rd_ptr_bin[0])
    // Hmm, let me just use a comparator.
    
    wire [PTR_W-1:0] src_diff = src_wr_ptr_bin - dst_rd_ptr_bin_synced;
    wire src_full = (src_diff == DEPTH);

    wire [PTR_W-1:0] dst_diff = src_wr_ptr_bin_synced - dst_rd_ptr_bin;
    wire dst_empty = (dst_diff == 0);

    // Source ready: not full
    assign src_ready_o = ~src_full;

    // Source write
    wire src_write = src_valid_i & src_ready_o;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_bin <= {PTR_W{1'b0}};
            src_wr_ptr_gray <= {PTR_W{1'b0}};
        end else if (src_write) begin
            src_wr_ptr_bin <= src_wr_ptr_bin + 1'b1;
            src_wr_ptr_gray <= bin2gray(src_wr_ptr_bin + 1'b1);
            mem[src_wr_ptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // Synchronize write pointer gray to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_sync[0] <= {PTR_W{1'b0}};
            wr_ptr_sync[1] <= {PTR_W{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    wr_ptr_sync[i] <= {PTR_W{1'b0}};
            end
        end else begin
            wr_ptr_sync[0] <= src_wr_ptr_gray;
            wr_ptr_sync[1] <= wr_ptr_sync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    wr_ptr_sync[i] <= wr_ptr_sync[i-1];
            end
        end
    end

    assign src_wr_ptr_gray_synced = wr_ptr_sync[SYNC_STAGES-1];
    assign src_wr_ptr_bin_synced = gray2bin(src_wr_ptr_gray_synced);

    // Synchronize read pointer gray to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_ptr_sync[0] <= {PTR_W{1'b0}};
            rd_ptr_sync[1] <= {PTR_W{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    rd_ptr_sync[i] <= {PTR_W{1'b0}};
            end
        end else begin
            rd_ptr_sync[0] <= dst_rd_ptr_gray;
            rd_ptr_sync[1] <= rd_ptr_sync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    rd_ptr_sync[i] <= rd_ptr_sync[i-1];
            end
        end
    end

    assign dst_rd_ptr_gray_synced = rd_ptr_sync[SYNC_STAGES-1];
    assign dst_rd_ptr_bin_synced = gray2bin(dst_rd_ptr_gray_synced);

    // Destination read
    wire dst_read = dst_valid_pipe1 & dst_ready_i;

    // Pipeline stage 0: read from memory
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_pipe0 <= {WIDTH{1'b0}};
            dst_valid_pipe0 <= 1'b0;
        end else begin
            if (~dst_empty) begin
                dst_data_pipe0 <= mem[dst_rd_ptr_bin[LOG_DEPTH-1:0]];
                dst_valid_pipe0 <= 1'b1;
            end else begin
                dst_valid_pipe0 <= 1'b0;
            end
        end
    end

    // Pipeline stage 1: output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_pipe1 <= {WIDTH{1'b0}};
            dst_valid_pipe1 <= 1'b0;
        end else begin
            dst_data_pipe1 <= dst_data_pipe0;
            dst_valid_pipe1 <= dst_valid_pipe0;
        end
    end

    assign dst_data_o = dst_data_pipe1;
    assign dst_valid_o = dst_valid_pipe1;

    // Update read pointer when a beat is accepted at the output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_bin <= {PTR_W{1'b0}};
            dst_rd_ptr_gray <= {PTR_W{1'b0}};
        end else if (dst_read) begin
            dst_rd_ptr_bin <= dst_rd_ptr_bin + 1'b1;
            dst_rd_ptr_gray <= bin2gray(dst_rd_ptr_bin + 1'b1);
        end
    end

endmodule
