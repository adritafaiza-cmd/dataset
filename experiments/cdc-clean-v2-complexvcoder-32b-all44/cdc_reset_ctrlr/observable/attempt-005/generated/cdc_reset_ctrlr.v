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
    reg  a_isolate;
    reg  a_clear;
    reg  b_isolate;
    reg  b_clear;
    reg  b_a_clear_req;
    reg  a_b_clear_req;
    reg  b_a_clear_ack;
    reg  a_b_clear_ack;
    reg  b_a_isolate_ack;
    reg  a_b_isolate_ack;

    // CDC synchronization instances
    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_clear_req_to_b (
        .clk_i(a_clk_i),
        .clk_o(b_clk_i),
        .data_i(a_clear_i),
        .data_o(b_a_clear_req)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_clear_req_to_a (
        .clk_i(b_clk_i),
        .clk_o(a_clk_i),
        .data_i(b_clear_i),
        .data_o(a_b_clear_req)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_clear_ack_to_b (
        .clk_i(a_clk_i),
        .clk_o(b_clk_i),
        .data_i(a_clear_ack_i),
        .data_o(b_a_clear_ack)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_clear_ack_to_a (
        .clk_i(b_clk_i),
        .clk_o(a_clk_i),
        .data_i(b_clear_ack_i),
        .data_o(a_b_clear_ack)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_isolate_ack_to_b (
        .clk_i(a_clk_i),
        .clk_o(b_clk_i),
        .data_i(a_isolate_ack_i),
        .data_o(b_a_isolate_ack)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_isolate_ack_to_a (
        .clk_i(b_clk_i),
        .clk_o(a_clk_i),
        .data_i(b_isolate_ack_i),
        .data_o(a_b_isolate_ack)
    );

    // A-clock domain logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate <= 1'b1;
            a_clear <= 1'b0;
        end else begin
            if (a_clear_i) begin
                b_a_clear_req <= 1'b1;
            end else if (a_clear_o) begin
                b_a_clear_req <= 1'b0;
            end

            if (b_a_clear_req && b_a_clear_ack) begin
                a_isolate <= 1'b1;
            end

            if (a_isolate_ack_i) begin
                a_clear <= 1'b1;
            end

            if (a_clear_ack_i) begin
                a_clear <= 1'b0;
                a_isolate <= 1'b0;
            end

            if (!a_isolate) begin
                b_a_isolate_ack <= 1'b0;
            end
        end
    end

    // B-clock domain logic
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate <= 1'b1;
            b_clear <= 1'b0;
        end else begin
            if (b_clear_i) begin
                a_b_clear_req <= 1'b1;
            end else if (b_clear_o) begin
                a_b_clear_req <= 1'b0;
            end

            if (a_b_clear_req && a_b_clear_ack) begin
                b_isolate <= 1'b1;
            end

            if (b_isolate_ack_i) begin
                b_clear <= 1'b1;
            end

            if (b_clear_ack_i) begin
                b_clear <= 1'b0;
                b_isolate <= 1'b0;
            end

            if (!b_isolate) begin
                a_b_isolate_ack <= 1'b0;
            end
        end
    end

    // Outputs
    assign a_isolate_o = a_isolate;
    assign a_clear_o = a_clear;
    assign b_isolate_o = b_isolate;
    assign b_clear_o = b_clear;

endmodule

module cdc_sync #(
    parameter SYNC_STAGES = 2
)(
    input  clk_i,
    input  clk_o,
    input  data_i,
    output data_o
);

    reg [SYNC_STAGES-1:0] sync_stages;

    always @(posedge clk_i) begin
        sync_stages[0] <= data_i;
        for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
            sync_stages[i] <= sync_stages[i-1];
        end
    end

    always @(posedge clk_o) begin
        data_o <= sync_stages[SYNC_STAGES-1];
    end

endmodule
