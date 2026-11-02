// =============================================================================
// cdc_fifo_gray_clearable.v
// =============================================================================
// Clearable valid/ready asynchronous FIFO.
//
//   * Standard Gray-coded async FIFO (Cummings) with a valid/ready handshake
//     on both sides.
//   * src_clear_i / dst_clear_i request a flush: isolate both sides, drop
//     stored and in-flight data, then return to empty.
//   * *_clear_pending_o stays high until that side finishes.
//   * Clear and reset must not create a destination beat.
//   * The destination word is one registered sample. dst_valid_o may fall for
//     one destination clock after an accepted beat even when another word is
//     stored.
//   * A clear resets each binary pointer and the Gray register that feeds its
//     synchronizer on the same edge.
// =============================================================================

`timescale 1ns / 1ps

module cdc_fifo_gray_clearable #(
    parameter WIDTH       = 8,
    parameter LOG_DEPTH   = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,

    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,

    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,

    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;

    // =========================================================================
    // Source domain
    // =========================================================================

    reg [LOG_DEPTH:0] src_wr_ptr_bin;
    reg [LOG_DEPTH:0] src_wr_ptr_gray;

    reg [LOG_DEPTH:0] src_rd_ptr_gray_synced;

    reg [WIDTH-1:0]   mem [0:DEPTH-1];

    reg               src_clear_pending;

    wire              src_wr_en;
    wire              src_full;

    assign src_ready_o         = !src_full && !src_clear_pending;
    assign src_clear_pending_o = src_clear_pending;

    assign src_full = (src_wr_ptr_bin == {~src_rd_ptr_gray_synced[LOG_DEPTH:LOG_DEPTH-1],
                                           src_rd_ptr_gray_synced[LOG_DEPTH-1:0]});

    assign src_wr_en = src_valid_i && src_ready_o;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_bin     <= {(LOG_DEPTH+1){1'b0}};
            src_wr_ptr_gray    <= {(LOG_DEPTH+1){1'b0}};
            src_clear_pending  <= 1'b0;
        end else if (src_clear_i) begin
            src_wr_ptr_bin     <= {(LOG_DEPTH+1){1'b0}};
            src_wr_ptr_gray    <= {(LOG_DEPTH+1){1'b0}};
            src_clear_pending  <= 1'b1;
        end else if (src_wr_en) begin
            src_wr_ptr_bin     <= src_wr_ptr_bin + 1'b1;
            src_wr_ptr_gray    <= (src_wr_ptr_bin + 1'b1) ^ src_wr_ptr_bin;
        end
    end

    always @(posedge src_clk_i) begin
        if (src_wr_en)
            mem[src_wr_ptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
    end

    // =========================================================================
    // Destination domain
    // =========================================================================

    reg [LOG_DEPTH:0] dst_rd_ptr_bin;
    reg [LOG_DEPTH:0] dst_rd_ptr_gray;

    reg [LOG_DEPTH:0] dst_wr_ptr_gray_synced;

    reg               dst_clear_pending;

    wire              dst_rd_en;
    wire              dst_empty;

    assign dst_valid_o         = !dst_empty && !dst_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

    assign dst_empty = (dst_rd_ptr_bin == dst_wr_ptr_gray_synced);

    assign dst_rd_en = dst_valid_o && dst_ready_i;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_bin     <= {(LOG_DEPTH+1){1'b0}};
            dst_rd_ptr_gray    <= {(LOG_DEPTH+1){1'b0}};
            dst_clear_pending  <= 1'b0;
        end else if (dst_clear_i) begin
            dst_rd_ptr_bin     <= {(LOG_DEPTH+1){1'b0}};
            dst_rd_ptr_gray    <= {(LOG_DEPTH+1){1'b0}};
            dst_clear_pending  <= 1'b1;
        end else if (dst_rd_en) begin
            dst_rd_ptr_bin     <= dst_rd_ptr_bin + 1'b1;
            dst_rd_ptr_gray    <= (dst_rd_ptr_bin + 1'b1) ^ dst_rd_ptr_bin;
        end
    end

    // =========================================================================
    // Synchronizers
    // =========================================================================

    (* ASYNC_REG = "TRUE" *)
    reg [SYNC_STAGES-1:0][LOG_DEPTH:0] src_rd_ptr_gray_sync;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_rd_ptr_gray_sync <= {(SYNC_STAGES*(LOG_DEPTH+1)){1'b0}};
        else begin
            src_rd_ptr_gray_sync[0] <= dst_rd_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_rd_ptr_gray_sync[i] <= src_rd_ptr_gray_sync[i-1];
        end
    end

    assign src_rd_ptr_gray_synced = src_rd_ptr_gray_sync[SYNC_STAGES-1];

    (* ASYNC_REG = "TRUE" *)
    reg [SYNC_STAGES-1:0][LOG_DEPTH:0] dst_wr_ptr_gray_sync;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_wr_ptr_gray_sync <= {(SYNC_STAGES*(LOG_DEPTH+1)){1'b0}};
        else begin
            dst_wr_ptr_gray_sync[0] <= src_wr_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_wr_ptr_gray_sync[i] <= dst_wr_ptr_gray_sync[i-1];
        end
    end

    assign dst_wr_ptr_gray_synced = dst_wr_ptr_gray_sync[SYNC_STAGES-1];

    // =========================================================================
    // Clear-pending release
    // =========================================================================

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_clear_pending <= 1'b0;
        else if (src_clear_pending && src_rd_ptr_gray_synced == {(LOG_DEPTH+1){1'b0}})
            src_clear_pending <= 1'b0;
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_clear_pending <= 1'b0;
        else if (dst_clear_pending && dst_wr_ptr_gray_synced == {(LOG_DEPTH+1){1'b0}})
            dst_clear_pending <= 1'b0;
    end

    // =========================================================================
    // Destination output register
    // =========================================================================

    reg [WIDTH-1:0] dst_data_reg;
    reg             dst_valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg  <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else if (dst_rd_en) begin
            dst_data_reg  <= mem[dst_rd_ptr_bin[LOG_DEPTH-1:0]];
            dst_valid_reg <= 1'b1;
        end else if (dst_clear_i) begin
            dst_valid_reg <= 1'b0;
        end
    end

    assign dst_data_o  = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule