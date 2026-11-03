module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  a_clk_i,
    input  a_rst_ni,
    input  a_clear_i,
    output a_clear_o,
    input  a_clear_ack_i,
    output a_isolate_o,
    input  a_isolate_ack_i,
    input  b_clk_i,
    input  b_rst_ni,
    input  b_clear_i,
    output b_clear_o,
    input  b_clear_ack_i,
    output b_isolate_o,
    input  b_isolate_ack_i
);

    // Internal signals for synchronization
    wire a_clear_sync;
    wire a_isolate_sync;
    wire b_clear_sync;
    wire b_isolate_sync;

    // Sync reset instances for a_domain
    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) sync_a_clear (
        .data_i(a_clear_i),
        .clk_i(a_clk_i),
        .data_o(a_clear_sync)
    );

    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) sync_a_isolate (
        .data_i(a_isolate_i),
        .clk_i(a_clk_i),
        .data_o(a_isolate_sync)
    );

    // Sync reset instances for b_domain
    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) sync_b_clear (
        .data_i(b_clear_i),
        .clk_i(b_clk_i),
        .data_o(b_clear_sync)
    );

    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) sync_b_isolate (
        .data_i(b_isolate_i),
        .clk_i(b_clk_i),
        .data_o(b_isolate_sync)
    );

    // Isolate-then-clear instances for a_domain
    isolate_then_clear isolate_then_clear_a (
        .clear_i(a_clear_sync),
        .isolate_i(a_isolate_sync),
        .clear_ack_i(a_clear_ack_i),
        .isolate_ack_i(a_isolate_ack_i),
        .clear_o(a_clear_o),
        .isolate_o(a_isolate_o)
    );

    // Isolate-then-clear instances for b_domain
    isolate_then_clear isolate_then_clear_b (
        .clear_i(b_clear_sync),
        .isolate_i(b_isolate_sync),
        .clear_ack_i(b_clear_ack_i),
        .isolate_ack_i(b_isolate_ack_i),
        .clear_o(b_clear_o),
        .isolate_o(b_isolate_o)
    );

endmodule

// Helper module for synchronization
module sync_reset #(
    parameter SYNC_STAGES = 2
)(
    input  data_i,
    input  clk_i,
    output data_o
);

    reg [SYNC_STAGES-1:0] shift_reg;

    always @(posedge clk_i) begin
        shift_reg <= {shift_reg[SYNC_STAGES-2:0], data_i};
    end

    assign data_o = shift_reg[SYNC_STAGES-1];

endmodule

// Helper module for isolate-then-clear sequence
module isolate_then_clear (
    input  clear_i,
    input  isolate_i,
    input  clear_ack_i,
    input  isolate_ack_i,
    output clear_o,
    output isolate_o
);

    reg clear_reg;
    reg isolate_reg;

    always @(posedge clear_i or posedge isolate_i) begin
        if (!clear_ack_i || !isolate_ack_i) begin
            clear_reg <= 0;
            isolate_reg <= 0;
        end else if (clear_i && !isolate_i) begin
            clear_reg <= 1;
            isolate_reg <= 0;
        end else if (!clear_i && isolate_i) begin
            clear_reg <= 0;
            isolate_reg <= 1;
        end
    end

    assign clear_o = clear_reg;
    assign isolate_o = isolate_reg;

endmodule
