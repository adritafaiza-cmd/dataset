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

    // Source domain signals
    reg src_valid_reg;
    reg src_ack_reg;

    // Destination domain signals
    reg dst_valid_reg;
    reg dst_ack_reg;

    // Synchronizers for crossing from source to destination
    reg [1:0] src_valid_sync;
    reg [1:0] src_ack_sync;

    // Synchronizers for crossing from destination to source
    reg [1:0] dst_valid_sync;
    reg [1:0] dst_ack_sync;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_reg <= 1'b0;
            src_ack_reg   <= 1'b0;
        end else begin
            // Four-phase handshake in source domain
            // src_valid_reg goes high when src_valid_i is high and src_ack_reg is low
            // src_ack_reg goes high when dst_ack_sync[1] is high (ack from dest)
            // src_valid_reg goes low when src_ack_reg is high (after ack received)
            // src_ack_reg goes low when src_valid_reg is low (after valid deasserted)
            
            if (src_valid_i && !src_ack_reg) begin
                src_valid_reg <= 1'b1;
            end else if (src_ack_reg) begin
                src_valid_reg <= 1'b0;
            end
            
            if (dst_ack_sync[1] && !src_valid_reg) begin
                src_ack_reg <= 1'b1;
            end else if (!src_valid_reg && !dst_ack_sync[1]) begin
                src_ack_reg <= 1'b0;
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 1'b0;
            dst_ack_reg   <= 1'b0;
        end else begin
            // Four-phase handshake in destination domain
            // dst_valid_reg goes high when src_valid_sync[1] is high and dst_ack_reg is low
            // dst_ack_reg goes high when dst_ready_i is high and dst_valid_reg is high
            // dst_valid_reg goes low when dst_ack_reg is high (after ack sent)
            // dst_ack_reg goes low when dst_valid_reg is low (after valid deasserted)
            
            if (src_valid_sync[1] && !dst_ack_reg) begin
                dst_valid_reg <= 1'b1;
            end else if (dst_ack_reg) begin
                dst_valid_reg <= 1'b0;
            end
            
            if (dst_ready_i && dst_valid_reg) begin
                dst_ack_reg <= 1'b1;
            end else if (!dst_valid_reg && !dst_ready_i) begin
                dst_ack_reg <= 1'b0;
            end
        end
    end

    // Synchronizer for src_valid to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync <= 2'b00;
        end else begin
            src_valid_sync <= {src_valid_sync[0], src_valid_reg};
        end
    end

    // Synchronizer for src_ack to destination domain (not needed for this design, but keep for completeness)
    // Actually, we don't need src_ack in destination domain for the four-phase protocol as implemented.
    // Let me reconsider the protocol.

    // Let me redo this with a cleaner four-phase handshake.
    // 
    // Four-phase handshake:
    // 1. Source asserts valid (src_valid_reg = 1)
    // 2. Destination sees valid, asserts ready (dst_ready_i = 1)
    // 3. Source sees ready, deasserts valid (src_valid_reg = 0)
    // 4. Destination sees valid deasserted, deasserts ready (dst_ready_i = 0)
    //
    // But in this design, dst_ready_i is an input, not something we control.
    // So the protocol is:
    // - src_valid_i is the source's valid signal
    // - src_ready_o is the source's ready signal (from destination)
    // - dst_valid_o is the destination's valid signal (from source)
    // - dst_ready_i is the destination's ready signal
    //
    // Four-phase valid/ready handshake:
    // Phase 1: src_valid_i rises, src_ready_o is low
    // Phase 2: dst_valid_o rises (after sync), dst_ready_i rises
    // Phase 3: src_ready_o rises (after sync of dst_ready), src_valid_i falls
    // Phase 4: dst_valid_o falls (after sync of src_valid falling), dst_ready_i falls
    //
    // Let me implement this properly.

    // Source domain: track valid and ready
    // dst_valid_o is driven from source domain based on src_valid_i
    // src_ready_o is driven from source domain based on synchronized dst_ready_i

    // Synchronize dst_ready_i to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_sync <= 2'b00;
        end else begin
            dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
        end
    end

    // Synchronize src_valid_i to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync <= 2'b00;
        end else begin
            src_valid_sync <= {src_valid_sync[0], src_valid_i};
        end
    end

    // Source domain: generate src_ready_o
    // src_ready_o should be high when the destination is ready and we're not in the middle of a transfer
    // For four-phase: src_ready_o goes high after dst_ready_i is seen, and goes low after src_valid_i goes low
    
    // Destination domain: generate dst_valid_o
    // dst_valid_o should be high when src_valid_i is seen, and goes low after dst_ready_i is seen

    // Let me use a state machine approach for clarity.

    // Source domain state: IDLE, WAIT_READY, WAIT_VALID_LOW
    // Destination domain state: IDLE, WAIT_READY, WAIT_VALID_LOW

    // Actually, let me simplify. The four-phase handshake with valid/ready:
    // 
    // src_valid_i: asserted by source
    // src_ready_o: asserted by destination (synchronized to source)
    // dst_valid_o: asserted by source (synchronized to destination)  
    // dst_ready_i: asserted by destination
    //
    // The handshake:
    // 1. src_valid_i goes high
    // 2. dst_valid_o goes high (after sync)
    // 3. dst_ready_i goes high
    // 4. src_ready_o goes high (after sync)
    // 5. src_valid_i goes low
    // 6. dst_valid_o goes low (after sync)
    // 7. dst_ready_i goes low
    // 8. src_ready_o goes low (after sync)
    //
    // So src_ready_o is essentially dst_ready_i synchronized to source domain
    // And dst_valid_o is essentially src_valid_i synchronized to destination domain
    //
    // But we need to ensure the four-phase ordering. Let me think about this more carefully.
    //
    // In a standard four-phase handshake:
    // - The sender asserts valid
    // - The receiver asserts ready
    // - The sender deasserts valid
    // - The receiver deasserts ready
    //
    // So:
    // - src_valid_i is the sender's valid
    // - src_ready_o is the receiver's ready (from destination, synced to source)
    // - dst_valid_o is the sender's valid (from source, synced to destination)
    // - dst_ready_i is the receiver's ready
    //
    // The key insight: src_ready_o should only be high when dst_ready_i is high AND we're in the right phase.
    // Similarly, dst_valid_o should only be high when src_valid_i is high AND we're in the right phase.
    //
    // For a simple implementation:
    // - dst_valid_o = src_valid_i synchronized to dst domain
    // - src_ready_o = dst_ready_i synchronized to src domain
    //
    // This naturally gives four-phase behavior because:
    // - When src_valid_i rises, dst_valid_o rises after sync
    // - When dst_ready_i rises, src_ready_o rises after sync
    // - When src_valid_i falls, dst_valid_o falls after sync
    // - When dst_ready_i falls, src_ready_o falls after sync

    // Synchronize dst_ready_i to source domain
    reg [1:0] dst_ready_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_sync <= 2'b00;
        end else begin
            dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
        end
    end

    // Synchronize src_valid_i to destination domain
    reg [1:0] src_valid_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync <= 2'b00;
        end else begin
            src_valid_sync <= {src_valid_sync[0], src_valid_i};
        end
    end

    // Outputs
    assign src_ready_o = dst_ready_sync[1];
    assign dst_valid_o = src_valid_sync[1];

endmodule
