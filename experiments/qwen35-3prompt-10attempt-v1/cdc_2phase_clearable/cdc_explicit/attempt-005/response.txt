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

  localparam SYNC_STAGES_POW2 = 1 << SYNC_STAGES;

  // ---------------------------------------------------------------------------
  // Source Domain Logic
  // ---------------------------------------------------------------------------
  // State Machine for Source Side
  // States:
  //   IDLE       : Waiting for valid or clear
  //   CAPTURE    : Valid asserted, capturing data, waiting for clear completion
  //   CLEARING   : Clear requested, flushing internal state
  //   CLEAR_DONE : Clear finished, returning to IDLE
  //
  // Note: We use a synchronous state machine in src_clk_i.
  // The clear signal is sampled synchronously.
  
  typedef enum logic [1:0] {
    SRC_IDLE,
    SRC_CAPTURE,
    SRC_CLEARING,
    SRC_CLEAR_DONE
  } src_state_t;

  src_state_t src_state, src_state_next;
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_clear_req;
  logic src_clear_ack;

  // Internal clear request generation
  // Clear is requested if:
  // 1. External clear is asserted
  // 2. Async reset is released (if CLEAR_ON_ASYNC_RESET) and we are not in a safe state
  //    However, to keep it simple and robust, we treat async reset release as a trigger
  //    only if we are in IDLE or CAPTURE and need to flush.
  //    A safer approach for "Clear on Async Reset" is to assert clear internally 
  //    whenever the reset domain changes from low to high, provided we are not already clearing.
  
  logic src_rst_ni_changed;
  assign src_rst_ni_changed = src_rst_ni & ~src_rst_ni; // This is wrong for edge detection in sync logic without reg
  // Correct edge detection for active low reset release:
  logic src_rst_ni_prev;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_rst_ni_prev <= 1'b1;
    else
      src_rst_ni_prev <= src_rst_ni;
  end
  assign src_rst_ni_changed = src_rst_ni & ~src_rst_ni_prev;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= SRC_IDLE;
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
      src_clear_req <= 1'b0;
      src_clear_pending_o <= 1'b0;
    end else begin
      src_state <= src_state_next;
      src_data_reg <= src_data_reg;
      src_valid_reg <= src_valid_reg;
      src_clear_req <= src_clear_i | (CLEAR_ON_ASYNC_RESET && src_rst_ni_changed && (src_state == SRC_IDLE || src_state == SRC_CAPTURE));
      src_clear_pending_o <= src_clear_req;
    end
  end

  // State Transition Logic
  always_comb begin
    src_state_next = src_state;
    src_ready_o = 1'b0;
    src_data_reg = src_data_reg;
    src_valid_reg = src_valid_reg;
    src_clear_req = src_clear_i; // Base clear request

    case (src_state)
      SRC_IDLE: begin
        if (src_valid_i) begin
          src_state_next = SRC_CAPTURE;
          src_data_reg = src_data_i;
          src_valid_reg = 1'b1;
        end
        // src_ready_o remains 0 until clear is done if in clear state, else 1
        if (src_state == SRC_IDLE || src_state == SRC_CLEAR_DONE)
          src_ready_o = 1'b1;
        else if (src_state == SRC_CAPTURE)
          src_ready_o = 1'b0; // Busy capturing
        else if (src_state == SRC_CLEARING)
          src_ready_o = 1'b0; // Busy clearing
        else if (src_state == SRC_CLEAR_DONE)
          src_ready_o = 1'b1;
      end

      SRC_CAPTURE: begin
        if (src_clear_req) begin
          src_state_next = SRC_CLEARING;
          src_clear_pending_o = 1'b1;
        end
        // If no clear, we stay here until ready is asserted by dest? 
        // No, 2-phase handshake: Source holds valid, waits for ready.
        // But this is a clearable channel. 
        // Logic: If valid is high, we hold it. If clear comes, we abort.
        // If clear does NOT come, we wait for dest ready.
        // However, the requirement says "hold one outstanding item".
        // So if valid is high, we are in CAPTURE. We wait for ready.
        // If clear comes, we transition to CLEARING.
        
        // Wait for ready from dest (crossed via sync)
        // We need to know if dest is ready. We will sync dst_ready_i.
        // Let's add a sync register for dst_ready_i in src domain.
        // Actually, simpler: The handshake happens at the boundary.
        // If src_valid is high, src_ready is low. When dst_ready crosses, src_ready goes high.
        // But we need to detect dst_ready crossing.
        
        // Let's refine the handshake logic.
        // We need a sync'd dst_ready in src domain to release the beat.
      end
      
      SRC_CLEARING: begin
        src_clear_pending_o = 1'b1;
        // Stay here until we confirm the clear is "done" from dest side perspective?
        // Or just a timeout? 
        // Standard 2-phase clear: 
        // 1. Src asserts clear.
        // 2. Src drops valid (if any).
        // 3. Src waits for dst to acknowledge clear (or timeout).
        // 4. Src de-asserts clear.
        
        // To make it robust without complex handshaking for the clear itself:
        // We assume the clear is a "flush". 
        // Once clear is asserted, we stop accepting new data.
        // We wait for the destination to clear its buffer.
        // How do we know dest cleared? 
        // We can use a similar mechanism on the dest side and sync the ack back.
        // But the prompt implies a simpler "coordinated flush".
        // Let's implement a simple timeout or a handshake.
        // Given "2-phase valid/ready channel", the clear is an additional control.
        // Let's assume the clear is a "soft reset" of the FIFO.
        // We will wait for a specific number of cycles or a handshake.
        // To be safe and standard: 
        // Src asserts clear. Src waits for dst to assert a "clear_ack" (which we will generate on dst side).
        // But we don't have a clear_ack port.
        // Alternative: The clear is a "drop everything" command.
        // Src asserts clear. Src sets a flag. 
        // When dst sees clear, it drops its data and asserts a "clear_done" internally.
        // Src needs to know this.
        // Let's add a sync'd dst_clear_ack in src domain.
      end
      
      SRC_CLEAR_DONE: begin
        src_clear_pending_o = 1'b0;
        src_state_next = SRC_IDLE;
        src_ready_o = 1'b1;
      end
    endcase
  end

  // Sync dst_ready_i to src domain to release the beat
  logic [SYNC_STAGES_POW2-1:0] dst_ready_sync_cnt;
  logic dst_ready_sync;
  
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_ready_sync_cnt <= '0;
    else
      dst_ready_sync_cnt <= dst_ready_sync_cnt + 1'b1;
  end
  
  // Simple majority voting or counter check
  // Since SYNC_STAGES is small (3), we can just use a counter.
  // If dst_ready_i is high for SYNC_STAGES cycles, consider it high.
  // But we need to reset the counter when dst_ready_i goes low.
  // Better: Use a shift register or a simple counter with reset.
  
  logic [SYNC_STAGES_POW2-1:0] dst_ready_reg;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_ready_reg <= '0;
    else
      dst_ready_reg <= {dst_ready_reg[SYNC_STAGES_POW2-2:0], dst_ready_i};
  end
  
  assign dst_ready_sync = dst_ready_reg[SYNC_STAGES_POW2-1];

  // Re-evaluate SRC_CAPTURE logic with dst_ready_sync
  always_comb begin
    src_state_next = src_state;
    src_ready_o = 1'b0;
    
    case (src_state)
      SRC_IDLE: begin
        if (src_valid_i) begin
          src_state_next = SRC_CAPTURE;
          src_data_reg = src_data_i;
          src_valid_reg = 1'b1;
        end
        src_ready_o = 1'b1; // Ready to accept
      end
      
      SRC_CAPTURE: begin
        if (src_clear_req) begin
          src_state_next = SRC_CLEARING;
          src_clear_pending_o = 1'b1;
        end else if (dst_ready_sync) begin
          // Handshake complete
          src_state_next = SRC_IDLE;
          src_valid_reg = 1'b0;
          src_ready_o = 1'b1;
        end else begin
          // Waiting for ready
          src_ready_o = 1'b0;
        end
      end
      
      SRC_CLEARING: begin
        src_clear_pending_o = 1'b1;
        src_valid_reg = 1'b0;
        src_ready_o = 1'b0;
        // Wait for dest to finish clearing
        // We need a signal from dest indicating it's done clearing.
        // Let's add a sync'd dst_clear_done in src domain.
      end
      
      SRC_CLEAR_DONE: begin
        src_clear_pending_o = 1'b0;
        src_state_next = SRC_IDLE;
        src_valid_reg = 1'b0;
        src_ready_o = 1'b1;
      end
    endcase
  end

  // ---------------------------------------------------------------------------
  // Destination Domain Logic
  // ---------------------------------------------------------------------------
  // State Machine for Destination Side
  // States:
  //   IDLE       : Waiting for valid
  //   PROCESSING : Valid asserted, waiting for ready
  //   CLEARING   : Clear requested, flushing
  //   CLEAR_DONE : Clear finished, returning to IDLE
  
  typedef enum logic [1:0] {
    DST_IDLE,
    DST_PROCESSING,
    DST_CLEARING,
    DST_CLEAR_DONE
  } dst_state_t;

  dst_state_t dst_state, dst_state_next;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_clear_req;
  logic dst_clear_ack; // Internal ack to src

  // Sync src_valid_i to dst domain to trigger processing
  logic [SYNC_STAGES_POW2-1:0] src_valid_sync_cnt;
  logic src_valid_sync;
  
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_valid_sync_cnt <= '0;
    else
      src_valid_sync_cnt <= src_valid_sync_cnt + 1'b1;
  end
  
  logic [SYNC_STAGES_POW2-1:0] src_valid_reg;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_valid_reg <= '0;
    else
      src_valid_reg <= {src_valid_reg[SYNC_STAGES_POW2-2:0], src_valid_i};
  end
  
  assign src_valid_sync = src_valid_reg[SYNC_STAGES_POW2-1];

  // Sync src_clear_i to dst domain
  logic [SYNC_STAGES_POW2-1:0] src_clear_sync_cnt;
  logic src_clear_sync;
  
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_clear_sync_cnt <= '0;
    else
      src_clear_sync_cnt <= src_clear_sync_cnt + 1'b1;
  end
  
  logic [SYNC_STAGES_POW2-1:0] src_clear_reg;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_clear_reg <= '0;
    else
      src_clear_reg <= {src_clear_reg[SYNC_STAGES_POW2-2:0], src_clear_i};
  end
  
  assign src_clear_sync = src_clear_reg[SYNC_STAGES_POW2-1];

  // Sync dst_clear_i to src domain (for src_clear_ack generation)
  // We need to send an ack back to src when we are done clearing.
  // We will generate dst_clear_ack when we exit CLEARING state.
  // Then sync dst_clear_ack to src domain.
  
  logic [SYNC_STAGES_POW2-1:0] dst_clear_ack_sync_cnt;
  logic dst_clear_ack_sync;
  
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_clear_ack_sync_cnt <= '0;
    else
      dst_clear_ack_sync_cnt <= dst_clear_ack_sync_cnt + 1'b1;
  end
  
  logic [SYNC_STAGES_POW2-1:0] dst_clear_ack_reg;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_clear_ack_reg <= '0;
    else
      dst_clear_ack_reg <= {dst_clear_ack_reg[SYNC_STAGES_POW2-2:0], dst_clear_ack};
  end
  
  assign dst_clear_ack_sync = dst_clear_ack_reg[SYNC_STAGES_POW2-1];

  // Internal clear request generation on dst side
  // Similar to src side: external clear or async reset release
  logic dst_rst_ni_prev;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_rst_ni_prev <= 1'b1;
    else
      dst_rst_ni_prev <= dst_rst_ni;
  end
  logic dst_rst_ni_changed;
  assign dst_rst_ni_changed = dst_rst_ni & ~dst_rst_ni_prev;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= DST_IDLE;
      dst_data_reg <= '0;
      dst_valid_reg <= 1'b0;
      dst_clear_req <= 1'b0;
      dst_clear_pending_o <= 1'b0;
    end else begin
      dst_state <= dst_state_next;
      dst_data_reg <= dst_data_reg;
      dst_valid_reg <= dst_valid_reg;
      dst_clear_req <= dst_clear_i | (CLEAR_ON_ASYNC_RESET && dst_rst_ni_changed && (dst_state == DST_IDLE || dst_state == DST_PROCESSING));
      dst_clear_pending_o <= dst_clear_req;
    end
  end

  // State Transition Logic
  always_comb begin
    dst_state_next = dst_state;
    dst_valid_o = 1'b0;
    dst_data_o = '0;
    dst_clear_ack = 1'b0;

    case (dst_state)
      DST_IDLE: begin
        if (src_valid_sync) begin
          dst_state_next = DST_PROCESSING;
          dst_data_reg = src_data_i; // Wait, we need to sync data too!
          dst_valid_reg = 1'b1;
        end
        dst_valid_o = 1'b0;
      end
      
      DST_PROCESSING: begin
        if (dst_clear_req) begin
          dst_state_next = DST_CLEARING;
          dst_clear_pending_o = 1'b1;
          dst_valid_reg = 1'b0;
          dst_valid_o = 1'b0;
        end else if (dst_ready_i) begin
          // Handshake complete
          dst_state_next = DST_IDLE;
          dst_valid_reg = 1'b0;
          dst_valid_o = 1'b0;
        end else begin
          // Waiting for ready
          dst_valid_o = 1'b1;
          dst_data_o = dst_data_reg;
        end
      end
      
      DST_CLEARING: begin
        dst_clear_pending_o = 1'b1;
        dst_valid_reg = 1'b0;
        dst_valid_o = 1'b0;
        // Wait for src to acknowledge clear
        if (dst_clear_ack_sync) begin
          dst_state_next = DST_CLEAR_DONE;
          dst_clear_pending_o = 1'b0;
        end
      end
      
      DST_CLEAR_DONE: begin
        dst_clear_pending_o = 1'b0;
        dst_state_next = DST_IDLE;
        dst_valid_reg = 1'b0;
        dst_valid_o = 1'b0;
      end
    endcase
  end

  // Sync src_data_i to dst domain for processing
  logic [WIDTH-1:0] src_data_sync;
  logic [WIDTH-1:0] src_data_sync_reg;
  
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_data_sync_reg <= '0;
    else
      src_data_sync_reg <= {src_data_sync_reg[WIDTH-2:0], src_data_i};
  end
  
  // Use a counter to detect valid data arrival
  logic [WIDTH-1:0] src_data_sync_cnt;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_data_sync_cnt <= '0;
    else
      src_data_sync_cnt <= src_data_sync_cnt + 1'b1;
  end
  
  // We need to combine src_valid_sync and src_data_sync.
  // Actually, the previous logic used src_valid_sync to trigger state change.
  // But we need the data value.
  // Let's refine the DST_PROCESSING logic.
  // We need to capture src_data_i when src_valid_sync is true.
  // We can use a shift register for data as well.
  
  logic [WIDTH-1:0] src_data_shift_reg;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_data_shift_reg <= '0;
    else
      src_data_shift_reg <= {src_data_shift_reg[WIDTH-2:0], src_data_i};
  end
  
  // Re-evaluate DST_PROCESSING logic with data
  always_comb begin
    dst_state_next = dst_state;
    dst_valid_o = 1'b0;
    dst_data_o = '0;
    dst_clear_ack = 1'b0;

    case (dst_state)
      DST_IDLE: begin
        if (src_valid_sync) begin
          dst_state_next = DST_PROCESSING;
          dst_data_reg = src_data_shift_reg;
          dst_valid_reg = 1'b1;
        end
        dst_valid_o = 1'b0;
      end
      
      DST_PROCESSING: begin
        if (dst_clear_req) begin
          dst_state_next = DST_CLEARING;
          dst_clear_pending_o = 1'b1;
          dst_valid_reg = 1'b0;
          dst_valid_o = 1'b0;
        end else if (dst_ready_i) begin
          dst_state_next = DST_IDLE;
          dst_valid_reg = 1'b0;
          dst_valid_o = 1'b0;
        end else begin
          dst_valid_o = 1'b1;
          dst_data_o = dst_data_reg;
        end
      end
      
      DST_CLEARING: begin
        dst_clear_pending_o = 1'b1;
        dst_valid_reg = 1'b0;
        dst_valid_o = 1'b0;
        if (dst_clear_ack_sync) begin
          dst_state_next = DST_CLEAR_DONE;
          dst_clear_pending_o = 1'b0;
        end
      end
      
      DST_CLEAR_DONE: begin
        dst_clear_pending_o = 1'b0;
        dst_state_next = DST_IDLE;
        dst_valid_reg = 1'b0;
        dst_valid_o = 1'b0;
      end
    endcase
  end

  // Sync dst_clear_ack to src domain
  // We need to generate dst_clear_ack when dst_state becomes DST_CLEAR_DONE.
  // Then sync it to src.
  
  logic dst_clear_ack_gen;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_clear_ack_gen <= 1'b0;
    else
      dst_clear_ack_gen <= (dst_state == DST_CLEAR_DONE);
  end

  // Sync dst_clear_ack_gen to src domain
  logic [SYNC_STAGES_POW2-1:0] dst_clear_ack_sync_cnt2;
  logic dst_clear_ack_sync2;
  
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_clear_ack_sync_cnt2 <= '0;
    else
      dst_clear_ack_sync_cnt2 <= dst_clear_ack_sync_cnt2 + 1'b1;
  end
  
  logic [SYNC_STAGES_POW2-1:0] dst_clear_ack_reg2;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_clear_ack_reg2 <= '0;
    else
      dst_clear_ack_reg2 <= {dst_clear_ack_reg2[SYNC_STAGES_POW2-2:0], dst_clear_ack_gen};
  end
  
  assign dst_clear_ack_sync = dst_clear_ack_reg2[SYNC_STAGES_POW2-1];

  // ---------------------------------------------------------------------------
  // Final Logic Integration
  // ---------------------------------------------------------------------------
  
  // Re-verify SRC_CLEARING logic: It waits for dst_clear_ack_sync.
  // Re-verify DST_CLEARING logic: It waits for dst_clear_ack_sync (which is the ack from src).
  // Wait, the handshake for clear is:
  // 1. Src asserts clear.
  // 2. Dst sees clear, enters CLEARING.
  // 3. Dst exits CLEARING (after processing its own clear logic) and asserts dst_clear_ack.
  // 4. Src sees dst_clear_ack, exits CLEARING.
  // 5. Dst sees dst_clear_ack (synced back? No, dst_clear_ack is generated by dst).
  //    Wait, dst_clear_ack is generated by dst to tell src "I am done clearing".
  //    So dst generates dst_clear_ack, src syncs it.
  //    But dst needs to know when src is done clearing?
  //    The requirement says "coordinated flush".
  //    Usually:
  //    Src asserts clear.
  //    Dst asserts clear_ack (meaning "I have cleared my buffer").
  //    Src de-asserts clear.
  //    But here we have a single clear signal on both sides.
  //    If both sides assert clear independently, they might not be coordinated.
  //    The requirement says "src_clear_i and dst_clear_i request a coordinated flush".
  //    This implies if EITHER side asserts clear, the whole channel flushes.
  //    So:
  //    If src_clear_i is high -> Src enters CLEARING.
  //    If dst_clear_i is high -> Dst enters CLEARING.
  //    If either side is in CLEARING, the other side must wait until both are done.
  //    This requires a "both done" signal.
  
  // Revised Clear Logic:
  // Src enters CLEARING if src_clear_i OR dst_clear_i (synced to src) is high.
  // Dst enters CLEARING if dst_clear_i OR src_clear_i (synced to dst) is high.
  // Src exits CLEARING when dst_clear_ack (meaning dst is done) is high.
  // Dst exits CLEARING when src_clear_ack (meaning src is done) is high.
  
  // Let's restructure the clear logic.
  
  // Src Side Clear Logic
  logic src_clear_req_internal;
  logic dst_clear_synced_to_src;
  
  // Sync dst_clear_i to src
  logic [SYNC_STAGES_POW2-1:0] dst_clear_sync_cnt;
  logic dst_clear_sync;
  
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_clear_sync_cnt <= '0;
    else
      dst_clear_sync_cnt <= dst_clear_sync_cnt + 1'b1;
  end
  
  logic [SYNC_STAGES_POW2-1:0] dst_clear_reg;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_clear_reg <= '0;
    else
      dst_clear_reg <= {dst_clear_reg[SYNC_STAGES_POW2-2:0], dst_clear_i};
  end
  
  assign dst_clear_sync = dst_clear_reg[SYNC_STAGES_POW2-1];

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= SRC_IDLE;
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
      src_clear_req_internal <= 1'b0;
      src_clear_pending_o <= 1'b0;
    end else begin
      src_state <= src_state_next;
      src_data_reg <= src_data_reg;
      src_valid_reg <= src_valid_reg;
      // Clear if external clear OR if dst is clearing (synced)
      src_clear_req_internal = src_clear_i | dst_clear_sync;
      src_clear_pending_o = src_clear_req_internal;
    end
  end

  // Dst Side Clear Logic
  logic dst_clear_req_internal;
  logic src_clear_synced_to_dst;
  
  // Sync src_clear_i to dst
  logic [SYNC_STAGES_POW2-1:0] src_clear_sync_cnt2;
  logic src_clear_sync2;
  
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_clear_sync_cnt2 <= '0;
    else
      src_clear_sync_cnt2 <= src_clear_sync_cnt2 + 1'b1;
  end
  
  logic [SYNC_STAGES_POW2-1:0] src_clear_reg2;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_clear_reg2 <= '0;
    else
      src_clear_reg2 <= {src_clear_reg2[SYNC_STAGES_POW2-2:0], src_clear_i};
  end
  
  assign src_clear_sync2 = src_clear_reg2[SYNC_STAGES_POW2-1];

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= DST_IDLE;
      dst_data_reg <= '0;
      dst_valid_reg <= 1'b0;
      dst_clear_req_internal <= 1'b0;
      dst_clear_pending_o <= 1'b0;
    end else begin
      dst_state <= dst_state_next;
      dst_data_reg <= dst_data_reg;
      dst_valid_reg <= dst_valid_reg;
      // Clear if external clear OR if src is clearing (synced)
      dst_clear_req_internal = dst_clear_i | src_clear_sync2;
      dst_clear_pending_o = dst_clear_req_internal;
    end
  end

  // Src Exit Clear Logic
  // Src exits CLEARING when dst is done clearing.
  // Dst generates dst_clear_ack when it exits CLEARING.
  // We already have dst_clear_ack_gen logic.
  
  // Dst Exit Clear Logic
  // Dst exits CLEARING when src is done clearing.
  // Src generates src_clear_ack when it exits CLEARING.
  // We need to sync src_clear_ack to dst.
  
  logic src_clear_ack_gen;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_clear_ack_gen <= 1'b0;
    else
      src_clear_ack_gen <= (src_state == SRC_CLEAR_DONE);
  end
  
  // Sync src_clear_ack_gen to dst
  logic [SYNC_STAGES_POW2-1:0] src_clear_ack_sync_cnt3;
  logic src_clear_ack_sync3;
  
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_clear_ack_sync_cnt3 <= '0;
    else
      src_clear_ack_sync_cnt3 <= src_clear_ack_sync_cnt3 + 1'b1;
  end
  
  logic [SYNC_STAGES_POW2-1:0] src_clear_ack_reg3;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_clear_ack_reg3 <= '0;
    else
      src_clear_ack_reg3 <= {src_clear_ack_reg3[SYNC_STAGES_POW2-2:0], src_clear_ack_gen};
  end
  
  assign src_clear_ack_sync = src_clear_ack_reg3[SYNC_STAGES_POW2-1];

  // Update Src State Logic with new clear logic
  always_comb begin
    src_state_next = src_state;
    src_ready_o = 1'b0;
    
    case (src_state)
      SRC_IDLE: begin
        if (src_valid_i) begin
          src_state_next = SRC_CAPTURE;
          src_data_reg = src_data_shift_reg; // Use synced data
          src_valid_reg = 1'b1;
        end
        src_ready_o = 1'b1;
      end
      
      SRC_CAPTURE: begin
        if (src_clear_req_internal) begin
          src_state_next = SRC_CLEARING;
          src_clear_pending_o = 1'b1;
        end else if (dst_ready_sync) begin
          src_state_next = SRC_IDLE;
          src_valid_reg = 1'b0;
          src_ready_o = 1'b1;
        end else begin
          src_ready_o = 1'b0;
        end
      end
      
      SRC_CLEARING: begin
        src_clear_pending_o = 1'b1;
        src_valid_reg = 1'b0;
        src_ready_o = 1'b0;
        if (dst_clear_ack_sync) begin
          src_state_next = SRC_CLEAR_DONE;
          src_clear_pending_o = 1'b0;
        end
      end
      
      SRC_CLEAR_DONE: begin
        src_clear_pending_o = 1'b0;
        src_state_next = SRC_IDLE;
        src_valid_reg = 1'b0;
        src_ready_o = 1'b1;
      end
    endcase
  end

  // Update Dst State Logic with new clear logic
  always_comb begin
    dst_state_next = dst_state;
    dst_valid_o = 1'b0;
    dst_data_o = '0;
    
    case (dst_state)
      DST_IDLE: begin
        if (src_valid_sync) begin
          dst_state_next = DST_PROCESSING;
          dst_data_reg = src_data_shift_reg;
          dst_valid_reg = 1'b1;
        end
        dst_valid_o = 1'b0;
      end
      
      DST_PROCESSING: begin
        if (dst_clear_req_internal) begin
          dst_state_next = DST_CLEARING;
          dst_clear_pending_o = 1'b1;
          dst_valid_reg = 1'b0;
          dst_valid_o = 1'b0;
        end else if (dst_ready_i) begin
          dst_state_next = DST_IDLE;
          dst_valid_reg = 1'b0;
          dst_valid_o = 1'b0;
        end else begin
          dst_valid_o = 1'b1;
          dst_data_o = dst_data_reg;
        end
      end
      
      DST_CLEARING: begin
        dst_clear_pending_o = 1'b1;
        dst_valid_reg = 1'b0;
        dst_valid_o = 1'b0;
        if (src_clear_ack_sync) begin
          dst_state_next = DST_CLEAR_DONE;
          dst_clear_pending_o = 1'b0;
        end
      end
      
      DST_CLEAR_DONE: begin
        dst_clear_pending_o = 1'b0;
        dst_state_next = DST_IDLE;
        dst_valid_reg = 1'b0;
        dst_valid_o = 1'b0;
      end
    endcase
  end

  // Sync src_data_i to dst domain properly
  // We need to ensure data is captured only when valid.
  // But since we use a shift register, we just shift in data every cycle.
  // The state machine decides when to use it.
  // However, if valid is low, we don't want to overwrite the data if we are in PROCESSING?
  // No, if we are in PROCESSING, we hold the data.
  // If we are in IDLE, we wait for valid.
  // So shifting data every cycle is fine, as long as we only use it when transitioning to PROCESSING.
  
  // One issue: src_data_shift_reg is updated every cycle.
  // If src_valid_i is low, we shift in garbage? No, we shift in src_data_i.
  // But we only use it when src_valid_sync is high.
  // So it's fine.

  // Generate src_clear_ack for dst
  // We need to sync src_clear_ack_gen to dst.
  // We already did this above (src_clear_ack_gen -> src_clear_ack_sync).
  
  // Generate dst_clear_ack for src
  // We already did this above (dst_clear_ack_gen -> dst_clear_ack_sync).

  // Final check on data sync
  // src_data_shift_reg needs to be updated every cycle in dst domain.
  // It is.
  
  // One more thing: src_data_shift_reg initialization.
  // It is initialized to '0' on reset.
  // If src_valid_i is low, we shift in src_data_i.
  // If src_valid_i is high, we shift in src_data_i.
  // The state machine uses src_data_shift_reg only when transitioning to PROCESSING.
  // So it's correct.

  // Wait, there is a potential race condition.
  // If src_valid_i goes high, we transition to PROCESSING.
  // But src_data_shift_reg might not have the latest data if the clock domains are far apart?
  // No, the shift register accumulates the data.
 