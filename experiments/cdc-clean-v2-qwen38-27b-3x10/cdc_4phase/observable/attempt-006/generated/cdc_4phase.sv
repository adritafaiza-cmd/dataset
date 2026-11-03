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

  // Internal signals for the 4-phase handshake
  // req: sender -> receiver (data valid)
  // ack: receiver -> sender (data accepted)
  //
  // 4-phase handshake:
  //   1. Sender asserts req (with data)
  //   2. Receiver asserts ack
  //   3. Sender deasserts req
  //   4. Receiver deasserts ack
  //
  // We use a simple 2-stage synchronizer for each signal crossing.

  // Source side state
  reg src_req;
  reg src_ack;
  reg [WIDTH-1:0] src_data_reg;

  // Destination side state
  reg dst_req;
  reg dst_ack;
  reg [WIDTH-1:0] dst_data_reg;

  // Synchronizer for req (src -> dst)
  reg [1:0] req_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      req_sync <= 2'b00;
    else
      req_sync <= {req_sync[0], src_req};
  end
  wire dst_req_synced = req_sync[1];

  // Synchronizer for ack (dst -> src)
  reg [1:0] ack_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      ack_sync <= 2'b00;
    else
      ack_sync <= {ack_sync[0], dst_ack};
  end
  wire src_ack_synced = ack_sync[1];

  // Data path: we need to transfer data along with req.
  // Since data is multi-bit, we use a gray-coded or multi-bit synchronizer.
  // For simplicity and correctness, we use a 2-stage synchronizer for each bit,
  // but this requires that data is stable while req is high.
  // Actually, for a 4-phase handshake, data is stable while req is high.
  // We can use a simple 2-stage synchronizer for the data as well, but we need
  // to ensure that the data is captured when req is asserted.
  //
  // A better approach: use a FIFO-like structure or a simple register that
  // captures data when req is asserted, and then synchronizes the data.
  //
  // Let's use a different approach: we'll use a 2-stage synchronizer for req,
  // and when req transitions from 0 to 1 on the destination side, we capture
  // the data. But the data needs to be synchronized too.
  //
  // Actually, the standard approach for multi-bit data in a 4-phase handshake
  // is to use a multi-bit synchronizer or to use a gray-coded counter.
  // For simplicity, let's use a 2-stage synchronizer for each bit of data,
  // and rely on the fact that data is stable while req is high.
  //
  // However, this can cause metastability issues if the data changes while
  // req is being synchronized. A safer approach is to use a small FIFO.
  //
  // Let's use a simpler approach: we'll use a 2-stage synchronizer for req,
  // and we'll capture the data on the source side when req is asserted,
  // and then synchronize the data using a 2-stage synchronizer.
  //
  // Actually, let's use a different strategy: we'll use a 2-stage synchronizer
  // for req, and we'll use a register on the destination side that captures
  // the data when req is high. The data will be synchronized using a 2-stage
  // synchronizer for each bit.
  //
  // Let's implement it step by step.

  // Source side: capture data when valid and ready
  wire src_can_send = src_valid_i & src_ready_o;

  // Source side: manage req and ack
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req <= 1'b0;
      src_ack <= 1'b0;
      src_data_reg <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
    end else begin
      // 4-phase handshake on source side
      if (!src_req) begin
        // Phase 1: assert req if we have data to send
        if (src_valid_i) begin
          src_req <= 1'b1;
          src_data_reg <= src_data_i;
        end
      end else begin
        // Phase 3: deassert req when ack is received
        if (src_ack_synced) begin
          src_req <= 1'b0;
          src_ack <= 1'b0;
        end
      end
    end
  end

  // Source ready: we can accept new data when req is low
  assign src_ready_o = !src_req;

  // Destination side: manage req and ack
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req <= 1'b0;
      dst_ack <= 1'b0;
      dst_data_reg <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
    end else begin
      // 4-phase handshake on destination side
      if (!dst_req) begin
        // Phase 1: wait for req from source
        if (dst_req_synced) begin
          dst_req <= 1'b1;
          dst_ack <= 1'b1;
        end
      end else begin
        // Phase 4: deassert ack when req is deasserted
        if (!dst_req_synced) begin
          dst_req <= 1'b0;
          dst_ack <= 1'b0;
        end
      end
    end
  end

  // Data synchronization: we need to synchronize the data from source to destination.
  // Since data is stable while req is high, we can use a 2-stage synchronizer for each bit.
  // But we need to capture the data when req is asserted.
  //
  // Let's use a different approach: we'll use a register on the destination side
  // that captures the data when req transitions from 0 to 1.
  //
  // Actually, let's use a simple 2-stage synchronizer for the data, and we'll
  // rely on the fact that data is stable while req is high.

  // Data synchronizer (src -> dst)
  reg [1:0][WIDTH-1:0] data_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      data_sync <= '0;
    else
      data_sync <= {data_sync[0], src_data_reg};
  end
  wire [WIDTH-1:0] dst_data_synced = data_sync[1];

  // Output data and valid
  assign dst_data_o = dst_data_synced;
  assign dst_valid_o = dst_req;

endmodule
