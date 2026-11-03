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
    reg a_clear_req;
    reg b_isolate_req;
    reg b_clear_req;
    reg a_isolate_done;
    reg a_clear_done;
    reg b_isolate_done;
    reg b_clear_done;
    reg a_isolate_sync;
    reg a_clear_sync;
    reg b_isolate_sync;
    reg b_clear_sync;
    reg a_isolate_ack_sync;
    reg a_clear_ack_sync;
    reg b_isolate_ack_sync;
    reg b_clear_ack_sync;

    // Cross-domain synchronization modules
    sync_cell #(.STAGES(SYNC_STAGES)) sync_a_isolate_ack (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .d_i(a_isolate_ack_i),
        .q_o(a_isolate_ack_sync)
    );

    sync_cell #(.STAGES(SYNC_STAGES)) sync_a_clear_ack (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .d_i(a_clear_ack_i),
        .q_o(a_clear_ack_sync)
    );

    sync_cell #(.STAGES(SYNC_STAGES)) sync_b_isolate_ack (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .d_i(b_isolate_ack_i),
        .q_o(b_isolate_ack_sync)
    );

    sync_cell #(.STAGES(SYNC_STAGES)) sync_b_clear_ack (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .d_i(b_clear_ack_i),
        .q_o(b_clear_ack_sync)
    );

    // State machine for domain A
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_o <= 0;
            a_clear_o <= 0;
            a_isolate_req <= 0;
            a_clear_req <= 0;
            a_isolate_done <= 0;
            a_clear_done <= 0;
        end else begin
            case ({a_isolate_req, a_clear_req, a_isolate_done, a_clear_done, a_isolate_ack_sync, a_clear_ack_sync})
                6'b000000: begin // Idle
                    if (a_clear_i || b_clear_sync)
                        a_isolate_req <= 1;
                end
                6'b100000: begin // Isolate requested
                    a_isolate_o <= 1;
                    if (a_isolate_ack_sync)
                        a_isolate_done <= 1;
                end
                6'b101000: begin // Isolate done, wait for peer
                    if (b_isolate_sync)
                        a_clear_req <= 1;
                end
                6'b101100: begin // Clear requested
                    a_clear_o <= 1;
                    if (a_clear_ack_sync)
                        a_clear_done <= 1;
                end
                6'b101110: begin // Clear done, wait for peer
                    if (b_clear_sync)
                        a_isolate_req <= 0;
                end
                6'b001110: begin // Release clear
                    a_clear_o <= 0;
                    if (!a_clear_i && !b_clear_sync)
                        a_clear_done <= 0;
                end
                6'b000110: begin // Release isolate
                    a_isolate_o <= 0;
                    if (!a_isolate_req)
                        a_isolate_done <= 0;
                end
            endcase
        end
    end

    // State machine for domain B
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_o <= 0;
            b_clear_o <= 0;
            b_isolate_req <= 0;
            b_clear_req <= 0;
            b_isolate_done <= 0;
            b_clear_done <= 0;
        end else begin
            case ({b_isolate_req, b_clear_req, b_isolate_done, b_clear_done, b_isolate_ack_sync, b_clear_ack_sync})
                6'b000000: begin // Idle
                    if (b_clear_i || a_clear_sync)
                        b_isolate_req <= 1;
                end
                6'b100000: begin // Isolate requested
                    b_isolate_o <= 1;
                    if (b_isolate_ack_sync)
                        b_isolate_done <= 1;
                end
                6'b101000: begin // Isolate done, wait for peer
                    if (a_isolate_sync)
                        b_clear_req <= 1;
                end
                6'b101100: begin // Clear requested
                    b_clear_o <= 1;
                    if (b_clear_ack_sync)
                        b_clear_done <= 1;
                end
                6'b101110: begin // Clear done, wait for peer
                    if (a_clear_sync)
                        b_isolate_req <= 0;
                end
                6'b001110: begin // Release clear
                    b_clear_o <= 0;
                    if (!b_clear_i && !a_clear_sync)
                        b_clear_done <= 0;
                end
                6'b000110: begin // Release isolate
                    b_isolate_o <= 0;
                    if (!b_isolate_req)
                        b_isolate_done <= 0;
                end
            endcase
        end
    end

    // Cross-domain synchronization for clear requests
    sync_cell #(.STAGES(SYNC_STAGES)) sync_b_clear_req (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .d_i(b_clear_i),
        .q_o(b_clear_sync)
    );

    sync_cell #(.STAGES(SYNC_STAGES)) sync_a_clear_req (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .d_i(a_clear_i),
        .q_o(a_clear_sync)
    );

    // Cross-domain synchronization for isolate done
    sync_cell #(.STAGES(SYNC_STAGES)) sync_a_isolate_done (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .d_i(a_isolate_done),
        .q_o(a_isolate_sync)
    );

    sync_cell #(.STAGES(SYNC_STAGES)) sync_b_isolate_done (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .d_i(b_isolate_done),
        .q_o(b_isolate_sync)
    );

endmodule

module sync_cell #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  d_i,
    output reg q_o
);

    reg [STAGES-1:0] sync_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= 0;
        end else begin
            sync_reg <= {sync_reg[STAGES-2:0], d_i};
        end
    end

    assign q_o = sync_reg[STAGES-1];

endmodule
