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

  localparam LOG_SYNC_STAGES = $clog2(SYNC_STAGES + 1);
  localparam CLEAR_STAGES = 2;

  // ---------------------------------------------------------
  // Source Domain: Capture Valid/Ready and Clear Request
  // ---------------------------------------------------------
  logic [LOG_SYNC_STAGES-1:0] src_valid_cnt;
  logic src_valid_synced;
  logic src_ready_synced;
  logic src_clear_synced;
  logic src_clear_pending;
  logic src_in_clear;

  // ---------------------------------------------------------
  // Destination Domain: Capture Valid/Ready and Clear Request
  // ---------------------------------------------------------
  logic [LOG_SYNC_STAGES-1:0] dst_valid_cnt;
  logic dst_valid_synced;
  logic dst_ready_synced;
  logic dst_clear_synced;
  logic dst_clear_pending;
  logic dst_in_clear;

  // ---------------------------------------------------------
  // State Machine: Cross-domain State
  // ---------------------------------------------------------
  typedef enum logic [1:0] {
    IDLE,
    WAIT_SRC_VALID,
    WAIT_DST_READY,
    CLEAR_SRC,
    CLEAR_DST
  } state_t;

  state_t state, next_state;
  logic [WIDTH-1:0] data_buffer;
  logic data_valid;
  logic clear_active;

  // ---------------------------------------------------------
  // Source Domain Logic
  // ---------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_cnt      <= 0;
      src_valid_synced   <= 0;
      src_ready_synced   <= 0;
      src_clear_synced   <= 0;
      src_clear_pending  <= 0;
      src_in_clear       <= 0;
    end else begin
      // Async Reset handling
      if (CLEAR_ON_ASYNC_RESET && !src_rst_ni) begin
        src_clear_synced <= 1;
        src_in_clear     <= 1;
      end else begin
        src_clear_synced <= src_clear_i;
        src_in_clear     <= src_clear_synced;
      end

      // Simple FIFO counter for valid/ready handshake
      if (src_valid_synced && src_ready_synced) begin
        src_valid_cnt <= src_valid_cnt + 1'b1;
      end
      if (src_valid_synced) begin
        src_ready_synced <= 1'b1;
      end
      if (src_ready_synced && !src_valid_synced) begin
        src_ready_synced <= 1'b0;
      end
      if (src_valid_cnt > 0 && !src_valid_synced) begin
        src_valid_cnt <= src_valid_cnt - 1'b1;
      end
    end
  end

  // ---------------------------------------------------------
  // Destination Domain Logic
  // ---------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_cnt      <= 0;
      dst_valid_synced   <= 0;
      dst_ready_synced   <= 0;
      dst_clear_synced   <= 0;
      dst_clear_pending  <= 0;
      dst_in_clear       <= 0;
    end else begin
      // Async Reset handling
      if (CLEAR_ON_ASYNC_RESET && !dst_rst_ni) begin
        dst_clear_synced <= 1;
        dst_in_clear     <= 1;
      end else begin
        dst_clear_synced <= dst_clear_i;
        dst_in_clear     <= dst_clear_synced;
      end

      // Simple FIFO counter for valid/ready handshake
      if (dst_valid_synced && dst_ready_synced) begin
        dst_valid_cnt <= dst_valid_cnt + 1'b1;
      end
      if (dst_valid_synced) begin
        dst_ready_synced <= 1'b1;
      end
      if (dst_ready_synced && !dst_valid_synced) begin
        dst_ready_synced <= 1'b0;
      end
      if (dst_valid_cnt > 0 && !dst_valid_synced) begin
        dst_valid_cnt <= dst_valid_cnt - 1'b1;
      end
    end
  end

  // ---------------------------------------------------------
  // Cross-Domain State Machine
  // ---------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      state <= IDLE;
      data_buffer <= '0;
      data_valid <= 0;
      clear_active <= 0;
    end else begin
      state <= next_state;
    end
  end

  always_comb begin
    next_state = state;
    clear_active = 0;

    case (state)
      IDLE: begin
        if (src_valid_synced && src_ready_synced) begin
          next_state = WAIT_DST_READY;
          data_buffer = src_data_i;
          data_valid = 1;
        end else if (src_clear_synced) begin
          next_state = CLEAR_SRC;
          clear_active = 1;
        end
      end

      WAIT_SRC_VALID: begin
        // This state is effectively merged into IDLE logic above for simplicity
        // as we only hold one item. If we had a queue, we'd wait here.
        // Given "hold one outstanding item", we transition immediately.
        if (src_valid_synced && src_ready_synced) begin
          next_state = WAIT_DST_READY;
          data_buffer = src_data_i;
          data_valid = 1;
        end else if (src_clear_synced) begin
          next_state = CLEAR_SRC;
          clear_active = 1;
        end
      end

      WAIT_DST_READY: begin
        if (dst_ready_synced) begin
          next_state = IDLE;
          data_valid = 0;
        end else if (src_clear_synced) begin
          next_state = CLEAR_SRC;
          clear_active = 1;
        end
      end

      CLEAR_SRC: begin
        if (src_clear_synced) begin
          next_state = CLEAR_DST;
          clear_active = 1;
        end else begin
          next_state = IDLE;
          clear_active = 0;
        end
      end

      CLEAR_DST: begin
        if (dst_clear_synced) begin
          next_state = IDLE;
          clear_active = 0;
        end else begin
          next_state = CLEAR_SRC;
          clear_active = 1;
        end
      end

      default: next_state = IDLE;
    endcase
  end

  // ---------------------------------------------------------
  // Output Logic
  // ---------------------------------------------------------
  assign src_ready_o = (state == IDLE) || (state == WAIT_SRC_VALID);
  assign src_clear_pending_o = (state == CLEAR_SRC) || (state == CLEAR_DST);
  
  assign dst_valid_o = (state == WAIT_DST_READY) && data_valid;
  assign dst_data_o = data_buffer;
  assign dst_clear_pending_o = (state == CLEAR_SRC) || (state == CLEAR_DST);

  // ---------------------------------------------------------
  // CDC Synchronization for Control Signals
  // ---------------------------------------------------------
  // Source Domain: Sync Valid, Ready, Clear from Dest
  logic [LOG_SYNC_STAGES-1:0] v_cnt, r_cnt, c_cnt;
  logic v_sync, r_sync, c_sync;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      v_cnt <= 0; r_cnt <= 0; c_cnt <= 0;
      v_sync <= 0; r_sync <= 0; c_sync <= 0;
    end else begin
      if (CLEAR_ON_ASYNC_RESET && !src_rst_ni) begin
        c_sync <= 1;
      end else begin
        c_sync <= dst_clear_synced;
      end

      if (v_cnt > 0) v_cnt <= v_cnt - 1'b1;
      if (r_cnt > 0) r_cnt <= r_cnt - 1'b1;
      if (c_cnt > 0) c_cnt <= c_cnt - 1'b1;

      if (dst_valid_synced) v_cnt <= v_cnt + 1'b1;
      if (dst_ready_synced) r_cnt <= r_cnt + 1'b1;
      if (dst_clear_synced) c_cnt <= c_cnt + 1'b1;

      if (v_cnt == 0) v_sync <= 1;
      if (r_cnt == 0) r_sync <= 1;
      if (c_cnt == 0) c_sync <= 1;
    end
  end

  // Destination Domain: Sync Valid, Ready, Clear from Src
  logic [LOG_SYNC_STAGES-1:0] vs_cnt, rs_cnt, cs_cnt;
  logic vs_sync, rs_sync, cs_sync;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      vs_cnt <= 0; rs_cnt <= 0; cs_cnt <= 0;
      vs_sync <= 0; rs_sync <= 0; cs_sync <= 0;
    end else begin
      if (CLEAR_ON_ASYNC_RESET && !dst_rst_ni) begin
        cs_sync <= 1;
      end else begin
        cs_sync <= src_clear_synced;
      end

      if (vs_cnt > 0) vs_cnt <= vs_cnt - 1'b1;
      if (rs_cnt > 0) rs_cnt <= rs_cnt - 1'b1;
      if (cs_cnt > 0) cs_cnt <= cs_cnt - 1'b1;

      if (src_valid_synced) vs_cnt <= vs_cnt + 1'b1;
      if (src_ready_synced) rs_cnt <= rs_cnt + 1'b1;
      if (src_clear_synced) cs_cnt <= cs_cnt + 1'b1;

      if (vs_cnt == 0) vs_sync <= 1;
      if (rs_cnt == 0) rs_sync <= 1;
      if (cs_cnt == 0) cs_sync <= 1;
    end
  end

  // Re-assign internal sync signals based on CDC counters to ensure robustness
  // Note: In a real design, we might use the CDC counters directly, but 
  // for clarity in this specific 2-phase structure, we map them to the 
  // logic used in the state machine.
  
  // Override the sync signals used in the state machine with the CDC results
  // to ensure the state machine sees the synchronized version.
  // However, since the state machine uses `src_valid_synced` etc., 
  // we need to drive those from the CDC logic.
  
  // Let's refactor the state machine inputs to use the CDC outputs directly
  // to avoid double synchronization issues.
  
  // Re-declare internal wires for the state machine inputs
  logic sm_src_valid_synced;
  logic sm_src_ready_synced;
  logic sm_src_clear_synced;
  logic sm_dst_valid_synced;
  logic sm_dst_ready_synced;
  logic sm_dst_clear_synced;

  assign sm_src_valid_synced = vs_sync;
  assign sm_src_ready_synced = rs_sync;
  assign sm_src_clear_synced = cs_sync;
  assign sm_dst_valid_synced = v_sync;
  assign sm_dst_ready_synced = r_sync;
  assign sm_dst_clear_synced = c_sync;

  // Update State Machine Logic to use SM signals
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      state <= IDLE;
      data_buffer <= '0;
      data_valid <= 0;
      clear_active <= 0;
    end else begin
      state <= next_state;
    end
  end

  always_comb begin
    next_state = state;
    clear_active = 0;

    case (state)
      IDLE: begin
        if (sm_src_valid_synced && sm_src_ready_synced) begin
          next_state = WAIT_DST_READY;
          data_buffer = src_data_i;
          data_valid = 1;
        end else if (sm_src_clear_synced) begin
          next_state = CLEAR_SRC;
          clear_active = 1;
        end
      end

      WAIT_SRC_VALID: begin
        if (sm_src_valid_synced && sm_src_ready_synced) begin
          next_state = WAIT_DST_READY;
          data_buffer = src_data_i;
          data_valid = 1;
        end else if (sm_src_clear_synced) begin
          next_state = CLEAR_SRC;
          clear_active = 1;
        end
      end

      WAIT_DST_READY: begin
        if (sm_dst_ready_synced) begin
          next_state = IDLE;
          data_valid = 0;
        end else if (sm_src_clear_synced) begin
          next_state = CLEAR_SRC;
          clear_active = 1;
        end
      end

      CLEAR_SRC: begin
        if (sm_src_clear_synced) begin
          next_state = CLEAR_DST;
          clear_active = 1;
        end else begin
          next_state = IDLE;
          clear_active = 0;
        end
      end

      CLEAR_DST: begin
        if (sm_dst_clear_synced) begin
          next_state = IDLE;
          clear_active = 0;
        end else begin
          next_state = CLEAR_SRC;
          clear_active = 1;
        end
      end

      default: next_state = IDLE;
    endcase
  end

  // Re-assign outputs based on updated state machine
  assign src_ready_o = (state == IDLE) || (state == WAIT_SRC_VALID);
  assign src_clear_pending_o = (state == CLEAR_SRC) || (state == CLEAR_DST);
  
  assign dst_valid_o = (state == WAIT_DST_READY) && data_valid;
  assign dst_data_o = data_buffer;
  assign dst_clear_pending_o = (state == CLEAR_SRC) || (state == CLEAR_DST);

endmodule
```<|im_end|>
