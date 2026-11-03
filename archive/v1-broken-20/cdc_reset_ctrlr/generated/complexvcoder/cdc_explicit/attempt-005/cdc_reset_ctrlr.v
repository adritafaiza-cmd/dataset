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
    reg a_clear_req;
    reg a_isolate_req;
    reg b_clear_req;
    reg b_isolate_req;
    wire a_clear_ack;
    wire a_isolate_ack;
    wire b_clear_ack;
    wire b_isolate_ack;

    // Sync modules for cross-domain signaling
    sync_module sync_a_to_b (
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .in(a_clear_i),
        .in_ack(a_isolate_ack_i),
        .out(b_clear_o),
        .out_ack(b_clear_i)
    );

    sync_module sync_b_to_a (
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .in(b_clear_i),
        .in_ack(b_isolate_ack_i),
        .out(a_clear_o),
        .out_ack(a_clear_i)
    );

    // Reset control modules for each domain
    reset_control reset_ctrl_a (
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .clear_req(a_clear_req),
        .isolate_req(a_isolate_req),
        .clear_ack(a_clear_ack),
        .isolate_ack(a_isolate_ack)
    );

    reset_control reset_ctrl_b (
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .clear_req(b_clear_req),
        .isolate_req(b_isolate_req),
        .clear_ack(b_clear_ack),
        .isolate_ack(b_isolate_ack)
    );

    // Control logic for clearing and isolating
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_req <= 0;
            a_isolate_req <= 0;
        end else begin
            a_clear_req <= a_clear_i;
            a_isolate_req <= a_isolate_ack_i;
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_req <= 0;
            b_isolate_req <= 0;
        end else begin
            b_clear_req <= b_clear_i;
            b_isolate_req <= b_isolate_ack_i;
        end
    end

endmodule

module sync_module (
    input  clk,
    input  rst_ni,
    input  in,
    input  in_ack,
    output out,
    output out_ack
);

    reg [SYNC_STAGES-1:0] shift_reg;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            shift_reg <= {SYNC_STAGES{0}};
        end else begin
            shift_reg <= {shift_reg[SYNC_STAGES-2:0], in};
        end
    end

    assign out = shift_reg[SYNC_STAGES-1];
    assign out_ack = in_ack;

endmodule

module reset_control (
    input  clk,
    input  rst_ni,
    input  clear_req,
    input  isolate_req,
    output clear_ack,
    output isolate_ack
);

    reg clear_state;
    reg isolate_state;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            clear_state <= 0;
            isolate_state <= 0;
        end else begin
            if (clear_req) begin
                isolate_state <= 1;
            end else if (isolate_req) begin
                clear_state <= 1;
            end else if (clear_ack && isolate_ack) begin
                clear_state <= 0;
                isolate_state <= 0;
            end
        end
    end

    assign clear_ack = clear_state && isolate_state;
    assign isolate_ack = clear_state && isolate_state;

endmodule
