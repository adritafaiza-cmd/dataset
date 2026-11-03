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
    wire a_sync_rst_n_o;
    wire b_sync_rst_n_o;
    wire a_isolate_reg;
    wire b_isolate_reg;
    wire a_clear_reg;
    wire b_clear_reg;
    wire a_clear_ack_reg;
    wire b_clear_ack_reg;

    // Synchronization blocks
    sync_reset #(
        .SYNC_STAGES(SYNC_STAGES)
    ) a_sync_reset (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .rst_n_o(a_sync_rst_n_o)
    );

    sync_reset #(
        .SYNC_STAGES(SYNC_STAGES)
    ) b_sync_reset (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .rst_n_o(b_sync_rst_n_o)
    );

    // Isolate and clear control
    always_ff @(posedge a_clk_i or negedge a_sync_rst_n_o) begin
        if (!a_sync_rst_n_o) begin
            a_isolate_reg <= 1'b0;
            a_clear_reg <= 1'b0;
            a_clear_ack_reg <= 1'b0;
        end else begin
            a_isolate_reg <= a_isolate_reg | a_isolate_i;
            a_clear_reg <= a_clear_reg | a_clear_i;
            a_clear_ack_reg <= a_clear_ack_reg | a_clear_ack_i;
            if (a_isolate_reg && a_clear_reg && a_clear_ack_reg) begin
                a_isolate_reg <= 1'b0;
                a_clear_reg <= 1'b0;
                a_clear_ack_reg <= 1'b0;
            end
        end
    end

    always_ff @(posedge b_clk_i or negedge b_sync_rst_n_o) begin
        if (!b_sync_rst_n_o) begin
            b_isolate_reg <= 1'b0;
            b_clear_reg <= 1'b0;
            b_clear_ack_reg <= 1'b0;
        end else begin
            b_isolate_reg <= b_isolate_reg | b_isolate_i;
            b_clear_reg <= b_clear_reg | b_clear_i;
            b_clear_ack_reg <= b_clear_ack_reg | b_clear_ack_i;
            if (b_isolate_reg && b_clear_reg && b_clear_ack_reg) begin
                b_isolate_reg <= 1'b0;
                b_clear_reg <= 1'b0;
                b_clear_ack_reg <= 1'b0;
            end
        end
    end

    // Output logic
    assign a_isolate_o = a_isolate_reg;
    assign a_clear_o = a_clear_reg;

    assign b_isolate_o = b_isolate_reg;
    assign b_clear_o = b_clear_reg;

endmodule

module sync_reset #(
    parameter SYNC_STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    output rst_n_o
);

    reg [SYNC_STAGES-1:0] sync_reg;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {SYNC_STAGES{1'b1}};
        end else begin
            sync_reg <= {sync_reg[SYNC_STAGES-2:0], rst_ni};
        end
    end

    assign rst_n_o = sync_reg[0];

endmodule
