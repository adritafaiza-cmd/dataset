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
  // Source Side: Data Capture & Handshake Logic
  // ------------------------------------------------------------------
  
  // Synchronizer for clear signal from destination (if needed) or local clear
  // We need to know if a clear is pending on the destination side to stop sending.
  // However, the requirement says "Clear isolates both ends". 
  // Usually, a clearable channel requires the destination to request a clear.
  // Let's assume dst_clear_i is the request to clear the channel.
  // The source needs to know if a clear is requested by the destination.
  
  // Synchronizer for dst_clear_i
  wire [SYNC_STAGES-1:0] dst_clear_sync;
  genvar i;
  generate
    for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_dst_clear
      assign dst_clear_sync[i] = i == 0 ? dst_clear_i : dst_clear_sync[i-1];
    end
  endgenerate
  
  // State for source side
  localparam IDLE = 2'b00;
  localparam WAITING_FOR_READY = 2'b01;
  localparam CLEARING = 2'b10;
  
  reg [1:0] src_state;
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_clear_req_reg; // Local clear request
  
  // Synchronizer for local src_clear_i
  wire [SYNC_STAGES-1:0] src_clear_sync;
  generate
    for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_src_clear
      assign src_clear_sync[i] = i == 0 ? src_clear_i : src_clear_sync[i-1];
    end
  endgenerate
  
  // Logic to detect if a clear is requested by destination
  // We use the synchronized dst_clear signal.
  wire dst_clear_requested = dst_clear_sync[SYNC_STAGES-1];
  
  // State Machine
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= IDLE;
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
      src_clear_req_reg <= 1'b0;
    end else begin
      case (src_state)
        IDLE: begin
          if (src_clear_sync[SYNC_STAGES-1]) begin
            // Destination requested clear
            src_state <= CLEARING;
            src_clear_req_reg <= 1'b1;
          end else if (src_valid_i && dst_ready_i) begin
            // Normal transfer
            src_data_reg <= src_data_i;
            src_valid_reg <= 1'b1;
            src_state <= WAITING_FOR_READY;
          end else begin
            src_state <= IDLE;
          end
        end
        
        WAITING_FOR_READY: begin
          if (dst_ready_i) begin
            src_valid_reg <= 1'b0;
            src_state <= IDLE;
          end else if (src_clear_sync[SYNC_STAGES-1]) begin
            src_state <= CLEARING;
            src_clear_req_reg <= 1'b1;
          end else begin
            // Hold valid until ready
          end
        end
        
        CLEARING: begin
          if (src_clear_sync[SYNC_STAGES-1]) begin
            // Acknowledge clear request to destination
            src_clear_req_reg <= 1'b0;
            src_state <= IDLE;
          end else begin
            // Wait for clear to be acknowledged by destination side logic
            // Actually, the handshake for clear is:
            // 1. Dest requests clear (dst_clear_i high)
            // 2. Src acknowledges clear (src_clear_pending_o high)
            // 3. Dest sees ack, pulls clear low.
            // 4. Src sees clear low, resets state.
            // The "acknowledge" is usually the signal sent back to dest.
            // Here src_clear_pending_o is the output.
            // We need to ensure we don't send data during clear.
            src_valid_reg <= 1'b0;
            src_state <= IDLE;
          end
        end
      endcase
    end
  end
  
  // Outputs
  assign src_ready_o = (src_state == IDLE) || (src_state == WAITING_FOR_READY && dst_ready_i);
  assign src_valid_o = src_valid_reg; // Wait, interface has src_valid_i as input? 
  // Re-reading interface: 
  // input src_valid_i, output src_ready_o
  // This is a standard producer-consumer. 
  // But wait, the interface provided in the prompt is:
  // input src_valid_i, output src_ready_o
  // output src_clear_pending_o
  // There is NO src_valid_o in the interface!
  // Let me re-read the prompt carefully.
  // "input src_valid_i, output src_ready_o"
  // This implies the module is the CONSUMER? 
  // No, "Move source data to the destination". 
  // Usually: Src has valid/ready, Dst has valid/ready.
  // Interface provided:
  // Src side: src_valid_i (input), src_ready_o (output). This looks like a consumer interface for valid?
  // OR is it a typo in my interpretation?
  // Standard AXI-like: Producer outputs valid, consumes ready. Consumer outputs ready, consumes valid.
  // If Src is the producer: It should have src_valid_o and src_ready_i.
  // If Src is the consumer: It should have src_valid_i and src_ready_o.
  // The prompt says: "Move source data to the destination".
  // And the interface lists:
  // input src_valid_i
  // output src_ready_o
  // This strongly suggests the SOURCE is the one RECEIVING data? 
  // No, that contradicts "Move source data".
  // Let's look at the Dst side:
  // output dst_valid_o
  // input dst_ready_i
  // This is the standard PRODUCER interface (outputs valid, consumes ready).
  // So Dst is the producer?
  // But the module name is "cdc_2phase_clearable". Usually we move data FROM Src TO Dst.
  // If Dst is the producer, then data flows Dst -> Src.
  // Let's re-read the interface again.
  // Src side: input src_valid_i, output src_ready_o.
  // Dst side: output dst_valid_o, input dst_ready_i.
  // This configuration means:
  // Src is waiting for data (Consumer).
  // Dst is sending data (Producer).
  // BUT the prompt says "Move source data to the destination".
  // This implies Src -> Dst.
  // If Src -> Dst, then Src should output valid, Dst should output ready.
  // The provided interface is the OPPOSITE of the standard naming convention for "Source to Destination".
  // However, I must follow the provided interface strictly.
  // 
  // Hypothesis 1: The prompt has a typo in the interface description relative to the text.
  // Hypothesis 2: The "Source" and "Destination" names in the interface are swapped relative to the flow direction described.
  // Hypothesis 3: I am misinterpreting the interface.
  // Let's look at the variables again.
  // Src: valid_i, ready_o. (Consumes valid, Produces ready). This is a Consumer.
  // Dst: valid_o, ready_i. (Produces valid, Consumes ready). This is a Producer.
  // Flow: Dst -> Src.
  // Text: "Move source data to the destination".
  // Contradiction.
  // 
  // Let's assume the text description of the flow ("Move source data to the destination") is the ground truth for functionality, 
  // and the interface labels might be confusing or I need to adapt the logic to the interface provided.
  // If I strictly follow the interface:
  // Dst generates data (valid_o). Src consumes data (valid_i).
  // But the prompt says "src_data_i". Src receives data?
  // If Src receives data, it is a consumer.
  // If Dst sends data, it is a producer.
  // So the flow is Dst -> Src.
  // Why does the text say "Move source data to the destination"?
  // Maybe "Source" refers to the origin of the data stream in the system, which is the Dst port in this specific module instantiation?
  // Or maybe the interface provided in the prompt has a mistake in the direction of valid/ready.
  // 
  // Let's reconsider the standard pattern for such questions.
  // Often, users copy-paste interfaces.
  // If I implement Dst->Src, and the user expects Src->Dst, it will be wrong.
  // Let's look at the variable names: src_data_i. Src has data input.
  // dst_data_o. Dst has data output.
  // This confirms: Data enters at Src, leaves at Dst.
  // So Src is the Producer?
  // If Src is the Producer, it should have src_valid_o.
  // But the interface says input src_valid_i.
  // This is a hard contradiction.
  // 
  // Possibility A: The interface is for a channel where Src is the receiver and Dst is the sender.
  //   - Data flows Dst -> Src.
  //   - "src_data_i" is the data coming in.
  //   - "dst_data_o" is the data going out.
  //   - Text "Move source data to the destination" is metaphorical or refers to the system level where Dst is the source and Src is the dest? Unlikely.
  // Possibility B: The interface has a typo. src_valid_i should be src_valid_o.
  // Possibility C: The interface is correct, and the text "Move source data to the destination" implies that the module is placed between two blocks, and the "Source" block is connected to the Dst port? No, that's convoluted.
  // 
  // Let's look at the "Clear" logic requirement: "Clear isolates both ends, then drops the one outstanding beat by returning request and acknowledge to zero."
  // This implies a bidirectional handshake capability or at least a way to signal "I am clearing".
  // 
  // Decision: I will trust the variable names (src_data_i, dst_data_o) as the primary indicator of data flow direction (Src -> Dst).
  // Therefore, Src must be the Producer.
  // If Src is the Producer, the interface MUST be:
  // Src: valid_o, ready_i.
  // Dst: valid_i, ready_o.
  // 
  // BUT the provided interface is:
  // Src: valid_i, ready_o.
  // Dst: valid_o, ready_i.
  // 
  // This is the EXACT reverse of what is needed for Src->Dst flow.
  // If I follow the interface literally, the data flows Dst -> Src.
  // If I follow the text "src_data_i" (input) and "dst_data_o" (output), the data flows Src -> Dst.
  // 
  // Wait, could "src_valid_i" mean "Valid signal from Source"? No, "i" usually means input to the module.
  // If the module is the channel, and data goes Src -> Dst:
  // The module receives valid from Src? No, the module generates valid to Src?
  // In a channel, the sender asserts valid. The receiver asserts ready.
  // If Src is the sender: Module receives src_data_i, src_valid_i? No, the module generates the handshake.
  // Usually, the module encapsulates the sender logic.
  // If the module is the sender: It takes data (src_data_i), asserts valid (src_valid_o), consumes ready (src_ready_i).
  // If the module is the receiver: It takes valid (src_valid_i), takes data (src_data_i), asserts ready (src_ready_o).
  // 
  // The interface provided:
  // Src side: input src_valid_i, output src_ready_o.
  // This describes a RECEIVER on the Src side.
  // Dst side: output dst_valid_o, input dst_ready_i.
  // This describes a PRODUCER on the Dst side.
  // Conclusion: The data flows from Dst to Src.
  // The text "Move source data to the destination" might be using "Source" to mean the Dst port (which holds the data) and "Destination" to mean the Src port?
  // OR, more likely, the user made a mistake in the interface definition in the prompt, swapping valid/ready directions.
  // 
  // However, as an AI, I should follow the interface provided unless it's impossible.
  // Is it impossible? No. I can implement a channel where Dst sends to Src.
  // But the variable names "src_data_i" and "dst_data_o" strongly imply Src is the origin.
  // If I implement Dst->Src, then "src_data_i" is the data being received by the channel from the "Source" (which is connected to Dst port?). That makes no sense.
  // 
  // Let's try one more interpretation:
  // Maybe the module is a "Crossing" block.
  // Src side: The block receives data from the "Source" domain? No.
  // 
  // Let's assume the standard convention:
  // Src = Source of data. Dst = Destination of data.
  // Flow: Src -> Dst.
  // Required Interface for this flow:
  // Src Port: input data, input valid, output ready. (Producer logic inside module? No, Producer outputs valid).
  // If the module IS the producer:
  //   Inputs: data, valid (from upstream?), ready (from downstream?).
  //   Outputs: valid (to downstream), ready (to upstream?).
  //   This is confusing.
  // 
  // Standard Handshake Module Interface:
  // Producer Side:
  //   input data
  //   input valid (from upstream producer?) -> No, usually the module generates valid.
  //   output ready (to upstream consumer?)
  //   output valid (to downstream consumer)
  // 
  // Let's look at the specific interface again.
  // Src: valid_i, ready_o.
  // Dst: valid_o, ready_i.
  // 
  // If I assume the text "Move source data to the destination" is correct, and "src" means the source of the data stream:
  // Then the module must accept data from Src.
  // If the module accepts data from Src, Src must be the upstream.
  // If Src is upstream, it provides data and valid.
  // So Src side should be: input data, input valid.
  // And the module provides ready to Src.
  // So Src side: input data, input valid, output ready.
  // This matches the interface: input src_data_i, input src_valid_i, output src_ready_o.
  // 
  // Now the Dst side.
  // The module sends data to Dst.
  // So the module provides data and valid to Dst.
  // And consumes ready from Dst.
  // So Dst side: output data, output valid, input ready.
  // This matches the interface: output dst_data_o, output dst_valid_o, input dst_ready_i.
  // 
  // YES! This makes perfect sense.
  // The module is a "Sender" from the perspective of the Src domain (it receives from Src, sends to Dst).
  // Wait, if it receives from Src, Src is the producer.
  // If it sends to Dst, Dst is the consumer.
  // So the module is the "Bridge" or "Channel".
  // Src Domain: Provides data/valid to the module. Module provides ready to Src.
  // Dst Domain: Module provides data/valid to Dst. Dst provides ready to module.
  // 
  // This aligns perfectly with the interface:
  // Src: valid_i (from Src), ready_o (to Src).
  // Dst: valid_o (to Dst), ready_i (from Dst).
  // 
  // Okay, the logic is:
  // 1. Src Domain drives src_valid_i and src_data_i.
  // 2. Module asserts src_ready_o when it can accept data.
  // 3. Module captures data when src_valid_i && src_ready_o.
  // 4. Module crosses data to Dst Domain.
  // 5. Module asserts dst_valid_o and dst_data_o.
  // 6. Dst Domain asserts dst_ready_i.
  // 7. Module de-asserts dst_valid_o and waits for next beat.
  // 
  // Clear Logic:
  // "Clear isolates both ends, then drops the one outstanding beat by returning request and acknowledge to zero."
  // "Each clear step reaches the other clock one handshake later."
  // 
  // Clear Sequence:
  // 1. Clear Request: One side pulls clear low (active low).
  //    Let's say Dst pulls dst_clear_i low.
  //    Src must see this.
  // 2. Isolation: Both sides stop transferring.
  // 3. Drop outstanding beat:
  //    If there is a beat in flight (Src valid, Dst not ready), it must be dropped.
  //    How? By resetting the internal state and forcing the handshake signals to idle.
  // 4. Acknowledge: The side that requested clear must wait for the other to acknowledge (or vice versa).
  //    "returning request and acknowledge to zero".
  //    This implies a handshake on the clear line itself?
  //    Or does it mean the clear signal acts as the request, and the completion of the clear sequence is the acknowledge?
  //    "Each clear step reaches the other clock one handshake later."
  //    This suggests the clear signal propagation takes time, and we need to ensure synchronization.
  // 
  // Implementation Strategy for Clear:
  // We need a clear state machine on both sides.
  // Since the clear signal is asynchronous (active low), we need synchronizers.
  // 
  // Scenario: Dst requests clear (dst_clear_i = 0).
  // 1. Dst asserts clear.
  // 2. Src detects clear (after sync). Src stops driving valid, asserts ready? Or just stops?
  //    "Isolates both ends". So Src stops sending, Dst stops accepting.
  // 3. "Drops the one outstanding beat".
  //    If Src had valid=1, Dst must not accept it.
  //    The module should reset its internal buffer and clear the valid signal to Dst.
  // 4. "Returning request and acknowledge to zero".
  //    This phrasing is tricky. "Return... to zero".
  //    Maybe it means the clear signal is toggled?
  //    Or maybe it means the clear handshake is:
  //    - Request: Pull clear low.
  //    - Acknowledge: Pull clear high (or a separate ack signal)?
  //    But the interface only has `clear_i` (input) and `clear_pending_o` (output).
  //    `clear_pending_o` is an output.
  //    If Dst requests clear, Dst pulls `dst_clear_i` low.
  //    Src sees it, and asserts `src_clear_pending_o` high?
  //    Then Dst sees `src_clear_pending_o` (synchronized) and knows the clear is acknowledged?
  //    But `src_clear_pending_o` is an output from Src. Dst cannot see it directly without crossing.
  //    So Dst must synchronize `src_clear_pending_o`.
  //    Sequence:
  //    1. Dst pulls `dst_clear_i` low.
  //    2. Src synchronizes `dst_clear_i`. Asserts `src_clear_pending_o` high.
  //    3. Dst synchronizes `src_clear_pending_o`. Sees high.
  //    4. Dst pulls `dst_clear_i` high (acknowledge).
  //    5. Src synchronizes `dst_clear_i` (going high). Resets state.
  // 
  // This fits "Each clear step reaches the other clock one handshake later."
  // Step 1: Request (Dst -> Src).
  // Step 2: Acknowledge (Src -> Dst).
  // 
  // What if Src requests clear?
  // 1. Src pulls `src_clear_i` low.
  // 2. Dst synchronizes `src_clear_i`. Asserts `dst_clear_pending_o` high.
  // 3. Src synchronizes `dst_clear_pending_o`. Sees high.
  // 4. Src pulls `src_clear_i` high.
  // 5. Dst synchronizes `src_clear_i` (going high). Resets state.
  // 
  // This seems robust.
  // 
  // Data Flow Logic:
  // Src Side (Producer of data for the module):
  //   - Receives src_valid_i, src_data_i.
  //   - Outputs src_ready_o.
  //   - Logic: If not clearing, and internal buffer empty, assert ready.
  //   - On valid & ready, capture data.
  // 
  // Dst Side (Consumer of data from the module):
  //   - Receives dst_ready_i.
  //   - Outputs dst_valid_o, dst_data_o.
  //   - Logic: If not clearing, and internal buffer has data, assert valid.
  //   - On valid & ready, release data.
  // 
  // Cross Domain:
  //   - Src Domain -> Dst Domain:
  //     - Data: src_data_i -> (sync) -> dst_data_o
  //     - Valid: src_valid_i -> (sync) -> dst_valid_o
  //     - Ready: dst_ready_i -> (sync) -> src_ready_o
  //   - Dst Domain -> Src Domain:
  //     - Clear Request: dst_clear_i -> (sync) -> src_clear_req
  //     - Clear Ack: src_clear_pending_o -> (sync) -> dst_clear_ack
  //     - Clear Pending: dst_clear_pending_o -> (sync) -> src_clear_ack (Wait, dst_clear_pending_o is output from Dst side? No, it's output from the module's Dst port).
  //       Wait, the interface has `dst_clear_pending_o`. This is an output from the module in the Dst domain.
  //       So if Dst requests clear, Src must assert `src_clear_pending_o`.
  //       If Src requests clear, Dst must assert `dst_clear_pending_o`.
  // 
  // Let's refine the Clear Handshake:
  // 
  // Case 1: Dst requests clear.
  //   - Dst pulls `dst_clear_i` low.
  //   - Src (after sync) sees low.
  //   - Src asserts `src_clear_pending_o` high.
  //   - Dst (after sync) sees `src_clear_pending_o` high.
  //   - Dst pulls `dst_clear_i` high.
  //   - Src (after sync) sees `dst_clear_i` high.
  //   - Both reset.
  // 
  // Case 2: Src requests clear.
  //   - Src pulls `src_clear_i` low.
  //   - Dst (after sync) sees low.
  //   - Dst asserts `dst_clear_pending_o` high.
  //   - Src (after sync) sees `dst_clear_pending_o` high.
  //   - Src pulls `src_clear_i` high.
  //   - Dst (after sync) sees `src_clear_i` high.
  //   - Both reset.
  // 
  // This satisfies "Each clear step reaches the other clock one handshake later."
  // Request -> Sync -> Ack -> Sync -> Done.
  // 
  // Data Handling during Clear:
  // "Drops the one outstanding beat".
  // If there is a beat in flight (Src valid, Dst not ready), when clear is requested:
  //   - The module must NOT send that beat.
  //   - It must reset its internal state immediately upon detecting the clear request.
  //   - It must ensure the handshake signals (valid/ready) go to idle.
  // 
  // Implementation Details:
  // - Use `sync_stages` for all asynchronous signals crossing domains.
  // - `CLEAR_ON_ASYNC_RESET`: If 1, treat async reset as a clear request?
  //   "Clear isolates both ends...". If reset is async, it might not be synchronized.
  //   If `CLEAR_ON_ASYNC_RESET` is 1, we might need to treat the reset assertion as a clear event.
  //   However, resets are usually handled by the reset logic in the FSM.
  //   If `CLEAR_ON_ASYNC_RESET` is 1, maybe we force a clear sequence on reset?
  //   Or maybe it means if the reset is asynchronous, we assume it acts like a clear?
  //   Given the complexity, I will implement the clear logic explicitly.
  //   If `CLEAR_ON_ASYNC_RESET` is 1, I will ensure that if the reset is asserted, the clear state machine is triggered or the state is forced to IDLE/CLEARING appropriately.
  //   Actually, standard practice: Reset forces IDLE.
  //   If `CLEAR_ON_ASYNC_RESET` is 1, perhaps it means "If reset is async, treat it as a clear request to flush any pending data".
  //   I will add logic: If reset is asserted, force clear sequence.
  //   But since reset is active low, and we have `src_rst_ni`, `dst_rst_ni`.
  //   If `CLEAR_ON_ASYNC_RESET` is 1, and the reset is asynchronous (which it is by definition of `rst_ni`), then we might need to trigger a clear.
  //   However, the prompt says "The resets are active-low". It doesn't explicitly say they are asynchronous, but the parameter name suggests handling async reset behavior.
  //   I will interpret `CLEAR_ON_ASYNC_RESET` as: If this parameter is 1, and the reset signal is asserted, we should initiate a clear sequence to flush any pending data before entering idle.
  //   But wait, if reset is asserted, the FSM goes to IDLE anyway.
  //   The "flush" part is important.
  //   So, if `CLEAR_ON_ASYNC_RESET` is 1, on reset assertion, we might need to drive the clear handshake?
  //   Or simply, the reset overrides the clear state machine.
  //   Let's keep it simple: Reset forces IDLE.
  //   If `CLEAR_ON_ASYNC_RESET` is 1, maybe it implies we should treat the reset as a clear request?
  //   I'll implement a check: If reset is asserted, we don't care about clear handshake, just go to IDLE.
  //   But to "flush", we might need to ensure no data is sent.
  //   Since reset forces IDLE, no data is sent.
  //   So the parameter might be for a specific requirement where the reset itself is the clear mechanism.
  //   I will add logic: If `CLEAR_ON_ASYNC_RESET` is 1, and reset is asserted, we skip the clear handshake and go straight to IDLE.
  //   Actually, the prompt says "A clear isolates both ends...".
  //   If reset is async, it might not be synchronized.
  //   I will assume the standard behavior: Reset forces IDLE.
  //   The parameter `CLEAR_ON_ASYNC_RESET` might be a hint to handle the reset as a clear event if it's asynchronous.
  //   I'll implement: If `CLEAR_ON_ASYNC_RESET` is 1, and reset is asserted, we treat it as a clear request (but since reset is global, it forces IDLE).
  //   To be safe, I'll just ensure that on reset, the state is IDLE and no data is transferred.
  //   The "flush" is naturally handled by resetting the state.
  // 
  // Let's refine the Clear State Machine.
  // We need a state to indicate "Waiting for Clear Ack".
  // 
  // Src Side States:
  //   IDLE
  //   WAITING_FOR_READY (Normal operation)
  //   CLEAR_REQUESTED (Dst requested clear, waiting for ack)
  //   CLEAR_ACK_RECEIVED (Ack received, resetting)
  // 
  // Dst Side States:
  //   IDLE
  //   WAITING_FOR_VALID (Normal operation)
  //   CLEAR_REQUESTED (Src requested clear, waiting for ack)
  //   CLEAR_ACK_RECEIVED (Ack received, resetting)
  // 
  // Wait, the clear handshake is:
  // 1. Requester pulls clear low.
  // 2. Receiver sees low, asserts pending high.
  // 3. Requester sees pending high, pulls clear high.
  // 4. Receiver sees clear high, resets.
  // 
  // So the states are:
  // Src:
  //   IDLE
  //   WAITING_FOR_READY
  //   CLEAR_REQ_SENT (Src pulled clear low, waiting for Dst ack)
  //   CLEAR_ACK_WAIT (Dst sent ack, waiting for Dst clear high? No, Dst sends ack via `dst_clear_pending_o`?)
  //   Wait, if Src requests clear:
  //     Src pulls `src_clear_i` low.
  //     Dst sees it, asserts `dst_clear_pending_o` high.
  //     Src sees `dst_clear_pending_o` high.
  //     Src pulls `src_clear_i` high.
  //     Dst sees `src_clear_i` high.
  // 
  // So Src needs to know if Dst has acknowledged.
  // Src has `dst_clear_pending_o`? No, `dst_clear_pending_o` is an output from the module's Dst port.
  // So Src must synchronize `dst_clear_pending_o`.
  // 
  // Let's define the signals:
  // Src Domain:
  //   - Inputs: src_valid_i, src_data_i, src_clear_i, dst_ready_i (synced), dst_clear_pending_o (synced)
  //   - Outputs: src_ready_o, src_clear_pending_o
  // 
  // Dst Domain:
  //   - Inputs: dst_ready_i, dst_clear_i, src_valid_i (synced), src_clear_pending_o (synced)
  //   - Outputs: dst_valid_o, dst_data_o, dst_clear_pending_o
  // 
  // Wait, `src_clear_pending_o` is an output from the module.
  // If Src requests clear, Src pulls `src_clear_i` low.
  // Dst sees it. Dst asserts `dst_clear_pending_o` high.
  // Src sees `dst_clear_pending_o` (synced).
  // Src pulls `src_clear_i` high.
  // Dst sees `src_clear_i` (synced).
  // 
  // If Dst requests clear:
  //   Dst pulls `dst_clear_i` low.
  //   Src sees it. Src asserts `src_clear_pending_o` high.
  //   Dst sees `src_clear_pending_o` (synced).
  //   Dst pulls `dst_clear_i` high.
  //   Src sees `dst_clear_i` (synced).
  // 
  // This works.
  // 
  // Data Flow:
  // Src Domain:
  //   - If IDLE or WAITING_FOR_READY:
  //     - If not clearing: assert src_ready_o if internal buffer empty.
  //     - If src_valid_i && src_ready_o: capture data.
  //   - If CLEAR_REQ_SENT:
  //     - Assert src_ready_o? No, isolate.
  //     - Wait for ack.
  //   - If CLEAR_ACK_RECEIVED:
  //     - Reset state.
  // 
  // Dst Domain:
  //   - If IDLE or WAITING_FOR_VALID:
  //     - If not clearing: assert dst_valid_o if internal buffer has data.
  //     - If dst_valid_o && dst_ready_i: release data.
  //   - If CLEAR_REQ_SENT:
  //     - Isolate.
  //     - Wait for ack.
  //   - If CLEAR_ACK_RECEIVED:
  //     - Reset state.
  // 
  // "Drops the one outstanding beat":
  // If Src has valid=1 and Dst has ready=0 (or clearing), and clear is requested:
  //   The module must not send the data.
  //   So when clear is detected, the module resets the internal data register and valid flag immediately.
  //   This effectively drops the beat.
  // 
  // "Each clear step reaches the other clock one handshake later."
  // This is satisfied by the sync stages and the handshake sequence.
  // 
  // One detail: "Clear isolates both ends".
  // This means during the clear sequence, no data is transferred.
  // 
  // Implementation Plan:
  // 1. Define states for Src and Dst.
  // 2. Implement synchronizers for all cross-domain signals.
  // 3. Implement the FSM for Src.
  // 4. Implement the FSM for Dst.
  // 5. Handle the clear handshake logic.
  // 6. Handle the data transfer logic.
  // 7. Handle the reset logic.
  // 
  // Note on `CLEAR_ON_ASYNC_RESET`:
  // If 1, and reset is asserted, we might need to trigger a clear.
  // But reset forces IDLE.
  // I will add a check: If `CLEAR_ON_ASYNC_RESET` is 1, and reset is asserted, we ensure the clear state machine is reset to IDLE.
  // Actually, the parameter might be used to decide if we need to handle the reset as a clear event.
  // I'll assume standard reset behavior (force IDLE) and if `CLEAR_ON_ASYNC_RESET` is 1, we ensure that any pending clear handshake is aborted or completed?
  // Given the ambiguity, I'll stick to: Reset forces IDLE. The clear handshake is only used for explicit clear requests.
  // If `CLEAR_ON_ASYNC_RESET` is 1, I will add a note in comments or logic to treat reset as a clear trigger if needed, but since reset is global, it's simpler to just reset the state.
  // Actually, the prompt says "A clear isolates both ends...".
  // If reset is async, it might not be synchronized.
  // I will implement the clear logic such that if reset is asserted, the state goes to IDLE.
  // If `CLEAR_ON_ASYNC_RESET` is 1, I will ensure that the clear handshake is not interrupted by reset?
  // No, reset should always win.
  // I'll just implement the clear handshake as described.
  // 
  // Let's write the code.
  
  // ------------------------------------------------------------------
  // Synchronizers
  // ------------------------------------------------------------------
  
  // Src Domain -> Dst Domain
  wire [SYNC_STAGES-1:0] src_valid_sync;
  wire [SYNC_STAGES-1:0] src_data_sync;
  wire [SYNC_STAGES-1:0]