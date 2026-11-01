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

    // Synchronizers for crossing from source to destination
    reg [1:0] src_valid_sync;
    reg [1:0] src_ack_sync;

    // Synchronizers for crossing from destination to source
    reg [1:0] dst_valid_sync;
    reg [1:0] dst_ack_sync;

    // Synchronize src_valid_reg into dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_valid_sync <= 2'b00;
        else
            src_valid_sync <= {src_valid_sync[0], src_valid_reg};
    end

    // Synchronize src_ack_reg into dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_ack_sync <= 2'b00;
        else
            src_ack_sync <= {src_ack_sync[0], src_ack_reg};
    end

    // Synchronize dst_valid_reg into src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_valid_sync <= 2'b00;
        else
            dst_valid_sync <= {dst_valid_sync[0], dst_valid_reg};
    end

    // Synchronize dst_ack_reg into src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ack_sync <= 2'b00;
        else
            dst_ack_sync <= {dst_ack_sync[0], dst_ack_reg};
    end

    // Source domain logic
    // src_ready_o is high when source is not asserting valid or when it has received ack
    // In 4-phase handshake:
    //   Phase 0: valid=0, ready=1 (idle)
    //   Phase 1: valid=1, ready=1 (request)
    //   Phase 2: valid=1, ready=0 (ack received)
    //   Phase 3: valid=0, ready=0 (deassert)
    //   Back to Phase 0

    // src_valid_reg: asserted when src_valid_i is high and we are in a state to accept
    // src_ack_reg: asserted when we see dst_valid_sync high (destination has acknowledged)

    // Source state machine
    // We track whether we have sent a valid and whether we have received an ack
    // src_valid_reg is the actual valid signal sent to destination
    // src_ack_reg is the ack received from destination (synchronized)

    // The source asserts valid when src_valid_i is high and we are ready
    // The source deasserts valid when it receives ack and src_valid_i goes low

    // Let's use a simpler approach:
    // src_valid_reg follows src_valid_i but only when we are in a valid state
    // Actually, in a 4-phase handshake without data, the valid signal is the request.

    // Source domain:
    // - src_valid_reg is the request signal
    // - src_ack_reg is the acknowledgment from destination
    // - src_ready_o indicates whether the source can accept a new request

    // The source asserts src_valid_reg when src_valid_i is high and src_ready_o is high
    // The source deasserts src_valid_reg when src_ack_reg is high and src_valid_i is low

    // Let's define:
    // src_ready_o = ~src_valid_reg | src_ack_reg
    //   - If we haven't sent valid, we are ready
    //   - If we have sent valid and received ack, we are ready (but need to deassert valid first)

    // Actually, let me think about this more carefully.

    // 4-phase handshake:
    // 1. Source asserts valid (valid=1, ready=1)
    // 2. Destination sees valid, asserts ready (valid=1, ready=1) - this is the ack
    // 3. Source sees ready (ack), deasserts valid (valid=0, ready=1)
    // 4. Destination sees valid deasserted, deasserts ready (valid=0, ready=0)
    // 5. Source sees ready deasserted, ready for next transfer (valid=0, ready=1)

    // So:
    // src_valid_reg: the valid signal from source
    // dst_ready_o (which is dst_valid_o in our naming): the ready/ack signal from destination

    // Wait, the port names are:
    // src_valid_i: input to source (the request from the source side)
    // src_ready_o: output from source (the ready/ack from the destination side, synchronized)
    // dst_valid_o: output to destination (the valid/request from source, synchronized)
    // dst_ready_i: input to destination (the ready/ack from the destination side)

    // So:
    // dst_valid_o is the valid signal that goes to the destination domain
    // src_ready_o is the ready signal that comes back to the source domain

    // In the source domain:
    // - We have src_valid_i as the local valid request
    // - We generate dst_valid_o (synchronized to dst domain) as the actual valid signal
    // - We receive src_ready_o (synchronized from dst domain) as the ready/ack

    // In the destination domain:
    // - We receive dst_valid_o (synchronized from src domain) as the valid signal
    // - We have dst_ready_i as the local ready
    // - We generate src_ready_o (synchronized to src domain) as the actual ready/ack

    // Let me redefine:
    // In source domain:
    //   src_valid_reg: the valid signal we want to send to destination
    //   src_ack_reg: the ack we receive from destination (synchronized)
    //   src_ready_o: output, indicates source is ready to accept new valid

    // In destination domain:
    //   dst_valid_reg: the valid signal we receive from source (synchronized)
    //   dst_ack_reg: the ack we generate (based on dst_ready_i)
    //   dst_valid_o: output, the valid signal to destination

    // Hmm, I'm getting confused with the naming. Let me re-read the ports.

    // Input ports:
    //   src_valid_i: Source valid (this is the valid signal from the source side, i.e., the request)
    //   dst_ready_i: Destination ready (this is the ready signal from the destination side, i.e., the ack)

    // Output ports:
    //   src_ready_o: Source ready (this is the ready/ack signal that goes back to the source)
    //   dst_valid_o: Destination valid (this is the valid/request signal that goes to the destination)

    // So the handshake is:
    // - Source asserts src_valid_i (request)
    // - This gets synchronized to dst domain as dst_valid_o
    // - Destination sees dst_valid_o and asserts dst_ready_i (ack)
    // - This gets synchronized to src domain as src_ready_o
    // - Source sees src_ready_o and deasserts src_valid_i
    // - Destination sees dst_valid_o deasserted and deasserts dst_ready_i
    // - Source sees src_ready_o deasserted and is ready for next transfer

    // So in the source domain:
    // - src_valid_i is the local valid
    // - We need to synchronize src_valid_i to dst domain to produce dst_valid_o
    // - We need to synchronize dst_ready_i to src domain to produce src_ready_o

    // In the destination domain:
    // - dst_ready_i is the local ready
    // - We receive dst_valid_o (synchronized from src)
    // - We need to synchronize dst_ready_i to src domain to produce src_ready_o

    // Wait, but dst_valid_o is an output port, so it's driven by the source domain logic
    // and src_ready_o is an output port, so it's driven by the destination domain logic

    // Let me reconsider:
    // - dst_valid_o is driven by source domain logic (it's the valid signal going to dst)
    // - src_ready_o is driven by destination domain logic (it's the ready signal going to src)

    // So:
    // In source domain:
    //   - We have src_valid_i (local valid)
    //   - We drive dst_valid_o (the valid signal to dst domain)
    //   - We receive src_ready_o (the ready signal from dst domain, synchronized)

    // In destination domain:
    //   - We have dst_ready_i (local ready)
    //   - We drive src_ready_o (the ready signal to src domain)
    //   - We receive dst_valid_o (the valid signal from src domain, synchronized)

    // For 4-phase handshake:
    // Source domain:
    //   dst_valid_o should follow src_valid_i but with proper handshake timing
    //   src_ready_o is the synchronized version of dst_ready_i

    // Destination domain:
    //   src_ready_o should follow dst_ready_i but with proper handshake timing
    //   dst_valid_o is the synchronized version of src_valid_i

    // Let me implement this:

    // Source domain:
    // dst_valid_o is driven by a register in the source domain
    // src_ready_o is the synchronized version of dst_ready_i

    // Destination domain:
    // src_ready_o is driven by a register in the destination domain
    // dst_valid_o is the synchronized version of src_valid_i

    // Wait, but dst_valid_o is a single output port. It can't be driven by both domains.
    // So dst_valid_o must be driven by one domain, and src_ready_o by the other.

    // Typically:
    // - dst_valid_o is driven by the source domain (since it's the valid signal going to dst)
    // - src_ready_o is driven by the destination domain (since it's the ready signal going to src)

    // So:
    // In source domain:
    //   - We have src_valid_i
    //   - We drive dst_valid_o
    //   - We receive a synchronized version of dst_ready_i (let's call it dst_ready_sync)

    // In destination domain:
    //   - We have dst_ready_i
    //   - We drive src_ready_o
    //   - We receive a synchronized version of src_valid_i (let's call it src_valid_sync)

    // For 4-phase handshake:
    // Source domain logic:
    //   dst_valid_o is asserted when src_valid_i is high and we are in a state to send
    //   dst_valid_o is deasserted when we receive dst_ready_sync (ack) and src_valid_i is low

    // Destination domain logic:
    //   src_ready_o is asserted when dst_ready_i is high and we see src_valid_sync
    //   src_ready_o is deasserted when we see src_valid_sync deasserted

    // Let me implement this with registers:

    // Source domain:
    reg dst_valid_reg;  // This drives dst_valid_o
    reg dst_ready_sync; // Synchronized version of dst_ready_i

    // Destination domain:
    reg src_ready_reg;  // This drives src_ready_o
    reg src_valid_sync; // Synchronized version of src_valid_i

    // Synchronize src_valid_i to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_valid_sync <= 1'b0;
        else
            src_valid_sync <= dst_valid_reg;
    end

    // Synchronize dst_ready_i to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ready_sync <= 1'b0;
        else
            dst_ready_sync <= src_ready_reg;
    end

    // Source domain logic for dst_valid_reg
    // 4-phase: 
    //   - Assert dst_valid_reg when src_valid_i is high and dst_ready_sync is low (or we are in idle)
    //   - Deassert dst_valid_reg when dst_ready_sync is high and src_valid_i is low

    // Actually, let's use a state machine approach:
    // State 0: Idle (dst_valid_reg=0, dst_ready_sync=0)
    // State 1: Request (dst_valid_reg=1, dst_ready_sync=0)
    // State 2: Ack (dst_valid_reg=1, dst_ready_sync=1)
    // State 3: Deassert (dst_valid_reg=0, dst_ready_sync=1)
    // Back to State 0

    // But we don't need explicit states, we can use the signals directly.

    // dst_valid_reg:
    //   - Set when src_valid_i is high and dst_valid_reg is low (or we are in a state to accept)
    //   - Clear when dst_ready_sync is high and src_valid_i is low

    // Let's simplify:
    // dst_valid_reg <= src_valid_i & ~dst_ready_sync | dst_valid_reg & ~src_valid_i & dst_ready_sync;
    // This doesn't seem right.

    // Let me think again. In a 4-phase handshake:
    // 1. Source asserts valid (dst_valid_reg goes high)
    // 2. Destination sees valid, asserts ready (src_ready_reg goes high)
    // 3. Source sees ready (dst_ready_sync goes high), deasserts valid (dst_valid_reg goes low)
    // 4. Destination sees valid deasserted (src_valid_sync goes low), deasserts ready (src_ready_reg goes low)

    // So:
    // dst_valid_reg:
    //   - Goes high when src_valid_i is high and dst_valid_reg is low
    //   - Goes low when dst_ready_sync is high and src_valid_i is low

    // src_ready_reg:
    //   - Goes high when dst_ready_i is high and src_valid_sync is high
    //   - Goes low when src_valid_sync is low

    // Let's implement this:

    // Source domain:
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_valid_reg <= 1'b0;
        else if (src_valid_i && !dst_valid_reg)
            dst_valid_reg <= 1'b1;
        else if (dst_ready_sync && !src_valid_i)
            dst_valid_reg <= 1'b0;
    end

    // Destination domain:
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_ready_reg <= 1'b0;
        else if (dst_ready_i && src_valid_sync)
            src_ready_reg <= 1'b1;
        else if (!src_valid_sync)
            src_ready_reg <= 1'b0;
    end

    // Assign outputs
    assign dst_valid_o = dst_valid_reg;
    assign src_ready_o = src_ready_reg;

endmodule
