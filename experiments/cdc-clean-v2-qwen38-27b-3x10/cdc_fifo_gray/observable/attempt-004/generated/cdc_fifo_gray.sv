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

    // Write pointer (binary) in source domain
    reg [PTR_W-1:0] wr_ptr_bin;
    // Read pointer (binary) in destination domain
    reg [PTR_W-1:0] rd_ptr_bin;

    // Gray code pointers
    wire [PTR_W-1:0] wr_ptr_gray = wr_ptr_bin ^ {wr_ptr_bin[PTR_W-1:1], {1'b0}};
    wire [PTR_W-1:0] rd_ptr_gray = rd_ptr_bin ^ {rd_ptr_bin[PTR_W-1:1], {1'b0}};

    // Synchronize write pointer gray to destination domain
    reg [PTR_W-1:0] wr_ptr_gray_sync [0:SYNC_STAGES-1];
    integer i;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                wr_ptr_gray_sync[i] <= {PTR_W{1'b0}};
        end else begin
            wr_ptr_gray_sync[0] <= wr_ptr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                wr_ptr_gray_sync[i] <= wr_ptr_gray_sync[i-1];
        end
    end

    // Synchronize read pointer gray to source domain
    reg [PTR_W-1:0] rd_ptr_gray_sync [0:SYNC_STAGES-1];
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                rd_ptr_gray_sync[i] <= {PTR_W{1'b0}};
        end else begin
            rd_ptr_gray_sync[0] <= rd_ptr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                rd_ptr_gray_sync[i] <= rd_ptr_gray_sync[i-1];
        end
    end

    // Convert synchronized gray to binary
    function [PTR_W-1:0] gray2bin;
        input [PTR_W-1:0] gray;
        integer j;
        begin
            gray2bin[PTR_W-1] = gray[PTR_W-1];
            for (j = PTR_W-2; j >= 0; j = j - 1)
                gray2bin[j] = gray2bin[j+1] ^ gray[j];
        end
    endfunction

    wire [PTR_W-1:0] wr_ptr_gray_dst = wr_ptr_gray_sync[SYNC_STAGES-1];
    wire [PTR_W-1:0] rd_ptr_gray_src = rd_ptr_gray_sync[SYNC_STAGES-1];

    wire [PTR_W-1:0] wr_ptr_bin_dst = gray2bin(wr_ptr_gray_dst);
    wire [PTR_W-1:0] rd_ptr_bin_src = gray2bin(rd_ptr_gray_src);

    // Full condition: write pointer has lapped read pointer by DEPTH
    // In binary, full when upper bits match and lower bits differ by DEPTH
    // For a FIFO of size 2^LOG_DEPTH, full when wr_ptr_bin_dst[PTR_W-1:LOG_DEPTH] == rd_ptr_bin_src[PTR_W-1:LOG_DEPTH]
    // and wr_ptr_bin_dst[LOG_DEPTH-1:0] != rd_ptr_bin_src[LOG_DEPTH-1:0]
    // Actually, the standard check: full when the MSB of the difference is set
    // wr_ptr_bin_dst - rd_ptr_bin_src == DEPTH
    // This is equivalent to: wr_ptr_bin_dst[PTR_W-1:LOG_DEPTH] == rd_ptr_bin_src[PTR_W-1:1:0] shifted... 
    // Let's use the standard approach:
    // full = (wr_ptr_bin_dst[PTR_W-1:LOG_DEPTH] == rd_ptr_bin_src[PTR_W-1:LOG_DEPTH]) &&
    //        (wr_ptr_bin_dst[LOG_DEPTH-1:0] != rd_ptr_bin_src[LOG_DEPTH-1:0])
    // Wait, that's not quite right either. Let me think again.
    //
    // For a FIFO with 2^N entries, pointers are N+1 bits wide.
    // Full when the top bit of the write pointer differs from the top bit of the read pointer,
    // and the lower N bits are equal.
    // Actually: full = (wr_ptr_bin_dst[PTR_W-1] != rd_ptr_bin_src[PTR_W-1]) &&
    //                  (wr_ptr_bin_dst[PTR_W-2:0] == rd_ptr_bin_src[PTR_W-2:0])
    //
    // Let me verify: if DEPTH = 8 (LOG_DEPTH=3), PTR_W=4.
    // Empty: wr_ptr = 0, rd_ptr = 0. Not full.
    // After 8 writes: wr_ptr = 8 (1000), rd_ptr = 0 (0000). 
    //   wr_ptr[3]=1, rd_ptr[3]=0. Different. wr_ptr[2:0]=000, rd_ptr[2:0]=000. Same. => Full. Correct.
    // After 7 writes: wr_ptr = 7 (0111), rd_ptr = 0 (0000).
    //   wr_ptr[3]=0, rd_ptr[3]=0. Same. => Not full. Correct.
    //
    // So: full = (wr_ptr_bin_dst[PTR_W-1] != rd_ptr_bin_src[PTR_W-1]) &&
    //            (wr_ptr_bin_dst[PTR_W-2:0] == rd_ptr_bin_src[PTR_W-2:0])

    wire fifo_full = (wr_ptr_bin_dst[PTR_W-1] != rd_ptr_bin_src[PTR_W-1]) &&
                     (wr_ptr_bin_dst[PTR_W-2:0] == rd_ptr_bin_src[PTR_W-2:0]);

    // Empty condition: pointers are equal
    wire fifo_empty = (wr_ptr_bin_dst == rd_ptr_bin);

    // Source side: ready is high when not full
    assign src_ready_o = ~fifo_full;

    // Write to memory
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    integer k;

    wire do_write = src_valid_i & src_ready_o;

    always @(posedge src_clk_i) begin
        if (do_write)
            mem[wr_ptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
    end

    // Increment write pointer
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            wr_ptr_bin <= {PTR_W{1'b0}};
        else if (do_write)
            wr_ptr_bin <= wr_ptr_bin + 1'b1;
    end

    // Destination side: read from memory
    wire do_read = dst_valid_o & dst_ready_i;

    // dst_valid_o is high when not empty
    assign dst_valid_o = ~fifo_empty;

    // Output data
    assign dst_data_o = mem[rd_ptr_bin[LOG_DEPTH-1:0]];

    // Increment read pointer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            rd_ptr_bin <= {PTR_W{1'b0}};
        else if (do_read)
            rd_ptr_bin <= rd_ptr_bin + 1'b1;
    end

endmodule
