// =============================================================================
// cdc_fifo_2phase.v
// =============================================================================
//
// 2-phase CDC FIFO with valid/ready handshake.
//
// Architecture:
//   - Gray-coded binary pointers for safe CDC (1-bit change per increment).
//   - 2-stage synchronizer per pointer (src->dst and dst->src).
//   - Multi-bit data is NOT synchronized; it is read from the FIFO in the
//     destination domain using the synchronized write pointer.
//   - dst_valid_o is registered (2-phase): a beat is only advertised as valid
//     one dst_clk after it has been read from the FIFO.
//   - src_ready_o is registered (2-phase): the source is only told "ready"
//     one src_clk after the FIFO has space.
//
// =============================================================================

`timescale 1ns / 1ps

module cdc_fifo_2phase #(
    parameter WIDTH     = 8,
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

    // =========================================================================
    // Source domain
    // =========================================================================

    reg [PTR_W-1:0] src_wr_ptr_bin;
    wire [PTR_W-1:0] src_wr_ptr_gray;

    reg [PTR_W-1:0] dst_rd_ptr_gray_synced;  // dst read ptr synchronized to src

    wire src_wr_en = src_valid_i & src_ready_o;
    wire src_full  = (src_wr_ptr_bin == {~dst_rd_ptr_gray_synced[PTR_W-1],
                                          dst_rd_ptr_gray_synced[PTR_W-2:0]});

    // Registered ready: one src_clk after FIFO has space
    reg src_ready_r;
    assign src_ready_o = src_ready_r;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_bin <= {PTR_W{1'b0}};
            src_ready_r    <= 1'b0;
        end else begin
            if (src_wr_en)
                src_wr_ptr_bin <= src_wr_ptr_bin + 1'b1;
            src_ready_r <= !src_full;
        end
    end

    // Gray code conversion
    assign src_wr_ptr_gray = src_wr_ptr_bin ^ (src_wr_ptr_bin >> 1);

    // =========================================================================
    // Destination domain
    // =========================================================================

    reg [PTR_W-1:0] dst_rd_ptr_bin;
    wire [PTR_W-1:0] dst_rd_ptr_gray;

    reg [PTR_W-1:0] src_wr_ptr_gray_synced;  // src write ptr synchronized to dst

    wire dst_rd_en = dst_valid_o & dst_ready_i;
    wire dst_empty = (dst_rd_ptr_bin == src_wr_ptr_gray_synced);

    // Registered valid: one dst_clk after FIFO has data
    reg dst_valid_r;
    assign dst_valid_o = dst_valid_r;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_bin <= {PTR_W{1'b0}};
            dst_valid_r    <= 1'b0;
        end else begin
            if (dst_rd_en)
                dst_rd_ptr_bin <= dst_rd_ptr_bin + 1'b1;
            dst_valid_r <= !dst_empty;
        end
    end

    // Gray code conversion
    assign dst_rd_ptr_gray = dst_rd_ptr_bin ^ (dst_rd_ptr_bin >> 1);

    // =========================================================================
    // FIFO storage (read in destination domain)
    // =========================================================================

    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Write in source domain
    always @(posedge src_clk_i) begin
        if (src_wr_en)
            mem[src_wr_ptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
    end

    // Read in destination domain
    wire [WIDTH-1:0] dst_data_r;
    assign dst_data_r = mem[dst_rd_ptr_bin[LOG_DEPTH-1:0]];

    // Registered output data
    reg [WIDTH-1:0] dst_data_r2;
    assign dst_data_o = dst_data_r2;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_data_r2 <= {WIDTH{1'b0}};
        else if (!dst_empty)
            dst_data_r2 <= dst_data_r;
    end

    // =========================================================================
    // CDC: src_wr_ptr_gray -> dst domain (2-stage synchronizer)
    // =========================================================================

    reg [PTR_W-1:0] wr_gray_sync [0:1];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_gray_sync[0] <= {PTR_W{1'b0}};
            wr_gray_sync[1] <= {PTR_W{1'b0}};
        end else begin
            wr_gray_sync[0] <= src_wr_ptr_gray;
            wr_gray_sync[1] <= wr_gray_sync[0];
        end
    end

    assign src_wr_ptr_gray_synced = wr_gray_sync[1];

    // =========================================================================
    // CDC: dst_rd_ptr_gray -> src domain (2-stage synchronizer)
    // =========================================================================

    reg [PTR_W-1:0] rd_gray_sync [0:1];

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_gray_sync[0] <= {PTR_W{1'b0}};
            rd_gray_sync[1] <= {PTR_W{1'b0}};
        end else begin
            rd_gray_sync[0] <= dst_rd_ptr_gray;
            rd_gray_sync[1] <= rd_gray_sync[0];
        end
    end

    assign dst_rd_ptr_gray_synced = rd_gray_sync[1];

endmodule