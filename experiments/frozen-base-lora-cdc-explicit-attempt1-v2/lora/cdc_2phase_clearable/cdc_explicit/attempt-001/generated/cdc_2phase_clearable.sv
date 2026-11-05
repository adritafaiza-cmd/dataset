// =============================================================================
// cdc_2phase_clearable
// =============================================================================
// Two-phase valid/ready channel between asynchronous clocks.
//
// Architecture:
//   - Two-phase handshake (req/ack) with one outstanding item.
//   - Payload held stable in the source domain under the request/acknowledge
//     protocol; synchronized through SYNC_STAGES destination-clock stages.
//   - Control indication (req) delayed by SYNC_STAGES destination cycles so
//     the payload settles before capture.
//   - Coordinated clear: isolate both ends, drop in-flight data by returning
//     req/ack to zero, then return to idle.
//   - Reset and clear must not create a destination beat.
// =============================================================================

module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_clear_i,
  output src_clear_pending_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,

  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // ===========================================================================
  // Source domain
  // ===========================================================================

  // Two-phase request: high when a beat is outstanding (sent, not yet acked).
  reg src_req;

  // Acknowledge synchronized back from destination.
  reg [SYNC_STAGES:0] src_ack_sync;
  wire src_ack = src_ack_sync[SYNC_STAGES];

  // Clear state machine: 0 = idle, 1 = waiting for ack to clear, 2 = done.
  reg [1:0] src_clear_state;
  wire src_clear_pending = (src_clear_state != 2'd0);

  // Isolate: block new transfers during clear.
  wire src_isolate = (src_clear_state != 2'd0);

  // Accept a new beat when valid, ready, and not isolated.
  wire src_accept = src_valid_i & src_ready_o & ~src_isolate;

  assign src_ready_o = ~src_req & ~src_isolate;

  // Payload held stable while request is outstanding.
  reg [WIDTH-1:0] src_data_hold;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req         <= 1'b0;
      src_data_hold   <= {WIDTH{1'b0}};
      src_clear_state <= 2'd0;
    end else begin
      case (src_clear_state)
        2'd0: begin
          // Idle: accept new beats.
          if (src_accept) begin
            src_req       <= 1'b1;
            src_data_hold <= src_data_i;
          end else if (src_req && src_ack) begin
            // Ack received: beat consumed.
            src_req <= 1'b0;
          end else if (src_clear_i) begin
            // Initiate clear.
            src_clear_state <= 2'd1;
          end
        end

        2'd1: begin
          // Waiting for ack to clear (req already deasserted or was 0).
          if (src_ack) begin
            src_clear_state <= 2'd2;
          end
        end

        2'd2: begin
          // Clear complete, return to idle.
          src_clear_state <= 2'd0;
        end

        default: begin
          src_clear_state <= 2'd0;
        end
      endcase

      // Deassert req when ack is received (normal or clear path).
      if (src_req && src_ack) begin
        src_req <= 1'b0;
      end

      // On clear initiation, drop the outstanding beat.
      if (src_clear_state == 2'd0 && src_clear_i) begin
        src_req <= 1'b0;
      end
    end
  end

  assign src_clear_pending_o = src_clear_pending;

  // ===========================================================================
  // Destination domain
  // ===========================================================================

  // Payload synchronized from source (held stable under req/ack protocol).
  reg [SYNC_STAGES:0][WIDTH-1:0] dst_data_sync;

  // Request synchronized from source, delayed for payload settling.
  reg [SYNC_STAGES:0] dst_req_sync;
  wire dst_req = dst_req_sync[SYNC_STAGES];

  // Acknowledge: high when destination has consumed the beat.
  reg dst_ack;

  // Clear state machine: 0 = idle, 1 = waiting for req to clear, 2 = done.
  reg [1:0] dst_clear_state;
  wire dst_clear_pending = (dst_clear_state != 2'd0);

  // Isolate: block new transfers during clear.
  wire dst_isolate = (dst_clear_state != 2'd0);

  // Accept a beat when req is high, not isolated, and ready.
  wire dst_accept = dst_req & dst_ready_i & ~dst_isolate;

  // Output valid: beat is available and not isolated.
  assign dst_valid_o = dst_req & ~dst_isolate;
  assign dst_data_o  = dst_data_sync[SYNC_STAGES];

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack         <= 1'b0;
      dst_clear_state <= 2'd0;
      dst_data_sync   <= {(SYNC_STAGES+1){{WIDTH{1'b0}}}};
      dst_req_sync    <= {(SYNC_STAGES+1){1'b0}};
    end else begin
      // Synchronize payload and request.
      dst_data_sync[0] <= src_data_hold;
      dst_req_sync[0]  <= src_req;
      for (int i = 1; i <= SYNC_STAGES; i = i + 1) begin
        dst_data_sync[i] <= dst_data_sync[i-1];
        dst_req_sync[i]  <= dst_req_sync[i-1];
      end

      case (dst_clear_state)
        2'd0: begin
          // Idle: accept beats.
          if (dst_accept) begin
            dst_ack <= 1'b1;
          end else if (dst_ack && !dst_req) begin
            // Req deasserted: ack complete.
            dst_ack <= 1'b0;
          end else if (dst_clear_i) begin
            // Initiate clear.
            dst_clear_state <= 2'd1;
          end
        end

        2'd1: begin
          // Waiting for req to clear (ack already deasserted or was 0).
          if (!dst_req) begin
            dst_clear_state <= 2'd2;
          end
        end

        2'd2: begin
          // Clear complete, return to idle.
          dst_clear_state <= 2'd0;
        end

        default: begin
          dst_clear_state <= 2'd0;
        end
      endcase

      // Deassert ack when req is deasserted (normal or clear path).
      if (dst_ack && !dst_req) begin
        dst_ack <= 1'b0;
      end

      // On clear initiation, drop the outstanding beat.
      if (dst_clear_state == 2'd0 && dst_clear_i) begin
        dst_ack <= 1'b0;
      end
    end
  end

  assign dst_clear_pending_o = dst_clear_pending;

  // ===========================================================================
  // Cross-domain synchronization
  // ===========================================================================

  // Source: synchronize ack from destination.
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ack_sync <= {(SYNC_STAGES+1){1'b0}};
    end else begin
      src_ack_sync[0] <= dst_ack;
      for (int i = 1; i <= SYNC_STAGES; i = i + 1) begin
        src_ack_sync[i] <= src_ack_sync[i-1];
      end
    end
  end

endmodule