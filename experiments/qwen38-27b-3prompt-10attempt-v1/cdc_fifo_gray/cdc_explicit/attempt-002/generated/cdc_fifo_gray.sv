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
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] dst_rd_ptr_src_sync;

    // Destination domain
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] src_wr_ptr_dst_sync;
    reg [WIDTH-1:0] dst_data_reg;
    reg             dst_valid_reg;

    // Synchronizer registers for source write pointer to destination
    reg [PTR_W-1:0] src_wr_ptr_sync [0:SYNC_STAGES-1];
    // Synchronizer registers for destination read pointer to source
    reg [PTR_W-1:0] dst_rd_ptr_sync [0:SYNC_STAGES-1];

    // Source domain logic
    wire src_wr_en = src_valid_i & src_ready_o;
    wire [PTR_W-1:0] src_wr_ptr_next = src_wr_ptr + 1'b1;

    // Full condition: write pointer has lapped read pointer by DEPTH
    wire src_full = (src_wr_ptr_next[PTR_W-1:1] == dst_rd_ptr_src_sync[PTR_W-1:1]) &&
                    (src_wr_ptr_next[0] != dst_rd_ptr_src_sync[0]);
    // Actually, for a FIFO of size DEPTH, full when the upper bits match and lower bits differ
    // Let's use the standard gray code comparison or binary comparison
    // Using binary: full when (wr_ptr + 1) has same upper bits as rd_ptr but different lower bit
    // Actually simpler: full when (src_wr_ptr_next[PTR_W-1:1] == dst_rd_ptr_src_sync[PTR_W-1:1]) && (src_wr_ptr_next[0] != dst_rd_ptr_src_sync[0])
    // Wait, that's not right either. Let me think again.
    // For a FIFO with DEPTH entries, the pointers are PTR_W bits wide.
    // Full when the write pointer has advanced DEPTH positions beyond the read pointer.
    // In binary, this means the upper LOG_DEPTH bits are equal, and the lower bit differs.
    // Actually, the standard way: full when (wr_ptr[PTR_W-1:1] == rd_ptr[PTR_W-1:1]) && (wr_ptr[0] != rd_ptr[0])
    // But we need to compare the *next* write pointer with the read pointer.
    // So: full when (src_wr_ptr_next[PTR_W-1:1] == dst_rd_ptr_src_sync[PTR_W-1:1]) && (src_wr_ptr_next[0] != dst_rd_ptr_src_sync[0])
    // Hmm, let me reconsider. If DEPTH = 8, PTR_W = 4.
    // wr_ptr = 0000, rd_ptr = 0000 -> empty
    // wr_ptr = 1000, rd_ptr = 0000 -> full (8 entries)
    // So full when upper bits (bits 3:1) are equal and lower bit (bit 0) differs.
    // Yes, that's correct.

    assign src_ready_o = ~src_full;

    // Write to memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
        end else begin
            if (src_wr_en) begin
                mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr_next;
            end
        end
    end

    // Synchronize source write pointer to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_sync[0] <= {PTR_W{1'b0}};
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                src_wr_ptr_sync[i] <= {PTR_W{1'b0}};
            end
        end else begin
            src_wr_ptr_sync[0] <= src_wr_ptr;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                src_wr_ptr_sync[i] <= src_wr_ptr_sync[i-1];
            end
        end
    end

    assign src_wr_ptr_dst_sync = src_wr_ptr_sync[SYNC_STAGES-1];

    // Destination domain logic
    wire dst_rd_en = dst_valid_reg & dst_ready_i;
    wire [PTR_W-1:0] dst_rd_ptr_next = dst_rd_ptr + 1'b1;

    // Empty condition: read pointer equals write pointer
    wire dst_empty = (dst_rd_ptr == src_wr_ptr_dst_sync);

    // Output valid: we have data to output
    // dst_valid_o is high when there is data in the FIFO
    // We use a register to hold the output data and valid
    // When dst_valid_reg is low and dst_empty is low, we can load new data
    wire dst_load_en = ~dst_valid_reg & ~dst_empty;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_load_en) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_valid_reg <= 1'b1;
                dst_rd_ptr <= dst_rd_ptr_next;
            end else if (dst_rd_en) begin
                dst_valid_reg <= 1'b0;
            end
        end
    end

    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    // Synchronize destination read pointer to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_sync[0] <= {PTR_W{1'b0}};
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                dst_rd_ptr_sync[i] <= {PTR_W{1'b0}};
            end
        end else begin
            dst_rd_ptr_sync[0] <= dst_rd_ptr;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                dst_rd_ptr_sync[i] <= dst_rd_ptr_sync[i-1];
            end
        end
    end

    assign dst_rd_ptr_src_sync = dst_rd_ptr_sync[SYNC_STAGES-1];

endmodule
