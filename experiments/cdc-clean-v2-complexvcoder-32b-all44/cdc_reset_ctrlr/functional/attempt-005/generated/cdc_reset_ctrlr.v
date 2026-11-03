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

    // Internal signals for synchronization
    wire a_clear_synced;
    wire b_clear_synced;

    // Internal state signals
    reg a_isolate_req;
    reg b_isolate_req;
    reg a_clear_req;
    reg b_clear_req;
    reg a_isolate_done;
    reg b_isolate_done;
    reg a_clear_done;
    reg b_clear_done;
    reg a_release_req;
    reg b_release_req;
    reg a_release_done;
    reg b_release_done;

    // Synchronization stages
    sync_stage #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_sync_stage (
        .async_in(a_clear_i),
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .sync_out(a_clear_synced)
    );

    sync_stage #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_sync_stage (
        .async_in(b_clear_i),
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .sync_out(b_clear_synced)
    );

    // FSM for a_clk_i domain
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_req <= 0;
            a_clear_req <= 0;
            a_isolate_done <= 0;
            a_clear_done <= 0;
            a_release_req <= 0;
            a_release_done <= 0;
        end else begin
            // Isolation request
            if (a_clear_i && !a_isolate_req)
                a_isolate_req <= 1;

            // Isolation done
            if (a_isolate_req && a_isolate_ack_i)
                a_isolate_done <= 1;

            // Clear request
            if (a_isolate_done && b_isolate_done && !a_clear_req)
                a_clear_req <= 1;

            // Clear done
            if (a_clear_req && a_clear_ack_i)
                a_clear_done <= 1;

            // Release request
            if (a_clear_done && b_clear_done && !a_release_req)
                a_release_req <= 1;

            // Release done
            if (a_release_req && a_isolate_ack_i && b_isolate_ack_i)
                a_release_done <= 1;

            // Reset after release
            if (a_release_done) begin
                a_isolate_req <= 0;
                a_clear_req <= 0;
                a_isolate_done <= 0;
                a_clear_done <= 0;
                a_release_req <= 0;
                a_release_done <= 0;
            end
        end
    end

    // FSM for b_clk_i domain
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_req <= 0;
            b_clear_req <= 0;
            b_isolate_done <= 0;
            b_clear_done <= 0;
            b_release_req <= 0;
            b_release_done <= 0;
        end else begin
            // Isolation request
            if (b_clear_i && !b_isolate_req)
                b_isolate_req <= 1;

            // Isolation done
            if (b_isolate_req && b_isolate_ack_i)
                b_isolate_done <= 1;

            // Clear request
            if (b_isolate_done && a_isolate_done && !b_clear_req)
                b_clear_req <= 1;

            // Clear done
            if (b_clear_req && b_clear_ack_i)
                b_clear_done <= 1;

            // Release request
            if (b_clear_done && a_clear_done && !b_release_req)
                b_release_req <= 1;

            // Release done
            if (b_release_req && a_isolate_ack_i && b_isolate_ack_i)
                b_release_done <= 1;

            // Reset after release
            if (b_release_done) begin
                b_isolate_req <= 0;
                b_clear_req <= 0;
                b_isolate_done <= 0;
                b_clear_done <= 0;
                b_release_req <= 0;
                b_release_done <= 0;
            end
        end
    end

    // Output assignments
    assign a_isolate_o = a_isolate_req;
    assign a_clear_o = a_clear_req;
    assign b_isolate_o = b_isolate_req;
    assign b_clear_o = b_clear_req;

endmodule

module sync_stage #(
    parameter SYNC_STAGES = 2
)(
    input  async_in,
    input  clk,
    input  rst_ni,
    output sync_out
);

    reg [SYNC_STAGES-1:0] sync_stages;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni)
            sync_stages <= 0;
        else
            sync_stages <= {sync_stages[SYNC_STAGES-2:0], async_in};
    end

    assign sync_out = sync_stages[SYNC_STAGES-1];

endmodule
