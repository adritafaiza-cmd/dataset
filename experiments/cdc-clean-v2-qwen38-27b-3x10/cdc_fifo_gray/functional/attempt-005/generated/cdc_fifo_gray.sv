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

    // Synchronizer for write pointer (src -> dst)
    reg [PTR_W-1:0] wr_ptr_sync [0:SYNC_STAGES-1];
    // Synchronizer for read pointer (dst -> src)
    reg [PTR_W-1:0] rd_ptr_sync [0:SYNC_STAGES-1];

    // Source domain logic
    wire src_wr_en = src_valid_i & src_ready_o;
    wire [PTR_W-1:0] src_wr_ptr_next = src_wr_ptr + 1'b1;

    // Full condition: write pointer catches up to read pointer (with wrap bit)
    wire src_full = (src_wr_ptr == {~dst_rd_ptr_src_sync[PTR_W-1], dst_rd_ptr_src_sync[PTR_W-1-1:0]});
    assign src_ready_o = ~src_full;

    // Write to memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
        end else if (src_wr_en) begin
            mem[src_wr_ptr[PTR_W-2:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr_next;
        end
    end

    // Synchronize write pointer to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_sync[0] <= {PTR_W{1'b0}};
            wr_ptr_sync[1] <= {PTR_W{1'b0}};
            for (int i = 2; i < SYNC_STAGES; i = i + 1)
                wr_ptr_sync[i] <= {PTR_W{1'b0}};
        end else begin
            wr_ptr_sync[0] <= src_wr_ptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wr_ptr_sync[i] <= wr_ptr_sync[i-1];
        end
    end

    assign src_wr_ptr_dst_sync = wr_ptr_sync[SYNC_STAGES-1];

    // Destination domain logic
    wire dst_rd_en = dst_valid_reg & dst_ready_i;
    wire [PTR_W-1:0] dst_rd_ptr_next = dst_rd_ptr + 1'b1;

    // Empty condition: read pointer equals write pointer
    wire dst_empty = (dst_rd_ptr == src_wr_ptr_dst_sync);

    // Load data when not empty and not currently valid (or after previous beat consumed)
    wire dst_load = ~dst_empty & ~dst_valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_load) begin
                dst_data_reg <= mem[dst_rd_ptr[PTR_W-2:0]];
                dst_valid_reg <= 1'b1;
                dst_rd_ptr <= dst_rd_ptr_next;
            end else if (dst_rd_en) begin
                dst_valid_reg <= 1'b0;
            end
        end
    end

    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    // Synchronize read pointer to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_ptr_sync[0] <= {PTR_W{1'b0}};
            rd_ptr_sync[1] <= {PTR_W{1'b0}};
            for (int i = 2; i < SYNC_STAGES; i = i + 1)
                rd_ptr_sync[i] <= {PTR_W{1'b0}};
        end else begin
            rd_ptr_sync[0] <= dst_rd_ptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rd_ptr_sync[i] <= rd_ptr_sync[i-1];
        end
    end

    assign dst_rd_ptr_src_sync = rd_ptr_sync[SYNC_STAGES-1];

endmodule
