module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output [WIDTH-1:0] dst_data_o
);

    // Internal signals
    reg [WIDTH-1:0] fifo [0:1];
    reg [1:0]       fifo_head, fifo_tail;
    reg             fifo_full, fifo_empty;
    reg             synced_src_valid, synced_src_ready;
    reg             synced_dst_ready, synced_dst_valid;

    // FIFO control logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_head <= 0;
            fifo_tail <= 0;
            fifo_full <= 0;
        end else if (src_valid_i && src_ready_o) begin
            fifo[fifo_tail] <= src_data_i;
            fifo_tail <= fifo_tail + 1;
            fifo_full <= (fifo_tail == fifo_head);
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            fifo_empty <= 1;
        end else if (dst_valid_o && dst_ready_i) begin
            fifo_head <= fifo_head + 1;
            fifo_empty <= (fifo_head == fifo_tail);
        end
    end

    // FIFO status
    assign fifo_full = (fifo_tail == fifo_head + 1) || (fifo_tail == 0 && fifo_head == 2);
    assign fifo_empty = (fifo_head == fifo_tail);

    // Synchronization logic
    cdc_sync sync_src_valid (
        .src_clk_i  (src_clk_i),
        .src_rst_ni (src_rst_ni),
        .src_signal_i (src_valid_i),
        .dst_clk_i  (dst_clk_i),
        .dst_rst_ni (dst_rst_ni),
        .dst_signal_o (synced_src_valid)
    );

    cdc_sync sync_src_ready (
        .src_clk_i  (dst_clk_i),
        .src_rst_ni (dst_rst_ni),
        .src_signal_i (synced_src_ready),
        .dst_clk_i  (src_clk_i),
        .dst_rst_ni (src_rst_ni),
        .dst_signal_o (src_ready_o)
    );

    cdc_sync sync_dst_ready (
        .src_clk_i  (dst_clk_i),
        .src_rst_ni (dst_rst_ni),
        .src_signal_i (dst_ready_i),
        .dst_clk_i  (src_clk_i),
        .dst_rst_ni (src_rst_ni),
        .dst_signal_o (synced_dst_ready)
    );

    cdc_sync sync_dst_valid (
        .src_clk_i  (src_clk_i),
        .src_rst_ni (src_rst_ni),
        .src_signal_i (synced_dst_valid),
        .dst_clk_i  (dst_clk_i),
        .dst_rst_ni (dst_rst_ni),
        .dst_signal_o (dst_valid_o)
    );

    // Source-side logic
    assign src_ready_o = !fifo_full;

    // Destination-side logic
    assign synced_dst_valid = !fifo_empty;
    assign dst_data_o = fifo[fifo_head];

endmodule

module cdc_sync (
    input  src_clk_i,
    input  src_rst_ni,
    input  src_signal_i,
    input  dst_clk_i,
    input  dst_rst_ni,
    output dst_signal_o
);

    reg sync_reg1, sync_reg2;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            sync_reg1 <= 0;
        else
            sync_reg1 <= src_signal_i;
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            sync_reg2 <= 0;
            dst_signal_o <= 0;
        end else begin
            sync_reg2 <= sync_reg1;
            dst_signal_o <= sync_reg2;
        end
    end

endmodule
