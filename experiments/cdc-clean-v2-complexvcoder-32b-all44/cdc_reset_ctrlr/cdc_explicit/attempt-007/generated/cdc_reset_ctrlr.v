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
    reg  a_isolate_req;
    reg  a_clear_req;
    reg  a_isolate;
    reg  a_clear;
    reg  a_isolate_ack;
    reg  a_clear_ack;

    reg  b_isolate_req;
    reg  b_clear_req;
    reg  b_isolate;
    reg  b_clear;
    reg  b_isolate_ack;
    reg  b_clear_ack;

    // Synchronizer instances
    sync_register #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_sync (
        .local(a_clear_req),
        .remote(b_to_a_clear_req)
    );

    sync_register #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_isolate_sync (
        .local(a_isolate_req),
        .remote(b_to_a_isolate_req)
    );

    sync_register #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_isolate_ack_sync (
        .local(a_isolate_ack),
        .remote(b_to_a_isolate_ack)
    );

    sync_register #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_clear_ack_sync (
        .local(a_clear_ack),
        .remote(b_to_a_clear_ack)
    );

    sync_register #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_sync (
        .local(b_clear_req),
        .remote(a_to_b_clear_req)
    );

    sync_register #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_isolate_sync (
        .local(b_isolate_req),
        .remote(a_to_b_isolate_req)
    );

    sync_register #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_isolate_ack_sync (
        .local(b_isolate_ack),
        .remote(a_to_b_isolate_ack)
    );

    sync_register #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_clear_ack_sync (
        .local(b_clear_ack),
        .remote(a_to_b_clear_ack)
    );

    // a_clk_i domain logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate <= 0;
            a_clear <= 0;
            a_isolate_ack <= 0;
            a_clear_ack <= 0;
            a_isolate_req <= 0;
            a_clear_req <= 0;
        end else begin
            // Handle isolate request
            if (a_clear_i && !a_isolate) begin
                a_isolate_req <= 1;
            end else if (b_to_a_isolate_ack && a_isolate_req) begin
                a_isolate <= 1;
                a_isolate_req <= 0;
            end

            // Handle clear request
            if (a_isolate && !a_clear && a_clear_i && b_to_a_isolate_ack) begin
                a_clear_req <= 1;
            end else if (b_to_a_clear_ack && a_clear_req) begin
                a_clear <= 1;
                a_clear_req <= 0;
            end

            // Handle clear release
            if (a_clear && a_clear_ack_i && b_to_a_clear_ack) begin
                a_clear <= 0;
                a_clear_ack <= 1;
            end

            // Handle isolate release
            if (a_isolate && a_isolate_ack_i && b_to_a_clear_ack && !a_clear) begin
                a_isolate <= 0;
                a_isolate_ack <= 1;
            end

            // Reset acknowledgments
            if (!a_clear_i) begin
                a_clear_ack <= 0;
            end

            if (!a_isolate_req) begin
                a_isolate_ack <= 0;
            end
        end
    end

    // b_clk_i domain logic
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate <= 0;
            b_clear <= 0;
            b_isolate_ack <= 0;
            b_clear_ack <= 0;
            b_isolate_req <= 0;
            b_clear_req <= 0;
        end else begin
            // Handle isolate request
            if (b_clear_i && !b_isolate) begin
                b_isolate_req <= 1;
            end else if (a_to_b_isolate_ack && b_isolate_req) begin
                b_isolate <= 1;
                b_isolate_req <= 0;
            end

            // Handle clear request
            if (b_isolate && !b_clear && b_clear_i && a_to_b_isolate_ack) begin
                b_clear_req <= 1;
            end else if (a_to_b_clear_ack && b_clear_req) begin
                b_clear <= 1;
                b_clear_req <= 0;
            end

            // Handle clear release
            if (b_clear && b_clear_ack_i && a_to_b_clear_ack) begin
                b_clear <= 0;
                b_clear_ack <= 1;
            end

            // Handle isolate release
            if (b_isolate && b_isolate_ack_i && a_to_b_clear_ack && !b_clear) begin
                b_isolate <= 0;
                b_isolate_ack <= 1;
            end

            // Reset acknowledgments
            if (!b_clear_i) begin
                b_clear_ack <= 0;
            end

            if (!b_isolate_req) begin
                b_isolate_ack <= 0;
            end
        end
    end

    // Output assignments
    assign a_isolate_o = a_isolate;
    assign a_clear_o = a_clear;
    assign b_isolate_o = b_isolate;
    assign b_clear_o = b_clear;

endmodule

module sync_register #(
    parameter SYNC_STAGES = 2
)(
    input  local,
    output remote
);

    reg [SYNC_STAGES-1:0] sync_stage;

    always @(posedge local_clk) begin
        sync_stage <= {sync_stage[SYNC_STAGES-2:0], local};
    end

    assign remote = sync_stage[SYNC_STAGES-1];

endmodule
