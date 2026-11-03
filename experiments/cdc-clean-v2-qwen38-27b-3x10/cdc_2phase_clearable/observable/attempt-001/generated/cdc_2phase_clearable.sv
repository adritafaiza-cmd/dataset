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
  wire [WIDTH-1:0] src_data_reg;
  wire             src_valid_reg;
  wire             src_ready_int;
  wire             src_clear_pending_int;

  wire [WIDTH-1:0] dst_data_reg;
  wire             dst_valid_reg;
  wire             dst_ready_int;
  wire             dst_clear_pending_int;

  // Source side: register data and valid, generate ready
  // Destination side: register data and valid, generate ready

  // We need a CDC mechanism that:
  // 1. Transfers data in order
  // 2. Supports clear that isolates both ends
  // 3. No extra valid gap between beats
  // 4. Each clear step reaches the other clock one handshake later

  // Let's use a simple approach:
  // - Source holds data in a register when valid is asserted
  // - Destination receives data via a synchronized valid signal
  // - Use a toggle-based or level-based handshake

  // Actually, let's think about this more carefully.
  // A two-phase valid/ready channel means:
  // - valid is asserted when data is available
  // - ready is asserted when the receiver can accept data
  // - Transfer occurs when both valid and ready are high

  // For CDC, we need to synchronize the valid and ready signals.
  // But we also need to handle clear.

  // Let's use a simple approach with synchronized signals:
  // - src_valid is synchronized to dst domain
  // - dst_ready is synchronized to src domain
  // - Data is transferred when both are high in their respective domains

  // But this can cause issues with data stability. Let's use a different approach.

  // Approach: Use a FIFO-like structure with a single entry
  // - Source writes data to a register
  // - Destination reads from the register
  // - Use synchronized valid/ready signals

  // Let's implement a simple 1-deep buffer with CDC:

  // Source side:
  // - When src_valid_i is high and src_ready_o is low, hold data
  // - When src_valid_i is high and src_ready_o is high, transfer data
  // - src_ready_o is high when the destination is ready to accept

  // Destination side:
  // - When dst_valid_o is high and dst_ready_i is low, hold data
  // - When dst_valid_o is high and dst_ready_i is high, transfer data
  // - dst_valid_o is high when there is data to transfer

  // For CDC, we need to synchronize:
  // - src_valid to dst domain (to indicate data is available)
  // - dst_ready to src domain (to indicate destination is ready)

  // But we also need to handle clear. Clear should:
  // - Isolate both ends
  // - Drop the one outstanding beat
  // - Return both sides to idle

  // Let's use a state machine approach:

  // Source states:
  // - IDLE: No data to send
  // - WAIT: Data is being sent, waiting for destination ready
  // - CLEAR: Clear is in progress

  // Destination states:
  // - IDLE: No data to receive
  // - WAIT: Data is being received, waiting for destination ready
  // - CLEAR: Clear is in progress

  // Actually, let's simplify. We'll use a single-entry buffer with synchronized control signals.

  // Source side:
  reg [WIDTH-1:0] src_data_r;
  reg             src_valid_r;
  reg             src_clear_pending_r;

  // Destination side:
  reg [WIDTH-1:0] dst_data_r;
  reg             dst_valid_r;
  reg             dst_clear_pending_r;

  // Synchronized signals
  wire [SYNC_STAGES-1:0] src_valid_sync;
  wire [SYNC_STAGES-1:0] dst_ready_sync;
  wire [SYNC_STAGES-1:0] src_clear_sync;
  wire [SYNC_STAGES-1:0] dst_clear_sync;

  // Source valid synchronized to destination
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_valid_sync <= {src_valid_sync[SYNC_STAGES-2:0], src_valid_r};
    end
  end

  // Destination ready synchronized to source
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_ready_sync <= {dst_ready_sync[SYNC_STAGES-2:0], dst_ready_i};
    end
  end

  // Source clear synchronized to destination
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
    end
  end

  // Destination clear synchronized to source
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
    end
  end

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_r <= {WIDTH{1'b0}};
      src_valid_r <= 1'b0;
      src_clear_pending_r <= 1'b0;
    end else begin
      if (src_clear_i) begin
        // Clear is asserted
        src_valid_r <= 1'b0;
        src_clear_pending_r <= 1'b1;
      end else if (src_clear_pending_r) begin
        // Wait for clear to propagate
        if (dst_clear_sync[SYNC_STAGES-1]) begin
          // Clear has reached destination
          src_clear_pending_r <= 1'b0;
        end
      end else if (src_valid_i && !src_valid_r) begin
        // New data available
        src_data_r <= src_data_i;
        src_valid_r <= 1'b1;
      end else if (src_valid_r && dst_ready_sync[SYNC_STAGES-1]) begin
        // Data accepted by destination
        src_valid_r <= 1'b0;
      end
    end
  end

  // Destination side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_r <= {WIDTH{1'b0}};
      dst_valid_r <= 1'b0;
      dst_clear_pending_r <= 1'b0;
    end else begin
      if (dst_clear_i) begin
        // Clear is asserted
        dst_valid_r <= 1'b0;
        dst_clear_pending_r <= 1'b1;
      end else if (dst_clear_pending_r) begin
        // Wait for clear to propagate
        if (src_clear_sync[SYNC_STAGES-1]) begin
          // Clear has reached source
          dst_clear_pending_r <= 1'b0;
        end
      end else if (src_valid_sync[SYNC_STAGES-1] && !dst_valid_r) begin
        // New data available from source
        dst_data_r <= src_data_r;
        dst_valid_r <= 1'b1;
      end else if (dst_valid_r && dst_ready_i) begin
        // Data accepted by receiver
        dst_valid_r <= 1'b0;
      end
    end
  end

  // Outputs
  assign src_ready_o = dst_ready_sync[SYNC_STAGES-1] && !src_clear_pending_r && !src_clear_i;
  assign src_clear_pending_o = src_clear_pending_r;
  assign dst_valid_o = dst_valid_r && !dst_clear_pending_r && !dst_clear_i;
  assign dst_data_o = dst_data_r;
  assign dst_clear_pending_o = dst_clear_pending_r;

endmodule
