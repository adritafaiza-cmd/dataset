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
    reg [PTR_W-1:0] dst_rd_ptr_src; // synchronized read pointer in src domain

    // Destination domain
    reg [WIDTH-1:0] dst_data_reg;
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] src_wr_ptr_dst; // synchronized write pointer in dst domain

    // Synchronization registers
    reg [PTR_W-1:0] src_wr_ptr_sync [0:SYNC_STAGES-1];
    reg [PTR_W-1:0] dst_rd_ptr_sync [0:SYNC_STAGES-1];

    // Full/Empty logic
    wire src_full;
    wire dst_empty;

    // Write pointer synchronization: src -> dst
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
        end else if (src_valid_i && src_ready_o) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1'b1;
        end
    end

    // Synchronize write pointer to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_sync[0] <= {PTR_W{1'b0}};
            src_wr_ptr_sync[1] <= {PTR_W{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    src_wr_ptr_sync[i] <= {PTR_W{1'b0}};
            end
        end else begin
            src_wr_ptr_sync[0] <= src_wr_ptr;
            src_wr_ptr_sync[1] <= src_wr_ptr_sync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    src_wr_ptr_sync[i] <= src_wr_ptr_sync[i-1];
            end
        end
    end

    assign src_wr_ptr_dst = src_wr_ptr_sync[SYNC_STAGES-1];

    // Read pointer synchronization: dst -> src
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
        end else if (dst_valid_o && dst_ready_i) begin
            dst_rd_ptr <= dst_rd_ptr + 1'b1;
        end
    end

    // Synchronize read pointer to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_sync[0] <= {PTR_W{1'b0}};
            dst_rd_ptr_sync[1] <= {PTR_W{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    dst_rd_ptr_sync[i] <= {PTR_W{1'b0}};
            end
        end else begin
            dst_rd_ptr_sync[0] <= dst_rd_ptr;
            dst_rd_ptr_sync[1] <= dst_rd_ptr_sync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    dst_rd_ptr_sync[i] <= dst_rd_ptr_sync[i-1];
            end
        end
    end

    assign dst_rd_ptr_src = dst_rd_ptr_sync[SYNC_STAGES-1];

    // Full: write pointer has lapped read pointer by DEPTH
    assign src_full = (src_wr_ptr[PTR_W-1:LOG_DEPTH] != dst_rd_ptr_src[PTR_W-1:LOG_DEPTH]) &&
                      (src_wr_ptr[LOG_DEPTH-1:0] == dst_rd_ptr_src[LOG_DEPTH-1:0]);

    // Empty: write pointer equals read pointer
    assign dst_empty = (src_wr_ptr_dst == dst_rd_ptr);

    // Ready and Valid
    assign src_ready_o = ~src_full;
    assign dst_valid_o = ~dst_empty;

    // Output data
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= {WIDTH{1'b0}};
        end else if (dst_valid_o) begin
            dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
        end
    end

    assign dst_data_o = dst_data_reg;

endmodule
