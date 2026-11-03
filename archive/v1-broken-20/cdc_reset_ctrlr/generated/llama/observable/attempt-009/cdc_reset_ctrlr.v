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

reg [SYNC_STAGES-1:0] a_clear_sync;
reg [SYNC_STAGES-1:0] b_clear_sync;
reg [SYNC_STAGES-1:0] a_isolate_sync;
reg [SYNC_STAGES-1:0] b_isolate_sync;

reg a_isolate_req;
reg a_clear_req;
reg b_isolate_req;
reg b_clear_req;

reg a_isolate_ack_d;
reg a_clear_ack_d;
reg b_isolate_ack_d;
reg b_clear_ack_d;

always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        a_isolate_req <= 1'b0;
        a_clear_req <= 1'b0;
        a_isolate_ack_d <= 1'b0;
        a_clear_ack_d <= 1'b0;
        a_clear_sync <= {SYNC_STAGES{1'b0}};
        a_isolate_sync <= {SYNC_STAGES{1'b0}};
    end else begin
        a_isolate_req <= (a_clear_i && !a_isolate_req) || (a_isolate_req && !a_isolate_ack_i);
        a_clear_req <= (a_isolate_req && a_isolate_ack_i && !a_clear_req) || (a_clear_req && !a_clear_ack_i);
        a_isolate_ack_d <= a_isolate_ack_i;
        a_clear_ack_d <= a_clear_ack_i;
        a_clear_sync <= {a_clear_sync[SYNC_STAGES-2:0], b_clear_i};
        a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], b_isolate_i};
    end
end

always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        b_isolate_req <= 1'b0;
        b_clear_req <= 1'b0;
        b_isolate_ack_d <= 1'b0;
        b_clear_ack_d <= 1'b0;
        b_clear_sync <= {SYNC_STAGES{1'b0}};
        b_isolate_sync <= {SYNC_STAGES{1'b0}};
    end else begin
        b_isolate_req <= (b_clear_i && !b_isolate_req) || (b_isolate_req && !b_isolate_ack_i);
        b_clear_req <= (b_isolate_req && b_isolate_ack_i && !b_clear_req) || (b_clear_req && !b_clear_ack_i);
        b_isolate_ack_d <= b_isolate_ack_i;
        b_clear_ack_d <= b_clear_ack_i;
        b_clear_sync <= {b_clear_sync[SYNC_STAGES-2:0], a_clear_i};
        b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], a_isolate_i};
    end
end

assign a_isolate_o = a_isolate_req;
assign a_clear_o = a_clear_req;
assign b_isolate_o = b_isolate_req;
assign b_clear_o = b_clear_req;

reg a_isolate_i;
reg a_clear_i;
reg b_isolate_i;
reg b_clear_i;

assign a_isolate_i = a_isolate_sync[SYNC_STAGES-1];
assign a_clear_i = a_clear_sync[SYNC_STAGES-1];
assign b_isolate_i = b_isolate_sync[SYNC_STAGES-1];
assign b_clear_i = b_clear_sync[SYNC_STAGES-1];

endmodule
