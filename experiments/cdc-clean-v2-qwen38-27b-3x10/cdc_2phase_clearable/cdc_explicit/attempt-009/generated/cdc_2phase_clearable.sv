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

  // Internal signals
  wire src_req;
  wire dst_ack;
  wire dst_req;
  wire src_ack;

  // Source domain: request generation
  reg src_req_reg;
  reg src_ack_reg;
  reg src_clear_pending_reg;
  reg [WIDTH-1:0] src_data_reg;

  // Destination domain: acknowledge generation
  reg dst_ack_reg;
  reg dst_req_reg;
  reg dst_ack_reg_next;
  reg dst_clear_pending_reg;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;

  // Synchronization chains
  // src_req -> dst domain
  reg [SYNC_STAGES-1:0] src_req_sync;
  // dst_ack -> src domain
  reg [SYNC_STAGES-1:0] dst_ack_sync;
  // dst_req -> src domain
  reg [SYNC_STAGES-1:0] dst_req_sync;
  // src_ack -> dst domain
  reg [SYNC_STAGES-1:0] src_ack_sync;

  // Data synchronization: src_data -> dst domain
  // We need to synchronize the data along with the request.
  // Since data is multi-bit, we use a handshake to ensure it's stable.
  // The data is captured in src domain when src_req is asserted.
  // We synchronize the data through a series of registers in the dst domain,
  // but we need to ensure it's stable. The standard approach is to use
  // a gray code or a handshake. Here, we use the fact that the data is
  // stable while src_req is high. We synchronize the data using a
  // multi-stage synchronizer that is enabled when the request is detected.

  // For simplicity and safety, we'll use a 2-stage synchronizer for the data
  // but we need to ensure it's captured at the right time.
  // Actually, the safest way is to use a FIFO-like approach or a
  // handshake-based data transfer.

  // Let's use a simpler approach: synchronize the data using a
  // series of registers that are clocked in the dst domain,
  // but we need to ensure the data is stable. Since the data is
  // stable while src_req is high, we can synchronize it using
  // a 2-stage synchronizer that is triggered by the synchronized request.

  // Actually, the standard approach for multi-bit data in a 2-phase handshake
  // is to use a gray code or to ensure the data is stable. Here, we'll use
  // a 2-stage synchronizer for the data, but we need to be careful.

  // Let's use a different approach: we'll use a 2-phase handshake for the
  // control signals, and for the data, we'll use a series of registers
  // that are clocked in the dst domain. The data is captured in the src
  // domain when src_req is asserted, and it remains stable until src_ack
  // is received. We synchronize the data using a 2-stage synchronizer
  // that is enabled when the synchronized request is detected.

  // For the data, we'll use a 2-stage synchronizer:
  reg [WIDTH-1:0] data_sync_1;
  reg [WIDTH-1:0] data_sync_2;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_reg <= 1'b0;
      src_ack_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
    end else begin
      // Clear handling
      if (src_clear_i) begin
        src_clear_pending_reg <= 1'b1;
        src_req_reg <= 1'b0;
        src_ack_reg <= 1'b0;
      end else begin
        // Normal operation
        if (src_ack_reg && !src_req_reg) begin
          // Ack received, request can be deasserted
          src_req_reg <= 1'b0;
          src_ack_reg <= 1'b0;
        end else if (!src_req_reg && src_valid_i && !src_clear_pending_reg) begin
          // New valid, assert request
          src_req_reg <= 1'b1;
          src_data_reg <= src_data_i;
        end
      end
    end
  end

  // Synchronize src_req to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_req_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_req_sync <= {src_req_sync[SYNC_STAGES-2:0], src_req_reg};
    end
  end

  // Synchronize dst_ack to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ack_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_ack_sync <= {dst_ack_sync[SYNC_STAGES-2:0], dst_ack_reg};
    end
  end

  // Synchronize dst_req to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_req_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_req_sync <= {dst_req_sync[SYNC_STAGES-2:0], dst_req_reg};
    end
  end

  // Synchronize src_ack to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ack_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_ack_sync <= {src_ack_sync[SYNC_STAGES-2:0], src_ack_reg};
    end
  end

  // Synchronize data to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      data_sync_1 <= {WIDTH{1'b0}};
      data_sync_2 <= {WIDTH{1'b0}};
    end else begin
      data_sync_1 <= src_data_reg;
      data_sync_2 <= data_sync_1;
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_reg <= 1'b0;
      dst_req_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else begin
      // Clear handling
      if (dst_clear_i) begin
        dst_clear_pending_reg <= 1'b1;
        dst_ack_reg <= 1'b0;
        dst_req_reg <= 1'b0;
        dst_valid_reg <= 1'b0;
      end else begin
        // Normal operation
        if (dst_req_reg && !dst_ack_reg) begin
          // Request received, assert acknowledge
          dst_ack_reg <= 1'b1;
          dst_data_reg <= data_sync_2;
          dst_valid_reg <= 1'b1;
        end else if (dst_ack_reg && !dst_req_reg) begin
          // Ack received, request can be deasserted
          dst_req_reg <= 1'b0;
          dst_ack_reg <= 1'b0;
          dst_valid_reg <= 1'b0;
        end else if (!dst_req_reg && !dst_ack_reg && dst_ready_i) begin
          // Ready to accept new request
          dst_req_reg <= 1'b1;
        end
      end
    end
  end

  // Output assignments
  assign src_ready_o = !src_req_reg && !src_clear_pending_reg;
  assign src_clear_pending_o = src_clear_pending_reg;
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

endmodule
