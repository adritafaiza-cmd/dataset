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
    reg a_isolate_req;
    reg b_isolate_req;
    reg a_isolate_done;
    reg b_isolate_done;
    reg a_clear_req;
    reg b_clear_req;
    reg a_clear_done;
    reg b_clear_done;
    reg a_release_req;
    reg b_release_req;
    reg a_release_done;
    reg b_release_done;

    // Synchronized signals
    reg a_clear_sync_b;
    reg b_clear_sync_a;
    reg a_clear_ack_sync_b;
    reg b_clear_ack_sync_a;
    reg a_isolate_ack_sync_b;
    reg b_isolate_ack_sync_a;

    // Instantiate sync_cells for cross-domain signaling
    sync_cell #(.SYNC_STAGES(SYNC_STAGES)) sync_a_clear_to_b (
        .async_in(a_clear_i),
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .sync_out(a_clear_sync_b)
    );

    sync_cell #(.SYNC_STAGES(SYNC_STAGES)) sync_b_clear_to_a (
        .async_in(b_clear_i),
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .sync_out(b_clear_sync_a)
    );

    sync_cell #(.SYNC_STAGES(SYNC_STAGES)) sync_a_clear_ack_to_b (
        .async_in(a_clear_ack_i),
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .sync_out(a_clear_ack_sync_b)
    );

    sync_cell #(.SYNC_STAGES(SYNC_STAGES)) sync_b_clear_ack_to_a (
        .async_in(b_clear_ack_i),
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .sync_out(b_clear_ack_sync_a)
    );

    sync_cell #(.SYNC_STAGES(SYNC_STAGES)) sync_a_isolate_ack_to_b (
        .async_in(a_isolate_ack_i),
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .sync_out(a_isolate_ack_sync_b)
    );

    sync_cell #(.SYNC_STAGES(SYNC_STAGES)) sync_b_isolate_ack_to_a (
        .async_in(b_isolate_ack_i),
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .sync_out(b_isolate_ack_sync_a)
    );

    // Logic for domain A
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_req <= 0;
            a_isolate_done <= 0;
            a_clear_req <= 0;
            a_clear_done <= 0;
            a_release_req <= 0;
            a_release_done <= 0;
            a_clear_o <= 0;
            a_isolate_o <= 0;
        end else begin
            // Isolate request
            if (a_clear_i)
                a_isolate_req <= 1;

            // Isolate completion
            if (a_isolate_req && a_isolate_ack_i && a_isolate_ack_sync_b)
                a_isolate_done <= 1;

            // Clear request
            if (a_isolate_done)
                a_clear_req <= 1;

            // Clear completion
            if (a_clear_req && a_clear_ack_i && a_clear_ack_sync_b) begin
                a_clear_done <= 1;
                a_clear_o <= 1;
            end

            // Release request
            if (a_clear_done)
                a_release_req <= 1;

            // Release completion
            if (a_release_req && a_isolate_ack_i && a_isolate_ack_sync_b) begin
                a_release_done <= 1;
                a_clear_o <= 0;
                a_isolate_o <= 0;
                a_isolate_req <= 0;
                a_isolate_done <= 0;
                a_clear_req <= 0;
                a_clear_done <= 0;
                a_release_req <= 0;
                a_release_done <= 0;
            end

            // Isolate output
            if (a_isolate_req && !a_release_done)
                a_isolate_o <= 1;
            else
                a_isolate_o <= 0;
        end
    end

    // Logic for domain B
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_req <= 0;
            b_isolate_done <= 0;
            b_clear_req <= 0;
            b_clear_done <= 0;
            b_release_req <= 0;
            b_release_done <= 0;
            b_clear_o <= 0;
            b_isolate_o <= 0;
        end else begin
            // Isolate request
            if (b_clear_i)
                b_isolate_req <= 1;

            // Isolate completion
            if (b_isolate_req && b_isolate_ack_i && b_isolate_ack_sync_a)
                b_isolate_done <= 1;

            // Clear request
            if (b_isolate_done)
                b_clear_req <= 1;

            // Clear completion
            if (b_clear_req && b_clear_ack_i && b_clear_ack_sync_a) begin
                b_clear_done <= 1;
                b_clear_o <= 1;
            end

            // Release request
            if (b_clear_done)
                b_release_req <= 1;

            // Release completion
            if (b_release_req && b_isolate_ack_i && b_isolate_ack_sync_a) begin
                b_release_done <= 1;
                b_clear_o <= 0;
                b_isolate_o <= 0;
                b_isolate_req <= 0;
                b_isolate_done <= 0;
                b_clear_req <= 0;
                b_clear_done <= 0;
                b_release_req <= 0;
                b_release_done <= 0;
            end

            // Isolate output
            if (b_isolate_req && !b_release_done)
                b_isolate_o <= 1;
            else
                b_isolate_o <= 0;
        end
    end

endmodule

module sync_cell #(
    parameter SYNC_STAGES = 2
)(
    input  async_in,
    input  clk,
    input  rst_ni,
    output sync_out
);

    reg [SYNC_STAGES-1:0] sync_stages;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stages <= 0;
        end else begin
            sync_stages[0] <= async_in;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stages[i] <= sync_stages[i-1];
            end
        end
    end

    assign sync_out = sync_stages[SYNC_STAGES-1];

endmodule
