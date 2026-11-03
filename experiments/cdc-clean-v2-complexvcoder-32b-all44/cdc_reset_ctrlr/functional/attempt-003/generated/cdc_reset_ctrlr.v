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

    // Instantiate CDC synchronizer for clear_i signals
    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_clear_i (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .d_i(a_clear_i),
        .q_o(a_clear_i_synced_b)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_clear_i (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .d_i(b_clear_i),
        .q_o(b_clear_i_synced_a)
    );

    // Instantiate CDC reset domain modules for each domain
    cdc_reset_domain domain_a (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .clear_i(a_clear_i),
        .clear_o(a_clear_o),
        .clear_ack_i(a_clear_ack_i),
        .isolate_o(a_isolate_o),
        .isolate_ack_i(a_isolate_ack_i),
        .peer_clear_o(b_clear_i_synced_a),
        .peer_clear_ack_i(b_clear_ack_i),
        .peer_isolate_o(b_isolate_o),
        .peer_isolate_ack_i(b_isolate_ack_i)
    );

    cdc_reset_domain domain_b (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .clear_i(b_clear_i),
        .clear_o(b_clear_o),
        .clear_ack_i(b_clear_ack_i),
        .isolate_o(b_isolate_o),
        .isolate_ack_i(b_isolate_ack_i),
        .peer_clear_o(a_clear_i_synced_b),
        .peer_clear_ack_i(a_clear_ack_i),
        .peer_isolate_o(a_isolate_o),
        .peer_isolate_ack_i(a_isolate_ack_i)
    );

endmodule

// CDC synchronizer module
module cdc_sync #(
    parameter SYNC_STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  d_i,
    output q_o
);

    reg [SYNC_STAGES-1:0] sync_chain;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= {SYNC_STAGES{1'b0}};
        end else begin
            sync_chain <= {sync_chain[SYNC_STAGES-2:0], d_i};
        end
    end

    assign q_o = sync_chain[SYNC_STAGES-1];

endmodule

// CDC reset domain module
module cdc_reset_domain #(
    parameter SYNC_STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  clear_i,
    output clear_o,
    input  clear_ack_i,
    output isolate_o,
    input  isolate_ack_i,
    input  peer_clear_o,
    input  peer_clear_ack_i,
    input  peer_isolate_o,
    input  peer_isolate_ack_i
);

    reg isolate_req;
    reg clear_req;
    reg isolate_done;
    reg clear_done;

    // State machine to handle isolate and clear sequence
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            isolate_req <= 1'b0;
            clear_req   <= 1'b0;
            isolate_done <= 1'b0;
            clear_done   <= 1'b0;
        end else begin
            // Request isolate when clear is asserted
            if (clear_i) begin
                isolate_req <= 1'b1;
            end

            // Wait for isolate ack before requesting clear
            if (isolate_req && isolate_ack_i) begin
                isolate_done <= 1'b1;
                clear_req    <= 1'b1;
            end

            // Wait for clear ack before releasing isolate and clear
            if (clear_req && clear_ack_i) begin
                clear_done   <= 1'b1;
            end

            // Release isolate and clear after peer completion
            if (clear_done && peer_clear_ack_i && peer_isolate_ack_i) begin
                isolate_req <= 1'b0;
                clear_req   <= 1'b0;
                isolate_done <= 1'b0;
                clear_done   <= 1'b0;
            end
        end
    end

    // Output assignment
    assign isolate_o = isolate_req;
    assign clear_o   = clear_req;

endmodule
