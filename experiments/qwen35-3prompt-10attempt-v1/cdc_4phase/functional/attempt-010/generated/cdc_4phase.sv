```systemverilog
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

  // Source domain state machine
  // States: IDLE, GRAB, WAIT_DST_READY, WAIT_DST_VALID
  typedef enum logic [1:0] {
    SRC_IDLE,
    SRC_GRAB,
    SRC_WAIT_DST_READY,
    SRC_WAIT_DST_VALID
  } src_state_t;

  src_state_t src_state, src_state_next;
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_valid_next;
  logic src_valid_sent; // Tracks if we have sent a valid to dst
  logic src_valid_pending; // Tracks if we are waiting for dst to accept

  // Destination domain state machine
  // States: IDLE, GRAB, WAIT_SRC_READY, WAIT_SRC_VALID
  typedef enum logic [1:0] {
    DST_IDLE,
    DST_GRAB,
    DST_WAIT_SRC_READY,
    DST_WAIT_SRC_VALID
  } dst_state_t;

  dst_state_t dst_state, dst_state_next;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_valid_next;
  logic dst_valid_pending; // Tracks if we are waiting for src to accept

  // Reset logic for state machines
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_state <= SRC_IDLE;
    else
      src_state <= src_state_next;
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_state <= DST_IDLE;
    else
      dst_state <= dst_state_next;
  end

  // Source State Logic
  always_comb begin
    src_state_next = src_state;
    src_data_reg = src_data_i;
    src_valid_reg = src_valid_i;
    src_valid_next = src_valid_i;
    src_valid_sent = 1'b0;
    src_valid_pending = 1'b0;

    case (src_state)
      SRC_IDLE: begin
        if (src_valid_i)
          src_state_next = SRC_GRAB;
      end

      SRC_GRAB: begin
        // We have grabbed the data. Now wait for destination to be ready.
        if (dst_ready_i)
          src_state_next = SRC_WAIT_DST_READY;
        else
          src_state_next = SRC_GRAB; // Stay here until dst_ready
      end

      SRC_WAIT_DST_READY: begin
        // Destination is ready, now wait for it to pull valid high.
        if (dst_valid_i)
          src_state_next = SRC_WAIT_DST_VALID;
        else
          src_state_next = SRC_WAIT_DST_READY;
      end

      SRC_WAIT_DST_VALID: begin
        // Destination has pulled valid high. Now wait for it to pull ready high.
        if (dst_ready_i)
          src_state_next = SRC_IDLE;
        else
          src_state_next = SRC_WAIT_DST_VALID;
      end
    endcase
  end

  // Destination State Logic
  always_comb begin
    dst_state_next = dst_state;
    dst_data_reg = dst_data_i; // Placeholder, will be updated when grabbed
    dst_valid_reg = dst_valid_i;
    dst_valid_next = dst_valid_i;
    dst_valid_pending = 1'b0;

    case (dst_state)
      DST_IDLE: begin
        if (src_valid_i)
          dst_state_next = DST_GRAB;
      end

      DST_GRAB: begin
        // We have grabbed the data. Now wait for source to be ready.
        if (src_ready_i)
          dst_state_next = DST_WAIT_SRC_READY;
        else
          dst_state_next = DST_GRAB; // Stay here until src_ready
      end

      DST_WAIT_SRC_READY: begin
        // Source is ready, now wait for it to pull valid high.
        if (src_valid_i)
          dst_state_next = DST_WAIT_SRC_VALID;
        else
          dst_state_next = DST_WAIT_SRC_READY;
      end

      DST_WAIT_SRC_VALID: begin
        // Source has pulled valid high. Now wait for it to pull ready high.
        if (src_ready_i)
          dst_state_next = DST_IDLE;
        else
          dst_state_next = DST_WAIT_SRC_VALID;
      end
    endcase
  end

  // Data and Valid Registration
  // Source Domain: Register data and valid when we enter GRAB state
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
    end else begin
      if (src_state == SRC_GRAB) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= src_valid_i;
      end
    end
  end

  // Destination Domain: Register data and valid when we enter GRAB state
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= '0;
      dst_valid_reg <= 1'b0;
    end else begin
      if (dst_state == DST_GRAB) begin
        dst_data_reg <= src_data_i; // Capture data from source domain
        dst_valid_reg <= src_valid_i;
      end
    end
  end

  // Output Logic
  // src_ready_o: High when source is allowed to send new data
  // dst_valid_o: High when destination is allowed to read data
  // dst_data_o: The data to be sent

  assign src_ready_o = (src_state == SRC_IDLE) || (src_state == SRC_WAIT_DST_VALID);
  
  assign dst_valid_o = (dst_state == DST_IDLE) || (dst_state == DST_WAIT_SRC_READY);
  
  assign dst_data_o = (dst_state == DST_IDLE) || (dst_state == DST_WAIT_SRC_READY) ? dst_data_reg : '0;

  // DECOUPLED Logic
  // If DECOUPLED is set, the source can accept a new item before the previous destination handshake returns.
  // This means src_ready_o should be high even if we are in SRC_WAIT_DST_READY or SRC_WAIT_DST_VALID,
  // provided we are not currently in SRC_GRAB.
  // However, the standard 4-phase handshake usually implies strict ordering unless decoupled.
  // With DECOUPLED=1, we allow overlapping handshakes.
  // The logic above for src_ready_o already allows this:
  // - SRC_IDLE: Ready
  // - SRC_WAIT_DST_VALID: Ready (waiting for dst to pull ready)
  // - SRC_GRAB: Not ready (grabbing data)
  // - SRC_WAIT_DST_READY: Not ready (waiting for dst to pull ready) -> Wait, this needs adjustment for decoupled.
  
  // Correction for DECOUPLED behavior:
  // If DECOUPLED, src_ready_o should be high whenever we are NOT in SRC_GRAB.
  // This allows the source to start a new transfer while waiting for the previous one to complete at the destination.
  
  if (DECOUPLED) begin
    assign src_ready_o = (src_state != SRC_GRAB);
  end else begin
    assign src_ready_o = (src_state == SRC_IDLE) || (src_state == SRC_WAIT_DST_VALID);
  end

  // SEND_RESET_MSG Logic
  // If SEND_RESET_MSG is set, emit RESET_MSG after reset instead of staying idle.
  // This is handled by initializing the destination state machine to a state that immediately sends the message.
  // However, the state machine logic above resets to DST_IDLE.
  // We need to modify the reset logic or add a specific state for sending the reset message.
  
  // Let's add a state for sending the reset message.
  typedef enum logic [2:0] {
    DST_IDLE,
    DST_GRAB,
    DST_WAIT_SRC_READY,
    DST_WAIT_SRC_VALID,
    DST_SEND_RESET_MSG
  } dst_state_t_extended;

  // Re-declare states with extended enum
  // Note: The previous state definitions were used in the always_comb blocks. 
  // We need to update the state definitions and logic to include the reset message state.
  
  // Re-defining states for clarity and correctness with SEND_RESET_MSG
  localparam logic [2:0] DST_IDLE = 3'b000;
  localparam logic [2:0] DST_GRAB = 3'b001;
  localparam logic [2:0] DST_WAIT_SRC_READY = 3'b010;
  localparam logic [2:0] DST_WAIT_SRC_VALID = 3'b011;
  localparam logic [2:0] DST_SEND_RESET_MSG = 3'b100;

  // Re-declaring state variables with wider type
  dst_state_t_extended dst_state_ext, dst_state_next_ext;
  
  // Reset logic for destination state machine with SEND_RESET_MSG
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      if (SEND_RESET_MSG)
        dst_state_ext <= DST_SEND_RESET_MSG;
      else
        dst_state_ext <= DST_IDLE;
    end else begin
      dst_state_ext <= dst_state_next_ext;
    end
  end

  // Re-implement Destination State Logic with SEND_RESET_MSG
  always_comb begin
    dst_state_next_ext = dst_state_ext;
    dst_data_reg = '0;
    dst_valid_reg = 1'b0;
    dst_valid_next = 1'b0;
    dst_valid_pending = 1'b0;

    case (dst_state_ext)
      DST_IDLE: begin
        if (src_valid_i)
          dst_state_next_ext = DST_GRAB;
      end

      DST_GRAB: begin
        if (src_ready_i)
          dst_state_next_ext = DST_WAIT_SRC_READY;
        else
          dst_state_next_ext = DST_GRAB;
      end

      DST_WAIT_SRC_READY: begin
        if (src_valid_i)
          dst_state_next_ext = DST_WAIT_SRC_VALID;
        else
          dst_state_next_ext = DST_WAIT_SRC_READY;
      end

      DST_WAIT_SRC_VALID: begin
        if (src_ready_i)
          dst_state_next_ext = DST_IDLE;
        else
          dst_state_next_ext = DST_WAIT_SRC_VALID;
      end

      DST_SEND_RESET_MSG: begin
        // Send reset message
        if (src_ready_i)
          dst_state_next_ext = DST_IDLE;
        else
          dst_state_next_ext = DST_SEND_RESET_MSG;
      end
    endcase
  end

  // Re-implement Data and Valid Registration for Destination
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= '0;
      dst_valid_reg <= 1'b0;
    end else begin
      if (dst_state_ext == DST_GRAB) begin
        dst_data_reg <= src_data_i;
        dst_valid_reg <= src_valid_i;
      end
      // For DST_SEND_RESET_MSG, we don't update dst_data_reg from src_data_i
      // We want to emit RESET_MSG.
    end
  end

  // Re-implement Output Logic with SEND_RESET_MSG
  // src_ready_o logic remains similar but needs to account for the extended state if necessary.
  // Actually, src_ready_o depends on src_state, which is independent of dst_state_ext.
  // However, the interaction between src and dst states must be consistent.
  
  // Re-defining Source States to be consistent if needed, but src_state logic is independent of dst_state_ext.
  // The only coupling is through signals.
  
  // Re-implement src_ready_o with DECOUPLED
  if (DECOUPLED) begin
    assign src_ready_o = (src_state != SRC_GRAB);
  end else begin
    assign src_ready_o = (src_state == SRC_IDLE) || (src_state == SRC_WAIT_DST_VALID);
  end

  // Re-implement dst_valid_o and dst_data_o with SEND_RESET_MSG
  assign dst_valid_o = (dst_state_ext == DST_IDLE) || (dst_state_ext == DST_WAIT_SRC_READY) || (dst_state_ext == DST_SEND_RESET_MSG);
  
  assign dst_data_o = (dst_state_ext == DST_IDLE) || (dst_state_ext == DST_WAIT_SRC_READY) || (dst_state_ext == DST_SEND_RESET_MSG) ? dst_data_reg : '0;

  // Special handling for RESET_MSG in destination data
  // When in DST_SEND_RESET_MSG, dst_data_reg should hold RESET_MSG
  // But the registration logic above only updates dst_data_reg when in DST_GRAB.
  // We need to update dst_data_reg when in DST_SEND_RESET_MSG as well.
  
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= '0;
      dst_valid_reg <= 1'b0;
    end else begin
      if (dst_state_ext == DST_GRAB) begin
        dst_data_reg <= src_data_i;
        dst_valid_reg <= src_valid_i;
      end else if (dst_state_ext == DST_SEND_RESET_MSG) begin
        dst_data_reg <= RESET_MSG;
        dst_valid_reg <= 1'b1;
      end
    end
  end

  // Re-implement dst_valid_o logic to ensure it's high during DST_SEND_RESET_MSG
  assign dst_valid_o = (dst_state_ext == DST_IDLE) || (dst_state_ext == DST_WAIT_SRC_READY) || (dst_state_ext == DST_SEND_RESET_MSG);

  // Re-implement src_ready_o logic to ensure it's high during DST_SEND_RESET_MSG if DECOUPLED
  // Actually, src_ready_o is determined by src_state.
  // If DECOUPLED, src_ready_o is high unless src_state == SRC_GRAB.
  // If not DECOUPLED, src_ready_o is high if src_state == SRC_IDLE or SRC_WAIT_DST_VALID.
  // This logic is correct as is.

  // One more check: When SEND_RESET_MSG is set, the destination should emit RESET_MSG.
  // The logic above does this by setting dst_data_reg to RESET_MSG and dst_valid_reg to 1'b1 when in DST_SEND_RESET_MSG.
  // The state machine transitions to DST_SEND_RESET_MSG on reset if SEND_RESET_MSG is set.
  // It stays there until src_ready_i is high, then transitions to DST_IDLE.
  // This ensures the reset message is sent exactly once after reset.

endmodule
```<|im_end|>
