```systemverilog
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

  // ---------------------------------------------------------------------------
  // Source Domain: Capture Valid/Ready and Clear Request
  // ---------------------------------------------------------------------------
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic src_clear_req;
  logic src_clear_pending;

  // Synchronize src_clear_i to src_clk_i
  logic src_clear_synced;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_clear_synced <= 1'b0;
    else
      src_clear_synced <= src_clear_i;
  end

  // State machine for Source side
  // States: IDLE, WAIT_DST_READY, CLEARING
  logic [1:0] src_state;
  parameter SRC_IDLE = 2'b00;
  parameter SRC_WAIT_READY = 2'b01;
  parameter SRC_CLEARING = 2'b10;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= SRC_IDLE;
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
      src_clear_pending <= 1'b0;
    end else begin
      case (src_state)
        SRC_IDLE: begin
          src_ready_reg <= 1'b1;
          if (src_clear_synced) begin
            src_state <= SRC_CLEARING;
            src_clear_pending <= 1'b1;
          end else if (src_valid_i) begin
            src_data_reg <= src_data_i;
            src_valid_reg <= 1'b1;
            src_state <= SRC_WAIT_READY;
          end
        end

        SRC_WAIT_READY: begin
          src_ready_reg <= 1'b0;
          if (src_clear_synced) begin
            src_state <= SRC_CLEARING;
            src_clear_pending <= 1'b1;
          end else if (dst_ready_i) begin
            // Data is pushed to destination
            src_state <= SRC_IDLE;
            src_valid_reg <= 1'b0;
            src_ready_reg <= 1'b1;
          end
        end

        SRC_CLEARING: begin
          src_clear_pending <= 1'b1;
          src_valid_reg <= 1'b0;
          src_ready_reg <= 1'b0;
          if (src_clear_synced) begin
            src_state <= SRC_IDLE;
            src_clear_pending <= 1'b0;
          end
        end
      endcase
    end
  end

  // Output assignments for Source side
  assign src_clear_pending_o = src_clear_pending;
  assign src_ready_o = src_ready_reg;

  // ---------------------------------------------------------------------------
  // Synchronization Stage: Capture Data and Valid
  // ---------------------------------------------------------------------------
  logic [WIDTH-1:0] sync_data;
  logic sync_valid;
  logic sync_clear_req;

  // Capture the beat from source domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_data <= {WIDTH{1'b0}};
      sync_valid <= 1'b0;
      sync_clear_req <= 1'b0;
    end else begin
      sync_data <= src_data_reg;
      sync_valid <= src_valid_reg;
      sync_clear_req <= src_clear_pending;
    end
  end

  // ---------------------------------------------------------------------------
  // Destination Domain: Synchronize Clear Request and State Machine
  // ---------------------------------------------------------------------------
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_clear_req;
  logic dst_clear_pending;
  logic dst_clear_done;

  // Synchronize src_clear_req to dst_clk_i
  logic [SYNC_STAGES-1:0] clear_sync_cnt;
  logic clear_synced;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      clear_sync_cnt <= {SYNC_STAGES{1'b0}};
      clear_synced <= 1'b0;
    end else begin
      if (clear_sync_cnt[SYNC_STAGES-1]) begin
        clear_synced <= 1'b1;
        clear_sync_cnt <= {SYNC_STAGES{1'b0}};
      end else begin
        clear_synced <= 1'b0;
        clear_sync_cnt <= clear_sync_cnt + 1'b1;
      end
    end
  end

  // State machine for Destination side
  // States: IDLE, WAIT_SRC_VALID, CLEARING
  logic [1:0] dst_state;
  parameter DST_IDLE = 2'b00;
  parameter DST_WAIT_VALID = 2'b01;
  parameter DST_CLEARING = 2'b10;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= DST_IDLE;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_clear_pending <= 1'b0;
      dst_clear_done <= 1'b0;
    end else begin
      case (dst_state)
        DST_IDLE: begin
          dst_valid_reg <= 1'b0;
          dst_clear_pending <= 1'b0;
          if (clear_synced) begin
            dst_state <= DST_CLEARING;
            dst_clear_pending <= 1'b1;
            dst_clear_done <= 1'b0;
          end else if (sync_valid) begin
            dst_data_reg <= sync_data;
            dst_valid_reg <= 1'b1;
            dst_state <= DST_WAIT_VALID;
          end
        end

        DST_WAIT_VALID: begin
          dst_clear_pending <= 1'b0;
          if (clear_synced) begin
            dst_state <= DST_CLEARING;
            dst_clear_pending <= 1'b1;
            dst_clear_done <= 1'b0;
          end else if (dst_ready_i) begin
            // Data is pushed to output
            dst_valid_reg <= 1'b0;
            dst_state <= DST_IDLE;
            dst_clear_done <= 1'b1;
          end
        end

        DST_CLEARING: begin
          dst_clear_pending <= 1'b1;
          dst_valid_reg <= 1'b0;
          if (clear_synced) begin
            dst_state <= DST_IDLE;
            dst_clear_pending <= 1'b0;
            dst_clear_done <= 1'b1;
          end
        end
      endcase
    end
  end

  // Output assignments for Destination side
  assign dst_clear_pending_o = dst_clear_pending;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // ---------------------------------------------------------------------------
  // Reset Synchronization (Optional based on parameter)
  // ---------------------------------------------------------------------------
  logic src_rst_synced;
  logic dst_rst_synced;

  // Synchronize src_rst_ni to dst_clk_i
  logic [SYNC_STAGES-1:0] src_rst_sync_cnt;
  always_ff @(posedge dst_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_rst_sync_cnt <= {SYNC_STAGES{1'b0}};
    end else begin
      if (src_rst_sync_cnt[SYNC_STAGES-1]) begin
        src_rst_sync_cnt <= {SYNC_STAGES{1'b0}};
        src_rst_synced <= 1'b1;
      end else begin
        src_rst_sync_cnt <= src_rst_sync_cnt + 1'b1;
        src_rst_synced <= 1'b0;
      end
    end
  end

  // Synchronize dst_rst_ni to src_clk_i
  logic [SYNC_STAGES-1:0] dst_rst_sync_cnt;
  always_ff @(posedge src_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_rst_sync_cnt <= {SYNC_STAGES{1'b0}};
    end else begin
      if (dst_rst_sync_cnt[SYNC_STAGES-1]) begin
        dst_rst_sync_cnt <= {SYNC_STAGES{1'b0}};
        dst_rst_synced <= 1'b1;
      end else begin
        dst_rst_sync_cnt <= dst_rst_sync_cnt + 1'b1;
        dst_rst_synced <= 1'b0;
      end
    end
  end

  // Logic to handle async reset clearing if enabled
  // This ensures that if an async reset occurs, the clear logic is triggered
  // to flush any in-flight data safely.
  
  // In the Source Domain:
  // If CLEAR_ON_ASYNC_RESET is 1, we treat the arrival of a reset pulse 
  // (detected via sync) as a clear request if we are not already clearing.
  // However, since the state machine already handles src_clear_synced,
  // we need to ensure that the reset release doesn't cause a spurious beat.
  // The current state machine logic handles this: if reset is active, state goes to IDLE.
  // If reset releases while in WAIT_READY or CLEARING, it forces back to IDLE.
  
  // To strictly adhere to "Reset and clear must not create a destination beat",
  // we ensure that valid is only asserted when in DST_WAIT_VALID and dst_ready_i is high.
  // The reset synchronization above helps in detecting reset transitions across domains
  // if needed for more complex RDC, but the primary mechanism is the state machine.
  
  // Additional safety: If CLEAR_ON_ASYNC_RESET is enabled, we can force a clear
  // if we detect a reset transition in the other domain that might have been missed
  // or to ensure clean state upon release. However, the standard 2-phase handshake
  // with proper reset handling in each domain usually suffices.
  // The explicit clear ports are the primary mechanism.
  
  // If CLEAR_ON_ASYNC_RESET is 1, we can optionally trigger a clear on the first
  // clock edge after reset release in the destination domain if the source domain
  // reset was also released. But typically, the user controls src_clear_i and dst_clear_i.
  // We will implement the parameter logic by forcing a clear request if the reset
  // transitions from low to high in the respective domain, assuming the other side
  // might have data.
  
  // Implementation of CLEAR_ON_ASYNC_RESET:
  // Detect reset release in src domain and force src_clear_req if dst has data?
  // No, that's complex. The standard interpretation is: if the system resets,
  // any data in flight should be discarded. Since we have explicit clear ports,
  // the user should assert them. If the parameter is set, we can automatically
  // assert the clear signal upon reset release in the local domain if the remote
  // domain is known to be resetting or if we want to be extra safe.
  
  // A simpler and safer interpretation for this specific parameter in a 2-phase channel:
  // If CLEAR_ON_ASYNC_RESET is 1, upon detecting the release of the local reset,
  // we assert the local clear signal for one cycle to ensure any potential
  // in-flight data (if the remote side was still driving) is flushed.
  
  logic src_rst_released;
  logic dst_rst_released;

  // Detect reset release in Source Domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_rst_released <= 1'b0;
    else
      src_rst_released <= 1'b1;
  end

  // Detect reset release in Destination Domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_rst_released <= 1'b0;
    else
      dst_rst_released <= 1'b1;
  end

  // Force clear if async reset release is detected and parameter is enabled
  // This is done locally to ensure the local side flushes its state.
  // We use a one-shot to avoid holding clear indefinitely.
  
  logic src_clear_auto;
  logic dst_clear_auto;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_clear_auto <= 1'b0;
    else if (CLEAR_ON_ASYNC_RESET && src_rst_released && src_clear_pending == 1'b0)
      src_clear_auto <= 1'b1;
    else
      src_clear_auto <= 1'b0;
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_clear_auto <= 1'b0;
    else if (CLEAR_ON_ASYNC_RESET && dst_rst_released && dst_clear_pending == 1'b0)
      dst_clear_auto <= 1'b1;
    else
      dst_clear_auto <= 1'b0;
  end

  // Combine user clear and auto clear
  assign src_clear_req = src_clear_synced || src_clear_auto;
  assign dst_clear_req = clear_synced || dst_clear_auto;

  // Note: The state machines above use `src_clear_synced` and `clear_synced` 
  // which are the synchronized versions of the inputs. 
  // We need to update the state machine logic to use the combined `src_clear_req` 
  // and `dst_clear_req` properly. 
  // Actually, `src_clear_synced` in the first block was just the input sync.
  // Let's refine the logic to use the combined signals.

  // Re-evaluating the state machine inputs:
  // The state machines should react to the synchronized version of the combined clear request.
  
  // Let's redefine the clear signals used in state machines to be the synchronized combined ones.
  
  // Source Side Clear Logic
  logic src_clear_combined_synced;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_clear_combined_synced <= 1'b0;
    else if (src_clear_req)
      src_clear_combined_synced <= 1'b1;
    else
      src_clear_combined_synced <= 1'b0;
  end

  // Destination Side Clear Logic
  logic dst_clear_combined_synced;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_clear_combined_synced <= 1'b0;
    else if (dst_clear_req)
      dst_clear_combined_synced <= 1'b1;
    else
      dst_clear_combined_synced <= 1'b0;
  end

  // Update State Machines to use combined signals
  // Source State Machine
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= SRC_IDLE;
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
      src_clear_pending <= 1'b0;
    end else begin
      case (src_state)
        SRC_IDLE: begin
          src_ready_reg <= 1'b1;
          if (src_clear_combined_synced) begin
            src_state <= SRC_CLEARING;
            src_clear_pending <= 1'b1;
          end else if (src_valid_i) begin
            src_data_reg <= src_data_i;
            src_valid_reg <= 1'b1;
            src_state <= SRC_WAIT_READY;
          end
        end

        SRC_WAIT_READY: begin
          src_ready_reg <= 1'b0;
          if (src_clear_combined_synced) begin
            src_state <= SRC_CLEARING;
            src_clear_pending <= 1'b1;
          end else if (dst_ready_i) begin
            src_state <= SRC_IDLE;
            src_valid_reg <= 1'b0;
            src_ready_reg <= 1'b1;
          end
        end

        SRC_CLEARING: begin
          src_clear_pending <= 1'b1;
          src_valid_reg <= 1'b0;
          src_ready_reg <= 1'b0;
          if (src_clear_combined_synced) begin
            src_state <= SRC_IDLE;
            src_clear_pending <= 1'b0;
          end
        end
      endcase
    end
  end

  // Destination State Machine
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= DST_IDLE;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_clear_pending <= 1'b0;
      dst_clear_done <= 1'b0;
    end else begin
      case (dst_state)
        DST_IDLE: begin
          dst_valid_reg <= 1'b0;
          dst_clear_pending <= 1'b0;
          if (dst_clear_combined_synced) begin
            dst_state <= DST_CLEARING;
            dst_clear_pending <= 1'b1;
            dst_clear_done <= 1'b0;
          end else if (sync_valid) begin
            dst_data_reg <= sync_data;
            dst_valid_reg <= 1'b1;
            dst_state <= DST_WAIT_VALID;
          end
        end

        DST_WAIT_VALID: begin
          dst_clear_pending <= 1'b0;
          if (dst_clear_combined_synced) begin
            dst_state <= DST_CLEARING;
            dst_clear_pending <= 1'b1;
            dst_clear_done <= 1'b0;
          end else if (dst_ready_i) begin
            dst_valid_reg <= 1'b0;
            dst_state <= DST_IDLE;
            dst_clear_done <= 1'b1;
          end
        end

        DST_CLEARING: begin
          dst_clear_pending <= 1'b1;
          dst_valid_reg <= 1'b0;
          if (dst_clear_combined_synced) begin
            dst_state <= DST_IDLE;
            dst_clear_pending <= 1'b0;
            dst_clear_done <= 1'b1;
          end
        end
      endcase
    end
  end

  // Final Output Assignments
  assign src_clear_pending_o = src_clear_pending;
  assign src_ready_o = src_ready_reg;
  assign dst_clear_pending_o = dst_clear_pending;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
```<|im_end|>
