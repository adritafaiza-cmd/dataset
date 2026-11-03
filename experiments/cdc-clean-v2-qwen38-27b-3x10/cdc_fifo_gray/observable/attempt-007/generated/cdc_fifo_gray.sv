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

    // Storage
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Source side pointers
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] src_rd_ptr_sync; // synchronized read pointer (binary)

    // Destination side pointers
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] dst_wr_ptr_sync; // synchronized write pointer (binary)

    // Gray code pointers
    wire [PTR_W-1:0] src_wr_ptr_gray = src_wr_ptr ^ (src_wr_ptr >> 1);
    wire [PTR_W-1:0] dst_rd_ptr_gray = dst_rd_ptr ^ (dst_rd_ptr >> 1);

    // Synchronize gray pointers across clock domains
    reg [PTR_W-1:0] src_wr_ptr_gray_sync [0:SYNC_STAGES-1];
    reg [PTR_W-1:0] dst_rd_ptr_gray_sync [0:SYNC_STAGES-1];

    // Synchronize binary pointers for full/empty detection
    // We need to synchronize the binary read pointer to source domain
    // and binary write pointer to destination domain
    // But standard approach: use gray code for CDC, then convert back to binary
    // for full/empty check. However, converting gray to binary in the
    // receiving domain after sync is safe because the pointer only changes
    // by 1 at a time.

    // Actually, the standard approach for async FIFO with valid/ready:
    // - Use gray code pointers for CDC
    // - In source domain: full = (src_wr_ptr_gray == dst_rd_ptr_gray_synced) && (src_wr_ptr[PTR_W-1] != dst_rd_ptr_synced[PTR_W-1])
    //   Wait, that's not quite right. Let me think more carefully.

    // Standard async FIFO full/empty:
    // Full: write pointer has lapped read pointer. In gray code:
    //   full = (wr_gray == rd_gray_synced) && (wr_ptr[MSB] != rd_ptr_synced[MSB])
    //   where rd_ptr_synced is the binary value reconstructed from gray.
    //
    // Actually, a simpler and correct approach:
    // Synchronize the gray code pointers. Then in each domain, compare
    // the local gray pointer with the synchronized remote gray pointer.
    //
    // Full (source domain): src_wr_ptr_gray == dst_rd_ptr_gray_synced[SYNC_STAGES-1]
    //   AND the MSB of src_wr_ptr != MSB of the binary equivalent of dst_rd_ptr_gray_synced
    //
    // This is getting complex. Let me use a cleaner approach:
    // Synchronize the binary pointers using gray code as the transport,
    // then convert back to binary in the receiving domain.

    // Gray to binary conversion
    function [PTR_W-1:0] gray2bin;
        input [PTR_W-1:0] gray;
        integer i;
        begin
            gray2bin[PTR_W-1] = gray[PTR_W-1];
            for (i = PTR_W-2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Synchronize src_wr_ptr_gray to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_wr_ptr_gray_sync[0] <= {PTR_W{1'b0}};
        else
            src_wr_ptr_gray_sync[0] <= src_wr_ptr_gray;
    end

    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : gen_src_wr_sync
            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni)
                    src_wr_ptr_gray_sync[i] <= {PTR_W{1'b0}};
                else
                    src_wr_ptr_gray_sync[i] <= src_wr_ptr_gray_sync[i-1];
            end
        end
    endgenerate

    // Synchronize dst_rd_ptr_gray to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_rd_ptr_gray_sync[0] <= {PTR_W{1'b0}};
        else
            dst_rd_ptr_gray_sync[0] <= dst_rd_ptr_gray;
    end

    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : gen_dst_rd_sync
            always @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni)
                    dst_rd_ptr_gray_sync[i] <= {PTR_W{1'b0}};
                else
                    dst_rd_ptr_gray_sync[i] <= dst_rd_ptr_gray_sync[i-1];
            end
        end
    endgenerate

    // Convert synchronized gray to binary
    wire [PTR_W-1:0] dst_rd_ptr_synced = gray2bin(dst_rd_ptr_gray_sync[SYNC_STAGES-1]);
    wire [PTR_W-1:0] src_wr_ptr_synced = gray2bin(src_wr_ptr_gray_sync[SYNC_STAGES-1]);

    // Full/Empty detection
    // Full: write pointer has lapped read pointer
    // In terms of binary pointers with extra MSB:
    // full = (src_wr_ptr[PTR_W-1] != dst_rd_ptr_synced[PTR_W-1]) &&
    //        (src_wr_ptr[PTR_W-2:0] == dst_rd_ptr_synced[PTR_W-2:0])
    // empty = (dst_rd_ptr == src_wr_ptr_synced)

    wire src_full = (src_wr_ptr[PTR_W-1] != dst_rd_ptr_synced[PTR_W-1]) &&
                    (src_wr_ptr[PTR_W-2:0] == dst_rd_ptr_synced[PTR_W-2:0]);

    wire dst_empty = (dst_rd_ptr == src_wr_ptr_synced);

    // Source side: write when valid and not full
    wire src_write = src_valid_i && !src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_wr_ptr <= {PTR_W{1'b0}};
        else if (src_write)
            src_wr_ptr <= src_wr_ptr + 1'b1;
    end

    always @(posedge src_clk_i) begin
        if (src_write)
            mem[src_wr_ptr[PTR_W-2:0]] <= src_data_i;
    end

    assign src_ready_o = !src_full;

    // Destination side: read when ready and not empty
    wire dst_read = dst_ready_i && !dst_empty;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_rd_ptr <= {PTR_W{1'b0}};
        else if (dst_read)
            dst_rd_ptr <= dst_rd_ptr + 1'b1;
    end

    assign dst_data_o = mem[dst_rd_ptr[PTR_W-2:0]];
    assign dst_valid_o = !dst_empty;

endmodule
