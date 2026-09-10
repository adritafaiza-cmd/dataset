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

reg [SYNC_STAGES-1:0] a_rst_n;
reg [SYNC_STAGES-1:0] b_rst_n;

always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        a_rst_n <= {SYNC_STAGES{1'b0}};
    end else begin
        a_rst_n <= {a_rst_n[SYNC_STAGES-2:0], a_rst_ni};
    end
end

always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        b_rst_n <= {SYNC_STAGES{1'b0}};
    end else begin
        b_rst_n <= {b_rst_n[SYNC_STAGES-2:0], b_rst_ni};
    end
end

reg a_clear_req;
reg b_clear_req;
reg a_isolate_req;
reg b_isolate_req;
reg a_clear_ack;
reg b_clear_ack;
reg a_isolate_ack;
reg b_isolate_ack;

always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        a_clear_req <= 1'b0;
        a_isolate_req <= 1'b0;
        a_clear_ack <= 1'b0;
        a_isolate_ack <= 1'b0;
    end else begin
        if (a_clear_i) begin
            a_clear_req <= 1'b1;
        end else if (a_isolate_ack_i && a_clear_ack_i) begin
            a_clear_req <= 1'b0;
        end
        if (a_isolate_ack_i) begin
            a_isolate_req <= 1'b0;
        end else if (a_clear_i) begin
            a_isolate_req <= 1'b1;
        end
        if (a_clear_ack_i) begin
            a_clear_ack <= 1'b1;
        end else if (a_isolate_ack_i && a_clear_ack_i) begin
            a_clear_ack <= 1'b0;
        end
        if (a_isolate_ack_i) begin
            a_isolate_ack <= 1'b1;
        end else if (a_isolate_ack_i && a_clear_ack_i) begin
            a_isolate_ack <= 1'b0;
        end
    end
end

always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        b_clear_req <= 1'b0;
        b_isolate_req <= 1'b0;
        b_clear_ack <= 1'b0;
        b_isolate_ack <= 1'b0;
    end else begin
        if (b_clear_i) begin
            b_clear_req <= 1'b1;
        end else if (b_isolate_ack_i && b_clear_ack_i) begin
            b_clear_req <= 1'b0;
        end
        if (b_isolate_ack_i) begin
            b_isolate_req <= 1'b0;
        end else if (b_clear_i) begin
            b_isolate_req <= 1'b1;
        end
        if (b_clear_ack_i) begin
            b_clear_ack <= 1'b1;
        end else if (b_isolate_ack_i && b_clear_ack_i) begin
            b_clear_ack <= 1'b0;
        end
        if (b_isolate_ack_i) begin
            b_isolate_ack <= 1'b1;
        end else if (b_isolate_ack_i && b_clear_ack_i) begin
            b_isolate_ack <= 1'b0;
        end
    end
end

assign a_clear_o = a_clear_req && a_rst_n[SYNC_STAGES-1];
assign b_clear_o = b_clear_req && b_rst_n[SYNC_STAGES-1];
assign a_isolate_o = a_isolate_req && a_rst_n[SYNC_STAGES-1];
assign b_isolate_o = b_isolate_req && b_rst_n[SYNC_STAGES-1];

endmodule
