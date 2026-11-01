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
  wire dst_ready_int;
  wire [WIDTH-1:0] dst_data_reg;

  // Source domain: capture data and valid when handshake occurs
  // Destination domain: generate valid and ready signals

  // We use a 4-phase handshake protocol:
  // Phase 1: src_valid=1, src_ready=0 (source has data)
  // Phase 2: src_valid=1, src_ready=1 (handshake, data captured)
  // Phase 3: src_valid=0, src_ready=1 (source clears valid)
  // Phase 4: src_valid=0, src_ready=0 (idle)

  // For CDC, we need to synchronize the control signals.
  // The data is transferred when the handshake occurs, and we use a
  // multi-bit synchronizer approach or a valid/ready with proper CDC.

  // Architecture:
  // - Source side: registers data and valid. When src_valid_i & src_ready_o,
  //   capture data and assert an internal "transfer request" to destination.
  // - Destination side: synchronizes the transfer request, presents data,
  //   and when dst_ready_i is high, clears the valid and sends a "done"
  //   signal back to source to allow next transfer.

  // Let's use a simpler approach with a 2-stage synchronizer for each
  // control signal, and ensure data is stable during transfer.

  // Source domain state
  reg [WIDTH-1:0] src_data_q;
  reg src_valid_q;
  reg src_ready_q;

  // Destination domain state
  reg [WIDTH-1:0] dst_data_q;
  reg dst_valid_q;
  reg dst_ready_q;

  // Synchronization signals
  // src_to_dst_valid: source indicates it has data to send
  // dst_to_src_ready: destination indicates it is ready to accept

  // Let's implement a proper 4-phase handshake with CDC.

  // Source domain:
  // - When src_valid_i and src_ready_o are both high, capture src_data_i
  // - Assert src_to_dst_valid (synchronized to dst domain)
  // - Wait for dst_to_src_ready (synchronized from dst domain) to clear

  // Destination domain:
  // - When src_to_dst_valid is high, present dst_data_q and dst_valid_q
  // - When dst_ready_i is high, clear dst_valid_q and assert dst_to_src_ready

  // For DECOUPLED mode, we can pipeline the handshake.

  // Let's use a standard approach:
  // 1. Source captures data when src_valid_i & src_ready_o
  // 2. Source asserts a "req" signal that is synchronized to dst domain
  // 3. Destination, upon seeing req, presents data and valid
  // 4. Destination, upon dst_ready_i, asserts an "ack" signal synchronized to src domain
  // 5. Source, upon seeing ack, clears its valid and allows next transfer

  // This is a 4-phase handshake: req up, ack up, req down, ack down.

  // Source domain
  reg src_req_q;
  reg src_ack_q;

  // Destination domain
  reg dst_req_q;
  reg dst_ack_q;

  // Synchronizers
  // src_req to dst domain
  reg [1:0] src_req_sync;
  // dst_ack to src domain
  reg [1:0] dst_ack_sync;

  // For data, we need to ensure it's stable. We'll use the fact that
  // data is only changed when src_valid_i & src_ready_o, and the req
  // signal is asserted at the same time. The destination will capture
  // the data when it sees the req transition.

  // Actually, for multi-bit data CDC, we need to ensure the data is
  // stable during the transfer. One approach is to use a valid/ready
  // where the data is only valid when valid is high, and we use a
  // multi-bit synchronizer for the data as well, or we use a technique
  // where the data is only changed when the channel is idle.

  // Let's use a simpler approach: since this is a 4-phase handshake,
  // the data is stable between handshakes. We can synchronize the data
  // along with the valid signal using a multi-bit synchronizer, or we
  // can use the fact that the data is only changed when the source is
  // ready, and the destination only reads it when it's valid.

  // For safety, let's use a 2-stage synchronizer for the control signals
  // and ensure data is stable. We'll use a "data valid" approach where
  // the data is only considered valid when the synchronized valid is high.

  // Let's implement this step by step.

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_q <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      src_valid_q <= SEND_RESET_MSG;
      src_ready_q <= 1'b1;
      src_req_q <= 1'b0;
      src_ack_q <= 1'b0;
    end else begin
      // If we have valid data and are ready, perform handshake
      if (src_valid_q && src_ready_q) begin
        // Capture new data if src_valid_i is high
        if (src_valid_i) begin
          src_data_q <= src_data_i;
        end
        // Assert request to destination
        src_req_q <= 1'b1;
        // Clear valid (4-phase: req up, then req down)
        src_valid_q <= 1'b0;
        // Wait for ack before becoming ready again
        src_ready_q <= 1'b0;
      end else if (src_ack_q) begin
        // Ack received, clear request and become ready
        src_req_q <= 1'b0;
        src_ack_q <= 1'b0;
        src_ready_q <= 1'b1;
        // If DECOUPLED, we can accept new data immediately
        if (DECOUPLED && src_valid_i) begin
          src_data_q <= src_data_i;
          src_valid_q <= 1'b1;
        end
      end else if (src_valid_i && !src_valid_q) begin
        // New data available, store it
        src_data_q <= src_data_i;
        src_valid_q <= 1'b1;
      end
    end
  end

  // Synchronize src_req to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_req_sync <= 2'b00;
    end else begin
      src_req_sync <= {src_req_sync[0], src_req_q};
    end
  end

  // Synchronize dst_ack to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ack_sync <= 2'b00;
    end else begin
      dst_ack_sync <= {dst_ack_sync[0], dst_ack_q};
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_q <= {WIDTH{1'b0}};
      dst_valid_q <= 1'b0;
      dst_ready_q <= 1'b1;
      dst_req_q <= 1'b0;
      dst_ack_q <= 1'b0;
    end else begin
      // If request is synchronized and we are ready, accept data
      if (src_req_sync[1] && dst_ready_q) begin
        // Capture data (data should be stable at this point)
        dst_data_q <= src_data_q;
        dst_valid_q <= 1'b1;
        dst_ready_q <= 1'b0;
        // Assert ack to source
        dst_ack_q <= 1'b1;
      end else if (dst_valid_q && dst_ready_i) begin
        // Destination ready, clear valid and ack
        dst_valid_q <= 1'b0;
        dst_ack_q <= 1'b0;
        dst_ready_q <= 1'b1;
      end
    end
  end

  // Assign outputs
  assign src_ready_o = src_ready_q;
  assign dst_data_o = dst_data_q;
  assign dst_valid_o = dst_valid_q;

endmodule
