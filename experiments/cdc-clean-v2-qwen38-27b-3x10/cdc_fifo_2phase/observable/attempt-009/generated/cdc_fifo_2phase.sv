module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
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

    // Source domain registers
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] dst_rd_ptr_src;
    reg [PTR_W-1:0] dst_rd_ptr_src_d1;
    reg [PTR_W-1:0] dst_rd_ptr_src_d2;

    // Destination domain registers
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] src_wr_ptr_dst;
    reg [PTR_W-1:0] src_wr_ptr_dst_d1;
    reg [PTR_W-1:0] src_wr_ptr_dst_d2;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // Source domain: write pointer and read pointer (synchronized from dst)
    wire src_full = (src_wr_ptr == dst_rd_ptr_src_d2);
    wire src_can_write = src_valid_i && !src_full;

    assign src_ready_o = !src_full;

    // Write to memory in source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
        end else if (src_can_write) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1'b1;
        end
    end

    // Synchronize dst_rd_ptr to source domain (2-stage)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_src_d1 <= {PTR_W{1'b0}};
            dst_rd_ptr_src_d2 <= {PTR_W{1'b0}};
        end else begin
            dst_rd_ptr_src_d1 <= dst_rd_ptr_src;
            dst_rd_ptr_src_d2 <= dst_rd_ptr_src_d1;
        end
    end

    // Destination domain: read pointer and write pointer (synchronized from src)
    wire dst_empty = (dst_rd_ptr == src_wr_ptr_dst_d2);
    wire dst_can_read = dst_ready_i && !dst_empty;

    // Synchronize src_wr_ptr to destination domain (2-stage)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_dst_d1 <= {PTR_W{1'b0}};
            src_wr_ptr_dst_d2 <= {PTR_W{1'b0}};
        end else begin
            src_wr_ptr_dst_d1 <= src_wr_ptr_dst;
            src_wr_ptr_dst_d2 <= src_wr_ptr_dst_d1;
        end
    end

    // Destination domain: read from memory and update read pointer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_can_read) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
                dst_valid_reg <= 1'b1;
            end else if (dst_valid_reg && dst_ready_i) begin
                dst_valid_reg <= 1'b0;
            end
        end
    end

    // Output
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    // Cross-domain pointer synchronization:
    // src_wr_ptr is in src domain, needs to be synchronized to dst domain
    // dst_rd_ptr is in dst domain, needs to be synchronized to src domain
    // We use the raw pointers for synchronization

    // src_wr_ptr_dst is the value of src_wr_ptr as seen in dst domain (synchronized)
    // We need to assign src_wr_ptr_dst from src_wr_ptr via synchronization
    // But src_wr_ptr is in src domain. We need to synchronize it to dst domain.
    // The synchronization registers src_wr_ptr_dst_d1 and src_wr_ptr_dst_d2 are in dst domain.
    // We need to feed src_wr_ptr into the first stage. But src_wr_ptr is in src domain.
    // This is a cross-domain assignment. In Verilog, we can do this by having
    // the dst domain registers sample the src domain signal. This is the standard
    // 2-phase CDC approach.

    // Actually, the standard approach is:
    // - In src domain: have a register that holds src_wr_ptr (already done)
    // - In dst domain: have 2-stage synchronizer that samples src_wr_ptr
    // The assignment src_wr_ptr_dst <= src_wr_ptr is a cross-domain assignment.
    // This is valid in Verilog synthesis as it creates a synchronizer.

    // Let me restructure: the synchronizer registers should sample the source signal.
    // src_wr_ptr_dst_d1 samples src_wr_ptr (cross-domain)
    // src_wr_ptr_dst_d2 samples src_wr_ptr_dst_d1 (same domain)

    // Similarly for dst_rd_ptr:
    // dst_rd_ptr_src_d1 samples dst_rd_ptr (cross-domain)
    // dst_rd_ptr_src_d2 samples dst_rd_ptr_src_d1 (same domain)

    // The above code already does this correctly. The cross-domain assignments
    // are:
    //   src_wr_ptr_dst_d1 <= src_wr_ptr;  (dst domain sampling src domain signal)
    //   dst_rd_ptr_src_d1 <= dst_rd_ptr;  (src domain sampling dst domain signal)

    // But in my code above, I have:
    //   src_wr_ptr_dst_d1 <= src_wr_ptr_dst;  -- this is wrong, should be src_wr_ptr
    //   dst_rd_ptr_src_d1 <= dst_rd_ptr_src;  -- this is wrong, should be dst_rd_ptr

    // Let me fix this. I need to remove the intermediate registers and directly
    // synchronize the source signals.

endmodule

module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
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

    // Destination domain
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // Synchronizer registers
    // dst_rd_ptr synchronized to src domain
    reg [PTR_W-1:0] dst_rd_ptr_sync1;
    reg [PTR_W-1:0] dst_rd_ptr_sync2;

    // src_wr_ptr synchronized to dst domain
    reg [PTR_W-1:0] src_wr_ptr_sync1;
    reg [PTR_W-1:0] src_wr_ptr_sync2;

    // Source domain logic
    wire src_full = (src_wr_ptr == dst_rd_ptr_sync2);
    wire src_can_write = src_valid_i && !src_full;

    assign src_ready_o = !src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
        end else if (src_can_write) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1'b1;
        end
    end

    // Synchronize dst_rd_ptr to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_sync1 <= {PTR_W{1'b0}};
            dst_rd_ptr_sync2 <= {PTR_W{1'b0}};
        end else begin
            dst_rd_ptr_sync1 <= dst_rd_ptr;
            dst_rd_ptr_sync2 <= dst_rd_ptr_sync1;
        end
    end

    // Destination domain logic
    wire dst_empty = (dst_rd_ptr == src_wr_ptr_sync2);
    wire dst_can_read = dst_ready_i && !dst_empty;

    // Synchronize src_wr_ptr to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_sync1 <= {PTR_W{1'b0}};
            src_wr_ptr_sync2 <= {PTR_W{1'b0}};
        end else begin
            src_wr_ptr_sync1 <= src_wr_ptr;
            src_wr_ptr_sync2 <= src_wr_ptr_sync1;
        end
    end

    // Destination domain: read and output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_can_read) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
                dst_valid_reg <= 1'b1;
            end else if (dst_valid_reg && dst_ready_i) begin
                dst_valid_reg <= 1'b0;
            end
        end
    end

    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
