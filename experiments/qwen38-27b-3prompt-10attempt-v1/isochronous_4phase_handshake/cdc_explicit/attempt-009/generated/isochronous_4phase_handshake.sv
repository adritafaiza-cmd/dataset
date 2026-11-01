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

    // Source domain state
    reg src_valid_reg;
    reg src_ack_reg;

    // Destination domain state
    reg dst_valid_reg;
    reg dst_ack_reg;

    // Synchronizers for crossing signals
    // src_valid crosses to dst domain
    reg [1:0] src_valid_sync;
    // src_ack crosses to dst domain
    reg [1:0] src_ack_sync;
    // dst_valid crosses to src domain
    reg [1:0] dst_valid_sync;
    // dst_ack crosses to src domain
    reg [1:0] dst_ack_sync;

    // Synchronize src_valid into dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_valid_sync <= 2'b00;
        else
            src_valid_sync <= {src_valid_sync[0], src_valid_reg};
    end

    // Synchronize src_ack into dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_ack_sync <= 2'b00;
        else
            src_ack_sync <= {src_ack_sync[0], src_ack_reg};
    end

    // Synchronize dst_valid into src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_valid_sync <= 2'b00;
        else
            dst_valid_sync <= {dst_valid_sync[0], dst_valid_reg};
    end

    // Synchronize dst_ack into src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ack_sync <= 2'b00;
        else
            dst_ack_sync <= {dst_ack_sync[0], dst_ack_reg};
    end

    // Source domain logic
    // src_ready_o is high when source is not waiting for ack or when ack is received
    // In 4-phase handshake:
    //   Phase 0: valid=0, ready=1 (idle)
    //   Phase 1: valid=1, ready=1 (data presented)
    //   Phase 2: valid=1, ready=0 (data accepted, waiting for ack)
    //   Phase 3: valid=0, ready=0 (ack received, returning to idle)
    //
    // Source drives valid, destination drives ready (from source's perspective,
    // the "ready" signal is actually the ack from destination).
    //
    // Let's redefine:
    // Source side:
    //   src_valid_reg: driven by source, indicates data is valid
    //   src_ready_o: driven by source, indicates source is ready to accept new data
    //   dst_ack_sync[1]: synchronized ack from destination
    //
    // Destination side:
    //   dst_valid_o: driven by destination, indicates data is valid at destination
    //   dst_ready_i: driven by destination consumer, indicates ready to accept
    //   src_valid_sync[1]: synchronized valid from source
    //
    // Four-phase handshake protocol:
    // 1. Source asserts valid (src_valid_reg = 1)
    // 2. Destination sees valid, asserts its valid (dst_valid_reg = 1)
    // 3. Destination consumer asserts ready (dst_ready_i = 1)
    // 4. Destination deasserts valid (dst_valid_reg = 0) and asserts ack
    // 5. Source sees ack, deasserts valid (src_valid_reg = 0)
    // 6. Source asserts ready (src_ready_o = 1)
    // 7. Destination deasserts ack
    // 8. Source deasserts ready (src_ready_o = 0) - back to idle
    //
    // Actually, let me think about this more carefully.
    //
    // In a standard 4-phase handshake:
    // - Sender drives valid, receiver drives ready
    // - valid goes 0->1, then 1->0
    // - ready goes 0->1, then 1->0
    //
    // For CDC, we need to synchronize these signals.
    //
    // Let's use a simpler model:
    // Source domain:
    //   src_valid_reg: the valid signal driven by source
    //   src_ready_o: the ready signal driven by source (indicates source can accept new data)
    //
    // Destination domain:
    //   dst_valid_o: the valid signal driven by destination
    //   dst_ready_i: the ready signal from destination consumer
    //
    // The handshake:
    // 1. Source asserts src_valid_reg
    // 2. Destination synchronizes src_valid, asserts dst_valid_o
    // 3. Destination consumer asserts dst_ready_i
    // 4. Destination deasserts dst_valid_o, asserts dst_ack_reg
    // 5. Source synchronizes dst_ack, deasserts src_valid_reg, asserts src_ready_o
    // 6. Destination synchronizes src_valid deassertion, deasserts dst_ack_reg
    // 7. Source deasserts src_ready_o
    //
    // Let me implement this step by step.

    // Source domain: manage src_valid_reg and src_ready_o
    // src_ready_o is high when source is idle (not in handshake)
    // src_valid_reg is asserted when source wants to send data

    // State machine for source:
    // IDLE: src_valid_reg=0, src_ready_o=1
    // WAIT_ACK: src_valid_reg=1, src_ready_o=0
    // DEASSERT_VALID: src_valid_reg=0, src_ready_o=0 (transient)
    // Back to IDLE

    // Actually, let's simplify. The source just needs to:
    // - Assert src_valid_reg when it has data and is ready
    // - Wait for ack from destination
    // - Deassert src_valid_reg when ack received
    // - Assert src_ready_o when idle

    // Let's use a simple approach:
    // src_ready_o = ~src_valid_reg (source is ready when not sending)
    // But we need to handle the 4-phase properly.

    // Let me reconsider the 4-phase handshake:
    // Phase 0 (Idle): valid=0, ready=1
    // Phase 1 (Valid): valid=1, ready=1
    // Phase 2 (Ack): valid=1, ready=0
    // Phase 3 (Deassert): valid=0, ready=0
    // Back to Phase 0

    // In our case:
    // Source drives valid (src_valid_reg)
    // Destination drives ready (which we'll call dst_ack_reg internally)
    //
    // But wait, the ports are:
    // src_valid_i: input to module (source valid)
    // src_ready_o: output from module (source ready)
    // dst_valid_o: output from module (destination valid)
    // dst_ready_i: input to module (destination ready)
    //
    // So the source side has:
    // - src_valid_i: external source valid
    // - src_ready_o: we drive this
    //
    // And the destination side has:
    // - dst_valid_o: we drive this
    // - dst_ready_i: external destination ready
    //
    // This is a bit unusual. Let me re-read the problem.
    //
    // "Implement a four-phase valid/ready handshake between related clocks."
    //
    // I think the idea is:
    // - Source domain: src_valid_i is the valid signal from the source, src_ready_o is the ready signal back to the source
    // - Destination domain: dst_valid_o is the valid signal to the destination, dst_ready_i is the ready signal from the destination
    //
    // So the handshake is:
    // 1. Source asserts src_valid_i
    // 2. Module (in source domain) sees src_valid_i and src_ready_o, and when both are high, it starts the transfer
    // 3. Module asserts dst_valid_o (in destination domain)
    // 4. Destination asserts dst_ready_i
    // 5. Module deasserts dst_valid_o
    // 6. Module deasserts src_ready_o
    // 7. Source deasserts src_valid_i
    // 8. Module asserts src_ready_o again
    //
    // Hmm, this is getting complicated. Let me think about it differently.
    //
    // Actually, I think the standard interpretation is:
    // - The module acts as a CDC bridge
    // - Source side: src_valid_i is the valid from the source, src_ready_o is the ready back to the source
    // - Destination side: dst_valid_o is the valid to the destination, dst_ready_i is the ready from the destination
    //
    // The 4-phase handshake:
    // 1. Source asserts src_valid_i
    // 2. Module asserts src_ready_o (source sees both valid and ready, so it can deassert valid later)
    // 3. Module asserts dst_valid_o
    // 4. Destination asserts dst_ready_i
    // 5. Module deasserts dst_valid_o
    // 6. Module deasserts src_ready_o
    // 7. Source deasserts src_valid_i
    // 8. Module asserts src_ready_o again (back to idle)
    //
    // Wait, that's not quite right either. In a 4-phase handshake:
    // - valid goes 0->1->0
    // - ready goes 0->1->0
    //
    // So:
    // Phase 0: valid=0, ready=1 (idle)
    // Phase 1: valid=1, ready=1 (data presented, ready to accept)
    // Phase 2: valid=1, ready=0 (data accepted, waiting for deassert)
    // Phase 3: valid=0, ready=0 (deasserting, returning to idle)
    //
    // For the source side:
    // - src_valid_i is the valid signal (driven by external source)
    // - src_ready_o is the ready signal (driven by module)
    //
    // For the destination side:
    // - dst_valid_o is the valid signal (driven by module)
    // - dst_ready_i is the ready signal (driven by external destination)
    //
    // So the module needs to:
    // 1. When src_valid_i and src_ready_o are both high, start the transfer
    // 2. Assert dst_valid_o
    // 3. When dst_valid_o and dst_ready_i are both high, complete the transfer
    // 4. Deassert dst_valid_o
    // 5. Deassert src_ready_o
    // 6. Wait for src_valid_i to deassert
    // 7. Assert src_ready_o again
    //
    // Let me implement this with state machines in each domain.

    // Source domain state machine
    // States:
    //   SRC_IDLE: src_ready_o=1, waiting for src_valid_i
    //   SRC_WAIT: src_ready_o=0, waiting for dst_ack (synchronized)
    //   SRC_DEASSERT: src_ready_o=0, waiting for src_valid_i to deassert

    reg [1:0] src_state;
    localparam SRC_IDLE = 2'b00;
    localparam SRC_WAIT = 2'b01;
    localparam SRC_DEASSERT = 2'b10;

    // Destination domain state machine
    // States:
    //   DST_IDLE: dst_valid_o=0, waiting for src_valid (synchronized)
    //   DST_VALID: dst_valid_o=1, waiting for dst_ready_i
    //   DST_ACK: dst_valid_o=0, asserting ack to source

    reg [1:0] dst_state;
    localparam DST_IDLE = 2'b00;
    localparam DST_VALID = 2'b01;
    localparam DST_ACK = 2'b10;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state <= SRC_IDLE;
            src_valid_reg <= 1'b0;
            src_ack_reg <= 1'b0;
        end else begin
            case (src_state)
                SRC_IDLE: begin
                    src_valid_reg <= 1'b0;
                    src_ack_reg <= 1'b0;
                    if (src_valid_i) begin
                        src_state <= SRC_WAIT;
                        src_valid_reg <= 1'b1;
                    end
                end
                SRC_WAIT: begin
                    src_valid_reg <= 1'b1;
                    if (dst_ack_sync[1]) begin
                        src_state <= SRC_DEASSERT;
                        src_valid_reg <= 1'b0;
                        src_ack_reg <= 1'b1;
                    end
                end
                SRC_DEASSERT: begin
                    src_valid_reg <= 1'b0;
                    src_ack_reg <= 1'b1;
                    if (!src_valid_i) begin
                        src_state <= SRC_IDLE;
                        src_ack_reg <= 1'b0;
                    end
                end
                default: begin
                    src_state <= SRC_IDLE;
                    src_valid_reg <= 1'b0;
                    src_ack_reg <= 1'b0;
                end
            endcase
        end
    end

    // src_ready_o is high when in IDLE state
    assign src_ready_o = (src_state == SRC_IDLE);

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state <= DST_IDLE;
            dst_valid_reg <= 1'b0;
            dst_ack_reg <= 1'b0;
        end else begin
            case (dst_state)
                DST_IDLE: begin
                    dst_valid_reg <= 1'b0;
                    dst_ack_reg <= 1'b0;
                    if (src_valid_sync[1]) begin
                        dst_state <= DST_VALID;
                        dst_valid_reg <= 1'b1;
                    end
                end
                DST_VALID: begin
                    dst_valid_reg <= 1'b1;
                    if (dst_ready_i) begin
                        dst_state <= DST_ACK;
                        dst_valid_reg <= 1'b0;
                        dst_ack_reg <= 1'b1;
                    end
                end
                DST_ACK: begin
                    dst_valid_reg <= 1'b0;
                    dst_ack_reg <= 1'b1;
                    if (!src_valid_sync[1]) begin
                        dst_state <= DST_IDLE;
                        dst_ack_reg <= 1'b0;
                    end
                end
                default: begin
                    dst_state <= DST_IDLE;
                    dst_valid_reg <= 1'b0;
                    dst_ack_reg <= 1'b0;
                end
            endcase
        end
    end

    // dst_valid_o is high when in VALID state
    assign dst_valid_o = dst_valid_reg;

endmodule
