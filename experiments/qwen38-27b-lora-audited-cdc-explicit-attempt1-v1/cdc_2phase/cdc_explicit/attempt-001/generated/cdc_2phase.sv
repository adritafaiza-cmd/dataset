// =============================================================================
// cdc_2phase — Two-phase valid/ready CDC channel
// =============================================================================
//
// Architecture:
//   * Source side: 2-phase handshake (req) + data latch.
//   * Destination: 2-phase handshake (ack) + data register.
//   * Data is latched at the source when the transfer is accepted and is
//     stable until the destination acknowledges.  This guarantees coherent
//     multi-bit data without a FIFO.
//   * At most one outstanding item.
//
// Handshake protocol (2-phase, level-based):
//
//   Source (req)          Destination (ack)
//   ─────────────────     ─────────────────────
//   idle:    req=0        idle:    ack=0
//   send:    req=1        wait:    ack=0
//   wait:    req=1        done:    ack=1
//   idle:    req=0        idle:    ack=0
//
//   req is set when src_valid && src_ready (i.e. no outstanding item).
//   req is cleared when ack is observed (destination consumed the item).
//   ack is set when dst_valid && dst_ready (destination consumed the item).
//   ack is cleared when req is observed low (source released the item).
//
//   Both req and ack are synchronised through 2-FF synchronisers.
//   Data is latched at the source and held stable until ack is observed.
// =============================================================================

module cdc_2phase #(
  parameter WIDTH = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,

  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // ---------------------------------------------------------------------------
  // Source domain
  // ---------------------------------------------------------------------------

  // Handshake request (2-phase)
  reg req;

  // Data latch — holds the payload until the destination acknowledges
  reg [WIDTH-1:0] data_latch;

  // Synchronised ack from destination
  reg [1:0] ack_sync;
  wire ack = ack_sync[1];

  // Source is ready when there is no outstanding item
  assign src_ready_o = ~req;

  // Accept a new item when valid and ready
  wire src_accept = src_valid_i & src_ready_o;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      req        <= 1'b0;
      data_latch <= {WIDTH{1'b0}};
      ack_sync   <= 2'b00;
    end else begin
      // Synchronise ack
      ack_sync <= {ack_sync[0], ack};

      // Set req when accepting a new item
      if (src_accept) begin
        req        <= 1'b1;
        data_latch <= src_data_i;
      end

      // Clear req when destination has acknowledged
      else if (ack) begin
        req <= 1'b0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Destination domain
  // ---------------------------------------------------------------------------

  // Handshake acknowledge (2-phase)
  reg ack;

  // Data register — holds the payload until the consumer is ready
  reg [WIDTH-1:0] data_reg;

  // Synchronised req from source
  reg [1:0] req_sync;
  wire req = req_sync[1];

  // Destination is valid when there is an outstanding item
  assign dst_valid_o = req;
  assign dst_data_o  = data_reg;

  // Destination accepts when valid and ready
  wire dst_accept = dst_valid_o & dst_ready_i;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      ack      <= 1'b0;
      data_reg <= {WIDTH{1'b0}};
      req_sync <= 2'b00;
    end else begin
      // Synchronise req
      req_sync <= {req_sync[0], req};

      // Set ack when destination consumes the item
      if (dst_accept) begin
        ack      <= 1'b1;
        data_reg <= data_latch;  // capture the stable data
      end

      // Clear ack when source has released the item
      else if (!req) begin
        ack <= 1'b0;
      end
    end
  end

endmodule