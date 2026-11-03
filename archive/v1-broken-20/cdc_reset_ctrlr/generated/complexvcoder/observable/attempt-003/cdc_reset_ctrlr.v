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

    wire a_clear_sync;
    wire b_clear_sync;
    wire a_clear_isolated;
    wire b_clear_isolated;
    wire a_clear_cleared;
    wire b_clear_cleared;
    wire a_isolate;
    wire b_isolate;

    sync_reset a_sync_reset (
        .input(a_rst_ni),
        .clk(a_clk_i),
        .output(a_clear_sync)
    );

    sync_reset b_sync_reset (
        .input(b_rst_ni),
        .clk(b_clk_i),
        .output(b_clear_sync)
    );

    isolate_then_clear a_isolate_then_clear (
        .input_clear(a_clear_i),
        .sync_reset(a_clear_sync),
        .isolate_ack(a_isolate_ack_i),
        .output_clear(a_clear_o),
        .output_isolate(a_isolate)
    );

    isolate_then_clear b_isolate_then_clear (
        .input_clear(b_clear_i),
        .sync_reset(b_clear_sync),
        .isolate_ack(b_isolate_ack_i),
        .output_clear(b_clear_o),
        .output_isolate(b_isolate)
    );

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_isolated <= 1'b0;
            a_clear_cleared <= 1'b0;
            a_isolate_o <= 1'b0;
        end else begin
            if (a_clear_i && a_isolate_ack_i) begin
                a_clear_isolated <= 1'b1;
                a_isolate_o <= 1'b1;
            end
            if (a_isolate_o && b_clear_isolated && b_clear_cleared) begin
                a_clear_cleared <= 1'b1;
                a_isolate_o <= 1'b0;
            end
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_isolated <= 1'b0;
            b_clear_cleared <= 1'b0;
            b_isolate_o <= 1'b0;
        end else begin
            if (b_clear_i && b_isolate_ack_i) begin
                b_clear_isolated <= 1'b1;
                b_isolate_o <= 1'b1;
            end
            if (b_isolate_o && a_clear_isolated && a_clear_cleared) begin
                b_clear_cleared <= 1'b1;
                b_isolate_o <= 1'b0;
            end
        end
    end

endmodule

module sync_reset (
    input  input,
    input  clk,
    output output
);

    reg [SYNC_STAGES-1:0] sync_reg;

    always @(posedge clk) begin
        sync_reg <= {sync_reg[SYNC_STAGES-2:0], input};
    end

    assign output = sync_reg[SYNC_STAGES-1];

endmodule

module isolate_then_clear (
    input  input_clear,
    input  sync_reset,
    input  isolate_ack,
    output output_clear,
    output output_isolate
);

    reg isolate_reg;
    reg clear_reg;

    always @(posedge sync_reset) begin
        isolate_reg <= isolate_ack;
    end

    always @(posedge sync_reset) begin
        clear_reg <= isolate_reg;
    end

    assign output_isolate = isolate_reg;
    assign output_clear = clear_reg;

endmodule
