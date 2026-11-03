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
    reg [SYNC_STAGES-1:0] a_clear_reg;
    reg [SYNC_STAGES-1:0] a_isolate_reg;
    reg [SYNC_STAGES-1:0] b_clear_reg;
    reg [SYNC_STAGES-1:0] b_isolate_reg;
    reg a_clear_out;
    reg a_isolate_out;
    reg b_clear_out;
    reg b_isolate_out;

    // Synchronize clear and isolate signals to b_clk_i domain
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_reg <= {SYNC_STAGES{1'b0}};
            b_isolate_reg <= {SYNC_STAGES{1'b0}};
        end else begin
            b_clear_reg <= {b_clear_reg[SYNC_STAGES-2:0], b_clear_i};
            b_isolate_reg <= {b_isolate_reg[SYNC_STAGES-2:0], a_clear_i};
        end
    end

    // Synchronize clear and isolate signals to a_clk_i domain
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_reg <= {SYNC_STAGES{1'b0}};
            a_isolate_reg <= {SYNC_STAGES{1'b0}};
        end else begin
            a_clear_reg <= {a_clear_reg[SYNC_STAGES-2:0], b_clear_i};
            a_isolate_reg <= {a_isolate_reg[SYNC_STAGES-2:0], b_clear_i};
        end
    end

    // Output logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_out <= 1'b0;
            a_isolate_out <= 1'b0;
        end else begin
            a_clear_out <= (b_clear_reg[SYNC_STAGES-1] && b_isolate_ack_i) ? 1'b1 : 1'b0;
            a_isolate_out <= (b_clear_reg[SYNC_STAGES-1] && b_isolate_ack_i) ? 1'b1 : 1'b0;
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_out <= 1'b0;
            b_isolate_out <= 1'b0;
        end else begin
            b_clear_out <= (a_clear_reg[SYNC_STAGES-1] && a_isolate_ack_i) ? 1'b1 : 1'b0;
            b_isolate_out <= (a_clear_reg[SYNC_STAGES-1] && a_isolate_ack_i) ? 1'b1 : 1'b0;
        end
    end

    // Assign outputs
    assign a_clear_o = a_clear_out;
    assign a_isolate_o = a_isolate_out;
    assign b_clear_o = b_clear_out;
    assign b_isolate_o = b_isolate_out;

endmodule
