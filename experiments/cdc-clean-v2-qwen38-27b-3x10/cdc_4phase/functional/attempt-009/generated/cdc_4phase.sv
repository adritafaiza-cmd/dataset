module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
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

  // Internal signals
  wire [WIDTH-1:0] src_data_reg;
  wire src_valid_reg;
  wire src_ready_int;
  wire dst_valid_int;
  wire [WIDTH-1:0] dst_data_int;
  wire dst_ready_int;

  // Source domain: capture data and valid when handshake occurs
  // Destination domain: generate valid and ready signals

  // We use a 4-phase handshake:
  // Phase 0: idle (valid=0, ready=0)
  // Phase 1: valid asserted (valid=1, ready=0)
  // Phase 2: ready asserted (valid=1, ready=1)
  // Phase 3: valid deasserted (valid=0, ready=1)
  // Back to Phase 0

  // Source side: we need to send data and a "valid" pulse to destination
  // Destination side: we need to acknowledge with "ready" pulse back to source

  // Let's use a simpler approach:
  // Source holds data and asserts a "send" signal
  // Destination receives, processes, and asserts "ack" signal
  // Source waits for ack before accepting new data (unless DECOUPLED)

  // For CDC, we need to synchronize signals across clock domains.
  // We'll use 2-flop synchronizers for control signals.

  // Source domain registers
  reg [WIDTH-1:0] src_data_hold;
  reg src_valid_hold;
  reg src_ack_sync0, src_ack_sync1;
  reg src_ack;

  // Destination domain registers
  reg [WIDTH-1:0] dst_data_hold;
  reg dst_valid_hold;
  reg dst_ready_sync0, dst_ready_sync1;
  reg dst_ready;

  // Synchronize src_ack from destination to source
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ack_sync0 <= 1'b0;
      src_ack_sync1 <= 1'b0;
      src_ack <= 1'b0;
    end else begin
      src_ack_sync0 <= dst_ready;
      src_ack_sync1 <= src_ack_sync0;
      src_ack <= src_ack_sync1;
    end
  end

  // Synchronize dst_ready from source to destination
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_sync0 <= 1'b0;
      dst_ready_sync1 <= 1'b0;
      dst_ready <= 1'b0;
    end else begin
      dst_ready_sync0 <= src_ack;
      dst_ready_sync1 <= dst_ready_sync0;
      dst_ready <= dst_ready_sync1;
    end
  end

  // Source domain: manage valid and data
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_hold <= {WIDTH{1'b0}};
      src_valid_hold <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_int) begin
        // Accept new data
        src_data_hold <= src_data_i;
        src_valid_hold <= 1'b1;
      end else if (src_ack) begin
        // Ack received, clear valid
        src_valid_hold <= 1'b0;
      end
    end
  end

  // Source ready: can accept new data if not currently holding valid data,
  // or if DECOUPLED and we've already sent the previous one
  assign src_ready_int = !src_valid_hold || (DECOUPLED && src_ack);
  assign src_ready_o = src_ready_int;

  // Destination domain: manage valid and data
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_hold <= {WIDTH{1'b0}};
      dst_valid_hold <= SEND_RESET_MSG ? 1'b1 : 1'b0;
      if (SEND_RESET_MSG) begin
        dst_data_hold <= RESET_MSG;
      end
    end else begin
      if (src_valid_hold && !dst_valid_hold) begin
        // New data available from source
        dst_data_hold <= src_data_hold;
        dst_valid_hold <= 1'b1;
      end else if (dst_valid_hold && dst_ready_i) begin
        // Handshake complete, clear valid
        dst_valid_hold <= 1'b0;
      end
    end
  end

  // Destination ready: can accept new data if not currently holding valid data
  assign dst_ready_int = !dst_valid_hold;
  assign dst_ready_o = dst_ready_int;

  // Output assignments
  assign dst_data_o = dst_data_hold;
  assign dst_valid_o = dst_valid_hold;

endmodule
