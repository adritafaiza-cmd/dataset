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
    logic a_clear_reg;
    logic a_isolate_reg;
    logic b_clear_reg;
    logic b_isolate_reg;
    logic [SYNC_STAGES-1:0] a_clear_sync;
    logic [SYNC_STAGES-1:0] a_isolate_sync;
    logic [SYNC_STAGES-1:0] b_clear_sync;
    logic [SYNC_STAGES-1:0] b_isolate_sync;

    // Synchronizer for a_clear_i and a_isolate_ack_i
    always_ff @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_sync <= {SYNC_STAGES{1'b0}};
            a_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            a_clear_sync <= {a_clear_i, a_clear_sync[SYNC_STAGES-2:0]};
            a_isolate_sync <= {a_isolate_ack_i, a_isolate_sync[SYNC_STAGES-2:0]};
        end
    end

    // Synchronizer for b_clear_i and b_isolate_ack_i
    always_ff @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_sync <= {SYNC_STAGES{1'b0}};
            b_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            b_clear_sync <= {b_clear_i, b_clear_sync[SYNC_STAGES-2:0]};
            b_isolate_sync <= {b_isolate_ack_i, b_isolate_sync[SYNC_STAGES-2:0]};
        end
    end

    // Logic to handle clear and isolate signals
    always_ff @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_reg <= 1'b0;
            a_isolate_reg <= 1'b0;
            a_clear_o <= 1'b0;
            a_isolate_o <= 1'b0;
        end else begin
            if (a_clear_i || b_clear_i) begin
                a_isolate_reg <= 1'b1;
                a_clear_reg <= 1'b1;
                a_clear_o <= 1'b1;
                a_isolate_o <= 1'b1;
            end else if (a_isolate_sync[SYNC_STAGES-1] && a_clear_sync[SYNC_STAGES-1] && a_clear_ack_i && b_clear_ack_i) begin
                a_isolate_reg <= 1'b0;
                a_clear_reg <= 1'b0;
                a_clear_o <= 1'b0;
                a_isolate_o <= 1'b0;
            end else begin
                a_clear_o <= a_clear_reg;
                a_isolate_o <= a_isolate_reg;
            end
        end
    end

    // Logic to handle clear and isolate signals for b_clk_i domain
    always_ff @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_reg <= 1'b0;
            b_isolate_reg <= 1'b0;
            b_clear_o <= 1'b0;
            b_isolate_o <= 1'b0;
        end else begin
            if (a_clear_i || b_clear_i) begin
                b_isolate_reg <= 1'b1;
                b_clear_reg <= 1'b1;
                b_clear_o <= 1'b1;
                b_isolate_o <= 1'b1;
            end else if (b_isolate_sync[SYNC_STAGES-1] && b_clear_sync[SYNC_STAGES-1] && b_clear_ack_i && a_clear_ack_i) begin
                b_isolate_reg <= 1'b0;
                b_clear_reg <= 1'b0;
                b_clear_o <= 1'b0;
                b_isolate_o <= 1'b0;
            end else begin
                b_clear_o <= b_clear_reg;
                b_isolate_o <= b_isolate_reg;
            end
        end
    end

endmodule
