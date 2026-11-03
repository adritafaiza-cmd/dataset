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

reg a_isolate;
reg a_clear;
reg b_isolate;
reg b_clear;

always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        a_isolate <= 1'b0;
        a_clear <= 1'b0;
        a_clear_sync <= {SYNC_STAGES{1'b0}};
        a_isolate_sync <= {SYNC_STAGES{1'b0}};
    end else begin
        a_isolate_sync[0] <= b_isolate;
        a_clear_sync[0] <= b_clear;
        for (genvar i = 1; i < SYNC_STAGES; i++) begin
            a_isolate_sync[i] <= a_isolate_sync[i-1];
            a_clear_sync[i] <= a_clear_sync[i-1];
        end
        if (a_clear_i && !a_isolate && !a_clear) begin
            a_isolate <= 1'b1;
        end else if (a_isolate && a_isolate_ack_i && b_isolate_sync[SYNC_STAGES-1]) begin
            a_isolate <= 1'b0;
            a_clear <= 1'b1;
        end else if (a_clear && a_clear_ack_i && b_clear_sync[SYNC_STAGES-1]) begin
            a_clear <= 1'b0;
        end
    end
end

always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        b_isolate <= 1'b0;
        b_clear <= 1'b0;
        b_isolate_sync <= {SYNC_STAGES{1'b0}};
        b_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
        b_isolate_sync[0] <= a_isolate;
        b_clear_sync[0] <= a_clear;
        for (genvar i = 1; i < SYNC_STAGES; i++) begin
            b_isolate_sync[i] <= b_isolate_sync[i-1];
            b_clear_sync[i] <= b_clear_sync[i-1];
        end
        if (b_clear_i && !b_isolate && !b_clear) begin
            b_isolate <= 1'b1;
        end else if (b_isolate && b_isolate_ack_i && a_isolate_sync[SYNC_STAGES-1]) begin
            b_isolate <= 1'b0;
            b_clear <= 1'b1;
        end else if (b_clear && b_clear_ack_i && a_clear_sync[SYNC_STAGES-1]) begin
            b_clear <= 1'b0;
        end
    end
end

assign a_isolate_o = a_isolate;
assign a_clear_o = a_clear;
assign b_isolate_o = b_isolate;
assign b_clear_o = b_clear;

endmodule
