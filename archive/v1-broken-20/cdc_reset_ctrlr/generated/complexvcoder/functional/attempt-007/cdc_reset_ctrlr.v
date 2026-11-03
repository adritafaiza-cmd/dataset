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

    reg [SYNC_STAGES-1:0] a_clear_reg;
    reg [SYNC_STAGES-1:0] a_isolate_reg;
    reg [SYNC_STAGES-1:0] b_clear_reg;
    reg [SYNC_STAGES-1:0] b_isolate_reg;
    reg [SYNC_STAGES-1:0] a_clear_ack_reg;
    reg [SYNC_STAGES-1:0] b_clear_ack_reg;

    wire a_clear_r;
    wire a_isolate_r;
    wire b_clear_r;
    wire b_isolate_r;

    assign a_clear_r = |a_clear_reg;
    assign a_isolate_r = |a_isolate_reg;
    assign b_clear_r = |b_clear_reg;
    assign b_isolate_r = |b_isolate_reg;

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_reg <= 0;
            a_isolate_reg <= 0;
        end else begin
            a_clear_reg <= {a_clear_reg[SYNC_STAGES-2:0], a_clear_i};
            a_isolate_reg <= {a_isolate_reg[SYNC_STAGES-2:0], a_clear_r & a_isolate_ack_i};
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_reg <= 0;
            b_isolate_reg <= 0;
        end else begin
            b_clear_reg <= {b_clear_reg[SYNC_STAGES-2:0], b_clear_i};
            b_isolate_reg <= {b_isolate_reg[SYNC_STAGES-2:0], b_clear_r & b_isolate_ack_i};
        end
    end

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_o <= 0;
            a_isolate_o <= 0;
        end else begin
            a_clear_o <= a_clear_r & b_clear_r & a_isolate_ack_reg & b_isolate_ack_reg;
            a_isolate_o <= a_clear_r & b_clear_r & a_isolate_reg & b_isolate_reg;
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_o <= 0;
            b_isolate_o <= 0;
        end else begin
            b_clear_o <= a_clear_r & b_clear_r & a_isolate_ack_reg & b_isolate_ack_reg;
            b_isolate_o <= a_clear_r & b_clear_r & a_isolate_reg & b_isolate_reg;
        end
    end

endmodule
