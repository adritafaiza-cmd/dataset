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
    reg [PTR_W-1:0] dst_rd_ptr_synced;
    reg [PTR_W-1:0] dst_rd_ptr_synced_d;

    // Destination domain
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] src_wr_ptr_synced;
    reg [PTR_W-1:0] src_wr_ptr_synced_d;
    reg [WIDTH-1:0] dst_data_reg;
    reg             dst_valid_reg;

    // Synchronizer registers for source write pointer to destination domain
    reg [SYNC_STAGES-1:0][PTR_W-1:0] src_wr_ptr_sync;
    // Synchronizer registers for destination read pointer to source domain
    reg [SYNC_STAGES-1:0][PTR_W-1:0] dst_rd_ptr_sync;

    // Source domain logic
    wire src_wr_en = src_valid_i & src_ready_o;
    wire [PTR_W-1:0] src_wr_ptr_next = src_wr_ptr + 1'b1;
    wire [PTR_W-1:0] src_wr_ptr_full = src_wr_ptr_next;
    wire [PTR_W-1:0] src_wr_ptr_empty = src_wr_ptr;
    
    // Full condition: write pointer catches up to read pointer (with extra bit)
    // For a FIFO of DEPTH entries, full when (wr_ptr - rd_ptr) == DEPTH
    // Using the extra bit: full when wr_ptr[LOG_DEPTH:0] == rd_ptr[LOG_DEPTH:0] and wr_ptr[LOG_DEPTH] != rd_ptr[LOG_DEPTH]
    // Actually, standard gray code FIFO full condition:
    // full when the upper bit differs and the lower bits are equal
    wire src_full = (src_wr_ptr_next[PTR_W-1] != dst_rd_ptr_synced[PTR_W-1]) && 
                    (src_wr_ptr_next[PTR_W-2:0] == dst_rd_ptr_synced[PTR_W-2:0]);
    
    assign src_ready_o = ~src_full;

    // Write to memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
        end else begin
            if (src_wr_en) begin
                mem[src_wr_ptr[PTR_W-2:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr_next;
            end
        end
    end

    // Synchronize source write pointer to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_sync[0] <= {PTR_W{1'b0}};
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_wr_ptr_sync[i] <= {PTR_W{1'b0}};
        end else begin
            src_wr_ptr_sync[0] <= src_wr_ptr;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_wr_ptr_sync[i] <= src_wr_ptr_sync[i-1];
        end
    end

    assign src_wr_ptr_synced = src_wr_ptr_sync[SYNC_STAGES-1];

    // Destination domain logic
    wire dst_rd_en = dst_valid_o & dst_ready_i;
    wire [PTR_W-1:0] dst_rd_ptr_next = dst_rd_ptr + 1'b1;
    
    // Empty condition: read pointer catches up to write pointer
    wire dst_empty = (dst_rd_ptr[PTR_W-1] != src_wr_ptr_synced[PTR_W-1]) && 
                     (dst_rd_ptr[PTR_W-2:0] == src_wr_ptr_synced[PTR_W-2:0]);
    
    // Actually, empty when pointers are equal
    wire dst_empty_correct = (dst_rd_ptr == src_wr_ptr_synced);

    // Read from memory
    wire [WIDTH-1:0] mem_rd_data = mem[dst_rd_ptr[PTR_W-2:0]];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_rd_en) begin
                dst_rd_ptr <= dst_rd_ptr_next;
                dst_valid_reg <= ~dst_empty_correct;
                if (~dst_empty_correct)
                    dst_data_reg <= mem[dst_rd_ptr_next[PTR_W-2:0]];
            end else if (~dst_valid_reg && ~dst_empty_correct) begin
                dst_valid_reg <= 1'b1;
                dst_data_reg <= mem_rd_data;
            end
        end
    end

    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    // Synchronize destination read pointer to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_sync[0] <= {PTR_W{1'b0}};
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_rd_ptr_sync[i] <= {PTR_W{1'b0}};
        end else begin
            dst_rd_ptr_sync[0] <= dst_rd_ptr;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_rd_ptr_sync[i] <= dst_rd_ptr_sync[i-1];
        end
    end

    assign dst_rd_ptr_synced = dst_rd_ptr_sync[SYNC_STAGES-1];

endmodule
