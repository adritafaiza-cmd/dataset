```verilog
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

    // State encoding
    localparam S_IDLE     = 2'd0;
    localparam S_ISOLATE  = 2'd1;
    localparam S_CLEAR    = 2'd2;
    localparam S_RELEASE  = 2'd3;

    // Local state registers
    reg [1:0] a_state;
    reg [1:0] b_state;

    // Local output registers
    reg a_isolate_o_reg;
    reg a_clear_o_reg;
    reg b_isolate_o_reg;
    reg b_clear_o_reg;

    // Synchronizer for a_isolate_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;
    wire a_isolate_ack_b = a_isolate_ack_sync[SYNC_STAGES-1];

    // Synchronizer for a_clear_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;
    wire a_clear_ack_b = a_clear_ack_sync[SYNC_STAGES-1];

    // Synchronizer for b_isolate_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;
    wire b_isolate_ack_a = b_isolate_ack_sync[SYNC_STAGES-1];

    // Synchronizer for b_clear_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;
    wire b_clear_ack_a = b_clear_ack_sync[SYNC_STAGES-1];

    // Synchronizer for b_clear_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_sync;
    wire b_clear_a = b_clear_sync[SYNC_STAGES-1];

    // Synchronizer for a_clear_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_sync;
    wire a_clear_b = a_clear_sync[SYNC_STAGES-1];

    // Synchronizer for a_isolate_o into b domain
    reg [SYNC_STAGES-1:0] a_isolate_o_sync;
    wire a_isolate_o_b = a_isolate_o_sync[SYNC_STAGES-1];

    // Synchronizer for a_clear_o into b domain
    reg [SYNC_STAGES-1:0] a_clear_o_sync;
    wire a_clear_o_b = a_clear_o_sync[SYNC_STAGES-1];

    // Synchronizer for b_isolate_o into a domain
    reg [SYNC_STAGES-1:0] b_isolate_o_sync;
    wire b_isolate_o_a = b_isolate_o_sync[SYNC_STAGES-1];

    // Synchronizer for b_clear_o into a domain
    reg [SYNC_STAGES-1:0] b_clear_o_sync;
    wire b_clear_o_a = b_clear_o_sync[SYNC_STAGES-1];

    // Synchronizer for a_state into b domain
    reg [SYNC_STAGES-1:0][1:0] a_state_sync;
    wire [1:0] a_state_b = a_state_sync[SYNC_STAGES-1];

    // Synchronizer for b_state into a domain
    reg [SYNC_STAGES-1:0][1:0] b_state_sync;
    wire [1:0] b_state_a = b_state_sync[SYNC_STAGES-1];

    // Synchronizer for a_rst_ni into b domain
    reg [SYNC_STAGES-1:0] a_rst_ni_sync;
    wire a_rst_ni_b = a_rst_ni_sync[SYNC_STAGES-1];

    // Synchronizer for b_rst_ni into a domain
    reg [SYNC_STAGES-1:0] b_rst_ni_sync;
    wire b_rst_ni_a = b_rst_ni_sync[SYNC_STAGES-1];

    // Synchronizer for a_clear_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_i_sync;
    wire a_clear_i_b = a_clear_i_sync[SYNC_STAGES-1];

    // Synchronizer for b_clear_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_i_sync;
    wire b_clear_i_a = b_clear_i_sync[SYNC_STAGES-1];

    // Synchronizer for a_isolate_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_i_sync;
    wire a_isolate_ack_i_b = a_isolate_ack_i_sync[SYNC_STAGES-1];

    // Synchronizer for a_clear_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_ack_i_sync;
    wire a_clear_ack_i_b = a_clear_ack_i_sync[SYNC_STAGES-1];

    // Synchronizer for b_isolate_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_i_sync;
    wire b_isolate_ack_i_a = b_isolate_ack_i_sync[SYNC_STAGES-1];

    // Synchronizer for b_clear_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_ack_i_sync;
    wire b_clear_ack_i_a = b_clear_ack_i_sync[SYNC_STAGES-1];

    // Synchronizer for a_isolate_o into b domain
    reg [SYNC_STAGES-1:0] a_isolate_o_sync2;
    wire a_isolate_o_b2 = a_isolate_o_sync2[SYNC_STAGES-1];

    // Synchronizer for a_clear_o into b domain
    reg [SYNC_STAGES-1:0] a_clear_o_sync2;
    wire a_clear_o_b2 = a_clear_o_sync2[SYNC_STAGES-1];

    // Synchronizer for b_isolate_o into a domain
    reg [SYNC_STAGES-1:0] b_isolate_o_sync2;
    wire b_isolate_o_a2 = b_isolate_o_sync2[SYNC_STAGES-1];

    // Synchronizer for b_clear_o into a domain
    reg [SYNC_STAGES-1:0] b_clear_o_sync2;
    wire b_clear_o_a2 = b_clear_o_sync2[SYNC_STAGES-1];

    // Synchronizer for a_state into b domain
    reg [SYNC_STAGES-1:0][1:0] a_state_sync2;
    wire [1:0] a_state_b2 = a_state_sync2[SYNC_STAGES-1];

    // Synchronizer for b_state into a domain
    reg [SYNC_STAGES-1:0][1:0] b_state_sync2;
    wire [1:0] b_state_a2 = b_state_sync2[SYNC_STAGES-1];

    // Synchronizer for a_rst_ni into b domain
    reg [SYNC_STAGES-1:0] a_rst_ni_sync2;
    wire a_rst_ni_b2 = a_rst_ni_sync2[SYNC_STAGES-1];

    // Synchronizer for b_rst_ni into a domain
    reg [SYNC_STAGES-1:0] b_rst_ni_sync2;
    wire b_rst_ni_a2 = b_rst_ni_sync2[SYNC_STAGES-1];

    // Synchronizer for a_clear_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_i_sync2;
    wire a_clear_i_b2 = a_clear_i_sync2[SYNC_STAGES-1];

    // Synchronizer for b_clear_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_i_sync2;
    wire b_clear_i_a2 = b_clear_i_sync2[SYNC_STAGES-1];

    // Synchronizer for a_isolate_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_i_sync2;
    wire a_isolate_ack_i_b2 = a_isolate_ack_i_sync2[SYNC_STAGES-1];

    // Synchronizer for a_clear_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_ack_i_sync2;
    wire a_clear_ack_i_b2 = a_clear_ack_i_sync2[SYNC_STAGES-1];

    // Synchronizer for b_isolate_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_i_sync2;
    wire b_isolate_ack_i_a2 = b_isolate_ack_i_sync2[SYNC_STAGES-1];

    // Synchronizer for b_clear_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_ack_i_sync2;
    wire b_clear_ack_i_a2 = b_clear_ack_i_sync2[SYNC_STAGES-1];

    // Synchronizer for a_isolate_o into b domain
    reg [SYNC_STAGES-1:0] a_isolate_o_sync3;
    wire a_isolate_o_b3 = a_isolate_o_sync3[SYNC_STAGES-1];

    // Synchronizer for a_clear_o into b domain
    reg [SYNC_STAGES-1:0] a_clear_o_sync3;
    wire a_clear_o_b3 = a_clear_o_sync3[SYNC_STAGES-1];

    // Synchronizer for b_isolate_o into a domain
    reg [SYNC_STAGES-1:0] b_isolate_o_sync3;
    wire b_isolate_o_a3 = b_isolate_o_sync3[SYNC_STAGES-1];

    // Synchronizer for b_clear_o into a domain
    reg [SYNC_STAGES-1:0] b_clear_o_sync3;
    wire b_clear_o_a3 = b_clear_o_sync3[SYNC_STAGES-1];

    // Synchronizer for a_state into b domain
    reg [SYNC_STAGES-1:0][1:0] a_state_sync3;
    wire [1:0] a_state_b3 = a_state_sync3[SYNC_STAGES-1];

    // Synchronizer for b_state into a domain
    reg [SYNC_STAGES-1:0][1:0] b_state_sync3;
    wire [1:0] b_state_a3 = b_state_sync3[SYNC_STAGES-1];

    // Synchronizer for a_rst_ni into b domain
    reg [SYNC_STAGES-1:0] a_rst_ni_sync3;
    wire a_rst_ni_b3 = a_rst_ni_sync3[SYNC_STAGES-1];

    // Synchronizer for b_rst_ni into a domain
    reg [SYNC_STAGES-1:0] b_rst_ni_sync3;
    wire b_rst_ni_a3 = b_rst_ni_sync3[SYNC_STAGES-1];

    // Synchronizer for a_clear_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_i_sync3;
    wire a_clear_i_b3 = a_clear_i_sync3[SYNC_STAGES-1];

    // Synchronizer for b_clear_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_i_sync3;
    wire b_clear_i_a3 = b_clear_i_sync3[SYNC_STAGES-1];

    // Synchronizer for a_isolate_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_i_sync3;
    wire a_isolate_ack_i_b3 = a_isolate_ack_i_sync3[SYNC_STAGES-1];

    // Synchronizer for a_clear_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_ack_i_sync3;
    wire a_clear_ack_i_b3 = a_clear_ack_i_sync3[SYNC_STAGES-1];

    // Synchronizer for b_isolate_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_i_sync3;
    wire b_isolate_ack_i_a3 = b_isolate_ack_i_sync3[SYNC_STAGES-1];

    // Synchronizer for b_clear_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_ack_i_sync3;
    wire b_clear_ack_i_a3 = b_clear_ack_i_sync3[SYNC_STAGES-1];

    // Synchronizer for a_isolate_o into b domain
    reg [SYNC_STAGES-1:0] a_isolate_o_sync4;
    wire a_isolate_o_b4 = a_isolate_o_sync4[SYNC_STAGES-1];

    // Synchronizer for a_clear_o into b domain
    reg [SYNC_STAGES-1:0] a_clear_o_sync4;
    wire a_clear_o_b4 = a_clear_o_sync4[SYNC_STAGES-1];

    // Synchronizer for b_isolate_o into a domain
    reg [SYNC_STAGES-1:0] b_isolate_o_sync4;
    wire b_isolate_o_a4 = b_isolate_o_sync4[SYNC_STAGES-1];

    // Synchronizer for b_clear_o into a domain
    reg [SYNC_STAGES-1:0] b_clear_o_sync4;
    wire b_clear_o_a4 = b_clear_o_sync4[SYNC_STAGES-1];

    // Synchronizer for a_state into b domain
    reg [SYNC_STAGES-1:0][1:0] a_state_sync4;
    wire [1:0] a_state_b4 = a_state_sync4[SYNC_STAGES-1];

    // Synchronizer for b_state into a domain
    reg [SYNC_STAGES-1:0][1:0] b_state_sync4;
    wire [1:0] b_state_a4 = b_state_sync4[SYNC_STAGES-1];

    // Synchronizer for a_rst_ni into b domain
    reg [SYNC_STAGES-1:0] a_rst_ni_sync4;
    wire a_rst_ni_b4 = a_rst_ni_sync4[SYNC_STAGES-1];

    // Synchronizer for b_rst_ni into a domain
    reg [SYNC_STAGES-1:0] b_rst_ni_sync4;
    wire b_rst_ni_a4 = b_rst_ni_sync4[SYNC_STAGES-1];

    // Synchronizer for a_clear_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_i_sync4;
    wire a_clear_i_b4 = a_clear_i_sync4[SYNC_STAGES-1];

    // Synchronizer for b_clear_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_i_sync4;
    wire b_clear_i_a4 = b_clear_i_sync4[SYNC_STAGES-1];

    // Synchronizer for a_isolate_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_i_sync4;
    wire a_isolate_ack_i_b4 = a_isolate_ack_i_sync4[SYNC_STAGES-1];

    // Synchronizer for a_clear_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_ack_i_sync4;
    wire a_clear_ack_i_b4 = a_clear_ack_i_sync4[SYNC_STAGES-1];

    // Synchronizer for b_isolate_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_i_sync4;
    wire b_isolate_ack_i_a4 = b_isolate_ack_i_sync4[SYNC_STAGES-1];

    // Synchronizer for b_clear_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_ack_i_sync4;
    wire b_clear_ack_i_a4 = b_clear_ack_i_sync4[SYNC_STAGES-1];

    // Synchronizer for a_isolate_o into b domain
    reg [SYNC_STAGES-1:0] a_isolate_o_sync5;
    wire a_isolate_o_b5 = a_isolate_o_sync5[SYNC_STAGES-1];

    // Synchronizer for a_clear_o into b domain
    reg [SYNC_STAGES-1:0] a_clear_o_sync5;
    wire a_clear_o_b5 = a_clear_o_sync5[SYNC_STAGES-1];

    // Synchronizer for b_isolate_o into a domain
    reg [SYNC_STAGES-1:0] b_isolate_o_sync5;
    wire b_isolate_o_a5 = b_isolate_o_sync5[SYNC_STAGES-1];

    // Synchronizer for b_clear_o into a domain
    reg [SYNC_STAGES-1:0] b_clear_o_sync5;
    wire b_clear_o_a5 = b_clear_o_sync5[SYNC_STAGES-1];

    // Synchronizer for a_state into b domain
    reg [SYNC_STAGES-1:0][1:0] a_state_sync5;
    wire [1:0] a_state_b5 = a_state_sync5[SYNC_STAGES-1];

    // Synchronizer for b_state into a domain
    reg [SYNC_STAGES-1:0][1:0] b_state_sync5;
    wire [1:0] b_state_a5 = b_state_sync5[SYNC_STAGES-1];

    // Synchronizer for a_rst_ni into b domain
    reg [SYNC_STAGES-1:0] a_rst_ni_sync5;
    wire a_rst_ni_b5 = a_rst_ni_sync5[SYNC_STAGES-1];

    // Synchronizer for b_rst_ni into a domain
    reg [SYNC_STAGES-1:0] b_rst_ni_sync5;
    wire b_rst_ni_a5 = b_rst_ni_sync5[SYNC_STAGES-1];

    // Synchronizer for a_clear_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_i_sync5;
    wire a_clear_i_b5 = a_clear_i_sync5[SYNC_STAGES-1];

    // Synchronizer for b_clear_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_i_sync5;
    wire b_clear_i_a5 = b_clear_i_sync5[SYNC_STAGES-1];

    // Synchronizer for a_isolate_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_i_sync5;
    wire a_isolate_ack_i_b5 = a_isolate_ack_i_sync5[SYNC_STAGES-1];

    // Synchronizer for a_clear_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_ack_i_sync5;
    wire a_clear_ack_i_b5 = a_clear_ack_i_sync5[SYNC_STAGES-1];

    // Synchronizer for b_isolate_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_i_sync5;
    wire b_isolate_ack_i_a5 = b_isolate_ack_i_sync5[SYNC_STAGES-1];

    // Synchronizer for b_clear_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_ack_i_sync5;
    wire b_clear_ack_i_a5 = b_clear_ack_i_sync5[SYNC_STAGES-1];

    // Synchronizer for a_isolate_o into b domain
    reg [SYNC_STAGES-1:0] a_isolate_o_sync6;
    wire a_isolate_o_b6 = a_isolate_o_sync6[SYNC_STAGES-1];

    // Synchronizer for a_clear_o into b domain
    reg [SYNC_STAGES-1:0] a_clear_o_sync6;
    wire a_clear_o_b6 = a_clear_o_sync6[SYNC_STAGES-1];

    // Synchronizer for b_isolate_o into a domain
    reg [SYNC_STAGES-1:0] b_isolate_o_sync6;
    wire b_isolate_o_a6 = b_isolate_o_sync6[SYNC_STAGES-1];

    // Synchronizer for b_clear_o into a domain
    reg [SYNC_STAGES-1:0] b_clear_o_sync6;
    wire b_clear_o_a6 = b_clear_o_sync6[SYNC_STAGES-1];

    // Synchronizer for a_state into b domain
    reg [SYNC_STAGES-1:0][1:0] a_state_sync6;
    wire [1:0] a_state_b6 = a_state_sync6[SYNC_STAGES-1];

    // Synchronizer for b_state into a domain
    reg [SYNC_STAGES-1:0][1:0] b_state_sync6;
    wire [1:0] b_state_a6 = b_state_sync6[SYNC_STAGES-1];

    // Synchronizer for a_rst_ni into b domain
    reg [SYNC_STAGES-1:0] a_rst_ni_sync6;
    wire a_rst_ni_b6 = a_rst_ni_sync6[SYNC_STAGES-1];

    // Synchronizer for b_rst_ni into a domain
    reg [SYNC_STAGES-1:0] b_rst_ni_sync6;
    wire b_rst_ni_a6 = b_rst_ni_sync6[SYNC_STAGES-1];

    // Synchronizer for a_clear_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_i_sync6;
    wire a_clear_i_b6 = a_clear_i_sync6[SYNC_STAGES-1];

    // Synchronizer for b_clear_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_i_sync6;
    wire b_clear_i_a6 = b_clear_i_sync6[SYNC_STAGES-1];

    // Synchronizer for a_isolate_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_i_sync6;
    wire a_isolate_ack_i_b6 = a_isolate_ack_i_sync6[SYNC_STAGES-1];

    // Synchronizer for a_clear_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_ack_i_sync6;
    wire a_clear_ack_i_b6 = a_clear_ack_i_sync6[SYNC_STAGES-1];

    // Synchronizer for b_isolate_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_i_sync6;
    wire b_isolate_ack_i_a6 = b_isolate_ack_i_sync6[SYNC_STAGES-1];

    // Synchronizer for b_clear_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_ack_i_sync6;
    wire b_clear_ack_i_a6 = b_clear_ack_i_sync6[SYNC_STAGES-1];

    // Synchronizer for a_isolate_o into b domain
    reg [SYNC_STAGES-1:0] a_isolate_o_sync7;
    wire a_isolate_o_b7 = a_isolate_o_sync7[SYNC_STAGES-1];

    // Synchronizer for a_clear_o into b domain
    reg [SYNC_STAGES-1:0] a_clear_o_sync7;
    wire a_clear_o_b7 = a_clear_o_sync7[SYNC_STAGES-1];

    // Synchronizer for b_isolate_o into a domain
    reg [SYNC_STAGES-1:0] b_isolate_o_sync7;
    wire b_isolate_o_a7 = b_isolate_o_sync7[SYNC_STAGES-1];

    // Synchronizer for b_clear_o into a domain
    reg [SYNC_STAGES-1:0] b_clear_o_sync7;
    wire b_clear_o_a7 = b_clear_o_sync7[SYNC_STAGES-1];

    // Synchronizer for a_state into b domain
    reg [SYNC_STAGES-1:0][1:0] a_state_sync7;
    wire [1:0] a_state_b7 = a_state_sync7[SYNC_STAGES-1];

    // Synchronizer for b_state into a domain
    reg [SYNC_STAGES-1:0][1:0] b_state_sync7;
    wire [1:0] b_state_a7 = b_state_sync7[SYNC_STAGES-1];

    // Synchronizer for a_rst_ni into b domain
    reg [SYNC_STAGES-1:0] a_rst_ni_sync7;
    wire a_rst_ni_b7 = a_rst_ni_sync7[SYNC_STAGES-1];

    // Synchronizer for b_rst_ni into a domain
    reg [SYNC_STAGES-1:0] b_rst_ni_sync7;
    wire b_rst_ni_a7 = b_rst_ni_sync7[SYNC_STAGES-1];

    // Synchronizer for a_clear_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_i_sync7;
    wire a_clear_i_b7 = a_clear_i_sync7[SYNC_STAGES-1];

    // Synchronizer for b_clear_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_i_sync7;
    wire b_clear_i_a7 = b_clear_i_sync7[SYNC_STAGES-1];

    // Synchronizer for a_isolate_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_i_sync7;
    wire a_isolate_ack_i_b7 = a_isolate_ack_i_sync7[SYNC_STAGES-1];

    // Synchronizer for a_clear_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_ack_i_sync7;
    wire a_clear_ack_i_b7 = a_clear_ack_i_sync7[SYNC_STAGES-1];

    // Synchronizer for b_isolate_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_i_sync7;
    wire b_isolate_ack_i_a7 = b_isolate_ack_i_sync7[SYNC_STAGES-1];

    // Synchronizer for b_clear_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_ack_i_sync7;
    wire b_clear_ack_i_a7 = b_clear_ack_i_sync7[SYNC_STAGES-1];

    // Synchronizer for a_isolate_o into b domain
    reg [SYNC_STAGES-1:0] a_isolate_o_sync8;
    wire a_isolate_o_b8 = a_isolate_o_sync8[SYNC_STAGES-1];

    // Synchronizer for a_clear_o into b domain
    reg [SYNC_STAGES-1:0] a_clear_o_sync8;
    wire a_clear_o_b8 = a_clear_o_sync8[SYNC_STAGES-1];

    // Synchronizer for b_isolate_o into a domain
    reg [SYNC_STAGES-1:0] b_isolate_o_sync8;
    wire b_isolate_o_a8 = b_isolate_o_sync8[SYNC_STAGES-1];

    // Synchronizer for b_clear_o into a domain
    reg [SYNC_STAGES-1:0] b_clear_o_sync8;
    wire b_clear_o_a8 = b_clear_o_sync8[SYNC_STAGES-1];

    // Synchronizer for a_state into b domain
    reg [SYNC_STAGES-1:0][1:0] a_state_sync8;
    wire [1:0] a_state_b8 = a_state_sync8[SYNC_STAGES-1];

    // Synchronizer for b_state into a domain
    reg [SYNC_STAGES-1:0][1:0] b_state_sync8;
    wire [1:0] b_state_a8 = b_state_sync8[SYNC_STAGES-1];

    // Synchronizer for a_rst_ni into b domain
    reg [SYNC_STAGES-1:0] a_rst_ni_sync8;
    wire a_rst_ni_b8 = a_rst_ni_sync8[SYNC_STAGES-1];

    // Synchronizer for b_rst_ni into a domain
    reg [SYNC_STAGES-1:0] b_rst_ni_sync8;
    wire b_rst_ni_a8 = b_rst_ni_sync8[SYNC_STAGES-1];

    // Synchronizer for a_clear_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_i_sync8;
    wire a_clear_i_b8 = a_clear_i_sync8[SYNC_STAGES-1];

    // Synchronizer for b_clear_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_i_sync8;
    wire b_clear_i_a8 = b_clear_i_sync8[SYNC_STAGES-1];

    // Synchronizer for a_isolate_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_i_sync8;
    wire a_isolate_ack_i_b8 = a_isolate_ack_i_sync8[SYNC_STAGES-1];

    // Synchronizer for a_clear_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_ack_i_sync8;
    wire a_clear_ack_i_b8 = a_clear_ack_i_sync8[SYNC_STAGES-1];

    // Synchronizer for b_isolate_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_i_sync8;
    wire b_isolate_ack_i_a8 = b_isolate_ack_i_sync8[SYNC_STAGES-1];

    // Synchronizer for b_clear_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_ack_i_sync8;
    wire b_clear_ack_i_a8 = b_clear_ack_i_sync8[SYNC_STAGES-1];

    // Synchronizer for a_isolate_o into b domain
    reg [SYNC_STAGES-1:0] a_isolate_o_sync9;
    wire a_isolate_o_b9 = a_isolate_o_sync9[SYNC_STAGES-1];

    // Synchronizer for a_clear_o into b domain
    reg [SYNC_STAGES-1:0] a_clear_o_sync9;
    wire a_clear_o_b9 = a_clear_o_sync9[SYNC_STAGES-1];

    // Synchronizer for b_isolate_o into a domain
    reg [SYNC_STAGES-1:0] b_isolate_o_sync9;
    wire b_isolate_o_a9 = b_isolate_o_sync9[SYNC_STAGES-1];

    // Synchronizer for b_clear_o into a domain
    reg [SYNC_STAGES-1:0] b_clear_o_sync9;
    wire b_clear_o_a9 = b_clear_o_sync9[SYNC_STAGES-1];

    // Synchronizer for a_state into b domain
    reg [SYNC_STAGES-1:0][1:0] a_state_sync9;
    wire [1:0] a_state_b9 = a_state_sync9[SYNC_STAGES-1];

    // Synchronizer for b_state into a domain
    reg [SYNC_STAGES-1:0][1:0] b_state_sync9;
    wire [1:0] b_state_a9 = b_state_sync9[SYNC_STAGES-1];

    // Synchronizer for a_rst_ni into b domain
    reg [SYNC_STAGES-1:0] a_rst_ni_sync9;
    wire a_rst_ni_b9 = a_rst_ni_sync9[SYNC_STAGES-1];

    // Synchronizer for b_rst_ni into a domain
    reg [SYNC_STAGES-1:0] b_rst_ni_sync9;
    wire b_rst_ni_a9 = b_rst_ni_sync9[SYNC_STAGES-1];

    // Synchronizer for a_clear_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_i_sync9;
    wire a_clear_i_b9 = a_clear_i_sync9[SYNC_STAGES-1];

    // Synchronizer for b_clear_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_i_sync9;
    wire b_clear_i_a9 = b_clear_i_sync9[SYNC_STAGES-1];

    // Synchronizer for a_isolate_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_i_sync9;
    wire a_isolate_ack_i_b9 = a_isolate_ack_i_sync9[SYNC_STAGES-1];

    // Synchronizer for a_clear_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_ack_i_sync9;
    wire a_clear_ack_i_b9 = a_clear_ack_i_sync9[SYNC_STAGES-1];

    // Synchronizer for b_isolate_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_i_sync9;
    wire b_isolate_ack_i_a9 = b_isolate_ack_i_sync9[SYNC_STAGES-1];

    // Synchronizer for b_clear_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_ack_i_sync9;
    wire b_clear_ack_i_a9 = b_clear_ack_i_sync9[SYNC_STAGES-1];

    // Synchronizer for a_isolate_o into b domain
    reg [SYNC_STAGES-1:0] a_isolate_o_sync10;
    wire a_isolate_o_b10 = a_isolate_o_sync10[SYNC_STAGES-1];

    // Synchronizer for a_clear_o into b domain
    reg [SYNC_STAGES-1:0] a_clear_o_sync10;
    wire a_clear_o_b10 = a_clear_o_sync10[SYNC_STAGES-1];

    // Synchronizer for b_isolate_o into a domain
    reg [SYNC_STAGES-1:0] b_isolate_o_sync10;
    wire b_isolate_o_a10 = b_isolate_o_sync10[SYNC_STAGES-1];

    // Synchronizer for b_clear_o into a domain
    reg [SYNC_STAGES-1:0] b_clear_o_sync10;
    wire b_clear_o_a10 = b_clear_o_sync10[SYNC_STAGES-1];

    // Synchronizer for a_state into b domain
    reg [SYNC_STAGES-1:0][1:0] a_state_sync10;
    wire [1:0] a_state_b10 = a_state_sync10[SYNC_STAGES-1];

    // Synchronizer for b_state into a domain
    reg [SYNC_STAGES-1:0][1:0] b_state_sync10;
    wire [1:0] b_state_a10 = b_state_sync10[SYNC_STAGES-1];

    // Synchronizer for a_rst_ni into b domain
    reg [SYNC_STAGES-1:0] a_rst_ni_sync10;
    wire a_rst_ni_b10 = a_rst_ni_sync10[SYNC_STAGES-1];

    // Synchronizer for b_rst_ni into a domain
    reg [SYNC_STAGES-1:0] b_rst_ni_sync10;
    wire b_rst_ni_a10 = b_rst_ni_sync10[SYNC_STAGES-1];

    // Synchronizer for a_clear_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_i_sync10;
    wire a_clear_i_b10 = a_clear_i_sync10[SYNC_STAGES-1];

    // Synchronizer for b_clear_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_i_sync10;
    wire b_clear_i_a10 = b_clear_i_sync10[SYNC_STAGES-1];

    // Synchronizer