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
    logic sync_a_reset_out;
    logic sync_b_reset_out;
    logic isolate_a;
    logic isolate_b;
    logic clear_a;
    logic clear_b;
    logic isolate_ack_a;
    logic isolate_ack_b;
    logic clear_ack_a;
    logic clear_ack_b;

    // Synchronizers
    sync_reset sync_a_reset (
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .in(sync_a_reset_out),
        .out(sync_b_reset_out)
    );

    sync_reset sync_b_reset (
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .in(sync_b_reset_out),
        .out(sync_a_reset_out)
    );

    // Isolate-then-clear logic
    isolate_then_clear isolate_then_clear_a (
        .reset(sync_a_reset_out),
        .clear_i(a_clear_i),
        .clear_ack_i(a_clear_ack_i),
        .isolate_ack_i(a_isolate_ack_i),
        .isolate_o(a_isolate_o),
        .clear_o(a_clear_o)
    );

    isolate_then_clear isolate_then_clear_b (
        .reset(sync_b_reset_out),
        .clear_i(b_clear_i),
        .clear_ack_i(b_clear_ack_i),
        .isolate_ack_i(b_isolate_ack_i),
        .isolate_o(b_isolate_o),
        .clear_o(b_clear_o)
    );

endmodule

module sync_reset (
    input  clk,
    input  rst_ni,
    input  in,
    output out
);
    reg [SYNC_STAGES-1:0] shift_reg;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            shift_reg <= 0;
            out <= 0;
        end else begin
            shift_reg <= {shift_reg[SYNC_STAGES-2:0], in};
            out <= shift_reg[SYNC_STAGES-1];
        end
    end
endmodule

module isolate_then_clear (
    input  reset,
    input  clear_i,
    input  clear_ack_i,
    input  isolate_ack_i,
    output isolate_o,
    output clear_o
);
    reg isolate;
    reg clear;

    always @(posedge reset or negedge clear_ack_i or negedge isolate_ack_i) begin
        if (!reset) begin
            isolate <= 0;
            clear <= 0;
        end else begin
            if (clear_i && !clear) begin
                isolate <= 1;
            end
            if (clear_ack_i) begin
                isolate <= 0;
            end
            if (clear_i && !clear) begin
                clear <= 1;
            end
            if (clear_ack_i) begin
                clear <= 0;
            end
        end
    end

    assign isolate_o = isolate;
    assign clear_o = clear;
endmodule
