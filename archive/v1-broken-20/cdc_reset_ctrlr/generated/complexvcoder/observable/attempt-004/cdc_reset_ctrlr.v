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
    reg a_clear_synced;
    reg b_clear_synced;
    reg a_isolate_synced;
    reg b_isolate_synced;
    reg a_clear_release;
    reg b_clear_release;
    reg a_isolate_release;
    reg b_isolate_release;

    // Synchronize clear signals
    sync_reset sync_a_clear (
        .input(a_clear_i),
        .clk(a_clk_i),
        .output(a_clear_synced)
    );

    sync_reset sync_b_clear (
        .input(b_clear_i),
        .clk(b_clk_i),
        .output(b_clear_synced)
    );

    // Synchronize isolate signals
    sync_reset sync_a_isolate (
        .input(a_isolate_i),
        .clk(a_clk_i),
        .output(a_isolate_synced)
    );

    sync_reset sync_b_isolate (
        .input(b_isolate_i),
        .clk(b_clk_i),
        .output(b_isolate_synced)
    );

    // CDC Reset Controller
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_release <= 0;
            a_isolate_release <= 0;
        end else begin
            if (a_clear_synced && b_clear_synced && a_isolate_synced && b_isolate_synced) begin
                a_clear_release <= 1;
                b_clear_release <= 1;
                a_isolate_release <= 1;
                b_isolate_release <= 1;
            end else if (a_clear_ack_i && b_clear_ack_i && a_isolate_ack_i && b_isolate_ack_i) begin
                a_clear_release <= 0;
                b_clear_release <= 0;
                a_isolate_release <= 0;
                b_isolate_release <= 0;
            end
        end
    end

    // Output logic
    assign a_clear_o = a_clear_release;
    assign b_clear_o = b_clear_release;
    assign a_isolate_o = a_isolate_release;
    assign b_isolate_o = b_isolate_release;

endmodule

module sync_reset (
    input input,
    input clk,
    output output
);

    reg [SYNC_STAGES-1:0] shift_reg;

    always @(posedge clk) begin
        shift_reg <= {shift_reg[SYNC_STAGES-2:0], input};
    end

    assign output = shift_reg[SYNC_STAGES-1];

endmodule
