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

    // Synchronizers for reset signals
    wire a_rst_n_synced;
    wire b_rst_n_synced;

    reset_sync #(.SYNC_STAGES(SYNC_STAGES)) a_reset_sync (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .rst_ni(a_rst_n_synced)
    );

    reset_sync #(.SYNC_STAGES(SYNC_STAGES)) b_reset_sync (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .rst_ni(b_rst_n_synced)
    );

    // Internal signals
    reg a_clear_reg;
    reg b_clear_reg;
    reg a_isolate_reg;
    reg b_isolate_reg;
    reg a_clear_ack_reg;
    reg b_clear_ack_reg;

    always @(posedge a_clk_i or negedge a_rst_n_synced) begin
        if (!a_rst_n_synced) begin
            a_clear_reg <= 1'b0;
            b_clear_reg <= 1'b0;
            a_isolate_reg <= 1'b0;
            b_isolate_reg <= 1'b0;
            a_clear_ack_reg <= 1'b0;
            b_clear_ack_reg <= 1'b0;
        end else begin
            a_clear_reg <= a_clear_i;
            b_clear_reg <= b_clear_i;
            a_isolate_reg <= a_clear_reg ? 1'b1 : (a_isolate_reg & a_isolate_ack_i);
            b_isolate_reg <= a_clear_reg ? 1'b1 : (b_isolate_reg & b_isolate_ack_i);
            a_clear_ack_reg <= a_clear_reg ? (a_clear_ack_reg | a_clear_ack_i) : (a_clear_ack_reg & ~a_clear_i);
            b_clear_ack_reg <= a_clear_reg ? (b_clear_ack_reg | b_clear_ack_i) : (b_clear_ack_reg & ~b_clear_i);
        end
    end

    always @(posedge b_clk_i or negedge b_rst_n_synced) begin
        if (!b_rst_n_synced) begin
            a_clear_reg <= 1'b0;
            b_clear_reg <= 1'b0;
            a_isolate_reg <= 1'b0;
            b_isolate_reg <= 1'b0;
            a_clear_ack_reg <= 1'b0;
            b_clear_ack_reg <= 1'b0;
        end else begin
            a_clear_reg <= b_clear_reg;
            b_clear_reg <= b_clear_i;
            a_isolate_reg <= b_clear_reg ? 1'b1 : (a_isolate_reg & a_isolate_ack_i);
            b_isolate_reg <= b_clear_reg ? 1'b1 : (b_isolate_reg & b_isolate_ack_i);
            a_clear_ack_reg <= b_clear_reg ? (a_clear_ack_reg | a_clear_ack_i) : (a_clear_ack_reg & ~b_clear_i);
            b_clear_ack_reg <= b_clear_reg ? (b_clear_ack_reg | b_clear_ack_i) : (b_clear_ack_reg & ~b_clear_i);
        end
    end

    assign a_clear_o = a_clear_reg;
    assign a_isolate_o = a_isolate_reg;
    assign b_clear_o = b_clear_reg;
    assign b_isolate_o = b_isolate_reg;

endmodule
