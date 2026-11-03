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
    logic [SYNC_STAGES-1:0] a_clear_sync;
    logic [SYNC_STAGES-1:0] b_clear_sync;
    logic [SYNC_STAGES-1:0] a_isolate_sync;
    logic [SYNC_STAGES-1:0] b_isolate_sync;

    // Sync reset signals
    reset_sync #(
        .SYNC_STAGES(SYNC_STAGES)
    ) a_reset_sync (
        .a_clk_i(a_clk_i),
        .a_rst_ni(a_rst_ni),
        .b_clk_i(b_clk_i),
        .b_rst_ni(b_rst_ni)
    );

    reset_sync #(
        .SYNC_STAGES(SYNC_STAGES)
    ) b_reset_sync (
        .a_clk_i(b_clk_i),
        .a_rst_ni(b_rst_ni),
        .b_clk_i(a_clk_i),
        .b_rst_ni(a_rst_ni)
    );

    // Clear and isolate control
    clear_isolate_ctrl #(
        .SYNC_STAGES(SYNC_STAGES)
    ) a_clear_isolate_ctrl (
        .a_clk_i(a_clk_i),
        .b_clk_i(b_clk_i),
        .a_clear_i(a_clear_i),
        .a_clear_o(a_clear_o),
        .a_isolate_o(a_isolate_o),
        .b_clear_o(b_clear_o),
        .b_isolate_o(b_isolate_o),
        .a_clear_ack_i(a_clear_ack_i),
        .b_clear_ack_i(b_clear_ack_i),
        .a_isolate_ack_i(a_isolate_ack_i),
        .b_isolate_ack_i(b_isolate_ack_i)
    );

    clear_isolate_ctrl #(
        .SYNC_STAGES(SYNC_STAGES)
    ) b_clear_isolate_ctrl (
        .a_clk_i(b_clk_i),
        .b_clk_i(a_clk_i),
        .a_clear_i(b_clear_i),
        .a_clear_o(b_clear_o),
        .a_isolate_o(b_isolate_o),
        .b_clear_o(a_clear_o),
        .b_isolate_o(a_isolate_o),
        .a_clear_ack_i(b_clear_ack_i),
        .b_clear_ack_i(a_clear_ack_i),
        .a_isolate_ack_i(b_isolate_ack_i),
        .b_isolate_ack_i(a_isolate_ack_i)
    );

endmodule

module reset_sync #(
    parameter SYNC_STAGES = 2
)(
    input  a_clk_i,
    input  a_rst_ni,
    input  b_clk_i,
    input  b_rst_ni,
    output b_rst_ni_synced
);

    logic [SYNC_STAGES-1:0] a_rst_ni_reg;

    always_ff @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_rst_ni_reg <= {SYNC_STAGES{1'b1}};
        end else begin
            a_rst_ni_reg <= {a_rst_ni_reg[SYNC_STAGES-2:0], a_rst_ni};
        end
    end

    assign b_rst_ni_synced = a_rst_ni_reg[SYNC_STAGES-1];

endmodule

module clear_isolate_ctrl #(
    parameter SYNC_STAGES = 2
)(
    input  a_clk_i,
    input  b_clk_i,
    input  a_clear_i,
    output a_clear_o,
    output a_isolate_o,
    output b_clear_o,
    output b_isolate_o,
    input  a_clear_ack_i,
    input  b_clear_ack_i,
    input  a_isolate_ack_i,
    input  b_isolate_ack_i
);

    logic [SYNC_STAGES-1:0] a_clear_sync;
    logic [SYNC_STAGES-1:0] b_clear_sync;
    logic [SYNC_STAGES-1:0] a_isolate_sync;
    logic [SYNC_STAGES-1:0] b_isolate_sync;

    logic a_clear_reg;
    logic b_clear_reg;
    logic a_isolate_reg;
    logic b_isolate_reg;

    assign a_clear_o = a_clear_reg;
    assign b_clear_o = b_clear_reg;
    assign a_isolate_o = a_isolate_reg;
    assign b_isolate_o = b_isolate_reg;

    always_ff @(posedge a_clk_i) begin
        a_clear_sync <= {a_clear_sync[SYNC_STAGES-2:0], a_clear_i};
        a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], a_clear_i};
    end

    always_ff @(posedge b_clk_i) begin
        b_clear_sync <= {b_clear_sync[SYNC_STAGES-2:0], a_clear_i};
        b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], a_clear_i};
    end

    always_ff @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_reg <= 1'b0;
            a_isolate_reg <= 1'b0;
        end else if (a_clear_sync[SYNC_STAGES-1] && a_clear_ack_i && b_clear_sync[SYNC_STAGES-1] && b_clear_ack_i) begin
            a_clear_reg <= 1'b1;
            a_isolate_reg <= 1'b1;
        end else if (a_clear_sync[SYNC_STAGES-1] && a_clear_ack_i && b_clear_sync[SYNC_STAGES-1] && !b_clear_ack_i) begin
            a_clear_reg <= 1'b0;
            a_isolate_reg <= 1'b1;
        end else if (a_clear_sync[SYNC_STAGES-1] && !a_clear_ack_i && b_clear_sync[SYNC_STAGES-1] && b_clear_ack_i) begin
            a_clear_reg <= 1'b1;
            a_isolate_reg <= 1'b0;
        end else if (a_clear_sync[SYNC_STAGES-1] && !a_clear_ack_i && b_clear_sync[SYNC_STAGES-1] && !b_clear_ack_i) begin
            a_clear_reg <= 1'b0;
            a_isolate_reg <= 1'b0;
        end
    end

    always_ff @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_reg <= 1'b0;
            b_isolate_reg <= 1'b0;
        end else if (b_clear_sync[SYNC_STAGES-1] && b_clear_ack_i && a_clear_sync[SYNC_STAGES-1] && a_clear_ack_i) begin
            b_clear_reg <= 1'b1;
            b_isolate_reg <= 1'b1;
        end else if (b_clear_sync[SYNC_STAGES-1] && b_clear_ack_i && a_clear_sync[SYNC_STAGES-1] && !a_clear_ack_i) begin
            b_clear_reg <= 1'b0;
            b_isolate_reg <= 1'b1;
        end else if (b_clear_sync[SYNC_STAGES-1] && !b_clear_ack_i && a_clear_sync[SYNC_STAGES-1] && a_clear_ack_i) begin
            b_clear_reg <= 1'b1;
            b_isolate_reg <= 1'b0;
        end else if (b_clear_sync[SYNC_STAGES-1] && !b_clear_ack_i && a_clear_sync[SYNC_STAGES-1] && !a_clear_ack_i) begin
            b_clear_reg <= 1'b0;
            b_isolate_reg <= 1'b0;
        end
    end

endmodule
