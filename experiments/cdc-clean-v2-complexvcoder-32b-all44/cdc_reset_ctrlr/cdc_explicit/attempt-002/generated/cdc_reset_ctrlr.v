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
    wire a_clear_sync_b;
    wire a_isolate_ack_sync_b;
    wire b_clear_sync_a;
    wire b_isolate_ack_sync_a;

    reg a_isolate_req;
    reg a_clear_req;
    reg a_isolate;
    reg a_clear;
    reg a_isolate_done;
    reg a_clear_done;

    reg b_isolate_req;
    reg b_clear_req;
    reg b_isolate;
    reg b_clear;
    reg b_isolate_done;
    reg b_clear_done;

    // Instantiate CDC synchronizers
    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_sync_clear (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .data_i(a_clear_i),
        .data_o(a_clear_sync_b)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_sync_isolate_ack (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .data_i(a_isolate_ack_i),
        .data_o(a_isolate_ack_sync_b)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_sync_clear (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .data_i(b_clear_i),
        .data_o(b_clear_sync_a)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_sync_isolate_ack (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .data_i(b_isolate_ack_i),
        .data_o(b_isolate_ack_sync_a)
    );

    // a_clk_i domain logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_req <= 0;
            a_clear_req <= 0;
            a_isolate <= 0;
            a_clear <= 0;
            a_isolate_done <= 0;
            a_clear_done <= 0;
        end else begin
            // Request isolate if clear is requested
            if (a_clear_i && !a_isolate) begin
                a_isolate_req <= 1;
            end

            // Wait for isolate ack from both sides before clearing
            if (a_isolate_req && a_isolate_ack_i && a_isolate_ack_sync_b) begin
                a_isolate <= 1;
                a_isolate_req <= 0;
                a_clear_req <= 1;
            end

            // Wait for clear ack from both sides before releasing clear
            if (a_clear_req && a_clear_ack_i && b_clear_ack_sync_a) begin
                a_clear <= 1;
                a_clear_req <= 0;
                a_clear_done <= 1;
            end

            // Release clear and isolate
            if (a_clear_done && a_isolate) begin
                a_clear <= 0;
                a_clear_done <= 0;
                a_isolate <= 0;
            end
        end
    end

    // b_clk_i domain logic
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_req <= 0;
            b_clear_req <= 0;
            b_isolate <= 0;
            b_clear <= 0;
            b_isolate_done <= 0;
            b_clear_done <= 0;
        end else begin
            // Request isolate if clear is requested
            if (b_clear_i && !b_isolate) begin
                b_isolate_req <= 1;
            end

            // Wait for isolate ack from both sides before clearing
            if (b_isolate_req && b_isolate_ack_i && b_isolate_ack_sync_a) begin
                b_isolate <= 1;
                b_isolate_req <= 0;
                b_clear_req <= 1;
            end

            // Wait for clear ack from both sides before releasing clear
            if (b_clear_req && b_clear_ack_i && a_clear_ack_sync_b) begin
                b_clear <= 1;
                b_clear_req <= 0;
                b_clear_done <= 1;
            end

            // Release clear and isolate
            if (b_clear_done && b_isolate) begin
                b_clear <= 0;
                b_clear_done <= 0;
                b_isolate <= 0;
            end
        end
    end

    // Assign outputs
    assign a_isolate_o = a_isolate;
    assign a_clear_o = a_clear;
    assign b_isolate_o = b_isolate;
    assign b_clear_o = b_clear;

endmodule

module cdc_sync #(
    parameter SYNC_STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  data_i,
    output data_o
);

    reg [SYNC_STAGES-1:0] sync_chain;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= 0;
        end else begin
            sync_chain <= {sync_chain[SYNC_STAGES-2:0], data_i};
        end
    end

    assign data_o = sync_chain[SYNC_STAGES-1];

endmodule
