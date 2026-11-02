// =============================================================================
// Module: pulse_sync
// Description: One-pulse-in, one-pulse-out crossing between asynchronous clocks.
// =============================================================================

`timescale 1ns / 1ps

module pulse_sync #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  pulseA_i,
    output pulseB_o,
    output busy_o
);

    // ========================================================================
    // Domain A: Pulse detection and request generation
    // ========================================================================

    // Detect rising edge of pulseA_i
    reg pulseA_d0, pulseA_d1;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulseA_d0 <= 1'b0;
            pulseA_d1 <= 1'b0;
        end else begin
            pulseA_d0 <= pulseA_i;
            pulseA_d1 <= pulseA_d0;
        end
    end

    wire pulseA_rise = pulseA_d0 & ~pulseA_d1;

    // Request signal (set on pulse, cleared on ack)
    reg req_a;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            req_a <= 1'b0;
        else if (pulseA_rise && !req_a)
            req_a <= 1'b1;
        else if (ack_a)
            req_a <= 1'b0;
    end

    // ========================================================================
    // Domain B: Acknowledge generation and pulse output
    // ========================================================================

    // Synchronize req_a to domain B
    reg [STAGES-1:0] req_b;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            req_b <= {STAGES{1'b0}};
        else
            req_b <= {req_b[STAGES-2:0], req_a};
    end

    // Detect rising edge of synchronized req
    reg req_b_d0, req_b_d1;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_b_d0 <= 1'b0;
            req_b_d1 <= 1'b0;
        end else begin
            req_b_d0 <= req_b[STAGES-1];
            req_b_d1 <= req_b_d0;
        end
    end

    wire req_b_rise = req_b[STAGES-1] & ~req_b_d1;

    // Acknowledge signal (set on req, cleared on req falling)
    reg ack_b;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            ack_b <= 1'b0;
        else if (req_b_rise)
            ack_b <= 1'b1;
        else if (!req_b[STAGES-1])
            ack_b <= 1'b0;
    end

    // Synchronize ack_b to domain A
    reg [STAGES-1:0] ack_a;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            ack_a <= {STAGES{1'b0}};
        else
            ack_a <= {ack_a[STAGES-2:0], ack_b};
    end

    // ========================================================================
    // Outputs
    // ========================================================================

    // Pulse output in domain B (one cycle high on req rising edge)
    assign pulseB_o = req_b_rise;

    // Busy output (high while pulse is in flight)
    assign busy_o = req_a;

endmodule