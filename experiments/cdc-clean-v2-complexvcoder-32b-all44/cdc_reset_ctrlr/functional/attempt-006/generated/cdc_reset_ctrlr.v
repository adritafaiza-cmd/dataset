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
    reg  a_isolate_req, b_isolate_req;
    reg  a_clear_req, b_clear_req;
    reg  a_clear_req_sync, b_clear_req_sync;
    reg  a_isolate_req_sync, b_isolate_req_sync;
    reg  a_clear_done, b_clear_done;
    reg  a_isolate_done, b_isolate_done;
    reg [1:0] a_clear_state, b_clear_state;

    // Sync signals between domains
    sync_cell #(.SYNC_STAGES(SYNC_STAGES)) sync_a_clear_req (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .d_i(a_clear_i),
        .q_o(a_clear_req_sync)
    );

    sync_cell #(.SYNC_STAGES(SYNC_STAGES)) sync_b_clear_req (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .d_i(b_clear_i),
        .q_o(b_clear_req_sync)
    );

    sync_cell #(.SYNC_STAGES(SYNC_STAGES)) sync_a_isolate_req (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .d_i(a_isolate_req),
        .q_o(a_isolate_req_sync)
    );

    sync_cell #(.SYNC_STAGES(SYNC_STAGES)) sync_b_isolate_req (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .d_i(b_isolate_req),
        .q_o(b_isolate_req_sync)
    );

    // FSM for domain A
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_o <= 0;
            a_isolate_o <= 0;
            a_clear_state <= 2'b00;
        end else begin
            case (a_clear_state)
                2'b00: begin // IDLE
                    a_isolate_req <= a_clear_i | b_clear_req_sync;
                    if (a_isolate_req & a_isolate_ack_i) begin
                        a_clear_state <= 2'b01; // ISOLATE
                    end
                end
                2'b01: begin // ISOLATE
                    a_isolate_o <= 1;
                    if (b_isolate_req_sync & b_isolate_ack_i) begin
                        a_clear_state <= 2'b10; // CLEAR
                    end
                end
                2'b10: begin // CLEAR
                    a_clear_o <= 1;
                    if (a_clear_ack_i & b_clear_ack_i) begin
                        a_clear_state <= 2'b11; // RELEASE
                    end
                end
                2'b11: begin // RELEASE
                    a_isolate_o <= 0;
                    a_clear_o <= 0;
                    a_clear_state <= 2'b00; // IDLE
                end
            endcase
        end
    end

    // FSM for domain B
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_o <= 0;
            b_isolate_o <= 0;
            b_clear_state <= 2'b00;
        end else begin
            case (b_clear_state)
                2'b00: begin // IDLE
                    b_isolate_req <= b_clear_i | a_clear_req_sync;
                    if (b_isolate_req & b_isolate_ack_i) begin
                        b_clear_state <= 2'b01; // ISOLATE
                    end
                end
                2'b01: begin // ISOLATE
                    b_isolate_o <= 1;
                    if (a_isolate_req_sync & a_isolate_ack_i) begin
                        b_clear_state <= 2'b10; // CLEAR
                    end
                end
                2'b10: begin // CLEAR
                    b_clear_o <= 1;
                    if (a_clear_ack_i & b_clear_ack_i) begin
                        b_clear_state <= 2'b11; // RELEASE
                    end
                end
                2'b11: begin // RELEASE
                    b_isolate_o <= 0;
                    b_clear_o <= 0;
                    b_clear_state <= 2'b00; // IDLE
                end
            endcase
        end
    end

endmodule

// Synchronizer cell module
module sync_cell #(
    parameter SYNC_STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  d_i,
    output q_o
);

    reg [SYNC_STAGES-1:0] sync_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {SYNC_STAGES{1'b0}};
        end else begin
            sync_reg <= {sync_reg[SYNC_STAGES-2:0], d_i};
        end
    end

    assign q_o = sync_reg[SYNC_STAGES-1];

endmodule
