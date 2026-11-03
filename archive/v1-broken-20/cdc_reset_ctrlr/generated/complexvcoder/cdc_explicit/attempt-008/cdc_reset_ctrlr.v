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
    logic a_clear_o_sync;
    logic a_isolate_o_sync;
    logic b_clear_o_sync;
    logic b_isolate_o_sync;

    // Synchronization modules
    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) a_sync_reset (
        .clk(a_clk_i),
        .rst_n(a_rst_ni),
        .sync_out(a_clear_o_sync)
    );

    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) b_sync_reset (
        .clk(b_clk_i),
        .rst_n(b_rst_ni),
        .sync_out(b_clear_o_sync)
    );

    // Control logic
    control_logic #(.SYNC_STAGES(SYNC_STAGES)) ctrl_logic (
        .a_clear_i(a_clear_i),
        .a_clear_ack_i(a_clear_ack_i),
        .a_isolate_ack_i(a_isolate_ack_i),
        .b_clear_i(b_clear_i),
        .b_clear_ack_i(b_clear_ack_i),
        .b_isolate_ack_i(b_isolate_ack_i),
        .a_sync_reset_out(a_clear_o_sync),
        .b_sync_reset_out(b_clear_o_sync),
        .a_clear_o(a_clear_o),
        .a_isolate_o(a_isolate_o),
        .b_clear_o(b_clear_o),
        .b_isolate_o(b_isolate_o)
    );

endmodule

module sync_reset #(
    parameter SYNC_STAGES = 2
)(
    input  clk,
    input  rst_n,
    output sync_out
);

    reg [SYNC_STAGES-1:0] sync_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg <= {SYNC_STAGES{1'b0}};
        end else begin
            sync_reg <= {sync_reg[SYNC_STAGES-2:0], 1'b1};
        end
    end

    assign sync_out = sync_reg[SYNC_STAGES-1];

endmodule

module control_logic #(
    parameter SYNC_STAGES = 2
)(
    input  a_clear_i,
    input  a_clear_ack_i,
    input  a_isolate_ack_i,
    input  b_clear_i,
    input  b_clear_ack_i,
    input  b_isolate_ack_i,
    input  a_sync_reset_out,
    input  b_sync_reset_out,
    output a_clear_o,
    output a_isolate_o,
    output b_clear_o,
    output b_isolate_o
);

    // Internal signals
    logic a_clear_ack_reg;
    logic a_isolate_ack_reg;
    logic b_clear_ack_reg;
    logic b_isolate_ack_reg;
    logic a_clear_o_reg;
    logic a_isolate_o_reg;
    logic b_clear_o_reg;
    logic b_isolate_o_reg;

    always @(posedge a_clk_i) begin
        a_clear_ack_reg <= a_clear_ack_i;
        a_isolate_ack_reg <= a_isolate_ack_i;
    end

    always @(posedge b_clk_i) begin
        b_clear_ack_reg <= b_clear_ack_i;
        b_isolate_ack_reg <= b_isolate_ack_i;
    end

    always @(posedge a_clk_i or posedge b_clk_i) begin
        if (!a_rst_n) begin
            a_clear_o_reg <= 1'b0;
            a_isolate_o_reg <= 1'b0;
        end else if (a_clear_i && a_clear_ack_reg && a_isolate_ack_reg) begin
            a_clear_o_reg <= 1'b1;
        end else if (a_clear_ack_i && a_isolate_ack_i) begin
            a_clear_o_reg <= 1'b0;
        end

        if (!b_rst_n) begin
            b_clear_o_reg <= 1'b0;
            b_isolate_o_reg <= 1'b0;
        end else if (b_clear_i && b_clear_ack_reg && b_isolate_ack_reg) begin
            b_clear_o_reg <= 1'b1;
        end else if (b_clear_ack_i && b_isolate_ack_i) begin
            b_clear_o_reg <= 1'b0;
        end
    end

    assign a_clear_o = a_clear_o_reg;
    assign a_isolate_o = a_isolate_o_reg;
    assign b_clear_o = b_clear_o_reg;
    assign b_isolate_o = b_isolate_o_reg;

endmodule
