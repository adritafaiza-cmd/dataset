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
    reg clear_req_a, clear_req_b;
    reg isolate_ack_a, isolate_ack_b;
    reg clear_ack_a, clear_ack_b;
    reg isolate_a, isolate_b;
    reg clear_a, clear_b;
    reg release_a, release_b;
    reg [1:0] state_a, state_b;

    // CDC synchronizers
    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_to_b_clear_req (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .async_in(a_clear_i),
        .sync_out(clear_req_a)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_to_a_clear_req (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .async_in(b_clear_i),
        .sync_out(clear_req_b)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_to_b_isolate_ack (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .async_in(a_isolate_ack_i),
        .sync_out(isolate_ack_a)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_to_a_isolate_ack (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .async_in(b_isolate_ack_i),
        .sync_out(isolate_ack_b)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_to_b_clear_ack (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .async_in(a_clear_ack_i),
        .sync_out(clear_ack_a)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_to_a_clear_ack (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .async_in(b_clear_ack_i),
        .sync_out(clear_ack_b)
    );

    // State machine for domain A
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            state_a <= 2'b00; // IDLE
            isolate_a <= 1'b0;
            clear_a <= 1'b0;
            release_a <= 1'b0;
        end else begin
            case (state_a)
                2'b00: begin // IDLE
                    if (clear_req_a || clear_req_b) begin
                        state_a <= 2'b01; // ISOLATE
                        isolate_a <= 1'b1;
                    end
                end
                2'b01: begin // ISOLATE
                    if (isolate_ack_a && isolate_ack_b) begin
                        state_a <= 2'b10; // CLEAR
                        clear_a <= 1'b1;
                    end
                end
                2'b10: begin // CLEAR
                    if (clear_ack_a && clear_ack_b) begin
                        state_a <= 2'b11; // RELEASE
                        clear_a <= 1'b0;
                    end
                end
                2'b11: begin // RELEASE
                    if (release_b) begin
                        state_a <= 2'b00; // IDLE
                        isolate_a <= 1'b0;
                    end
                end
            endcase
        end
    end

    // State machine for domain B
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            state_b <= 2'b00; // IDLE
            isolate_b <= 1'b0;
            clear_b <= 1'b0;
            release_b <= 1'b0;
        end else begin
            case (state_b)
                2'b00: begin // IDLE
                    if (clear_req_a || clear_req_b) begin
                        state_b <= 2'b01; // ISOLATE
                        isolate_b <= 1'b1;
                    end
                end
                2'b01: begin // ISOLATE
                    if (isolate_ack_a && isolate_ack_b) begin
                        state_b <= 2'b10; // CLEAR
                        clear_b <= 1'b1;
                    end
                end
                2'b10: begin // CLEAR
                    if (clear_ack_a && clear_ack_b) begin
                        state_b <= 2'b11; // RELEASE
                        clear_b <= 1'b0;
                    end
                end
                2'b11: begin // RELEASE
                    if (release_a) begin
                        state_b <= 2'b00; // IDLE
                        isolate_b <= 1'b0;
                    end
                end
            endcase
        end
    end

    // Outputs
    assign a_clear_o = clear_a;
    assign a_isolate_o = isolate_a;
    assign b_clear_o = clear_b;
    assign b_isolate_o = isolate_b;

    // Release signal generation
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            release_a <= 1'b0;
        end else begin
            if (state_a == 2'b11) begin
                release_a <= 1'b1;
            end else if (state_a == 2'b00) begin
                release_a <= 1'b0;
            end
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            release_b <= 1'b0;
        end else begin
            if (state_b == 2'b11) begin
                release_b <= 1'b1;
            end else if (state_b == 2'b00) begin
                release_b <= 1'b0;
            end
        end
    end

endmodule

module cdc_sync #(
    parameter SYNC_STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_in,
    output sync_out
);

    reg [SYNC_STAGES-1:0] sync_stages;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stages <= {SYNC_STAGES{1'b0}};
        end else begin
            sync_stages[0] <= async_in;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stages[i] <= sync_stages[i-1];
            end
        end
    end

    assign sync_out = sync_stages[SYNC_STAGES-1];

endmodule
