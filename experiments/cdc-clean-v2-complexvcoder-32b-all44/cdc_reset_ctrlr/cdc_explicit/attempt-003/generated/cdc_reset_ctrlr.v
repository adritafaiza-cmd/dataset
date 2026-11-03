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
    reg a_clear_req_sync;
    reg b_clear_req_sync;
    reg a_isolate_ack_sync;
    reg b_isolate_ack_sync;
    reg a_clear_ack_sync;
    reg b_clear_ack_sync;
    reg a_isolate_req;
    reg b_isolate_req;
    reg a_clear_req;
    reg b_clear_req;
    reg a_clear_done;
    reg b_clear_done;
    reg a_isolate_done;
    reg b_isolate_done;

    // Synchronization instances
    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_sync_clear_req (
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .async_in(a_clear_i),
        .sync_out(a_clear_req_sync)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_sync_clear_req (
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .async_in(b_clear_i),
        .sync_out(b_clear_req_sync)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_sync_isolate_ack (
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .async_in(a_isolate_ack_i),
        .sync_out(a_isolate_ack_sync)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_sync_isolate_ack (
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .async_in(b_isolate_ack_i),
        .sync_out(b_isolate_ack_sync)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_sync_clear_ack (
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .async_in(a_clear_ack_i),
        .sync_out(a_clear_ack_sync)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_sync_clear_ack (
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .async_in(b_clear_ack_i),
        .sync_out(b_clear_ack_sync)
    );

    // a_clk_i domain logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_req <= 0;
            a_clear_req <= 0;
            a_clear_done <= 0;
            a_isolate_done <= 0;
        end else begin
            // Isolate request logic
            a_isolate_req <= (a_clear_i || b_clear_req_sync) && !a_isolate_ack_i && !b_isolate_ack_i;

            // Clear request logic
            a_clear_req <= a_isolate_ack_sync && b_isolate_ack_sync && a_clear_i;

            // Clear done logic
            a_clear_done <= a_clear_ack_sync;

            // Isolate done logic
            a_isolate_done <= a_isolate_ack_i;
        end
    end

    // b_clk_i domain logic
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_req <= 0;
            b_clear_req <= 0;
            b_clear_done <= 0;
            b_isolate_done <= 0;
        end else begin
            // Isolate request logic
            b_isolate_req <= (b_clear_i || a_clear_req_sync) && !b_isolate_ack_i && !a_isolate_ack_i;

            // Clear request logic
            b_clear_req <= a_isolate_ack_sync && b_isolate_ack_sync && b_clear_i;

            // Clear done logic
            b_clear_done <= b_clear_ack_sync;

            // Isolate done logic
            b_isolate_done <= b_isolate_ack_i;
        end
    end

    // Output assignments
    assign a_isolate_o = a_isolate_req && a_isolate_done;
    assign a_clear_o = a_clear_req && a_clear_done;

    assign b_isolate_o = b_isolate_req && b_isolate_done;
    assign b_clear_o = b_clear_req && b_clear_done;

endmodule

module cdc_sync #(
    parameter SYNC_STAGES = 2
)(
    input  clk,
    input  rst_ni,
    input  async_in,
    output sync_out
);

    reg [SYNC_STAGES-1:0] sync_reg;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= 0;
        end else begin
            sync_reg <= {sync_reg[SYNC_STAGES-2:0], async_in};
        end
    end

    assign sync_out = sync_reg[SYNC_STAGES-1];

endmodule
