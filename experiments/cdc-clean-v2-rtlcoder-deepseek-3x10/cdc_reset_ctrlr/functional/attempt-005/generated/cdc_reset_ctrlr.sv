Sure, here is the complete Verilog code for the two-domain isolate-then-clear reset controller:

```
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
    reg [SYNC_STAGES-1:0] a_clear_sync;
    reg [SYNC_STAGES-1:0] a_isolate_sync;
    reg [SYNC_STAGES-1:0] b_clear_sync;
    reg [SYNC_STAGES-1:0] b_isolate_sync;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] b_isolate_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack;
    reg [SYNC_STAGES-1:0] a_clear_sync_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack_ack