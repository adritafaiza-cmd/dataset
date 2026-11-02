// =============================================================================
// cdc_reset_ctrlr.v
// =============================================================================
// Two-domain isolate-then-clear reset controller.
//
// Protocol (per side):
//   *_clear_i        : request to clear this side (level, held until done)
//   *_clear_o        : clear asserted (level, held until done)
//   *_clear_ack_i    : peer has completed its clear (level, held until done)
//   *_isolate_o      : isolate asserted (level, held until done)
//   *_isolate_ack_i  : peer has completed its isolate (level, held until done)
//
// Sequence (initiated by either side):
//   1. Raise both *_isolate_o.
//   2. Wait for both *_isolate_ack_i.
//   3. Raise both *_clear_o.
//   4. Wait for both *_clear_ack_i.
//   5. Release both *_clear_o and *_isolate_o.
//
// CDC: each side's outputs are registered in its own clock domain and
//       synchronized to the peer via a SYNC_STAGES-deep synchronizer.
//       The peer's ack signals are synchronized back the same way.
// =============================================================================

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

    // ------------------------------------------------------------------
    // FSM states
    // ------------------------------------------------------------------
    localparam S_IDLE     = 2'd0;
    localparam S_ISOLATE  = 2'd1;
    localparam S_CLEAR    = 2'd2;
    localparam S_RELEASE  = 2'd3;

    // ------------------------------------------------------------------
    // Side A (a_clk domain)
    // ------------------------------------------------------------------
    reg [1:0] a_state;
    reg       a_isolate_r;
    reg       a_clear_r;

    // Synchronize B's outputs into A's domain
    reg [SYNC_STAGES-1:0] a_b_isolate_sync;
    reg [SYNC_STAGES-1:0] a_b_clear_sync;

    // Synchronize A's outputs into B's domain
    reg [SYNC_STAGES-1:0] b_a_isolate_sync;
    reg [SYNC_STAGES-1:0] b_a_clear_sync;

    wire a_b_isolate = a_b_isolate_sync[SYNC_STAGES-1];
    wire a_b_clear   = a_b_clear_sync[SYNC_STAGES-1];

    // ------------------------------------------------------------------
    // Side B (b_clk domain)
    // ------------------------------------------------------------------
    reg [1:0] b_state;
    reg       b_isolate_r;
    reg       b_clear_r;

    wire b_a_isolate = b_a_isolate_sync[SYNC_STAGES-1];
    wire b_a_clear   = b_a_clear_sync[SYNC_STAGES-1];

    // ------------------------------------------------------------------
    // Side A FSM
    // ------------------------------------------------------------------
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state       <= S_IDLE;
            a_isolate_r   <= 1'b0;
            a_clear_r     <= 1'b0;
            a_b_isolate_sync <= {SYNC_STAGES{1'b0}};
            a_b_clear_sync   <= {SYNC_STAGES{1'b0}};
        end else begin
            a_b_isolate_sync <= {a_b_isolate_sync[SYNC_STAGES-2:0], b_isolate_r};
            a_b_clear_sync   <= {a_b_clear_sync[SYNC_STAGES-2:0],   b_clear_r};

            case (a_state)
                S_IDLE: begin
                    if (a_clear_i || b_clear_i) begin
                        a_state     <= S_ISOLATE;
                        a_isolate_r <= 1'b1;
                    end
                end

                S_ISOLATE: begin
                    if (a_isolate_ack_i && a_b_isolate) begin
                        a_state   <= S_CLEAR;
                        a_clear_r <= 1'b1;
                    end
                end

                S_CLEAR: begin
                    if (a_clear_ack_i && a_b_clear) begin
                        a_state   <= S_RELEASE;
                        a_clear_r <= 1'b0;
                    end
                end

                S_RELEASE: begin
                    a_state     <= S_IDLE;
                    a_isolate_r <= 1'b0;
                end

                default: begin
                    a_state     <= S_IDLE;
                    a_isolate_r <= 1'b0;
                    a_clear_r   <= 1'b0;
                end
            endcase
        end
    end

    assign a_isolate_o = a_isolate_r;
    assign a_clear_o   = a_clear_r;

    // ------------------------------------------------------------------
    // Side B FSM
    // ------------------------------------------------------------------
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state       <= S_IDLE;
            b_isolate_r   <= 1'b0;
            b_clear_r     <= 1'b0;
            b_a_isolate_sync <= {SYNC_STAGES{1'b0}};
            b_a_clear_sync   <= {SYNC_STAGES{1'b0}};
        end else begin
            b_a_isolate_sync <= {b_a_isolate_sync[SYNC_STAGES-2:0], a_isolate_r};
            b_a_clear_sync   <= {b_a_clear_sync[SYNC_STAGES-2:0],   a_clear_r};

            case (b_state)
                S_IDLE: begin
                    if (a_clear_i || b_clear_i) begin
                        b_state     <= S_ISOLATE;
                        b_isolate_r <= 1'b1;
                    end
                end

                S_ISOLATE: begin
                    if (b_isolate_ack_i && b_a_isolate) begin
                        b_state   <= S_CLEAR;
                        b_clear_r <= 1'b1;
                    end
                end

                S_CLEAR: begin
                    if (b_clear_ack_i && b_a_clear) begin
                        b_state   <= S_RELEASE;
                        b_clear_r <= 1'b0;
                    end
                end

                S_RELEASE: begin
                    b_state     <= S_IDLE;
                    b_isolate_r <= 1'b0;
                end

                default: begin
                    b_state     <= S_IDLE;
                    b_isolate_r <= 1'b0;
                    b_clear_r   <= 1'b0;
                end
            endcase
        end
    end

    assign b_isolate_o = b_isolate_r;
    assign b_clear_o   = b_clear_r;

endmodule