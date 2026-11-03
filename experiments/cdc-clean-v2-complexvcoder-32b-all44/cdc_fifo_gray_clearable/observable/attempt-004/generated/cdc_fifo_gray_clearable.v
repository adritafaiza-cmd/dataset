module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
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

    // Internal signals
    reg [LOG_DEPTH-1:0] src_wr_ptr, src_wr_gray, src_wr_gray_sync;
    reg [LOG_DEPTH-1:0] dst_rd_ptr, dst_rd_gray, dst_rd_gray_sync;
    reg                 src_full, dst_empty;
    reg [WIDTH-1:0]     fifo_memory [0:(1<<LOG_DEPTH)-1];
    reg                 src_clear_pending, dst_clear_pending;
    reg                 src_clear_edge, dst_clear_edge;

    // Gray counter for source write pointer
    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) src_gray_counter (
        .clk(clk      (src_clk_i)),
        .rst_ni(rst_ni(src_rst_ni)),
        .clear(clear  (src_clear_i)),
        .increment(increment(src_valid_i & src_ready_o)),
        .gray_code(gray_code(src_wr_gray))
    );

    // Gray counter for destination read pointer
    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_gray_counter (
        .clk(clk      (dst_clk_i)),
        .rst_ni(rst_ni(dst_rst_ni)),
        .clear(clear  (dst_clear_i)),
        .increment(increment(dst_valid_o & dst_ready_i)),
        .gray_code(gray_code(dst_rd_gray))
    );

    // Synchronize source Gray code to destination clock domain
    sync_gray_counter #(
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_src_gray_counter (
        .clk(clk      (dst_clk_i)),
        .rst_ni(rst_ni(dst_rst_ni)),
        .async_in(async_in(src_wr_gray)),
        .sync_out(sync_out(src_wr_gray_sync))
    );

    // Synchronize destination Gray code to source clock domain
    sync_gray_counter #(
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_dst_gray_counter (
        .clk(clk      (src_clk_i)),
        .rst_ni(rst_ni(src_rst_ni)),
        .async_in(async_in(dst_rd_gray)),
        .sync_out(sync_out(dst_rd_gray_sync))
    );

    // Source-side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_wr_gray <= 0;
            src_clear_pending <= 0;
            src_clear_edge <= 0;
            src_ready_o <= 0;
        end else begin
            // Handle clear request
            if (!src_clear_i) begin
                src_clear_pending <= 1;
                src_clear_edge <= 1;
            end else if (src_clear_edge) begin
                src_wr_ptr <= 0;
                src_wr_gray <= 0;
                src_clear_edge <= 0;
                // Clear FIFO memory
                for (integer i = 0; i < (1<<LOG_DEPTH); i = i + 1) begin
                    fifo_memory[i] <= 0;
                end
            end else if (src_clear_pending && src_rst_ni) begin
                src_clear_pending <= 0;
            end

            // Calculate full condition
            src_full <= (src_wr_gray == (src_wr_gray_sync ^ (1 << (LOG_DEPTH - 1))));

            // Set ready signal
            src_ready_o <= !src_full;

            // Write data to FIFO
            if (src_valid_i && src_ready_o) begin
                fifo_memory[src_wr_ptr] <= src_data_i;
            end
        end
    end

    // Destination-side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
            dst_rd_gray <= 0;
            dst_clear_pending <= 0;
            dst_clear_edge <= 0;
            dst_valid_o <= 0;
            dst_data_o <= 0;
        end else begin
            // Handle clear request
            if (!dst_clear_i) begin
                dst_clear_pending <= 1;
                dst_clear_edge <= 1;
            end else if (dst_clear_edge) begin
                dst_rd_ptr <= 0;
                dst_rd_gray <= 0;
                dst_clear_edge <= 0;
                // Clear FIFO memory (already cleared on src side)
            end else if (dst_clear_pending && dst_rst_ni) begin
                dst_clear_pending <= 0;
            end

            // Calculate empty condition
            dst_empty <= (dst_rd_gray == dst_rd_gray_sync);

            // Set valid signal and read data from FIFO
            if (!dst_empty && dst_ready_i) begin
                dst_data_o <= fifo_memory[dst_rd_ptr];
                dst_valid_o <= 1;
            end else begin
                dst_valid_o <= 0;
            end
        end
    end

    // Output clear pending signals
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_ni,
    input                  clear,
    input                  increment,
    output [LOG_DEPTH-1:0] gray_code
);

    reg [LOG_DEPTH-1:0] counter;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            counter <= 0;
        end else if (!clear) begin
            counter <= 0;
        end else if (increment) begin
            counter <= counter + 1;
        end
    end

    assign gray_code = counter ^ (counter >> 1);

endmodule

module sync_gray_counter #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  clk,
    input                  rst_ni,
    input  [LOG_DEPTH-1:0] async_in,
    output [LOG_DEPTH-1:0] sync_out
);

    reg [LOG_DEPTH-1:0] sync_stage [0:SYNC_STAGES-1];

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            for (integer i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_stage[i] <= 0;
            end
        end else begin
            sync_stage[0] <= async_in;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stage[i] <= sync_stage[i-1];
            end
        end
    end

    assign sync_out = sync_stage[SYNC_STAGES-1];

endmodule
