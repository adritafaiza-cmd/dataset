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

    // Synchronization registers for clear signals
    sync_reg #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) a_clear_sync (
        .clk(a_clk_i),
        .din(a_clear_i),
        .rst_ni(a_rst_ni),
        .dout(a_clear_synced)
    );
    sync_reg #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) b_clear_sync (
        .clk(b_clk_i),
        .din(b_clear_i),
        .rst_ni(b_rst_ni),
        .dout(b_clear_synced)
    );

    // Synchronization registers for clear ack signals
    sync_reg #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) a_clear_ack_sync (
        .clk(a_clk_i),
        .din(a_clear_ack_i),
        .rst_ni(a_rst_ni),
        .dout(a_clear_ack_synced)
    );
    sync_reg #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) b_clear_ack_sync (
        .clk(b_clk_i),
        .din(b_clear_ack_i),
        .rst_ni(b_rst_ni),
        .dout(b_clear_ack_synced)
    );

    // Synchronization registers for isolate signals
    sync_reg #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) a_isolate_sync (
        .clk(a_clk_i),
        .din(a_isolate_i),
        .rst_ni(a_rst_ni),
        .dout(a_isolate_synced)
    );
    sync_reg #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) b_isolate_sync (
        .clk(b_clk_i),
        .din(b_isolate_i),
        .rst_ni(b_rst_ni),
        .dout(b_isolate_synced)
    );

    // Synchronization registers for isolate ack signals
    sync_reg #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) a_isolate_ack_sync (
        .clk(a_clk_i),
        .din(a_isolate_ack_i),
        .rst_ni(a_rst_ni),
        .dout(a_isolate_ack_synced)
    );
    sync_reg #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) b_isolate_ack_sync (
        .clk(b_clk_i),
        .din(b_isolate_ack_i),
        .rst_ni(b_rst_ni),
        .dout(b_isolate_ack_synced)
    );

    // Isolate and then clear logic
    logic a_isolate;
    logic b_isolate;
    logic a_clear;
    logic b_clear;

    assign a_isolate = a_isolate_synced | b_isolate_synced;
    assign b_isolate = a_isolate_synced | b_isolate_synced;
    assign a_clear = a_clear_synced | b_clear_synced;
    assign b_clear = a_clear_synced | b_clear_synced;

    assign a_isolate_o = a_isolate;
    assign b_isolate_o = b_isolate;
    assign a_clear_o = a_clear;
    assign b_clear_o = b_clear;

endmodule

module sync_reg #(
    parameter WIDTH = 1,
    parameter SYNC_STAGES = 2
)(
    input  clk,
    input  rst_ni,
    input  din,
    output dout
);

    reg [WIDTH-1:0] reg_q [0:SYNC_STAGES-1];

    always_ff @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            reg_q <= {WIDTH{1'b0}};
        end else begin
            reg_q <= {reg_q[SYNC_STAGES-2:0], din};
        end
    end

    assign dout = reg_q[SYNC_STAGES-1];

endmodule
