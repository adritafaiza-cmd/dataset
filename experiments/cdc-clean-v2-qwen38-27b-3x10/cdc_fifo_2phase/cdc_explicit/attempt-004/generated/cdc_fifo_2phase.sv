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
    localparam PTR_W = LOG_DEPTH;
    localparam FULL_PTR_W = LOG_DEPTH + 1;

    // Source domain: write pointer and FIFO storage
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [FULL_PTR_W-1:0] wptr;
    reg [FULL_PTR_W-1:0] rptr_src_sync;

    // Destination domain: read pointer
    reg [FULL_PTR_W-1:0] rptr;
    reg [FULL_PTR_W-1:0] wptr_dst_sync;

    // Synchronization registers for write pointer to destination domain
    reg [FULL_PTR_W-1:0] wptr_sync1;
    reg [FULL_PTR_W-1:0] wptr_sync2;

    // Synchronization registers for read pointer to source domain
    reg [FULL_PTR_W-1:0] rptr_sync1;
    reg [FULL_PTR_W-1:0] rptr_sync2;

    // Destination domain: two-stage pipeline for data and valid
    reg [WIDTH-1:0] stage1_data;
    reg             stage1_valid;
    reg [WIDTH-1:0] stage2_data;
    reg             stage2_valid;

    // Compute full and empty conditions
    wire full = (wptr == {rptr_src_sync[PTR_W-1:0], ~rptr_src_sync[FULL_PTR_W-1]});
    wire empty = (wptr == rptr_src_sync);

    // Source ready: not full
    assign src_ready_o = ~full;

    // Write to FIFO in source domain
    wire src_write = src_valid_i & src_ready_o;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wptr <= {FULL_PTR_W{1'b0}};
        end else if (src_write) begin
            mem[wptr[PTR_W-1:0]] <= src_data_i;
            wptr <= wptr + 1'b1;
        end
    end

    // Synchronize read pointer to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rptr_sync1 <= {FULL_PTR_W{1'b0}};
            rptr_sync2 <= {FULL_PTR_W{1'b0}};
        end else begin
            rptr_sync1 <= rptr;
            rptr_sync2 <= rptr_sync1;
        end
    end

    assign rptr_src_sync = rptr_sync2;

    // Synchronize write pointer to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wptr_sync1 <= {FULL_PTR_W{1'b0}};
            wptr_sync2 <= {FULL_PTR_W{1'b0}};
        end else begin
            wptr_sync1 <= wptr;
            wptr_sync2 <= wptr_sync1;
        end
    end

    assign wptr_dst_sync = wptr_sync2;

    // Destination domain: read from FIFO and pipeline
    wire dst_not_empty = (rptr != wptr_dst_sync);
    wire dst_read = dst_not_empty & dst_ready_i;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rptr <= {FULL_PTR_W{1'b0}};
            stage1_data <= {WIDTH{1'b0}};
            stage1_valid <= 1'b0;
            stage2_data <= {WIDTH{1'b0}};
            stage2_valid <= 1'b0;
        end else begin
            // Stage 2: output stage
            stage2_data <= stage1_data;
            stage2_valid <= stage1_valid;

            // Stage 1: read from FIFO if there's data and we're ready to accept
            if (dst_read) begin
                stage1_data <= mem[rptr[PTR_W-1:0]];
                stage1_valid <= 1'b1;
                rptr <= rptr + 1'b1;
            end else begin
                stage1_valid <= 1'b0;
            end
        end
    end

    assign dst_data_o = stage2_data;
    assign dst_valid_o = stage2_valid;

endmodule
