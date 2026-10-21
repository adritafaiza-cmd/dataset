module isochronous_4phase_handshake (
    input  src_clk_i,
    input  src_rst_ni,
    input  src_valid_i,
    output src_ready_o,
    input  dst_clk_i,
    input  dst_rst_ni,
    output dst_valid_o,
    input  dst_ready_i
);

    reg src_state;
    reg dst_state;
    reg src_valid_reg;
    reg dst_valid_reg;
    reg dst_ready_reg;

    // State encoding: 0=Idle, 1=WaitSrc, 2=WaitDst, 3=WaitSrcAck, 4=WaitDstAck
    // We use separate state machines for clarity, but the handshake logic is coupled.
    // Actually, for a 4-phase handshake between two domains, we need to track the phase
    // in each domain relative to the other. A common approach is to have the source
    // drive the sequence and the destination acknowledge, or vice versa.
    //
    // Let's define the 4 phases explicitly in the source domain logic and destination domain logic.
    // Phase 1: Source asserts VALID (src_valid_i = 1)
    // Phase 2: Destination asserts READY (dst_ready_i = 1) -> Source deasserts VALID, Destination asserts VALID
    // Phase 3: Source asserts READY (src_ready_o = 1)
    // Phase 4: Destination deasserts VALID, Destination asserts READY (dst_ready_i = 1) -> Source deasserts READY
    //
    // However, the standard 4-phase handshake usually looks like this:
    // 1. Src: Valid=1, Ready=0
    // 2. Dst: Ready=1 (Src sees this), Src: Valid=0, Ready=1 (Dst sees this)
    // 3. Dst: Valid=1, Ready=0
    // 4. Src: Ready=1 (Dst sees this), Dst: Valid=0, Ready=1 (Src sees this)
    //
    // Since we don't have data, we just toggle the signals.
    // We need to synchronize the incoming signals and drive the outgoing signals.
    //
    // Let's use a single state machine that tracks the global handshake phase,
    // but since clocks are different, we must implement the state machine in both domains
    // or use a cross-domain synchronization mechanism.
    //
    // Given the constraints and typical implementation for this specific problem:
    // We will implement the handshake logic such that:
    // - In src domain: We wait for dst_valid_o to be asserted (which comes from dst domain).
    // - In dst domain: We wait for src_ready_o to be asserted (which comes from src domain).
    //
    // Actually, the cleanest way for "related clocks" without a FIFO is to have the
    // handshake protocol be self-synchronizing.
    //
    // Let's define the states based on the local signal status.
    //
    // Source Domain Logic:
    // State S0 (Idle): src_valid_i=0, src_ready_o=0
    // State S1 (Wait for Dst Ready): src_valid_i=1, src_ready_o=0. Wait until dst_valid_o is seen.
    // State S2 (Wait for Dst Valid): src_valid_i=0, src_ready_o=1. Wait until dst_ready_i is seen.
    // State S3 (Idle): src_valid_i=0, src_ready_o=0.
    //
    // Destination Domain Logic:
    // State D0 (Idle): dst_ready_i=0, dst_valid_o=0
    // State D1 (Wait for Src Valid): dst_ready_i=1, dst_valid_o=0. Wait until src_valid_i is seen.
    // State D2 (Wait for Src Ready): dst_ready_i=0, dst_valid_o=1. Wait until src_ready_o is seen.
    // State D3 (Idle): dst_ready_i=1, dst_valid_o=0.
    //
    // Wait, the 4-phase handshake requires a specific sequence.
    // Let's trace:
    // 1. Src wants to send: src_valid=1, src_ready=0.
    // 2. Dst accepts: dst_ready=1. (Src sees dst_ready=1? No, Src needs to see dst_valid to know Dst is ready to accept the "handshake token").
    //
    // Correct 4-phase sequence for "Valid/Ready" without data:
    // Phase 1: Src asserts VALID. (Src: V=1, R=0). Dst sees V=1.
    // Phase 2: Dst asserts READY. (Dst: R=1, V=0). Src sees R=1.
    // Phase 3: Src asserts READY. (Src: V=0, R=1). Dst sees R=1.
    // Phase 4: Dst asserts VALID. (Dst: R=0, V=1). Src sees V=1.
    //
    // This creates a loop. But we need to break it.
    // Usually, the handshake is:
    // 1. Src: V=1, R=0
    // 2. Dst: R=1 (Src sees this? No, Src needs to see Dst's V to know Dst is ready to take the next item? No.)
    //
    // Let's stick to the definition: "four-phase valid/ready handshake".
    // This typically means:
    // 1. Src asserts VALID.
    // 2. Dst asserts READY (acknowledging the valid).
    // 3. Src asserts READY (acknowledging the ready).
    // 4. Dst asserts VALID (for the next transaction? Or deasserting ready?).
    //
    // Actually, the standard 4-phase handshake for a single data transfer is:
    // 1. Src: Valid=1, Ready=0
    // 2. Dst: Ready=1 (Src sees this? No, Src must see Dst's Valid to know Dst is ready? No.)
    //
    // Let's re-evaluate the standard 4-phase handshake protocol (e.g., from ARM or standard AXI-lite variations):
    // It involves 4 signal transitions.
    // 1. Src: Valid -> 1
    // 2. Dst: Ready -> 1 (Src sees this? No, Src needs to see Dst's Valid to know Dst is ready to accept? No.)
    //
    // Okay, let's look at the signals provided:
    // Src outputs: src_ready_o
    // Dst outputs: dst_valid_o
    // Src inputs: src_valid_i, dst_ready_i (wait, dst_ready_i is input to the module? Yes, "input dst_ready_i")
    // Dst inputs: dst_ready_i (wait, the port list says "input dst_ready_i" for the module, but logically Dst should output ready?
    //
    // Let's re-read the port list carefully:
    // Inputs: src_valid_i, dst_ready_i.
    // Outputs: src_ready_o, dst_valid_o.
    //
    // This implies:
    // - Source Domain: Has src_valid_i (input), drives src_ready_o (output).
    // - Destination Domain: Has dst_ready_i (input), drives dst_valid_o (output).
    //
    // Wait, if Dst has dst_ready_i as input, then Dst is waiting for something to be ready?
    // And Src has src_valid_i as input.
    //
    // This looks like a cross-domain handshake where:
    // - Src Domain generates src_valid_i (from outside) and waits for src_ready_o to be asserted by the handshake logic.
    // - Dst Domain generates dst_ready_i (from outside) and waits for dst_valid_o to be asserted by the handshake logic.
    //
    // No, that doesn't make sense. Usually, the module implements the handshake logic.
    // Let's assume the standard interpretation:
    // - The module sits between two domains.
    // - Src Domain provides src_valid_i (request) and expects src_ready_o (grant).
    // - Dst Domain provides dst_ready_i (request) and expects dst_valid_o (grant).
    //
    // But the handshake is between the two domains.
    // Sequence:
    // 1. Src asserts src_valid_i.
    // 2. Dst asserts dst_ready_i.
    // 3. Src asserts src_ready_o.
    // 4. Dst asserts dst_valid_o.
    //
    // This is a 4-phase handshake.
    //
    // Implementation Strategy:
    // We need to synchronize the signals across domains.
    // Since clocks are related (integer ratio), we can use a simple synchronizer (2 FFs) for each cross-domain signal.
    //
    // Logic:
    // - In Src Domain:
    //   - Detect src_valid_i (synchronized).
    //   - Wait for dst_ready_i (synchronized from Dst).
    //   - Once both are high, assert src_ready_o.
    //   - Wait for dst_valid_o (synchronized from Dst).
    //   - Once dst_valid_o is high, deassert src_ready_o and wait for next src_valid_i.
    //
    // - In Dst Domain:
    //   - Detect dst_ready_i (synchronized).
    //   - Wait for src_valid_i (synchronized from Src).
    //   - Once both are high, assert dst_valid_o.
    //   - Wait for src_ready_o (synchronized from Src).
    //   - Once src_ready_o is high, deassert dst_valid_o and wait for next dst_ready_i.
    //
    // This ensures the 4-phase order:
    // 1. Src Valid (Input)
    // 2. Dst Ready (Input)
    // 3. Src Ready (Output)
    // 4. Dst Valid (Output)
    //
    // We need to handle resets and ensure no glitches.
    // We will use 2-stage synchronizers for all cross-domain signals.
    // We will use a state machine in each domain to track the handshake phase.

    // Synchronizers for cross-domain signals
    // Src Domain needs to see: dst_ready_i, dst_valid_o
    reg [1:0] dst_ready_sync;
    reg [1:0] dst_valid_sync;

    // Dst Domain needs to see: src_valid_i, src_ready_o
    reg [1:0] src_valid_sync;
    reg [1:0] src_ready_sync;

    // State Machine in Src Domain
    // States: IDLE, WAIT_DST_READY, WAIT_DST_VALID
    reg [1:0] src_state;
    parameter SRC_IDLE = 2'b00;
    parameter SRC_WAIT_DST_READY = 2'b01;
    parameter SRC_WAIT_DST_VALID = 2'b10;

    // State Machine in Dst Domain
    // States: IDLE, WAIT_SRC_VALID, WAIT_SRC_READY
    reg [1:0] dst_state;
    parameter DST_IDLE = 2'b00;
    parameter DST_WAIT_SRC_VALID = 2'b01;
    parameter DST_WAIT_SRC_READY = 2'b10;

    // Synchronizer logic for Src Domain (inputs from Dst)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_sync <= 2'b00;
            dst_valid_sync <= 2'b00;
        end else begin
            dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
            dst_valid_sync <= {dst_valid_sync[0], dst_ready_i}; // Wait, dst_valid_sync should sync dst_valid_o
            // Correction: dst_valid_sync should sync dst_valid_o
            // Let's fix the variable names in the always block
        end
    end

    // Corrected Synchronizer logic for Src Domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_sync <= 2'b00;
            dst_valid_sync <= 2'b00;
        end else begin
            dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
            dst_valid_sync <= {dst_valid_sync[0], dst_valid_o};
        end
    end

    // Synchronizer logic for Dst Domain (inputs from Src)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync <= 2'b00;
            src_ready_sync <= 2'b00;
        end else begin
            src_valid_sync <= {src_valid_sync[0], src_valid_i};
            src_ready_sync <= {src_ready_sync[0], src_ready_o};
        end
    end

    // Src Domain State Machine
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state <= SRC_IDLE;
            src_ready_o <= 1'b0;
        end else begin
            case (src_state)
                SRC_IDLE: begin
                    if (src_valid_i) begin
                        src_state <= SRC_WAIT_DST_READY;
                    end
                    src_ready_o <= 1'b0;
                end
                SRC_WAIT_DST_READY: begin
                    if (dst_ready_sync[1]) begin
                        src_state <= SRC_WAIT_DST_VALID;
                    end
                    src_ready_o <= 1'b0;
                end
                SRC_WAIT_DST_VALID: begin
                    if (dst_valid_sync[1]) begin
                        src_state <= SRC_IDLE;
                    end
                    src_ready_o <= 1'b1;
                end
                default: begin
                    src_state <= SRC_IDLE;
                    src_ready_o <= 1'b0;
                end
            endcase
        end
    end

    // Dst Domain State Machine
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state <= DST_IDLE;
            dst_valid_o <= 1'b0;
        end else begin
            case (dst_state)
                DST_IDLE: begin
                    if (dst_ready_i) begin
                        dst_state <= DST_WAIT_SRC_VALID;
                    end
                    dst_valid_o <= 1'b0;
                end
                DST_WAIT_SRC_VALID: begin
                    if (src_valid_sync[1]) begin
                        dst_state <= DST_WAIT_SRC_READY;
                    end
                    dst_valid_o <= 1'b0;
                end
                DST_WAIT_SRC_READY: begin
                    if (src_ready_sync[1]) begin
                        dst_state <= DST_IDLE;
                    end
                    dst_valid_o <= 1'b1;
                end
                default: begin
                    dst_state <= DST_IDLE;
                    dst_valid_o <= 1'b0;
                end
            endcase
        end
    end

endmodule<|im_end|>
