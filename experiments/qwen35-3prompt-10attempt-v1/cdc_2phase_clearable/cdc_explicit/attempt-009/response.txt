```systemverilog
module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  wire src_rst_ni,
  input  wire src_clk_i,
  input  wire src_clear_i,
  output reg  src_clear_pending_o,
  input  wire [WIDTH-1:0] src_data_i,
  input  wire src_valid_i,
  output reg  src_ready_o,
  input  wire dst_rst_ni,
  input  wire dst_clk_i,
  input  wire dst_clear_i,
  output reg  dst_clear_pending_o,
  output reg  [WIDTH-1:0] dst_data_o,
  output reg  dst_valid_o,
  input  wire dst_ready_i
);

  localparam SYNC_STAGES_CNT = 1 << SYNC_STAGES;

  // ---------------------------------------------------------------------------
  // Source Domain Logic
  // ---------------------------------------------------------------------------
  // State Machine for Source Side
  // States:
  //   IDLE       : Waiting for valid or clear
  //   CAPTURE    : Valid asserted, capturing data, waiting for clear or ready
  //   CLEARING   : Clear requested, flushing state, waiting for clear release
  //   CLEAR_DONE : Clear finished, returning to IDLE
  //
  // Note: We use a synchronous state machine in src_clk_i.
  // The 'clear_pending' signal is driven high when entering CAPTURE or CLEARING states
  // and cleared when returning to IDLE.

  typedef enum logic [1:0] {
    SRC_IDLE,
    SRC_CAPTURE,
    SRC_CLEARING,
    SRC_CLEAR_DONE
  } src_state_t;

  src_state_t src_state_curr, src_state_next;
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_clear_pending_reg;

  // Synchronous State Machine
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state_curr <= SRC_IDLE;
      src_data_reg   <= '0;
      src_valid_reg  <= 1'b0;
      src_clear_pending_reg <= 1'b0;
    end else begin
      src_state_curr <= src_state_next;
      src_data_reg   <= src_data_reg;
      src_valid_reg  <= src_valid_reg;
      src_clear_pending_reg <= src_clear_pending_reg;
    end
  end

  // Next State Logic
  always_comb begin
    src_state_next = src_state_curr;
    src_ready_o = 1'b0;
    src_clear_pending_o = 1'b0;

    case (src_state_curr)
      SRC_IDLE: begin
        if (src_valid_i) begin
          src_state_next = SRC_CAPTURE;
          src_data_reg   = src_data_i;
          src_valid_reg  = 1'b1;
          src_clear_pending_o = 1'b1;
        end else if (src_clear_i) begin
          // If clear is asserted while idle, we can immediately acknowledge
          // but typically we wait for the beat to be processed or just stay idle.
          // Per spec: "isolate the channel... return both sides to idle".
          // If idle, nothing to isolate. Just ensure clear_pending is low.
          src_clear_pending_o = 1'b0;
        end
      end

      SRC_CAPTURE: begin
        src_clear_pending_o = 1'b1;
        if (src_clear_i) begin
          src_state_next = SRC_CLEARING;
        end else if (dst_ready_i) begin
          // Handshake complete, move to idle
          src_state_next = SRC_IDLE;
          src_valid_reg = 1'b0;
          src_clear_pending_o = 1'b0;
        end
      end

      SRC_CLEARING: begin
        src_clear_pending_o = 1'b1;
        if (src_clear_i) begin
          // Hold state until clear is de-asserted
        end else begin
          src_state_next = SRC_CLEAR_DONE;
        end
      end

      SRC_CLEAR_DONE: begin
        src_clear_pending_o = 1'b0;
        if (src_clear_i) begin
          src_state_next = SRC_CLEARING;
        end else begin
          src_state_next = SRC_IDLE;
        end
      end

      default: begin
        src_state_next = SRC_IDLE;
      end
    endcase
  end

  // ---------------------------------------------------------------------------
  // Destination Domain Logic (CDC Crossing)
  // ---------------------------------------------------------------------------
  // We use a 2-phase handshake with asynchronous FIFO-like storage.
  // Since we need to support clearing, we implement a "flushable" register array.
  //
  // Architecture:
  // 1. Async FIFO (Gray-coded pointer) to store the data/valid pair.
  // 2. Clear logic: When clear is asserted, we flush the FIFO and reset pointers.
  // 3. Handshake:
  //    - Source pushes to FIFO (when src_valid && dst_ready).
  //    - Source waits for FIFO write complete (src_ready).
  //    - Destination pops from FIFO (when dst_valid && src_ready).
  //    - Destination waits for FIFO read complete (dst_ready).
  //
  // Clear Behavior:
  // - If clear is asserted in SRC, SRC enters CLEARING. It will not push new data.
  //   It waits for the current item to be popped or for the clear to complete.
  // - If clear is asserted in DST, DST enters CLEARING. It will not pop new data.
  //   It waits for the current item to be pushed or for the clear to complete.
  // - Coordination:
  //   The "Clear" signal must be synchronized to both domains.
  //   We use a 2-stage synchronizer for src_clear_i in dst domain and dst_clear_i in src domain.
  //   However, the spec says "coordinated flush".
  //   Strategy:
  //     1. Synchronize clear signals to both domains.
  //     2. If either side sees a clear, it sets its local clear_pending.
  //     3. The side that sees clear first (or both) initiates the flush.
  //     4. The other side must wait until the flush is complete before resuming normal operation.
  //
  // To ensure "Reset and clear must not create a destination beat", we ensure that
  // during clear, no data is read from the FIFO to the output.

  // Synchronizers for Clear Signals
  // src_clear_synced: Synchronized src_clear_i in dst domain
  // dst_clear_synced: Synchronized dst_clear_i in src domain

  logic [SYNC_STAGES-1:0] src_clear_synced;
  logic [SYNC_STAGES-1:0] dst_clear_synced;

  // Synchronizer for src_clear_i in dst domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_clear_synced <= '0;
    else
      src_clear_synced <= {src_clear_synced[SYNC_STAGES-2:0], src_clear_i};
  end

  // Synchronizer for dst_clear_i in src domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_clear_synced <= '0;
    else
      dst_clear_synced <= {dst_clear_synced[SYNC_STAGES-2:0], dst_clear_i};
  end

  // ---------------------------------------------------------------------------
  // Async FIFO Implementation (Clearable)
  // ---------------------------------------------------------------------------
  // We implement a simple pointer-based FIFO with clear capability.
  // Since SYNC_STAGES is small (3), we can unroll or use a small array.
  // Data width: WIDTH + 1 (for valid bit)
  
  typedef enum logic [1:0] {
    FIFO_IDLE,
    FIFO_WRITING,
    FIFO_READING,
    FIFO_CLEARING
  } fifo_state_t;

  fifo_state_t fifo_state;
  logic [WIDTH-1:0] fifo_data [SYNC_STAGES_CNT-1:0];
  logic fifo_valid [SYNC_STAGES_CNT-1:0];
  logic [SYNC_STAGES-1:0] fifo_write_ptr;
  logic [SYNC_STAGES-1:0] fifo_read_ptr;
  logic fifo_empty;
  logic fifo_full;
  logic fifo_write_en;
  logic fifo_read_en;
  logic fifo_clear_req;
  logic fifo_clear_ack;

  // Clear Request Logic
  // If either domain requests clear, we initiate a global clear.
  // We use a 2-stage synchronizer for the clear request to avoid metastability
  // on the cross-domain clear signal.
  logic [SYNC_STAGES-1:0] global_clear_req;
  
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      global_clear_req <= '0;
    else
      global_clear_req <= {global_clear_req[SYNC_STAGES-2:0], (src_clear_synced | dst_clear_synced)};
  end

  // Clear Ack Logic (in src domain)
  // We need to know if the clear has been acknowledged by the destination.
  // Since the clear is global, once the destination starts clearing, the source knows.
  // But we need to coordinate the "pending" signals.
  // Let's simplify:
  // - If global_clear_req is high, both sides set their pending flag.
  // - The side that is "behind" (e.g., source has data, dest is idle) must wait.
  // - Actually, the simplest robust way for a 2-phase channel with clear:
  //   1. Both sides synchronize the clear request.
  //   2. If clear is active, the FIFO enters a "clearing" state.
  //   3. No new data is written. No data is read.
  //   4. Once clear is de-asserted, the FIFO resets pointers and data.
  //   5. The "pending" flag is high during the transition.

  // Let's refine the state machine for the FIFO to handle clear properly.
  // We will use the global_clear_req to drive the FIFO clear.
  
  // Synchronizer for global_clear_req in src domain to drive FIFO clear logic safely
  logic [SYNC_STAGES-1:0] global_clear_req_src;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      global_clear_req_src <= '0;
    else
      global_clear_req_src <= {global_clear_req_src[SYNC_STAGES-2:0], global_clear_req};
  end

  // Synchronizer for global_clear_req in dst domain to drive FIFO clear logic safely
  logic [SYNC_STAGES-1:0] global_clear_req_dst;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      global_clear_req_dst <= '0;
    else
      global_clear_req_dst <= {global_clear_req_dst[SYNC_STAGES-2:0], global_clear_req};
  end

  // FIFO State Machine
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      fifo_state <= FIFO_IDLE;
      fifo_write_ptr <= '0;
      fifo_read_ptr <= '0;
      fifo_data <= '0;
      fifo_valid <= '0;
      fifo_empty <= 1'b1;
      fifo_full <= 1'b0;
    end else begin
      fifo_state <= fifo_state_next;
      fifo_write_ptr <= fifo_write_ptr_next;
      fifo_read_ptr <= fifo_read_ptr_next;
      fifo_data <= fifo_data_next;
      fifo_valid <= fifo_valid_next;
      fifo_empty <= fifo_empty_next;
      fifo_full <= fifo_full_next;
    end
  end

  // Next State Logic for FIFO
  always_comb begin
    fifo_state_next = fifo_state;
    fifo_write_ptr_next = fifo_write_ptr;
    fifo_read_ptr_next = fifo_read_ptr;
    fifo_data_next = fifo_data;
    fifo_valid_next = fifo_valid;
    fifo_empty_next = 1'b1;
    fifo_full_next = 1'b0;
    fifo_write_en = 1'b0;
    fifo_read_en = 1'b0;

    case (fifo_state)
      FIFO_IDLE: begin
        if (global_clear_req_dst) begin
          fifo_state_next = FIFO_CLEARING;
        end else if (fifo_write_en && !fifo_full) begin
          fifo_state_next = FIFO_WRITING;
        end else if (fifo_read_en && !fifo_empty) begin
          fifo_state_next = FIFO_READING;
        end
      end

      FIFO_WRITING: begin
        if (global_clear_req_dst) begin
          fifo_state_next = FIFO_CLEARING;
        end else if (fifo_write_en && !fifo_full) begin
          // Data is written on the next cycle
          fifo_data_next[fifo_write_ptr] = {src_valid_reg, src_data_reg};
          fifo_write_ptr_next = fifo_write_ptr + 1;
          if (fifo_write_ptr_next == SYNC_STAGES_CNT) fifo_write_ptr_next = '0;
          fifo_state_next = FIFO_IDLE;
        end
      end

      FIFO_READING: begin
        if (global_clear_req_dst) begin
          fifo_state_next = FIFO_CLEARING;
        end else if (fifo_read_en && !fifo_empty) begin
          fifo_read_ptr_next = fifo_read_ptr + 1;
          if (fifo_read_ptr_next == SYNC_STAGES_CNT) fifo_read_ptr_next = '0;
          fifo_state_next = FIFO_IDLE;
        end
      end

      FIFO_CLEARING: begin
        if (global_clear_req_dst) begin
          // Hold clearing state
        end else begin
          fifo_state_next = FIFO_IDLE;
          fifo_write_ptr_next = '0;
          fifo_read_ptr_next = '0;
          fifo_data_next = '0;
          fifo_valid_next = '0;
          fifo_empty_next = 1'b1;
          fifo_full_next = 1'b0;
        end
      end

      default: begin
        fifo_state_next = FIFO_IDLE;
        fifo_write_ptr_next = '0;
        fifo_read_ptr_next = '0;
        fifo_data_next = '0;
        fifo_valid_next = '0;
        fifo_empty_next = 1'b1;
        fifo_full_next = 1'b0;
      end
    endcase
  end

  // FIFO Empty/Full Logic
  always_comb begin
    fifo_empty = (fifo_write_ptr == fifo_read_ptr) && (fifo_state == FIFO_IDLE);
    fifo_full = (fifo_write_ptr == fifo_read_ptr) && (fifo_state != FIFO_IDLE);
  end

  // ---------------------------------------------------------------------------
  // Handshake Logic
  // ---------------------------------------------------------------------------
  
  // Source Side Handshake
  // src_ready_o is high when the FIFO is not full (and not clearing)
  // AND the source is not in a clear state.
  
  // We need to determine if the source is "clearing" based on its own state
  // or the global clear request.
  // The spec says: "src_clear_pending_o / dst_clear_pending_o stay high until that side has finished the clear."
  
  // Let's define clear_pending logic explicitly.
  // If global_clear_req is active, both sides are clearing.
  // If the source is in SRC_CLEARING state, it is clearing.
  // If the destination is in FIFO_CLEARING state, it is clearing.
  
  // Actually, the simplest interpretation of "coordinated flush":
  // 1. When clear is asserted, both sides set their pending flag.
  // 2. They wait until the clear is de-asserted AND any in-flight data is handled.
  // 3. Once clear is de-asserted, they reset to idle.
  
  // Revised Clear Logic:
  // - If global_clear_req is high, both sides set pending.
  // - If global_clear_req is low, but one side is still processing the clear (e.g., waiting for the other to finish),
  //   we need to track that.
  // However, since the clear is a single-bit signal, the "pending" duration is essentially the time from assertion to de-assertion
  // plus the time to drain the FIFO.
  
  // Let's simplify the pending logic:
  // - If global_clear_req is high, pending is high.
  // - If global_clear_req is low, but the FIFO is in CLEARING state, pending is high.
  // - If global_clear_req is low and FIFO is IDLE, pending is low.
  
  // But wait, the source might be clearing while the dest is idle, or vice versa.
  // The "coordinated" part implies that if one side clears, the other must also clear.
  // So, if global_clear_req is high, BOTH pending flags are high.
  // If global_clear_req is low, BOTH pending flags are low (assuming FIFO is not stuck in clearing state).
  
  // Let's implement the pending flags based on the global clear request and the local state.
  
  // Source Pending
  // High if:
  // 1. global_clear_req_src is high (meaning clear was seen in src domain)
  // 2. OR src_state is SRC_CLEARING
  // 3. OR fifo_state is FIFO_CLEARING (if dest cleared while src was idle)
  
  // Actually, to be safe and simple:
  // If global_clear_req is high, both pending are high.
  // If global_clear_req is low, pending is high only if the local state machine is in a clearing state.
  
  // Let's re-evaluate the "coordinated" requirement.
  // "src_clear_i and dst_clear_i request a coordinated flush: isolate the channel, drop in-flight data, then return both sides to idle."
  // This implies that if src_clear_i is high, dst_clear_pending_o should be high, and vice versa.
  // So, pending = global_clear_req OR (local_clear_state).
  
  // Let's define the pending signals:
  logic src_clear_pending_internal;
  logic dst_clear_pending_internal;

  // Source Pending Logic
  // High if global clear is active OR source is in clearing state
  always_comb begin
    src_clear_pending_o = global_clear_req_src | (src_state_curr == SRC_CLEARING);
  end

  // Destination Pending Logic
  // High if global clear is active OR dest is in clearing state
  always_comb begin
    dst_clear_pending_o = global_clear_req_dst | (fifo_state == FIFO_CLEARING);
  end

  // Handshake Signals
  // src_ready_o: High when FIFO is not full and not clearing
  // dst_valid_o: High when FIFO is not empty and not clearing
  
  // Note: The FIFO state machine already handles the clearing state.
  // We just need to ensure that during clearing, no data is transferred.
  
  // src_ready_o
  always_comb begin
    src_ready_o = 1'b0;
    if (src_state_curr != SRC_CLEARING && 
        src_state_curr != SRC_CAPTURE && // In capture, we are waiting for ready
        fifo_state != FIFO_CLEARING &&
        !fifo_full) begin
      src_ready_o = 1'b1;
    end
  end

  // dst_valid_o
  always_comb begin
    dst_valid_o = 1'b0;
    if (fifo_state != FIFO_CLEARING &&
        !fifo_empty) begin
      dst_valid_o = 1'b1;
    end
  end

  // Write Enable (from Source)
  // Only enable if src_valid_reg is high, src_ready_o is high, and not clearing
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_i && src_ready_o && (src_state_curr != SRC_CLEARING);
    end
  end

  // Read Enable (to Destination)
  // Only enable if dst_valid_o is high, dst_ready_i is high, and not clearing
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      fifo_read_en <= 1'b0;
    end else begin
      fifo_read_en <= dst_valid_o && dst_ready_i && (fifo_state != FIFO_CLEARING);
    end
  end

  // Output Data
  // Read from FIFO when dst_valid_o is high
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= '0;
      dst_valid_o <= 1'b0;
    end else begin
      if (fifo_read_en && (fifo_state != FIFO_CLEARING)) begin
        dst_data_o = fifo_data[fifo_read_ptr];
        dst_valid_o = 1'b1;
      end else begin
        dst_data_o <= '0;
        dst_valid_o <= 1'b0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Reset Logic for Clear
  // ---------------------------------------------------------------------------
  // If CLEAR_ON_ASYNC_RESET is set, we treat async reset as a clear request.
  // We can do this by OR-ing the reset signal with the clear logic in the synchronizer.
  
  if (CLEAR_ON_ASYNC_RESET) begin
    // Modify the global_clear_req generation to include reset
    // We need to re-synchronize the reset signal to both domains and OR it with clear.
    
    // Synchronizer for src_rst_ni in dst domain
    logic [SYNC_STAGES-1:0] src_rst_synced;
    always_ff @(posedge dst_clk_i or negedge src_rst_ni) begin
      if (!src_rst_ni)
        src_rst_synced <= '1;
      else
        src_rst_synced <= {src_rst_synced[SYNC_STAGES-2:0], src_rst_ni};
    end

    // Synchronizer for dst_rst_ni in src domain
    logic [SYNC_STAGES-1:0] dst_rst_synced;
    always_ff @(posedge src_clk_i or negedge dst_rst_ni) begin
      if (!dst_rst_ni)
        dst_rst_synced <= '1;
      else
        dst_rst_synced <= {dst_rst_synced[SYNC_STAGES-2:0], dst_rst_ni};
    end

    // Re-define global_clear_req to include reset
    // Note: This requires re-writing the synchronizer logic for global_clear_req
    // to include the reset signals.
    
    // Let's refactor the global_clear_req logic to be more modular.
    // We will create a new signal 'global_clear_req_new' that includes reset.
    
    logic [SYNC_STAGES-1:0] global_clear_req_new;
    
    // Synchronizer for (src_clear | src_rst) in dst domain
    logic [SYNC_STAGES-1:0] src_clear_rst_synced;
    always_ff @(posedge dst_clk_i or negedge src_rst_ni) begin
      if (!src_rst_ni)
        src_clear_rst_synced <= '1;
      else
        src_clear_rst_synced <= {src_clear_rst_synced[SYNC_STAGES-2:0], (src_clear_i | src_rst_ni)};
    end

    // Synchronizer for (dst_clear | dst_rst) in src domain
    logic [SYNC_STAGES-1:0] dst_clear_rst_synced;
    always_ff @(posedge src_clk_i or negedge dst_rst_ni) begin
      if (!dst_rst_ni)
        dst_clear_rst_synced <= '1;
      else
        dst_clear_rst_synced <= {dst_clear_rst_synced[SYNC_STAGES-2:0], (dst_clear_i | dst_rst_ni)};
    end

    // Update global_clear_req to use the new synchronized signals
    // We need to update the FIFO state machine and pending logic to use global_clear_req_new
    // But since we can't easily refactor the existing code without breaking the flow,
    // let's just redefine the global_clear_req logic inline or use a new variable.
    
    // Actually, the cleanest way is to replace the previous global_clear_req logic with the new one.
    // Let's do that.
    
    // Re-define global_clear_req as the OR of the two synchronized clear+reset signals
    // But wait, the previous logic used 'global_clear_req' which was derived from src_clear_synced | dst_clear_synced.
    // We need to replace that derivation.
    
    // Let's restart the global_clear_req logic block.
    
    // Synchronizer for src_clear_i in dst domain (already defined as src_clear_synced)
    // Synchronizer for dst_clear_i in src domain (already defined as dst_clear_synced)
    
    // Now, if CLEAR_ON_ASYNC_RESET, we OR the reset signals into the clear logic.
    // We need to re-synchronize the reset signals to the opposite domains.
    
    // Reset Sync in DST domain
    logic [SYNC_STAGES-1:0] src_rst_synced_dst;
    always_ff @(posedge dst_clk_i or negedge src_rst_ni) begin
      if (!src_rst_ni)
        src_rst_synced_dst <= '1;
      else
        src_rst_synced_dst <= {src_rst_synced_dst[SYNC_STAGES-2:0], src_rst_ni};
    end

    // Reset Sync in SRC domain
    logic [SYNC_STAGES-1:0] dst_rst_synced_src;
    always_ff @(posedge src_clk_i or negedge dst_rst_ni) begin
      if (!dst_rst_ni)
        dst_rst_synced_src <= '1;
      else
        dst_rst_synced_src <= {dst_rst_synced_src[SYNC_STAGES-2:0], dst_rst_ni};
    end

    // New Global Clear Request
    logic [SYNC_STAGES-1:0] global_clear_req_final;
    if (CLEAR_ON_ASYNC_RESET) begin
      global_clear_req_final = {global_clear_req_final[SYNC_STAGES-2:0], (src_clear_synced | src_rst_synced_dst | dst_clear_synced | dst_rst_synced_src)};
    end else begin
      global_clear_req_final = {global_clear_req_final[SYNC_STAGES-2:0], (src_clear_synced | dst_clear_synced)};
    end

    // Update FIFO State Machine to use global_clear_req_final
    // We need to replace 'global_clear_req_dst' and 'global_clear_req_src' with 'global_clear_req_final'
    // in the FIFO state machine and pending logic.
    
    // Update FIFO State Machine
    // Replace 'global_clear_req_dst' with 'global_clear_req_final'
    // Replace 'global_clear_req_src' with 'global_clear_req_final'
    
    // Update Pending Logic
    // Replace 'global_clear_req_src' with 'global_clear_req_final'
    // Replace 'global_clear_req_dst' with 'global_clear_req_final'
    
    // Since we cannot edit the previous code blocks directly in this thought process,
    // we will rewrite the entire module with the corrected logic.
    
    // Re-writing the module with the corrected global_clear_req logic.
    
    // Synchronizers for Clear + Reset
    logic [SYNC_STAGES-1:0] src_clear_synced;
    logic [SYNC_STAGES-1:0] dst_clear_synced;
    logic [SYNC_STAGES-1:0] src_rst_synced_dst;
    logic [SYNC_STAGES-1:0] dst_rst_synced_src;

    // Synchronizer for src_clear_i in dst domain
    always_ff @(posedge dst_clk_i or negedge src_rst_ni) begin
      if (!src_rst_ni)
        src_clear_synced <= '0;
      else
        src_clear_synced <= {src_clear_synced[SYNC_STAGES-2:0], src_clear_i};
    end

    // Synchronizer for dst_clear_i in src domain
    always_ff @(posedge src_clk_i or negedge dst_rst_ni) begin
      if (!dst_rst_ni)
        dst_clear_synced <= '0;
      else
        dst_clear_synced <= {dst_clear_synced[SYNC_STAGES-2:0], dst_clear_i};
    end

    // Synchronizer for src_rst_ni in dst domain
    always_ff @(posedge dst_clk_i or negedge src_rst_ni) begin
      if (!src_rst_ni)
        src_rst_synced_dst <= '1;
      else
        src_rst_synced_dst <= {src_rst_synced_dst[SYNC_STAGES-2:0], src_rst_ni};
    end

    // Synchronizer for dst_rst_ni in src domain
    always_ff @(posedge src_clk_i or negedge dst_rst_ni) begin
      if (!dst_rst_ni)
        dst_rst_synced_src <= '1;
      else
        dst_rst_synced_src <= {dst_rst_synced_src[SYNC_STAGES-2:0], dst_rst_ni};
    end

    // Global Clear Request
    logic [SYNC_STAGES-1:0] global_clear_req;
    if (CLEAR_ON_ASYNC_RESET) begin
      global_clear_req = {global_clear_req[SYNC_STAGES-2:0], (src_clear_synced | src_rst_synced_dst | dst_clear_synced | dst_rst_synced_src)};
    end else begin
      global_clear_req = {global_clear_req[SYNC_STAGES-2:0], (src_clear_synced | dst_clear_synced)};
    end

    // FIFO State Machine
    fifo_state_t fifo_state;
    logic [WIDTH-1:0] fifo_data [SYNC_STAGES_CNT-1:0];
    logic fifo_valid [SYNC_STAGES_CNT-1:0];
    logic [SYNC_STAGES-1:0] fifo_write_ptr;
    logic [SYNC_STAGES-1:0] fifo_read_ptr;
    logic fifo_empty;
    logic fifo_full;
    logic fifo_write_en;
    logic fifo_read_en;

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
      if (!dst_rst_ni) begin
        fifo_state <= FIFO_IDLE;
        fifo_write_ptr <= '0;
        fifo_read_ptr <= '0;
        fifo_data <= '0;
        fifo_valid <= '0;
        fifo_empty <= 1'b1;
        fifo_full <= 1'b0;
      end else begin
        fifo_state <= fifo_state_next;
        fifo_write_ptr <= fifo_write_ptr_next;
        fifo_read_ptr <= fifo_read_ptr_next;
        fifo_data <= fifo_data_next;
        fifo_valid <= fifo_valid_next;
        fifo_empty <= fifo_empty_next;
        fifo_full <= fifo_full_next;
      end
    end

    always_comb begin
      fifo_state_next = fifo_state;
      fifo_write_ptr_next = fifo_write_ptr;
      fifo_read_ptr_next = fifo_read_ptr;
      fifo_data_next = fifo_data;
      fifo_valid_next = fifo_valid;
      fifo_empty_next = 1'b1;
      fifo_full_next = 1'b0;
      fifo_write_en = 1'b0;
      fifo_read_en = 1'b0;

      case (fifo_state)
        FIFO_IDLE: begin
          if (global_clear_req) begin
            fifo_state_next = FIFO_CLEARING;
          end else if (fifo_write_en && !fifo_full) begin
            fifo_state_next = FIFO_WRITING;
          end else if (fifo_read_en && !fifo_empty) begin
            fifo_state_next = FIFO_READING;
          end
        end

        FIFO_WRITING: begin
          if (global_clear_req) begin
            fifo_state_next = FIFO_CLEARING;
          end else if (fifo_write_en && !fifo_full) begin
            fifo_data_next[fifo_write_ptr] = {src_valid_reg, src_data_reg};
            fifo_write_ptr_next = fifo_write_ptr + 1;
            if (fifo_write_ptr_next == SYNC_STAGES_CNT) fifo_write_ptr_next = '0;
            fifo_state_next = FIFO_IDLE;
          end
        end

        FIFO_READING: begin
          if (global_clear_req) begin
            fifo_state_next = FIFO_CLEARING;
          end else if (fifo_read_en && !fifo_empty) begin
            fifo_read_ptr_next = fifo_read_ptr + 1;
            if (fifo_read_ptr_next == SYNC_STAGES_CNT) fifo_read_ptr_next = '0;
            fifo_state_next = FIFO_IDLE;
          end
        end

        FIFO_CLEARING: begin
          if (global_clear_req) begin
            // Hold clearing state
          end else begin
            fifo_state_next = FIFO_IDLE;
            fifo_write_ptr_next = '0;
            fifo_read_ptr_next = '0;
            fifo_data_next = '0;
            fifo_valid_next = '0;
            fifo_empty_next = 1'b1;
            fifo_full_next = 1'b0;
          end
        end

        default: begin
          fifo_state_next = FIFO_IDLE;
          fifo_write_ptr_next = '0;
          fifo_read_ptr_next = '0;
          fifo_data_next = '0;
          fifo_valid_next = '0;
          fifo_empty_next = 1'b1;
          fifo_full_next = 1'b0;
        end
      endcase
    end

    always_comb begin
      fifo_empty = (fifo_write_ptr == fifo_read_ptr) && (fifo_state == FIFO_IDLE);
      fifo_full = (fifo_write_ptr == fifo_read_ptr) && (fifo_state != FIFO_IDLE);
    end

    // Source Side Handshake
    src_state_t src_state_curr, src_state_next;
    logic [WIDTH-1:0] src_data_reg;
    logic src_valid_reg;
    logic src_clear_pending_o;

    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
      if (!src_rst_ni) begin
        src_state_curr <= SRC_IDLE;
        src_data_reg   <= '0;
        src_valid_reg  <= 1'b0;
      end else begin
        src_state_curr <= src_state_next;
        src_data_reg   <= src_data_reg;
        src_valid_reg  <= src_valid_reg;
      end
    end

    always_comb begin
      src_state_next = src_state_curr;
      src_ready_o = 1'b0;
      src_clear_pending_o = 1'b0;

      case (src_state_curr)
        SRC_IDLE: begin
          if (src_valid_i) begin
            src_state_next = SRC_CAPTURE;
            src_data_reg   = src_data_i;
            src_valid_reg  = 1'b1;
            src_clear_pending_o = 1'b1;
          end else if (global_clear_req) begin
            src_clear_pending_o = 1'b1;
          end
        end

        SRC_CAPTURE: begin
          src_clear_pending_o = 1'b1;
          if (global_clear_req) begin
            src_state_next = SRC_CLEARING;
          end else if (dst_ready_i) begin
            src_state_next = SRC_IDLE;
            src_valid_reg = 1'b0;
            src_clear_pending_o = 1'b0;
          end
        end

        SRC_CLEARING: begin
          src_clear_pending_o = 1'b1;
          if (global_clear_req) begin
            // Hold state
          end else begin
            src_state_next = SRC_CLEAR_DONE;
          end
        end

        SRC_CLEAR_DONE: begin
          src_clear_pending_o = 1'b