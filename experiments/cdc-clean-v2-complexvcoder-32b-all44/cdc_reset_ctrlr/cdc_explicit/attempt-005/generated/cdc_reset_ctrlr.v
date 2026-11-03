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
    reg sync_a_clear_to_b_o;
    reg sync_b_clear_to_a_o;
    reg sync_a_isolate_ack_to_b_o;
    reg sync_b_isolate_ack_to_a_o;
    reg sync_a_clear_ack_to_b_o;
    reg sync_b_clear_ack_to_a_o;

    reg a_clear_req;
    reg b_clear_req;
    reg a_isolate;
    reg b_isolate;
    reg a_clear;
    reg b_clear;

    // Sync signals across domains
    sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_clear_to_b (
        .async_in(a_clear_i),
        .clk(b_clk_i),
        .sync_out(sync_a_clear_to_b_o)
    );

    sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_clear_to_a (
        .async_in(b_clear_i),
        .clk(a_clk_i),
        .sync_out(sync_b_clear_to_a_o)
    );

    sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_isolate_ack_to_b (
        .async_in(a_isolate_ack_i),
        .clk(b_clk_i),
        .sync_out(sync_a_isolate_ack_to_b_o)
    );

    sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_isolate_ack_to_a (
        .async_in(b_isolate_ack_i),
        .clk(a_clk_i),
        .sync_out(sync_b_isolate_ack_to_a_o)
    );

    sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_clear_ack_to_b (
        .async_in(a_clear_ack_i),
        .clk(b_clk_i),
        .sync_out(sync_a_clear_ack_to_b_o)
    );

    sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_clear_ack_to_a (
        .async_in(b_clear_ack_i),
        .clk(a_clk_i),
        .sync_out(sync_b_clear_ack_to_a_o)
    );

    // State machine for domain A
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_req <= 0;
            a_isolate <= 0;
            a_clear <= 0;
        end else begin
            if (a_clear_i && !a_clear_req && !a_clear && !a_isolate) begin
                a_clear_req <= 1;
            end else if (sync_b_isolate_ack_to_a_o && a_clear_req && !a_isolate) begin
                a_isolate <= 1;
            end else if (sync_b_clear_ack_to_a_o && a_isolate && a_clear_req) begin
                a_clear <= 1;
            end else if (a_clear_ack_i && a_clear) begin
                a_clear <= 0;
                a_isolate <= 0;
                a_clear_req <= 0;
            end
        end
    end

    // State machine for domain B
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_req <= 0;
            b_isolate <= 0;
            b_clear <= 0;
        end else begin
            if (b_clear_i && !b_clear_req && !b_clear && !b_isolate) begin
                b_clear_req <= 1;
            end else if (sync_a_isolate_ack_to_b_o && b_clear_req && !b_isolate) begin
                b_isolate <= 1;
            end else if (sync_a_clear_ack_to_b_o && b_isolate && b_clear_req) begin
                b_clear <= 1;
            end else if (b_clear_ack_i && b_clear) begin
                b_clear <= 0;
                b_isolate <= 0;
                b_clear_req <= 0;
            end
        end
    end

    // Outputs
    assign a_isolate_o = a_isolate;
    assign a_clear_o = a_clear;
    assign b_isolate_o = b_isolate;
    assign b_clear_o = b_clear;

endmodule

module sync #(
    parameter SYNC_STAGES = 2
)(
    input  async_in,
    input  clk,
    output sync_out
);

    reg [SYNC_STAGES-1:0] sync_reg;

    always @(posedge clk) begin
        sync_reg <= {sync_reg[SYNC_STAGES-2:0], async_in};
    end

    assign sync_out = sync_reg[SYNC_STAGES-1];

endmodule
