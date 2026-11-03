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

    reg [1:0] a_state, b_state;
    reg a_isolate_sync, b_isolate_sync;
    reg a_clear_sync, b_clear_sync;
    reg a_isolate_ack_sync, b_isolate_ack_sync;
    reg a_clear_ack_sync, b_clear_ack_sync;

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= 0;
            a_isolate_sync <= 0;
            a_clear_sync <= 0;
            a_isolate_ack_sync <= 0;
            a_clear_ack_sync <= 0;
        end else begin
            if (a_clear_i) begin
                case (a_state)
                    0: begin
                        a_isolate_sync <= 1;
                        a_state <= 1;
                    end
                    1: begin
                        if (a_isolate_ack_i && b_isolate_sync) begin
                            a_clear_sync <= 1;
                            a_state <= 2;
                        end
                    end
                    2: begin
                        if (a_clear_ack_i && b_clear_sync) begin
                            a_isolate_sync <= 0;
                            a_clear_sync <= 0;
                            a_state <= 0;
                        end
                    end
                endcase
            end
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= 0;
            b_isolate_sync <= 0;
            b_clear_sync <= 0;
            b_isolate_ack_sync <= 0;
            b_clear_ack_sync <= 0;
        end else begin
            if (b_clear_i) begin
                case (b_state)
                    0: begin
                        b_isolate_sync <= 1;
                        b_state <= 1;
                    end
                    1: begin
                        if (b_isolate_ack_i && a_isolate_sync) begin
                            b_clear_sync <= 1;
                            b_state <= 2;
                        end
                    end
                    2: begin
                        if (b_clear_ack_i && a_clear_sync) begin
                            b_isolate_sync <= 0;
                            b_clear_sync <= 0;
                            b_state <= 0;
                        end
                    end
                endcase
            end
        end
    end

    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) u_a_isolate_sync (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .async_i(a_isolate_o),
        .sync_o(b_isolate_sync)
    );

    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) u_b_isolate_sync (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .async_i(b_isolate_o),
        .sync_o(a_isolate_sync)
    );

    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) u_a_clear_sync (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .async_i(a_clear_o),
        .sync_o(b_clear_sync)
    );

    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) u_b_clear_sync (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .async_i(b_clear_o),
        .sync_o(a_clear_sync)
    );

    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) u_a_isolate_ack_sync (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .async_i(a_isolate_ack_i),
        .sync_o(b_isolate_ack_sync)
    );

    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) u_b_isolate_ack_sync (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .async_i(b_isolate_ack_i),
        .sync_o(a_isolate_ack_sync)
    );

    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) u_a_clear_ack_sync (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .async_i(a_clear_ack_i),
        .sync_o(b_clear_ack_sync)
    );

    sync_reset #(.SYNC_STAGES(SYNC_STAGES)) u_b_clear_ack_sync (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .async_i(b_clear_ack_i),
        .sync_o(a_clear_ack_sync)
    );

    assign a_isolate_o = a_isolate_sync;
    assign b_isolate_o = b_isolate_sync;
    assign a_clear_o = a_clear_sync;
    assign b_clear_o = b_clear_sync;

endmodule

module sync_reset #(
    parameter SYNC_STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_i,
    output sync_o
);

    reg [SYNC_STAGES-1:0] sync_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {SYNC_STAGES{1'b0}};
        end else begin
            sync_reg[0] <= async_i;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign sync_o = sync_reg[SYNC_STAGES-1];

endmodule
