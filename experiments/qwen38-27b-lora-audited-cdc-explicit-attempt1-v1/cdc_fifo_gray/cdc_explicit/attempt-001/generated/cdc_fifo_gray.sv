// =============================================================================
// cdc_fifo_gray.v
// =============================================================================
// Asynchronous FIFO with Gray-coded pointers for safe CDC.
// =============================================================================

`timescale 1ns / 1ps

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

    // ========================================================================
    // Source domain
    // ========================================================================
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    reg [PTR_W-1:0] src_wr_ptr_bin;
    reg [PTR_W-1:0] src_wr_ptr_gray;
    reg [PTR_W-1:0] src_rd_ptr_gray;

    wire [PTR_W-1:0] src_wr_ptr_gray_next = src_wr_ptr_bin ^ (src_wr_ptr_bin >> 1);

    wire src_wr_en = src_valid_i & src_ready_o;
    wire src_full  = (src_wr_ptr_gray_next == src_rd_ptr_gray);
    assign src_ready_o = ~src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_bin   <= {PTR_W{1'b0}};
            src_wr_ptr_gray  <= {PTR_W{1'b0}};
            src_rd_ptr_gray  <= {PTR_W{1'b0}};
        end else begin
            if (src_wr_en) begin
                mem[src_wr_ptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr_bin  <= src_wr_ptr_bin + 1'b1;
                src_wr_ptr_gray <= src_wr_ptr_gray_next;
            end
            if (src_rd_ptr_gray != src_rd_ptr_gray_synced)
                src_rd_ptr_gray <= src_rd_ptr_gray_synced;
        end
    end

    // ========================================================================
    // Destination domain
    // ========================================================================
    reg [PTR_W-1:0] dst_rd_ptr_bin;
    reg [PTR_W-1:0] dst_rd_ptr_gray;
    reg [PTR_W-1:0] dst_wr_ptr_gray;

    wire [PTR_W-1:0] dst_rd_ptr_gray_next = dst_rd_ptr_bin ^ (dst_rd_ptr_bin >> 1);

    wire dst_rd_en = dst_valid_o & dst_ready_i;
    wire dst_empty  = (dst_rd_ptr_gray == dst_wr_ptr_gray);
    assign dst_valid_o = ~dst_empty;
    assign dst_data_o  = mem[dst_rd_ptr_bin[LOG_DEPTH-1:0]];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_bin   <= {PTR_W{1'b0}};
            dst_rd_ptr_gray  <= {PTR_W{1'b0}};
            dst_wr_ptr_gray  <= {PTR_W{1'b0}};
        end else begin
            if (dst_rd_en) begin
                dst_rd_ptr_bin  <= dst_rd_ptr_bin + 1'b1;
                dst_rd_ptr_gray <= dst_rd_ptr_gray_next;
            end
            if (dst_wr_ptr_gray != dst_wr_ptr_gray_synced)
                dst_wr_ptr_gray <= dst_wr_ptr_gray_synced;
        end
    end

    // ========================================================================
    // Synchronizers
    // ========================================================================
    (* ASYNC_REG = "TRUE" *)
    reg [SYNC_STAGES-1:0][PTR_W-1:0] wr_ptr_sync;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            wr_ptr_sync <= {SYNC_STAGES{1'b0}};
        else begin
            wr_ptr_sync[0] <= src_wr_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                wr_ptr_sync[i] <= wr_ptr_sync[i-1];
        end
    end

    wire [PTR_W-1:0] dst_wr_ptr_gray_synced = wr_ptr_sync[SYNC_STAGES-1];

    (* ASYNC_REG = "TRUE" *)
    reg [SYNC_STAGES-1:0][PTR_W-1:0] rd_ptr_sync;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            rd_ptr_sync <= {SYNC_STAGES{1'b0}};
        else begin
            rd_ptr_sync[0] <= dst_rd_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                rd_ptr_sync[i] <= rd_ptr_sync[i-1];
        end
    end

    wire [PTR_W-1:0] src_rd_ptr_gray_synced = rd_ptr_sync[SYNC_STAGES-1];

endmodule