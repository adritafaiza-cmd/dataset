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
    logic a_sync_rst_o;
    logic a_sync_clear_ack_o;
    logic a_sync_rst_ack_o;
    logic b_sync_rst_o;
    logic b_sync_clear_ack_o;
    logic b_sync_rst_ack_o;

    // Synchronizer for domain A
    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) a_sync_reset (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .clear_i(a_clear_i),
        .rst_o(a_sync_rst_o),
        .clear_ack_o(a_sync_clear_ack_o),
        .rst_ack_o(a_sync_rst_ack_o)
    );

    // Synchronizer for domain B
    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) b_sync_reset (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .clear_i(b_clear_i),
        .rst_o(b_sync_rst_o),
        .clear_ack_o(b_sync_clear_ack_o),
        .rst_ack_o(b_sync_rst_ack_o)
    );

    // Domain crossing for clear and isolate signals from A to B
    domain_crossing #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_domain_crossing (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .clear_i(a_sync_clear_o),
        .isolate_i(a_isolate_o),
        .clear_ack_i(a_sync_clear_ack_o),
        .isolate_ack_i(a_sync_isolate_ack_o),
        .b_clear_i(b_sync_clear_o),
        .b_isolate_i(b_sync_isolate_o),
        .b_clear_ack_i(b_sync_clear_ack_o),
        .b_isolate_ack_i(b_sync_isolate_ack_o)
    );

    // Domain crossing for clear and isolate signals from B to A
    domain_crossing #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_domain_crossing (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .clear_i(b_sync_clear_o),
        .isolate_i(b_isolate_o),
        .clear_ack_i(b_sync_clear_ack_o),
        .isolate_ack_i(b_sync_isolate_ack_o),
        .b_clear_i(a_sync_clear_o),
        .b_isolate_i(a_sync_isolate_o),
        .b_clear_ack_i(a_sync_clear_ack_o),
        .b_isolate_ack_i(a_sync_isolate_ack_o)
    );

    // Isolation logic for domain A
    isolation_logic #(.SYNC_STAGES(SYNC_STAGES)) isolation_logic_a (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .clear_i(a_clear_i),
        .isolate_i(a_isolate_i),
        .clear_ack_i(a_clear_ack_i),
        .isolate_ack_i(a_isolate_ack_i),
        .b_clear_i(b_sync_clear_o),
        .b_isolate_i(b_sync_isolate_o),
        .b_clear_ack_i(b_sync_clear_ack_o),
        .b_isolate_ack_i(b_sync_isolate_ack_o)
    );

    // Isolation logic for domain B
    isolation_logic #(.SYNC_STAGES(SYNC_STAGES)) isolation_logic_b (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .clear_i(b_clear_i),
        .isolate_i(b_isolate_i),
        .clear_ack_i(b_clear_ack_i),
        .isolate_ack_i(b_isolate_ack_i),
        .b_clear_i(a_sync_clear_o),
        .b_isolate_i(a_sync_isolate_o),
        .b_clear_ack_i(a_sync_clear_ack_o),
        .b_isolate_ack_i(a_sync_isolate_ack_o)
    );

    // Outputs
    assign a_clear_o = a_to_b_domain_crossing.b_clear_o;
    assign a_isolate_o = a_to_b_domain_crossing.b_isolate_o;
    assign b_clear_o = b_to_a_domain_crossing.a_clear_o;
    assign b_isolate_o = b_to_a_domain_crossing.a_isolate_o;

endmodule
