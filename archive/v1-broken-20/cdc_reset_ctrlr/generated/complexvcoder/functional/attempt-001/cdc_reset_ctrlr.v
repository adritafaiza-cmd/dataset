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

    reg a_clear_o_r;
    reg a_isolate_o_r;
    reg b_clear_o_r;
    reg b_isolate_o_r;

    // Synchronizers for a_clk_i domain
    wire a_clear_synced;
    wire a_clear_ack_synced;
    wire a_isolate_ack_synced;

    // Synchronizers for b_clk_i domain
    wire b_clear_synced;
    wire b_clear_ack_synced;
    wire b_isolate_ack_synced;

    // Synchronizer stages
    wire [SYNC_STAGES-1:0] a_clear_sync;
    wire [SYNC_STAGES-1:0] a_clear_ack_sync;
    wire [SYNC_STAGES-1:0] a_isolate_ack_sync;
    wire [SYNC_STAGES-1:0] b_clear_sync;
    wire [SYNC_STAGES-1:0] b_clear_ack_sync;
    wire [SYNC_STAGES-1:0] b_isolate_ack_sync;

    // Synchronizer logic
    generate
        for (genvar i = 0; i < SYNC_STAGES; i++) begin : sync_a_clear
            assign a_clear_sync[i] = (i == 0) ? a_clear_i : a_clear_sync[i-1];
        end
        for (genvar i = 0; i < SYNC_STAGES; i++) begin : sync_a_clear_ack
            assign a_clear_ack_sync[i] = (i == 0) ? a_clear_ack_i : a_clear_ack_sync[i-1];
        end
        for (genvar i = 0; i < SYNC_STAGES; i++) begin : sync_a_isolate_ack
            assign a_isolate_ack_sync[i] = (i == 0) ? a_isolate_ack_i : a_isolate_ack_sync[i-1];
        end
        for (genvar i = 0; i < SYNC_STAGES; i++) begin : sync_b_clear
            assign b_clear_sync[i] = (i == 0) ? b_clear_i : b_clear_sync[i-1];
        end
        for (genvar i = 0; i < SYNC_STAGES; i++) begin : sync_b_clear_ack
            assign b_clear_ack_sync[i] = (i == 0) ? b_clear_ack_i : b_clear_ack_sync[i-1];
        end
        for (genvar i = 0; i < SYNC_STAGES; i++) begin : sync_b_isolate_ack
            assign b_isolate_ack_sync[i] = (i == 0) ? b_isolate_ack_i : b_isolate_ack_sync[i-1];
        end
    endgenerate

    // Output logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_o_r <= 1'b0;
            a_isolate_o_r <= 1'b0;
        end else begin
            a_clear_o_r <= (a_clear_sync[SYNC_STAGES-1] & a_clear_ack_sync[SYNC_STAGES-1]) ? 1'b0 : a_clear_o_r;
            a_isolate_o_r <= (a_clear_sync[SYNC_STAGES-1] & a_clear_ack_sync[SYNC_STAGES-1]) ? 1'b1 : a_isolate_o_r;
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_o_r <= 1'b0;
            b_isolate_o_r <= 1'b0;
        end else begin
            b_clear_o_r <= (b_clear_sync[SYNC_STAGES-1] & b_clear_ack_sync[SYNC_STAGES-1]) ? 1'b0 : b_clear_o_r;
            b_isolate_o_r <= (b_clear_sync[SYNC_STAGES-1] & b_clear_ack_sync[SYNC_STAGES-1]) ? 1'b1 : b_isolate_o_r;
        end
    end

    // Assign outputs
    assign a_clear_o = a_clear_o_r;
    assign a_isolate_o = a_isolate_o_r;
    assign b_clear_o = b_clear_o_r;
    assign b_isolate_o = b_isolate_o_r;

endmodule
