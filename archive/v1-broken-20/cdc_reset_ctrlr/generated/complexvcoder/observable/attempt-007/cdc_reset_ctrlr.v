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

    // Internal signals
    logic a_clear_synced, b_clear_synced;
    logic a_isolate_synced, b_isolate_synced;
    logic a_clear_synced_ack, b_clear_synced_ack;
    logic a_isolate_synced_ack, b_isolate_synced_ack;
    logic a_clear_isolated, b_clear_isolated;
    logic a_clear_cleared, b_clear_cleared;

    // Synchronization instances
    sync_reset #(
        .SYNC_STAGES(SYNC_STAGES)
    ) a_sync_reset (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .clear_i(a_clear_i),
        .isolate_i(1'b0),
        .clear_o(a_clear_synced),
        .isolate_o(),
        .clear_ack_o(a_clear_synced_ack),
        .isolate_ack_o(),
        .clear_ack_i(a_clear_ack_i),
        .isolate_ack_i()
    );

    sync_reset #(
        .SYNC_STAGES(SYNC_STAGES)
    ) b_sync_reset (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .clear_i(b_clear_i),
        .isolate_i(1'b0),
        .clear_o(b_clear_synced),
        .isolate_o(),
        .clear_ack_o(b_clear_synced_ack),
        .isolate_ack_o(),
        .clear_ack_i(b_clear_ack_i),
        .isolate_ack_i()
    );

    // Isolate-then-clear logic
    always_ff @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_isolated <= 1'b0;
            a_clear_cleared <= 1'b0;
        end else begin
            if (a_clear_synced && a_clear_synced_ack && !a_clear_isolated) begin
                a_clear_isolated <= 1'b1;
                a_clear_cleared <= 1'b0;
            end else if (a_clear_isolated && a_clear_synced_ack && !a_clear_cleared) begin
                a_clear_cleared <= 1'b1;
            end else begin
                a_clear_isolated <= 1'b0;
                a_clear_cleared <= 1'b0;
            end
        end
    end

    always_ff @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_isolated <= 1'b0;
            b_clear_cleared <= 1'b0;
        end else begin
            if (b_clear_synced && b_clear_synced_ack && !b_clear_isolated) begin
                b_clear_isolated <= 1'b1;
                b_clear_cleared <= 1'b0;
            end else if (b_clear_isolated && b_clear_synced_ack && !b_clear_cleared) begin
                b_clear_cleared <= 1'b1;
            end else begin
                b_clear_isolated <= 1'b0;
                b_clear_cleared <= 1'b0;
            end
        end
    end

    // Output logic
    assign a_clear_o = a_clear_cleared;
    assign a_isolate_o = a_clear_isolated;

    assign b_clear_o = b_clear_cleared;
    assign b_isolate_o = b_clear_isolated;

endmodule

module sync_reset #(
    parameter SYNC_STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  clear_i,
    input  isolate_i,
    output clear_o,
    output isolate_o,
    output clear_ack_o,
    output isolate_ack_o,
    input  clear_ack_i,
    input  isolate_ack_i
);

    // Internal signals
    logic [SYNC_STAGES-1:0] clear_reg, isolate_reg;
    logic [SYNC_STAGES-1:0] clear_ack_reg, isolate_ack_reg;

    // Synchronization logic
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            clear_reg <= 0;
            isolate_reg <= 0;
            clear_ack_reg <= 0;
            isolate_ack_reg <= 0;
        end else begin
            clear_reg <= {clear_reg[SYNC_STAGES-2:0], clear_i};
            isolate_reg <= {isolate_reg[SYNC_STAGES-2:0], isolate_i};
            clear_ack_reg <= {clear_ack_reg[SYNC_STAGES-2:0], clear_ack_i};
            isolate_ack_reg <= {isolate_ack_reg[SYNC_STAGES-2:0], isolate_ack_i};
        end
    end

    // Output logic
    assign clear_o = clear_reg[SYNC_STAGES-1];
    assign isolate_o = isolate_reg[SYNC_STAGES-1];
    assign clear_ack_o = clear_ack_reg[SYNC_STAGES-1];
    assign isolate_ack_o = isolate_ack_reg[SYNC_STAGES-1];

endmodule
