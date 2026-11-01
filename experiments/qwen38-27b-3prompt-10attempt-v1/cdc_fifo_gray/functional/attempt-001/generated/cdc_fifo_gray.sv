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
    reg [PTR_W-1:0] src_rd_ptr_synced;

    // Destination domain
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] dst_wr_ptr_synced;

    // Synchronizer registers for write pointer (src -> dst)
    reg [PTR_W-1:0] wr_ptr_sync [0:SYNC_STAGES-1];

    // Synchronizer registers for read pointer (dst -> src)
    reg [PTR_W-1:0] rd_ptr_sync [0:SYNC_STAGES-1];

    // Write enable
    wire src_wr_en = src_valid_i & src_ready_o;

    // Read enable
    wire dst_rd_en = dst_valid_o & dst_ready_i;

    // Full condition: write pointer has lapped read pointer by DEPTH
    wire src_full = (src_wr_ptr[PTR_W-1] != src_rd_ptr_synced[PTR_W-1]) &&
                    (src_wr_ptr[LOG_DEPTH-1:0] == src_rd_ptr_synced[LOG_DEPTH-1:0]);

    // Empty condition: write pointer equals read pointer
    wire dst_empty = (dst_rd_ptr == dst_wr_ptr_synced);

    // Ready and valid
    assign src_ready_o = ~src_full;
    assign dst_valid_o = ~dst_empty;

    // Write to memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
        end else if (src_wr_en) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1'b1;
        end
    end

    // Read from memory
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_data_o <= {WIDTH{1'b0}};
        end else if (dst_rd_en) begin
            dst_data_o <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
            dst_rd_ptr <= dst_rd_ptr + 1'b1;
        end
    end

    // Synchronize write pointer from src to dst
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
            wr_ptr_sync[0] <= src_wr_ptr;
            wr_ptr_sync[1] <= wr_ptr_sync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    wr_ptr_sync[i] <= wr_ptr_sync[i-1];
            end
        end
    end

    assign dst_wr_ptr_synced = wr_ptr_sync[SYNC_STAGES-1];

    // Synchronize read pointer from dst to src
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
            rd_ptr_sync[0] <= dst_rd_ptr;
            rd_ptr_sync[1] <= rd_ptr_sync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    rd_ptr_sync[i] <= rd_ptr_sync[i-1];
            end
        end
    end

    assign src_rd_ptr_synced = rd_ptr_sync[SYNC_STAGES-1];

endmodule
