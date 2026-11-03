module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  a_clk_i,
    input  a_rst_ni,
    input  a_clear_i,
    output reg a_clear_o,
    input  a_clear_ack_i,
    output reg a_isolate_o,
    input  a_isolate_ack_i,
    input  b_clk_i,
    input  b_rst_ni,
    input  b_clear_i,
    output reg b_clear_o,
    input  b_clear_ack_i,
    output reg b_isolate_o,
    input  b_isolate_ack_i
);

    // Internal signals for synchronization
    wire a2b_clear_sync;
    wire a2b_isolate_ack_sync;
    wire b2a_clear_sync;
    wire b2a_isolate_ack_sync;

    // Internal state signals
    reg a_isolate_req;
    reg a_clear_req;
    reg a_isolate_done;
    reg a_clear_done;

    reg b_isolate_req;
    reg b_clear_req;
    reg b_isolate_done;
    reg b_clear_done;

    // Synchronizer instances
    sync_ff #(.SYNC_STAGES(SYNC_STAGES)) a2b_sync_clear (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .din_i(a_clear_i),
        .dout_o(a2b_clear_sync)
    );

    sync_ff #(.SYNC_STAGES(SYNC_STAGES)) a2b_sync_isolate_ack (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .din_i(a_isolate_ack_i),
        .dout_o(a2b_isolate_ack_sync)
    );

    sync_ff #(.SYNC_STAGES(SYNC_STAGES)) b2a_sync_clear (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .din_i(b_clear_i),
        .dout_o(b2a_clear_sync)
    );

    sync_ff #(.SYNC_STAGES(SYNC_STAGES)) b2a_sync_isolate_ack (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .din_i(b_isolate_ack_i),
        .dout_o(b2a_isolate_ack_sync)
    );

    // FSM for domain A
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_req <= 0;
            a_clear_req <= 0;
            a_isolate_done <= 0;
            a_clear_done <= 0;
            a_isolate_o <= 0;
            a_clear_o <= 0;
        end else begin
            if (a_clear_i && !a_isolate_done) begin
                a_isolate_req <= 1;
            end
            if (a2b_isolate_ack_sync) begin
                a_isolate_done <= 1;
                a_isolate_req <= 0;
            end
            if (a_isolate_done && b2a_isolate_ack_sync && !a_clear_req) begin
                a_clear_req <= 1;
            end
            if (a_clear_req && a2b_clear_ack_sync) begin
                a_clear_done <= 1;
                a_clear_req <= 0;
            end
            if (a_clear_done && b2a_clear_ack_sync) begin
                a_clear_done <= 0;
                a_isolate_done <= 0;
            end
            a_isolate_o <= a_isolate_req || a_isolate_done;
            a_clear_o <= a_clear_req || a_clear_done;
        end
    end

    // FSM for domain B
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_req <= 0;
            b_clear_req <= 0;
            b_isolate_done <= 0;
            b_clear_done <= 0;
            b_isolate_o <= 0;
            b_clear_o <= 0;
        end else begin
            if (b_clear_i && !b_isolate_done) begin
                b_isolate_req <= 1;
            end
            if (b2a_isolate_ack_sync) begin
                b_isolate_done <= 1;
                b_isolate_req <= 0;
            end
            if (b_isolate_done && a2b_isolate_ack_sync && !b_clear_req) begin
                b_clear_req <= 1;
            end
            if (b_clear_req && b2a_clear_ack_sync) begin
                b_clear_done <= 1;
                b_clear_req <= 0;
            end
            if (b_clear_done && a2b_clear_ack_sync) begin
                b_clear_done <= 0;
                b_isolate_done <= 0;
            end
            b_isolate_o <= b_isolate_req || b_isolate_done;
            b_clear_o <= b_clear_req || b_clear_done;
        end
    end

endmodule

module sync_ff #(
    parameter SYNC_STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  din_i,
    output reg dout_o
);

    reg [SYNC_STAGES-1:0] sync_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= 0;
            dout_o <= 0;
        end else begin
            sync_reg <= {sync_reg[SYNC_STAGES-2:0], din_i};
            dout_o <= sync_reg[SYNC_STAGES-1];
        end
    end

endmodule
