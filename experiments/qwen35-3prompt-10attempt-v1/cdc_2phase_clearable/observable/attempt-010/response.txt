```verilog
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

  // ------------------------------------------------------------------
  // Source Side: Handshake Logic & Clear Request Generation
  // ------------------------------------------------------------------
  logic src_valid_reg;
  logic src_ready_reg;
  logic src_data_reg;
  logic src_clear_req;
  logic src_clear_ack;
  logic src_clear_pending;

  // Internal state for clear request generation
  logic src_clear_pending_int;
  logic src_clear_done;

  // Source Handshake Logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
      src_data_reg  <= 1'b0;
      src_clear_req <= 1'b0;
      src_clear_pending_int <= 1'b0;
      src_clear_done <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_i;
      src_ready_reg <= src_ready_o; // Feedback loop handled by handshake logic below
      src_data_reg  <= src_data_i;
      
      // Clear Request Logic
      // A clear request is generated when the source wants to clear but 
      // cannot yet acknowledge the clear from the destination side.
      // We use a simple state machine approach within the handshake.
      
      if (src_clear_i && src_valid_i && src_ready_i) begin
        // If we have a valid beat and clear is asserted, we want to clear.
        // However, we must ensure we don't generate a new request while one is pending
        // unless the previous one was acknowledged.
        if (!src_clear_req) begin
          src_clear_req <= 1'b1;
        end
      end
      
      // If clear is deasserted and we had a request, we might need to wait for ack
      // But the requirement says: "A clear isolates both ends, then drops the one outstanding beat".
      // This implies the clear signal itself triggers the flush sequence.
      
      // Standard Handshake
      if (src_valid_i && src_ready_i) begin
        src_valid_reg <= 1'b0;
        src_ready_reg <= 1'b1;
        src_data_reg  <= 1'b0;
      end else if (src_valid_i && !src_ready_i) begin
        src_ready_reg <= 1'b0;
      end
    end
  end

  // Output assignments for Source
  assign src_ready_o = src_ready_reg;
  assign src_data_o = src_data_reg; // Note: Interface has src_data_i as input, but usually we output data. 
  // Wait, looking at interface: input src_data_i. This is a point-to-point channel.
  // The source side logic is primarily about Valid/Ready and Clear.
  // The data is passed through.
  
  assign src_clear_pending_o = src_clear_pending_int;

  // ------------------------------------------------------------------
  // Destination Side: Handshake Logic & Clear Acknowledgment
  // ------------------------------------------------------------------
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic dst_data_reg;
  logic dst_clear_ack;
  logic dst_clear_req;
  logic dst_clear_pending;

  // Destination Handshake Logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b1;
      dst_data_reg  <= 1'b0;
      dst_clear_ack <= 1'b0;
      dst_clear_req <= 1'b0;
      dst_clear_pending <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_o; // Feedback
      dst_ready_reg <= dst_ready_i;
      dst_data_reg  <= dst_data_i;  // Wait, interface has dst_data_o as output. 
      // Let's re-read interface carefully.
      // Input: src_data_i, src_valid_i, src_ready_o
      // Output: dst_data_o, dst_valid_o, dst_ready_i
      // So data flows src -> dst.
      
      // Corrected Destination Logic
      if (dst_valid_i && dst_ready_i) begin
        dst_valid_reg <= 1'b0;
        dst_ready_reg <= 1'b1;
        dst_data_reg  <= dst_data_i;
      end else if (dst_valid_i && !dst_ready_i) begin
        dst_ready_reg <= 1'b0;
      end
    end
  end

  // Output assignments for Destination
  assign dst_valid_o = dst_valid_reg;
  assign dst_ready_i = dst_ready_reg; // This is an input in the module port list, which is unusual for a module definition unless it's a specific style.
  // Wait, the prompt says: "input dst_ready_i". 
  // In a module definition, if dst_ready_i is an input, the module cannot drive it.
  // However, standard handshake requires the receiver to drive ready.
  // Let's look at the interface again:
  // input dst_ready_i
  // output dst_valid_o
  // This implies the module is the SOURCE of the handshake from the perspective of the caller?
  // No, "dst" usually means destination.
  // If dst_ready_i is an input, then the module is waiting for the destination to be ready?
  // That contradicts "Move source data to the destination".
  // 
  // Re-evaluating the interface provided in the prompt:
  // input dst_ready_i
  // output dst_valid_o
  // This looks like the module is the SOURCE of the data stream, and 'dst' refers to the destination of the data, 
  // but the ports are named confusingly.
  // 
  // Let's assume the standard naming convention where:
  // src_* are the source of the data (sending side).
  // dst_* are the destination of the data (receiving side).
  // 
  // If the interface is fixed as:
  // input dst_ready_i
  // output dst_valid_o
  // Then the module is driving 'dst_valid' and receiving 'dst_ready'.
  // This means the module is the RECEIVER of the handshake? 
  // No, if it drives valid, it is the sender.
  // If it receives ready, it is the receiver.
  // So the module is the SENDER of data to some external entity called 'dst'?
  // But the parameters say "src_clk_i" and "dst_clk_i".
  // 
  // Hypothesis: The interface provided in the prompt has a typo or non-standard naming where:
  // - src_* ports are the Source side of the channel (Clock Domain A).
  // - dst_* ports are the Destination side of the channel (Clock Domain B).
  // - But the direction of Valid/Ready is flipped in the port list?
  // 
  // Let's look at the prompt again: "input dst_ready_i".
  // If I cannot change the interface, I must implement based on it.
  // If dst_ready_i is an INPUT, then the module cannot drive it.
  // If dst_valid_o is an OUTPUT, the module drives it.
  // This describes a component that asserts Valid and waits for Ready.
  // This is the behavior of a RECEIVER in a handshake pair (it waits for the sender's ready).
  // BUT, the data flow is "Move source data to the destination".
  // If the module is the receiver, where does the data come from? src_data_i.
  // So the module receives data from src, and sends it to dst?
  // If it sends to dst, it should drive dst_valid and receive dst_ready.
  // The interface says: input dst_ready_i, output dst_valid_o.
  // This is exactly the behavior of a SENDER (drives valid, waits for ready).
  // So the module is the SENDER of the data to the 'dst' domain.
  // 
  // Conclusion on Interface Interpretation:
  // The module acts as the bridge.
  // Source Side (src_clk): Receives src_valid_i, src_data_i. Drives src_ready_o.
  // Destination Side (dst_clk): Drives dst_valid_o, dst_data_o. Receives dst_ready_i.
  // 
  // Wait, if it drives dst_valid_o, it is asserting data availability to the dst domain.
  // If it receives dst_ready_i, it is waiting for the dst domain to accept.
  // This is correct for a sender in the dst domain.
  // 
  // However, the prompt says "Move source data to the destination".
  // Usually, the bridge receives from Src and sends to Dst.
  // So:
  // 1. Src Domain: Module receives src_valid, src_data. Module drives src_ready.
  // 2. Dst Domain: Module drives dst_valid, dst_data. Module receives dst_ready.
  // 
  // This matches the interface:
  // src_valid_i (in), src_ready_o (out) -> Module is Receiver in Src Domain.
  // dst_valid_o (out), dst_ready_i (in) -> Module is Sender in Dst Domain.
  // 
  // Okay, the logic is:
  // Src Domain: Wait for src_valid, assert src_ready when data is ready.
  // Dst Domain: Assert dst_valid when data is ready, wait for dst_ready.
  // 
  // Now, let's handle the Clear logic with this understanding.
  // "A clear request should flush the channel... drops the one outstanding beat".
  // "Each clear step reaches the other clock one handshake later."
  
  // Re-implementing the logic with the correct port directions.
  
  // ------------------------------------------------------------------
  // Source Side (Src Domain)
  // Receives: src_valid_i, src_data_i, src_clear_i
  // Drives:   src_ready_o, src_clear_pending_o
  // ------------------------------------------------------------------
  logic src_valid_int;
  logic src_ready_int;
  logic src_data_int;
  logic src_clear_req_int;
  logic src_clear_ack_int;
  logic src_clear_pending_int;
  logic src_clear_done_int;

  // State for Clear Request on Source side
  // We need to track if we have a pending clear request that hasn't been acknowledged.
  // The requirement: "A clear isolates both ends, then drops the one outstanding beat by returning request and acknowledge to zero."
  // This implies a sequence:
  // 1. Clear asserted.
  // 2. Source wants to clear (request).
  // 3. Destination acknowledges clear.
  // 4. Source acknowledges clear.
  // 
  // Since we are in the source domain, we generate the clear request.
  // We need to know if the destination has acknowledged the clear.
  // The destination will send a clear acknowledge back to the source.
  // But wait, the interface doesn't have a clear_ack input on the source side.
  // It only has src_clear_i (input) and src_clear_pending_o (output).
  // 
  // How does the source know the clear is done?
  // "Each clear step reaches the other clock one handshake later."
  // This implies the clear signal itself propagates.
  // But we need a handshake to clear the channel.
  // 
  // Let's re-read: "A clear request should flush the channel... drops the one outstanding beat".
  // "A clear isolates both ends".
  // 
  // Maybe the clear signal is a control signal that triggers a flush sequence internally?
  // If src_clear_i is asserted, the source wants to clear.
  // The source must wait until the destination is also clear.
  // But how does the source know the destination is clear?
  // 
  // Perhaps the "Clear" is a two-phase handshake itself?
  // But the interface only provides src_clear_i (input) and src_clear_pending_o (output).
  // And dst_clear_i (input) and dst_clear_pending_o (output).
  // 
  // This suggests that the clear signal is a "request" from the local side, and the "pending" output indicates to the local caller that the clear is in progress.
  // But how do the two sides synchronize the clear?
  // 
  // Alternative interpretation:
  // The clear signal is a "flush" command.
  // When src_clear_i is high, the source enters a "clearing" state.
  // It stops accepting new data.
  // It waits for the destination to also be clearing.
  // But without a clear_ack input, how does it know?
  // 
  // Maybe the "Clear" is implemented via the Valid/Ready handshake?
  // No, that's for data.
  // 
  // Let's look at the constraint: "Each clear step reaches the other clock one handshake later."
  // This implies a handshake on the clear signal.
  // But the interface doesn't show clear_valid/clear_ready.
  // It shows clear_i (input) and clear_pending_o (output).
  // 
  // Could it be that the clear signal is level-sensitive, but the "pending" output is the handshake response?
  // If src_clear_i is asserted, src_clear_pending_o goes high?
  // And when the destination acknowledges, src_clear_pending_o goes low?
  // But the destination doesn't have a clear_ack output.
  // 
  // Let's reconsider the standard pattern for "Clearable Channel".
  // Often, clear is a separate handshake.
  // If the interface is fixed as provided, we must assume:
  // - src_clear_i: Request to clear from Source side.
  // - dst_clear_i: Request to clear from Destination side.
  // - src_clear_pending_o: Indicates to Source caller that a clear is happening/pending.
  // - dst_clear_pending_o: Indicates to Destination caller that a clear is happening/pending.
  // 
  // How to synchronize?
  // Maybe the clear request is sent via the data channel? No, that's messy.
  // 
  // Is it possible the problem assumes a specific protocol where:
  // 1. Source asserts src_clear_i.
  // 2. Source sets src_clear_pending_o = 1.
  // 3. Destination sees src_clear_pending_o (via CDC) and asserts dst_clear_i?
  // 4. Destination sets dst_clear_pending_o = 1.
  // 5. Source sees dst_clear_pending_o (via CDC) and clears the channel?
  // 
  // This seems plausible. The "pending" signals act as the handshake for the clear.
  // 
  // Let's trace the "drops the one outstanding beat" requirement.
  // If there is a valid beat in flight when clear is requested:
  // 1. Source asserts src_clear_i.
  // 2. Source sets src_clear_pending_o = 1.
  // 3. Destination (after CDC) sees src_clear_pending_o.
  // 4. Destination asserts dst_clear_i.
  // 5. Destination sets dst_clear_pending_o = 1.
  // 6. Source (after CDC) sees dst_clear_pending_o.
  // 7. Source completes the clear (drops the beat).
  // 
  // But wait, the interface has src_clear_i as an INPUT.
  // If the source wants to clear, it asserts src_clear_i.
  // The source also needs to know when the destination has cleared.
  // If the destination asserts dst_clear_i, does the source know?
  // Only if the destination drives a signal back to the source.
  // The only signal going back is dst_clear_pending_o.
  // 
  // So the protocol is:
  // - Source asserts src_clear_i.
  // - Source drives src_clear_pending_o = 1.
  // - Destination (CDC'd) sees src_clear_pending_o.
  // - Destination asserts dst_clear_i.
  // - Destination drives dst_clear_pending_o = 1.
  // - Source (CDC'd) sees dst_clear_pending_o.
  // - Source knows the clear is synchronized.
  // 
  // But what about the "drops the one outstanding beat"?
  // If there is a valid beat, it must be dropped.
  // The drop happens when the clear is fully synchronized.
  // 
  // Also, "A clear isolates both ends".
  // This means no new data can be transferred during the clear.
  // 
  // Implementation Plan:
  // 1. CDC the clear signals (src_clear_pending_o -> dst, dst_clear_pending_o -> src).
  // 2. In Src Domain:
  //    - If src_clear_i is high, set internal clear_req.
  //    - Wait for dst_clear_pending (CDC'd) to go high.
  //    - Once both are high, perform the flush.
  //    - The flush involves:
  //      a. Stop accepting new data.
  //      b. If there is a pending valid beat, do not re-assert valid (or assert then deassert immediately?).
  //      c. The requirement says "drops the one outstanding beat by returning request and acknowledge to zero".
  //         This phrasing is tricky. "returning request and acknowledge to zero".
  //         Maybe it means the clear handshake completes?
  //         Or maybe it means the data transfer is cancelled?
  //         "drops the one outstanding beat" -> The beat is lost.
  //         "returning request and acknowledge to zero" -> The clear signals go back to 0.
  // 
  // 3. In Dst Domain:
  //    - Similar logic.
  //    - If dst_clear_i is high, set internal clear_req.
  //    - Wait for src_clear_pending (CDC'd) to go high.
  //    - Once synchronized, stop accepting data.
  //    - If there is a pending valid beat (from src), do not consume it (or consume and drop?).
  //      "drops the one outstanding beat" -> Usually means the beat is not delivered.
  //      So if src_valid is high and we are clearing, we should not assert dst_valid.
  //      Or if we already asserted dst_valid, we must deassert it?
  //      "drops" implies it never arrives.
  //      So if src_valid is high, and we are clearing, we should NOT assert dst_valid.
  //      But if src_valid was already high and we are clearing, we might have already asserted dst_valid?
  //      The requirement says "drops the one outstanding beat".
  //      This implies the beat is in flight (src_valid=1, dst_ready=1) but not yet consumed?
  //      Or it means the beat is in the pipeline.
  //      If we are clearing, we should not forward the data.
  //      So dst_valid should remain 0.
  // 
  // 4. CDC Implementation:
  //    - Use a simple FIFO or multi-stage synchronizer for the clear_pending signals.
    //    - Since SYNC_STAGES is a parameter, we will use a multi-stage synchronizer.
    //    - We need to CDC src_clear_pending_o to dst domain.
    //    - We need to CDC dst_clear_pending_o to src domain.
    //    - We also need to CDC src_valid_i and src_data_i to dst domain.
    //    - We need to CDC dst_ready_i to src domain.
    //    - We need to CDC src_clear_i to dst domain? 
    //      Actually, the clear request is local. The synchronization is via the pending signals.
    //      But the destination needs to know when the source wants to clear to initiate its part.
    //      So src_clear_pending_o (which is driven by src_clear_i) is the signal to CDC to dst.
    //      Similarly, dst_clear_pending_o is CDC'd to src.
    // 
    // 5. Handling the "Clear" State Machine:
    //    - Normal State: Handshake data.
    //    - Clear Initiated (Src): src_clear_i is high. Set pending. Wait for dst pending.
    //    - Clear Initiated (Dst): dst_clear_i is high. Set pending. Wait for src pending.
    //    - Clear Complete: Both pending are high. Flush data. Reset state.
    // 
    //    What if both assert clear at the same time?
    //    They will see each other's pending and complete.
    // 
    //    What if one asserts clear, then the other asserts clear later?
    //    The first one waits for the second.
    // 
    //    Data Drop Logic:
    //    - If in Clear Complete state, ignore src_valid_i.
    //    - If in Clear Complete state, do not assert dst_valid_o even if src_valid_i is high.
    //    - If in Clear Complete state, do not assert dst_valid_o even if dst_ready_i is high.
    //    - Once clear is done, return to normal.
    // 
    //    Wait, "drops the one outstanding beat".
    //    If there is a beat in flight (src_valid=1, dst_ready=1) when clear starts:
    //    - Src asserts src_clear_i.
    //    - Src sets src_clear_pending_o = 1.
    //    - Dst sees src_clear_pending_o.
    //    - Dst asserts dst_clear_i.
    //    - Dst sets dst_clear_pending_o = 1.
    //    - Src sees dst_clear_pending_o.
    //    - Src knows clear is synchronized.
    //    - At this point, if src_valid was 1, and dst_ready was 1, the handshake hasn't completed yet?
    //      Or has it?
    //      If src_valid=1 and dst_ready=1, the handshake completes immediately.
    //      But we want to DROP it.
    //      So we must prevent the handshake from completing.
    //      How?
    //      If src_valid=1, and we are in "Clear Sync" state, we should NOT assert src_ready_o?
    //      No, src_ready_o is driven by the handshake logic.
    //      If src_valid=1, and we want to drop it, we should assert src_ready_o=0?
    //      But src_ready_o is an output. If we assert it, the handshake completes.
    //      So we must NOT assert src_ready_o if we are clearing.
    //      But if src_valid=1 and dst_ready=1, the handshake logic naturally wants to complete.
    //      We need to override this.
    // 
    //    Revised Data Drop Logic:
    //    - If Clear is synchronized (both pending high):
    //      - Ignore src_valid_i.
    //      - Force src_ready_o = 0 (to prevent handshake completion).
    //      - Force dst_valid_o = 0 (to prevent data delivery).
    //      - Wait until clear is done (both pending go low).
    //      - Then resume normal operation.
    // 
    //    But wait, if src_valid=1 and dst_ready=1, and we force src_ready_o=0, the handshake is stuck?
    //    Yes, until we reset.
    //    So the sequence is:
    //    1. Clear asserted.
    //    2. Both sides sync.
    //    3. Both sides stop handshake (force ready/valid low).
    //    4. The outstanding beat is dropped (never consumed).
    //    5. Clear signals go low.
    //    6. Resume handshake.
    // 
    //    This matches "drops the one outstanding beat".
    // 
    //    One detail: "Each clear step reaches the other clock one handshake later."
    //    This refers to the CDC delay of the clear_pending signal.
    //    So the synchronization takes a few cycles.
    // 
    //    Implementation Details:
    //    - Use a parameterized synchronizer for the clear_pending signals crossing domains.
    //    - State machine in each domain to track clear status.
    //    - Override Valid/Ready during clear sync.
  
  // ------------------------------------------------------------------
  // CDC Synchronizers
  // ------------------------------------------------------------------
  // Synchronize src_clear_pending_o to dst domain
  logic [SYNC_STAGES-1:0] src_clear_pending_synced;
  logic src_clear_pending_dst;
  
  // Synchronize dst_clear_pending_o to src domain
  logic [SYNC_STAGES-1:0] dst_clear_pending_synced;
  logic dst_clear_pending_src;
  
  // Synchronize src_valid_i to dst domain
  logic [SYNC_STAGES-1:0] src_valid_synced;
  logic src_valid_dst;
  
  // Synchronize src_data_i to dst domain
  logic [WIDTH-1:0] src_data_synced;
  logic [SYNC_STAGES-1:0] src_data_synced_stages;
  logic src_data_dst;
  
  // Synchronize dst_ready_i to src domain
  logic [SYNC_STAGES-1:0] dst_ready_synced;
  logic dst_ready_src;
  
  // ------------------------------------------------------------------
  // Synchronizer Logic
  // ------------------------------------------------------------------
  // Synchronizer for src_clear_pending_o -> dst
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_clear_pending_synced <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_pending_synced <= {src_clear_pending_synced[SYNC_STAGES-2:0], src_clear_pending_o};
    end
  end
  assign src_clear_pending_dst = src_clear_pending_synced[SYNC_STAGES-1];

  // Synchronizer for dst_clear_pending_o -> src
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_pending_synced <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_pending_synced <= {dst_clear_pending_synced[SYNC_STAGES-2:0], dst_clear_pending_o};
    end
  end
  assign dst_clear_pending_src = dst_clear_pending_synced[SYNC_STAGES-1];

  // Synchronizer for src_valid_i -> dst
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_synced <= {SYNC_STAGES{1'b0}};
    end else begin
      src_valid_synced <= {src_valid_synced[SYNC_STAGES-2:0], src_valid_i};
    end
  end
  assign src_valid_dst = src_valid_synced[SYNC_STAGES-1];

  // Synchronizer for src_data_i -> dst
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_synced_stages <= {SYNC_STAGES{1'b0}};
      src_data_synced <= {WIDTH{1'b0}};
    end else begin
      src_data_synced_stages <= {src_data_synced_stages[SYNC_STAGES-2:0], src_valid_i};
      if (src_valid_synced[SYNC_STAGES-2]) begin
        src_data_synced <= src_data_i;
      end else begin
        src_data_synced <= {WIDTH{1'b0}};
      end
    end
  end
  // Note: The above data synchronizer is slightly complex. 
  // Standard approach: Synchronize valid, then latch data on the last stage of valid.
  // Let's refine the data synchronizer.
  
  // Refined Data Synchronizer
  logic [SYNC_STAGES-1:0] src_valid_synced_data;
  logic src_valid_dst_data;
  
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_synced_data <= {SYNC_STAGES{1'b0}};
    end else begin
      src_valid_synced_data <= {src_valid_synced_data[SYNC_STAGES-2:0], src_valid_i};
    end
  end
  assign src_valid_dst_data = src_valid_synced_data[SYNC_STAGES-1];
  
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_synced <= {WIDTH{1'b0}};
    end else begin
      if (src_valid_synced_data[SYNC_STAGES-2]) begin
        src_data_synced <= src_data_i;
      end else begin
        src_data_synced <= {WIDTH{1'b0}};
      end
    end
  end

  // Synchronizer for dst_ready_i -> src
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_synced <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_ready_synced <= {dst_ready_synced[SYNC_STAGES-2:0], dst_ready_i};
    end
  end
  assign dst_ready_src = dst_ready_synced[SYNC_STAGES-1];

  // ------------------------------------------------------------------
  // Source Side Logic
  // ------------------------------------------------------------------
  logic src_clear_req;
  logic src_clear_synced;
  logic src_clear_done;
  
  // Clear Request Generation
  // If src_clear_i is high, we want to clear.
  // But we must ensure we don't generate a new request while one is pending.
  // We use a flag to track if we are in the middle of a clear.
  logic src_clear_in_progress;
  
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_req <= 1'b0;
      src_clear_in_progress <= 1'b0;
      src_clear_synced <= 1'b0;
      src_clear_done <= 1'b0;
    end else begin
      // If clear is asserted and we are not already in progress, request it.
      if (src_clear_i && !src_clear_in_progress) begin
        src_clear_req <= 1'b1;
        src_clear_in_progress <= 1'b1;
      end else if (!src_clear_i) begin
        // If clear is deasserted, we might still be waiting for sync.
        // We only exit progress when sync is done.
        if (src_clear_synced) begin
          src_clear_in_progress <= 1'b0;
          src_clear_req <= 1'b0;
        end
      end
      
      // Sync logic: If we requested clear, wait for dst_clear_pending_src.
      if (src_clear_req && !dst_clear_pending_src) begin
        // Waiting for dst to see our request.
      end else if (src_clear_req && dst_clear_pending_src) begin
        // Dst has seen our request. Now wait for dst to request clear.
        // We need to wait for dst_clear_req to be asserted in dst domain.
        // But we only have dst_clear_pending_o.
        // The dst domain will assert dst_clear_pending_o when it sees src_clear_pending.
        // So if dst_clear_pending_src is high, it means dst has seen our request.
        // Now we wait for dst to complete its clear request.
        // How do we know dst has requested clear?
        // We don't have a direct signal.
        // But the protocol is:
        // 1. Src asserts src_clear_i -> src_clear_pending_o = 1.
        // 2. Dst sees src_clear_pending_o -> asserts dst_clear_i -> dst_clear_pending_o = 1.
        // 3. Src sees dst_clear_pending_o -> Clear is synchronized.
        // 
        // So if dst_clear_pending_src is high, it means Dst has seen Src's request.
        // Does it mean Dst has asserted dst_clear_i?
        // Yes, because Dst only sets dst_clear_pending_o when it asserts dst_clear_i.
        // So if dst_clear_pending_src is high, Dst is in the process of clearing.
        // 
        // So the condition for "Clear Synchronized" is:
        // src_clear_req AND dst_clear_pending_src.
        // 
        // But wait, what if Dst asserts dst_clear_i independently?
        // Then Dst sets dst_clear_pending_o.
        // Src sees it.
        // But Src hasn't asserted src_clear_i yet.
        // In this case, Src should also assert src_clear_i?
        // The requirement says "A clear request should flush...".
        // If Dst requests clear, Src should join.
        // So if dst_clear_pending_src is high, Src should assert src_clear_req?
        // But Src might not have seen src_clear_i.
        // 
        // Let's assume the clear is initiated by one side, and the other side joins.
        // If Src initiates: Src sets pending. Dst sees it, sets pending. Src sees Dst pending -> Done.
        // If Dst initiates: Dst sets pending. Src sees it, sets pending. Dst sees Src pending -> Done.
        // 
        // So the logic is:
        // If (src_clear_i OR dst_clear_pending_src) AND (dst_clear_pending_dst OR src_clear_i) ... this is getting complex.
        // 
        // Simpler approach:
        // We want to enter "Clear Mode" if either side requests it.
        // Once in Clear Mode, we wait for the other side to confirm.
        // 
        // Let's define a state:
        // IDLE
        // WAITING_FOR_DST (Src requested, waiting for Dst to see)
        // WAITING_FOR_SRC (Dst requested, waiting for Src to see)
        // SYNCING (Both requested, waiting for sync completion)
        // 
        // Actually, the "pending" signals are the handshake.
        // 
        // Logic:
        // 1. If src_clear_i is high, set src_clear_req = 1.
        // 2. If dst_clear_pending_src is high, it means Dst has seen Src's request (or Dst requested independently).
        //    If Dst requested independently, Dst set dst_clear_pending_o.
        //    Src sees it. Src should also request clear.
        // 
        // Let's simplify:
        // We enter clear mode if:
        // (src_clear_i) OR (dst_clear_pending_src)
        // But we must ensure we don't toggle back and forth.
        // 
        // Proposed Logic:
        // If (src_clear_i || dst_clear_pending_src) and !src_clear_in_progress:
        //    src_clear_req = 1;
        //    src_clear_in_progress = 1;
        // 
        // If src_clear_req is 1:
        //    If dst_clear_pending_src is 1:
        //       // Dst has seen our request (or requested independently).
        //       // We are synchronized.
        //       src_clear_synced = 1;
        //       src_clear_done = 1; // Mark as done so we can exit
        //    Else:
        //       // Waiting for Dst.
        //       src_clear_synced = 0;
        // 
        // If src_clear_synced is 1:
        //    // Perform flush.
        //    // Stop handshake.
        //    // Wait for clear to be done.
        //    // How do we know clear is done?
        //    // When both pending signals go low.
        //    // But we need to wait for the other