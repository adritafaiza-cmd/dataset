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

  // Source side: capture data when valid and ready
  // Destination side: 2-phase handshake for CDC

  // Source side registers
  reg [WIDTH-1:0] src_data_reg;
  reg             src_valid_reg;
  reg             src_ready_reg;

  // Destination side registers
  reg [WIDTH-1:0] dst_data_reg;
  reg             dst_valid_reg;
  reg             dst_ready_reg;

  // CDC: 2-phase handshake signals
  // req: source -> destination (request)
  // ack: destination -> source (acknowledge)

  // Source side: generate request when data is valid and not already pending
  // We use a simple 2-phase protocol:
  // - Source asserts req when it has data to send
  // - Destination asserts ack when it has received the data
  // - Source deasserts req when it sees ack
  // - Destination deasserts ack when it sees req deasserted

  // Actually, let's use a standard 2-phase valid/ready CDC:
  // The source holds data and valid until the destination acknowledges.
  // We need to synchronize the handshake signals.

  // Let's use a different approach:
  // Source side:
  //   - When src_valid_i is high and src_ready_o is high, capture data
  //   - Assert a "pending" flag
  //   - Wait for destination to acknowledge
  //   - Deassert pending when acknowledged

  // Destination side:
  //   - Synchronize the pending flag
  //   - When pending is high, present data and valid
  //   - Wait for dst_ready_i
  //   - Assert acknowledge
  //   - Deassert acknowledge when pending is deasserted

  // Let's implement this with proper 2-phase handshake:

  // Source side state
  reg src_pending;
  reg [WIDTH-1:0] src_data_hold;

  // Destination side state
  reg dst_pending_sync1;
  reg dst_pending_sync2;
  reg dst_ack;
  reg dst_ack_sync1;
  reg dst_ack_sync2;

  // Source side: ready is high when not pending
  assign src_ready_o = ~src_pending;

  // Source side: capture data when valid and ready
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_pending   <= 1'b0;
      src_data_hold <= {WIDTH{1'b0}};
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_pending   <= 1'b1;
        src_data_hold <= src_data_i;
      end else if (src_pending && dst_ack_sync2) begin
        src_pending <= 1'b0;
      end
    end
  end

  // Synchronize dst_ack to source clock domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ack_sync1 <= 1'b0;
      dst_ack_sync2 <= 1'b0;
    end else begin
      dst_ack_sync1 <= dst_ack;
      dst_ack_sync2 <= dst_ack_sync1;
    end
  end

  // Destination side: synchronize src_pending to destination clock domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_pending_sync1 <= 1'b0;
      dst_pending_sync2 <= 1'b0;
    end else begin
      dst_pending_sync1 <= src_pending;
      dst_pending_sync2 <= dst_pending_sync1;
    end
  end

  // Destination side: data and valid
  assign dst_data_o  = src_data_hold;
  assign dst_valid_o = dst_pending_sync2;

  // Destination side: acknowledge when pending is high and ready is high
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack <= 1'b0;
    end else begin
      if (dst_pending_sync2 && dst_ready_i) begin
        dst_ack <= 1'b1;
      end else if (!dst_pending_sync2) begin
        dst_ack <= 1'b0;
      end
    end
  end

endmodule
