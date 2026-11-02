// =============================================================================
// cdc_fifo_2phase.v
// =============================================================================
//
// 2-phase Gray-coded asynchronous FIFO (valid/ready interface).
//
//   - WIDTH      : payload width in bits
//   - LOG_DEPTH  : log2 of FIFO depth (depth = 2**LOG_DEPTH)
//
//   src_rst_ni / src_clk_i : source (write) clock domain
//   dst_rst_ni / dst_clk_i : destination (read) clock domain
//
//   src_valid_i / src_ready_o : source handshake
//   dst_valid_o / dst_ready_i : destination handshake
//
//   src_data_i  : source payload (sampled when src_valid_i & src_ready_o)
//   dst_data_o  : destination payload (valid when dst_valid_o)
//
// =============================================================================

`include "cdc_fifo_2phase.vh"

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

    // =====================================================================
    //  Storage
    // =====================================================================

    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // =====================================================================
    //  Source (write) domain
    // =====================================================================

    reg [LOG_DEPTH:0] wptr_bin;
    reg [LOG_DEPTH:0] wptr_gray;
    reg [LOG_DEPTH:0] rptr_gray_src;

    wire [LOG_DEPTH:0] wptr_gray_next = wptr_bin + 1'b1 ^ wptr_bin;

    wire wfull = (wptr_gray_next == rptr_gray_src) &&
                 (wptr_bin[LOG_DEPTH] != rptr_gray_src[LOG_DEPTH]);

    assign src_ready_o = !wfull;

    wire winc = src_valid_i & src_ready_o;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wptr_bin  <= {(LOG_DEPTH+1){1'b0}};
            wptr_gray <= {(LOG_DEPTH+1){1'b0}};
        end else if (winc) begin
            wptr_bin  <= wptr_bin + 1'b1;
            wptr_gray <= wptr_gray_next;
        end
    end

    always @(posedge src_clk_i) begin
        if (winc)
            mem[wptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
    end

    // =====================================================================
    //  Destination (read) domain
    // =====================================================================

    reg [LOG_DEPTH:0] rptr_bin;
    reg [LOG_DEPTH:0] rptr_gray;
    reg [LOG_DEPTH:0] wptr_gray_dst;

    wire [LOG_DEPTH:0] rptr_gray_next = rptr_bin + 1'b1 ^ rptr_bin;

    wire rempty = (rptr_bin == wptr_gray_dst);

    assign dst_valid_o = !rempty;

    wire rinc = dst_valid_o & dst_ready_i;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rptr_bin  <= {(LOG_DEPTH+1){1'b0}};
            rptr_gray <= {(LOG_DEPTH+1){1'b0}};
        end else if (rinc) begin
            rptr_bin  <= rptr_bin + 1'b1;
            rptr_gray <= rptr_gray_next;
        end
    end

    assign dst_data_o = mem[rptr_bin[LOG_DEPTH-1:0]];

    // =====================================================================
    //  CDC synchronizers (2-stage, reset to 0)
    // =====================================================================

    cdc_sync_2phase #(
        .WIDTH (LOG_DEPTH + 1),
        .RESET (0)
    ) u_sync_wptr (
        .rst_ni (dst_rst_ni),
        .clk_i  (dst_clk_i),
        .data_i (wptr_gray),
        .data_o (wptr_gray_dst)
    );

    cdc_sync_2phase #(
        .WIDTH (LOG_DEPTH + 1),
        .RESET (0)
    ) u_sync_rptr (
        .rst_ni (src_rst_ni),
        .clk_i  (src_clk_i),
        .data_i (rptr_gray),
        .data_o (rptr_gray_src)
    );

endmodule