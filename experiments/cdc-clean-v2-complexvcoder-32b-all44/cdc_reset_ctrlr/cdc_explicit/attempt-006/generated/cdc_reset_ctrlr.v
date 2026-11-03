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
    reg  a_clear_sync_b;
    reg  b_clear_sync_a;
    reg  a_clear_ack_sync_a;
    reg  b_clear_ack_sync_b;
    reg  a_isolate_ack_sync_a;
    reg  b_isolate_ack_sync_b;

    // Internal control signals
    reg  a_isolate_req;
    reg  b_isolate_req;
    reg  a_clear_req;
    reg  b_clear_req;
    reg  a_clear_active;
    reg  b_clear_active;
    reg  a_isolate_active;
    reg  b_isolate_active;
    reg  a_clear_done;
    reg  b_clear_done;
    reg  a_isolate_done;
    reg  b_isolate_done;

    // Instantiate synchronization modules
    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_clear_to_b (
        .async_in(a_clear_i),
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .sync_out(a_clear_sync_b)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_clear_ack_to_a (
        .async_in(b_clear_ack_i),
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .sync_out(b_clear_ack_sync_a)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_clear_to_a (
        .async_in(b_clear_i),
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .sync_out(b_clear_sync_a)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_clear_ack_to_b (
        .async_in(a_clear_ack_i),
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .sync_out(a_clear_ack_sync_b)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_isolate_ack_to_a (
        .async_in(b_isolate_ack_i),
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .sync_out(b_isolate_ack_sync_a)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_isolate_ack_to_b (
        .async_in(a_isolate_ack_i),
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .sync_out(a_isolate_ack_sync_b)
    );

    // FSM for domain A
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_req  <= 0;
            a_clear_req    <= 0;
            a_clear_active <= 0;
            a_isolate_active <= 0;
            a_clear_done   <= 0;
            a_isolate_done <= 0;
        end else begin
            // Request isolate if clear is requested and not already active
            if (a_clear_i && !a_clear_active) begin
                a_isolate_req <= 1;
            end

            // Confirm isolate request
            if (a_isolate_req && a_isolate_ack_sync_a) begin
                a_isolate_active <= 1;
                a_isolate_req    <= 0;
            end

            // Request clear if both isolates are active
            if (a_isolate_active && b_isolate_active) begin
                a_clear_req <= 1;
            end

            // Confirm clear request
            if (a_clear_req && a_clear_ack_sync_a) begin
                a_clear_active <= 1;
                a_clear_req    <= 0;
            end

            // Confirm clear done
            if (a_clear_active && !a_clear_sync_b) begin
                a_clear_done <= 1;
                a_clear_active <= 0;
            end

            // Confirm release
            if (a_clear_done && b_clear_done) begin
                a_clear_done     <= 0;
                a_isolate_active <= 0;
                a_isolate_req    <= 0;
            end
        end
    end

    // FSM for domain B
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_req  <= 0;
            b_clear_req    <= 0;
            b_clear_active <= 0;
            b_isolate_active <= 0;
            b_clear_done   <= 0;
            b_isolate_done <= 0;
        end else begin
            // Request isolate if clear is requested and not already active
            if (b_clear_i && !b_clear_active) begin
                b_isolate_req <= 1;
            end

            // Confirm isolate request
            if (b_isolate_req && b_isolate_ack_sync_b) begin
                b_isolate_active <= 1;
                b_isolate_req    <= 0;
            end

            // Request clear if both isolates are active
            if (b_isolate_active && a_isolate_active) begin
                b_clear_req <= 1;
            end

            // Confirm clear request
            if (b_clear_req && b_clear_ack_sync_b) begin
                b_clear_active <= 1;
                b_clear_req    <= 0;
            end

            // Confirm clear done
            if (b_clear_active && !b_clear_sync_a) begin
                b_clear_done <= 1;
                b_clear_active <= 0;
            end

            // Confirm release
            if (b_clear_done && a_clear_done) begin
                b_clear_done     <= 0;
                b_isolate_active <= 0;
                b_isolate_req    <= 0;
            end
        end
    end

    // Output assignments
    assign a_isolate_o = a_isolate_req;
    assign a_clear_o   = a_clear_active;
    assign b_isolate_o = b_isolate_req;
    assign b_clear_o   = b_clear_active;

endmodule

module cdc_sync #(
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
            for (int i = 0; i < SYNC_STAGES-1; i = i + 1) begin
                sync_stages[i+1] <= sync_stages[i];
            end
        end
    end

    assign sync_out = sync_stages[SYNC_STAGES-1];

endmodule
