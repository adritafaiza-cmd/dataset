```verilog
`timescale 1ns/1ps

module async_fifo
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        output wire             wfull,
        output wire             awfull,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output wire [DSIZE-1:0] rdata,
        output wire             rempty,
        output wire             arempty
    );

    localparam GRANT_WIDTH = ASIZE;
    localparam GRANT_MASK = (1 << GRANT_WIDTH) - 1;

    // Write Domain Signals
    reg [GRANT_WIDTH-1:0] wr_ptr;
    reg [GRANT_WIDTH-1:0] wr_gray;
    reg [GRANT_WIDTH-1:0] wr_next_gray;
    reg [GRANT_WIDTH-1:0] wr_next_ptr;
    reg [GRANT_WIDTH-1:0] wr_count;
    reg [GRANT_WIDTH-1:0] wr_count_next;
    reg [GRANT_WIDTH-1:0] wr_count_next_next; // Used for full detection logic stability

    // Read Domain Signals
    reg [GRANT_WIDTH-1:0] rd_ptr;
    reg [GRANT_WIDTH-1:0] rd_gray;
    reg [GRANT_WIDTH-1:0] rd_next_gray;
    reg [GRANT_WIDTH-1:0] rd_next_ptr;
    reg [GRANT_WIDTH-1:0] rd_count;
    reg [GRANT_WIDTH-1:0] rd_count_next;
    reg [GRANT_WIDTH-1:0] rd_count_next_next;

    // Cross-domain pointers (Gray encoded for CDC safety)
    wire [GRANT_WIDTH-1:0] rd_gray_cross;
    wire [GRANT_WIDTH-1:0] wr_gray_cross;

    // Cross-domain counters (for full/empty detection)
    wire [GRANT_WIDTH-1:0] rd_count_cross;
    wire [GRANT_WIDTH-1:0] wr_count_cross;

    // Memory Instance
    // Depth = 2^ASIZE
    reg [DSIZE-1:0] mem [0 : (1 << ASIZE) - 1];

    // --- Write Domain Logic ---

    // Reset Logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            wr_count <= 0;
            wr_gray <= 0;
        end else begin
            // Pointer update
            if (winc && !wfull) begin
                wr_next_ptr <= wr_ptr + 1'b1;
                // Calculate next gray code directly from next pointer to avoid race
                wr_next_gray <= wr_next_ptr ^ (wr_next_ptr >> 1);
                wr_count_next <= wr_count + 1'b1;
            end else begin
                wr_next_ptr <= wr_ptr;
                wr_next_gray <= wr_gray;
                wr_count_next <= wr_count;
            end
        end
    end

    // Register the next state to current state on clock edge
    always @(posedge wclk) begin
        wr_ptr <= wr_next_ptr;
        wr_gray <= wr_next_gray;
        wr_count <= wr_count_next;
    end

    // Full Detection
    // Full when write count == depth - 1
    // We use the cross-domain read count to determine if we are truly full
    // Full = (wr_count == depth - 1) AND (rd_count_cross == 0)
    // However, standard Gray code FIFO full detection:
    // Full when wr_gray == rd_gray AND wr_count == depth - 1
    // But since rd_gray is cross-domain, we rely on the counter comparison.
    // Safe Full: wr_count == depth - 1 AND rd_count_cross == 0
    // Actually, the most robust method for full is:
    // Full when (wr_count == depth - 1) AND (rd_count_cross == 0)
    // Let's refine: 
    // If we write when full, we lose data. So we must ensure we don't write if full.
    // Full condition: wr_count == depth - 1 AND rd_count_cross == 0.
    // Wait, rd_count_cross is the read count seen in write domain.
    // If wr_count == depth - 1 and rd_count_cross == 0, then FIFO is full.
    
    // Let's implement the standard Gray code full logic:
    // Full = (wr_count == depth - 1) && (rd_count_cross == 0)
    // This works because if rd_count_cross is not 0, there is at least one item read.
    // If wr_count is max, and rd_count is > 0, then it's not full.
    // If wr_count is max, and rd_count is 0, then it is full.
    
    // To avoid metastability on the comparison, we can use the Gray code pointers directly
    // Full = (wr_gray == rd_gray_cross) && (wr_count == depth - 1)
    // This is the classic Gray code FIFO full detection.
    
    // Generate wfull
    // wfull is high when FIFO is full.
    // We need to compare wr_gray with the read pointer seen in write domain.
    // rd_gray_cross is the read pointer (Gray) as seen in write domain.
    // If wr_gray == rd_gray_cross, it means the write pointer has caught up to the read pointer.
    // Additionally, we must check the count to distinguish between empty and full when pointers align.
    // When pointers align:
    //   If count == 0 -> Empty
    //   If count == depth - 1 -> Full
    
    // However, there is a nuance: when pointers cross, the count might be unstable for one cycle.
    // Standard approach:
    // wfull = (wr_gray == rd_gray_cross) && (wr_count == depth - 1);
    // rempty = (wr_gray == rd_gray_cross) && (rd_count_cross == 0);
    
    // Let's assign wfull and rempty based on this logic.
    // Note: wr_count is the write domain count. rd_count_cross is the read domain count seen in write domain.
    
    // wfull: High when full
    // Condition: Write pointer == Read pointer AND Count == Depth - 1
    // We use the cross-domain read gray code.
    assign wfull = (wr_gray == rd_gray_cross) && (wr_count == (1 << ASIZE) - 1);

    // awfull: Almost full (e.g., depth - 2)
    // Condition: Write pointer == Read pointer AND Count == Depth - 2
    assign awfull = (wr_gray == rd_gray_cross) && (wr_count == (1 << ASIZE) - 2);

    // Write Data Logic
    // Only write if winc is high and wfull is low.
    // Since wfull is an output, we can use it in the combinational logic for the write enable,
    // but to be safe against propagation delay, we check the condition inside the always block
    // or use the winc signal gated by the full condition.
    // The requirement says: "A write is accepted ... when winc is high and wfull is low."
    // Since wfull is registered in the write domain, we can use it directly in the write enable logic.
    
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem[wr_ptr] <= 0;
        end else if (winc && !wfull) begin
            mem[wr_ptr] <= wdata;
        end
    end

    // --- Read Domain Logic ---

    // Reset Logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
            rd_count <= 0;
            rd_gray <= 0;
        end else begin
            if (rinc && !rempty) begin
                rd_next_ptr <= rd_ptr + 1'b1;
                rd_next_gray <= rd_next_ptr ^ (rd_next_ptr >> 1);
                rd_count_next <= rd_count - 1'b1;
            end else begin
                rd_next_ptr <= rd_ptr;
                rd_next_gray <= rd_gray;
                rd_count_next <= rd_count;
            end
        end
    end

    // Register the next state to current state on clock edge
    always @(posedge rclk) begin
        rd_ptr <= rd_next_ptr;
        rd_gray <= rd_next_gray;
        rd_count <= rd_count_next;
    end

    // Empty Detection
    // rempty: High when FIFO is empty.
    // Condition: Read pointer == Write pointer AND Count == 0
    // We use the cross-domain write gray code.
    assign rempty = (rd_gray == wr_gray_cross) && (rd_count == 0);

    // arempty: Almost empty (e.g., count == 1)
    // Condition: Read pointer == Write pointer AND Count == 1
    assign arempty = (rd_gray == wr_gray_cross) && (rd_count == 1);

    // Read Data Logic
    // rdata is the data at rd_ptr.
    // If FALLTHROUGH is TRUE, rdata should present the current oldest unread word without requiring an additional registered-read cycle.
    // This means rdata should be combinational with respect to the memory read, but the memory address (rd_ptr) is registered.
    // However, the requirement says: "`rdata` is one read-clock sample." and "FALLTHROUGH does not select a combinational memory read."
    // This implies that even in FALLTHROUGH mode, the data is registered once (sampled on rclk) to ensure CDC safety and stability.
    // The distinction of "fall-through" usually refers to whether the data is updated immediately after a read or waits for the next read cycle.
    // In standard FIFOs:
    //   - Normal: rdata is updated on the read clock edge when rinc is asserted.
    //   - Fall-through: rdata is updated immediately (combinational) when the pointer moves? 
    //   But the prompt says: "FALLTHROUGH does not select a combinational memory read."
    //   This suggests that in FALLTHROUGH mode, we still register the data, but perhaps the logic for updating is different?
    //   Re-reading: "When FALLTHROUGH equals "TRUE", rdata presents the current oldest unread word without requiring an additional registered-read cycle."
    //   This usually means that if you read, the data is available immediately for the next cycle without waiting for a new 'rinc'.
    //   Actually, the standard interpretation of "Fall-through" in FIFOs is that the data output is valid as soon as the pointer advances, and it stays valid until overwritten or until the next read.
    //   However, the constraint "FALLTHROUGH does not select a combinational memory read" is key. It means we cannot do `assign rdata = mem[rd_ptr];`.
    //   We must register the data.
    //   So, in both modes, we register the data. The difference might be in how the pointer update interacts with the data output.
    //   Let's interpret "Fall-through" as: The data is updated on the read clock edge regardless of rinc, OR the data is updated immediately after the pointer update.
    //   Given "rdata is one read-clock sample", it implies a registered output.
    //   Let's implement a standard registered read.
    //   If FALLTHROUGH is TRUE, we might want to update rdata even if rinc is low, as long as the pointer has moved? 
    //   No, the pointer moves on rinc. So if rinc is low, pointer doesn't move.
    //   Perhaps the requirement means: In FALLTHROUGH mode, the data is valid immediately after the read operation completes (within the same cycle), whereas in non-fall-through, it might wait?
    //   Actually, a common implementation of Fall-through is:
    //   rdata <= mem[rd_ptr]; (registered)
    //   This happens every clock cycle.
    //   In non-fall-through, maybe rdata is only updated when rinc is high?
    //   Let's stick to the most robust CDC-compliant method: Register the data on every clock edge.
    //   The "Fall-through" behavior is often achieved by ensuring that the data is valid as soon as the pointer advances.
    //   Since the pointer advances on rinc, the data will naturally be valid in the next cycle.
    //   The phrase "without requiring an additional registered-read cycle" might imply that we don't need a separate "read data" control signal separate from the pointer increment.
    //   Let's assume standard registered read: rdata is updated on rclk.
    
    // To strictly follow "FALLTHROUGH does not select a combinational memory read", we must use an always block.
    // To satisfy "presents the current oldest unread word", we update rdata on every clock edge.
    // If FALLTHROUGH is FALSE, maybe we only update on rinc? 
    // But if we only update on rinc, and rinc is low, rdata holds old value. That's fine.
    // If FALLTHROUGH is TRUE, we update every cycle? 
    // Let's implement: 
    // If FALLTHROUGH: Update rdata every clock cycle (always).
    // If !FALLTHROUGH: Update rdata only when rinc is high (and not rempty).
    // This matches the description: "without requiring an additional registered-read cycle" implies the read cycle IS the update cycle.
    
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else if (FALLTHROUGH) begin
            // Always update to the current head
            rdata <= mem[rd_ptr];
        end else begin
            // Update only on read request
            if (rinc && !rempty) begin
                rdata <= mem[rd_ptr];
            end
        end
    end

    // --- Cross Domain Pointers (Gray Code) ---
    // Write domain sends Gray encoded pointer to Read domain
    assign wr_gray_cross = wr_gray;

    // Read domain sends Gray encoded pointer to Write domain
    assign rd_gray_cross = rd_gray;

    // Cross Domain Counters
    // Write domain needs to know the read count to detect full/empty accurately.
    // We use a Gray-to-Binary converter for the read pointer to get the count, 
    // but comparing Gray pointers is safer for full/empty detection.
    // However, for the count comparison (wr_count vs rd_count_cross), we need the binary value of the read pointer.
    // We can generate the binary read count in the write domain using a Gray-to-Binary converter.
    
    // Gray to Binary Converter for Read Pointer (in Write Domain)
    // rd_gray_cross is the input.
    // We need rd_count_cross which is the binary value of rd_gray_cross.
    // Since ASIZE is small (parameter), we can unroll or use a generic converter.
    // Let's use a generic Gray to Binary converter.
    
    // rd_count_cross calculation:
    // bin[i] = gray[i] ^ bin[i+1] (for i from 0 to N-1), with bin[N] = 0.
    // We can implement this in the write domain logic.
    
    // Similarly, we need wr_count_cross for the read domain?
    // Actually, the standard Gray FIFO uses:
    // Full: wr_gray == rd_gray AND wr_count == depth - 1
    // Empty: wr_gray == rd_gray AND rd_count == 0
    // Here, wr_count is local to write domain. rd_count is local to read domain.
    // To compare wr_count and rd_count, we need to cross them.
    // But the standard logic above (wr_gray == rd_gray) handles the pointer alignment.
    // The count check (wr_count == depth - 1) is local to write domain.
    // The count check (rd_count == 0) is local to read domain.
    // So we don't necessarily need to cross the counts for the basic full/empty logic if we use the Gray pointer comparison.
    // However, the prompt asks for "transferred multi-bit data must remain coherent".
    // The pointers are multi-bit. We are transferring them as Gray codes.
    // The counts are used for the "Almost Full/Empty" signals.
    // awfull: wr_count == depth - 2. This is local to write domain.
    // arempty: rd_count == 1. This is local to read domain.
    // So we don't need to cross the counts for these signals either.
    // The only thing we need to cross is the pointers to detect the alignment (wr_gray == rd_gray).
    
    // Wait, is the logic `wr_gray == rd_gray` sufficient for full/empty?
    // Yes, because when pointers align, the count tells us the state.
    // If count == 0 -> Empty.
    // If count == depth - 1 -> Full.
    // This is the standard Gray code FIFO algorithm.
    
    // One detail: The prompt mentions "Reset release must be safe".
    // Both domains reset to 0. So pointers align at 0.
    // wr_count = 0, rd_count = 0.
    // wr_gray = 0, rd_gray = 0.
    // rempty = (0==0) && (0==0) -> High. Correct.
    // wfull = (0==0) && (0 == depth-1) -> Low (assuming depth > 1). Correct.
    
    // What if ASIZE is 0? 
    // If ASIZE=0, depth=1.
    // wr_count max = 0.
    // wfull = (0==0) && (0==0) -> High.
    // rempty = (0==0) && (0==0) -> High.
    // This creates a conflict: Full and Empty at the same time?
    // Usually ASIZE >= 1. If ASIZE=0, depth=1.
    // If depth=1, it can hold 1 item.
    // When empty: count=0. rempty=1.
    // When full: count=0 (since max count is 0). wfull=1.
    // So for depth=1, wfull and rempty are both high when count=0?
    // No. 
    // Empty: count=0. rempty = (ptr_align) && (count==0).
    // Full: count=0 (max). wfull = (ptr_align) && (count==0).
    // So for depth=1, wfull and rempty are identical.
    // This is a known edge case for depth=1.
    // Usually, depth=1 is not recommended for FIFOs.
    // We assume ASIZE >= 1 for proper operation.
    // If ASIZE=0 is passed, the behavior is undefined by standard FIFO specs, but the code will produce wfull=rempty.
    // We will proceed with the standard implementation.

    // Cross Domain Counter Transfer (Optional but good for debugging or specific full logic variations)
    // The standard Gray FIFO logic does not require crossing the binary counts if we use the Gray pointer comparison.
    // However, some designs cross the binary counts to avoid the Gray pointer comparison latency or for specific full/empty definitions.
    // Given the requirement "transferred multi-bit data must remain coherent", crossing the pointers (Gray) is the standard way.
    // Crossing the binary counts is also possible but requires a Gray-to-Binary converter in the other domain.
    // Since we already have the Gray pointers, we use them for alignment.
    
    // Let's double check the "Almost Full/Empty" logic.
    // awfull: wr_count == depth - 2.
    // This is purely local to the write domain. It doesn't depend on the read domain state directly, 
    // except that if the FIFO is actually full, we shouldn't be in "almost full" state?
    // No, "Almost Full" is a warning signal. It means "We are close to full".
    // If the FIFO is full, wfull is high. awfull should be low.
    // If wr_count == depth - 2, it is almost full.
    // But if the read domain has read items, the effective count is lower.
    // The standard definition of awfull is based on the write count relative to the depth, 
    // OR relative to the current free space.
    // If we define awfull as "Write count == depth - 2", then even if the FIFO is empty (read count = depth - 2), 
    // awfull would be high. This is incorrect.
    // awfull should indicate that the FIFO is approaching full, i.e., free space is low.
    // Free space = Depth - (wr_count - rd_count_cross).
    // So awfull should be high when Free Space == 2.
    // Free Space == 2 => wr_count - rd_count_cross == Depth - 2.
    // This requires crossing the binary counts.
    
    // Let's re-evaluate the requirement for awfull and arempty.
    // "awfull indicates that the FIFO is approaching full"
    // "arempty indicates that it is approaching empty"
    // This implies they are relative to the current data level, not just the write pointer.
    // Therefore, we MUST cross the binary counts to calculate the actual free space.
    
    // Revised Plan:
    // 1. Cross the Read Pointer (Gray) to Write Domain to get rd_gray_cross.
    // 2. Convert rd_gray_cross to Binary in Write Domain -> rd_count_cross.
    // 3. Calculate Free Space = wr_count - rd_count_cross.
    // 4. wfull = (Free Space == 0).
    // 5. awfull = (Free Space == 1). (Or 2, depending on definition, usually 1 or 2).
    //    Let's assume awfull means "1 slot free" or "2 slots free". 
    //    Standard: awfull = (wr_count - rd_count_cross == 1).
    //    But wait, if Free Space is 0, wfull is high. awfull should be low.
    //    If Free Space is 1, wfull is low, awfull is high.
    //    So awfull = (Free Space == 1).
    //    Similarly, arempty = (Occupied Space == 1) => (rd_count_cross - wr_count == -1)? No.
    //    Occupied = rd_count_cross - wr_count? No.
    //    Occupied = (wr_count - rd_count_cross).
    //    arempty = (Occupied == 1).
    
    // Let's implement the Gray-to-Binary converter in the Write Domain to get rd_count_cross.
    // And in the Read Domain to get wr_count_cross?
    // Actually, for arempty, we need to know if there is 1 item left.
    // Items left = Occupied = wr_count - rd_count_cross.
    // So we need wr_count (local) and rd_count_cross (crossed).
    // For awfull, we need Free Space = Depth - Occupied = Depth - (wr_count - rd_count_cross).
    // So we need wr_count and rd_count_cross.
    
    // Do we need wr_count_cross in the Read Domain?
    // rempty = (Occupied == 0) => (wr_count - rd_count_cross == 0).
    // This uses wr_count_cross (crossed to read domain) and rd_count (local).
    // arempty = (Occupied == 1) => (wr_count_cross - rd_count == 1).
    // So yes, we need to cross the binary counts in both directions.
    
    // Implementation of Gray to Binary Converter:
    // Input: gray [N-1:0]
    // Output: bin [N-1:0]
    // bin[N-1] = gray[N-1]
    // bin[i] = gray[i] ^ bin[i+1]
    
    // Since ASIZE is a parameter, we can instantiate a generic converter or write a loop.
    // Verilog doesn't support loops in continuous assignment or procedural blocks for bit slicing easily without generate.
    // We will use a generate block to create the converter.
    
    // Write Domain: Convert rd_gray_cross to rd_count_cross
    // Read Domain: Convert wr_gray_cross to wr_count_cross
    
    // Note: The pointers are Gray encoded.
    // We need to be careful with the reset.
    // On reset, gray=0, bin=0.
    
    // Let's define the converter logic.
    
    // Write Domain Converter (rd_gray_cross -> rd_count_cross)
    genvar i;
    generate
        for (i = 0; i < ASIZE; i = i + 1) begin : gray_to_bin_write
            assign rd_count_cross[i] = rd_gray_cross[i] ^ rd_count_cross[i+1];
        end
    endgenerate
    // Handle the MSB (i = ASIZE-1)
    // The loop above goes 0 to ASIZE-1.
    // For i = ASIZE-1: rd_count_cross[ASIZE-1] = rd_gray_cross[ASIZE-1] ^ rd_count_cross[ASIZE].
    // We need to define rd_count_cross[ASIZE] = 0.
    // We can add a specific assignment for the MSB or use a 1-bit wider vector.
    // Let's use a 1-bit wider vector for the intermediate calculation.
    
    // Re-doing the converter logic properly:
    // We need rd_count_cross[ASIZE-1:0].
    // rd_count_cross[ASIZE-1] = rd_gray_cross[ASIZE-1] ^ 0;
    // rd_count_cross[i] = rd_gray_cross[i] ^ rd_count_cross[i+1];
    
    // Let's use a generate block that handles the MSB separately or uses a wider temp wire.
    
    // Actually, a simpler way for small ASIZE is to unroll or use a specific structure.
    // But since ASIZE is a parameter, generate is best.
    
    // Let's refine the converter:
    // We need a wire [ASIZE:0] for the temporary calculation where bit ASIZE is 0.
    // Then slice [ASIZE-1:0].
    
    wire [ASIZE:0] rd_count_cross_temp;
    assign rd_count_cross_temp[ASIZE] = 1'b0;
    generate
        for (i = 0; i < ASIZE; i = i + 1) begin : gray_to_bin_write
            assign rd_count_cross_temp[i] = rd_gray_cross[i] ^ rd_count_cross_temp[i+1];
        end
    endgenerate
    assign rd_count_cross = rd_count_cross_temp[ASIZE-1:0];

    // Read Domain Converter (wr_gray_cross -> wr_count_cross)
    wire [ASIZE:0] wr_count_cross_temp;
    assign wr_count_cross_temp[ASIZE] = 1'b0;
    generate
        for (i = 0; i < ASIZE; i = i + 1) begin : gray_to_bin_read
            assign wr_count_cross_temp[i] = wr_gray_cross[i] ^ wr_count_cross_temp[i+1];
        end
    endgenerate
    assign wr_count_cross = wr_count_cross_temp[ASIZE-1:0];

    // Now update the Full/Empty logic with the crossed counts.
    
    // Occupied = wr_count - rd_count_cross
    // Full: Occupied == Depth - 1 => wr_count - rd_count_cross == (1<<ASIZE) - 1
    // Empty: Occupied == 0 => wr_count - rd_count_cross == 0
    
    // However, subtraction can be tricky with unsigned numbers if we don't handle borrows.
    // Alternative: Full when (wr_gray == rd_gray_cross) && (wr_count == depth - 1).
    // This is the standard Gray code method and avoids subtraction.
    // Why did I think we need crossed counts for awfull/arempty?
    // Because "approaching full" depends on the current occupancy.
    // If we use the standard method:
    // wfull = (wr_gray == rd_gray_cross) && (wr_count == depth - 1);
    // This is correct.
    // awfull: When is the FIFO "almost full"?
    // Usually, awfull is asserted when there is only 1 or 2 slots left.
    // Slots left = Depth - Occupied.
    // Occupied = wr_count - rd_count_cross.
    // So Slots left = Depth - (wr_count - rd_count_cross).
    // We need to calculate this.
    // But wait, if we use the standard Gray method for wfull, we rely on pointer alignment.
    // For awfull, we can use the same logic:
    // awfull = (wr_gray == rd_gray_cross) && (wr_count == depth - 2);
    // Is this correct?
    // If wr_gray == rd_gray_cross, it means the pointers are aligned.
    // If wr_count == depth - 2, it means the write pointer is at depth-2.
    // Since pointers are aligned, the read pointer is also at depth-2.
    // So Occupied = (depth-2) - (depth-2) = 0? No.
    // If pointers are aligned, Occupied = wr_count - rd_count_cross.
    // But rd_count_cross is the binary value of rd_gray_cross.
    // If wr_gray == rd_gray, then wr_count and rd_count_cross are NOT necessarily equal.
    // Example: Depth=4.
    // State: Write 3, Read 3. Aligned. Occupied = 0.
    // State: Write 3, Read 2. Not aligned. Occupied = 1.
    // State: Write 3, Read 1. Not aligned. Occupied = 2.
    // State: Write 3, Read 0. Not aligned. Occupied = 3 (Full).
    // So if pointers are aligned, Occupied is 0.
    // Wait, the standard Gray FIFO logic is:
    // Full when (wr_gray == rd_gray) AND (wr_count == depth - 1).
    // Empty when (wr_gray == rd_gray) AND (rd_count == 0).
    // In these cases, the pointers are aligned.
    // What about awfull?
    // awfull should be high when Occupied == Depth - 2.
    // This does NOT require pointer alignment.
    // So we MUST use the crossed counts for awfull and arempty.
    
    // Let's calculate Occupied = wr_count - rd_count_cross.
    // We need to handle the case where wr_count < rd_count_cross (should not happen if logic is correct, but mathematically possible in subtraction).
    // Actually, Occupied is always >= 0.
    // We can use a subtractor.
    
    // awfull: Occupied == Depth - 2
    // arempty: Occupied == 1
    
    // Let's implement the subtraction.
    // Since we are in Verilog, we can use a subtractor or just compare.
    // Occupied = wr_count - rd_count_cross.
    // We can check if (wr_count - rd_count_cross == Depth - 2).
    // But subtraction of unsigned numbers wraps around.
    // If wr_count < rd_count_cross, the result is large (wrapped).
    // However, logically, Occupied cannot be negative.
    // So we can assume wr_count >= rd_count_cross.
    // But to be safe, we can check:
    // awfull = (wr_count - rd_count_cross == Depth - 2);
    // This works if we treat the result as unsigned.
    // If wr_count < rd_count_cross, the result is (wr_count - rd_count_cross + Depth).
    // Since Depth = 2^ASIZE, and wr_count, rd_count_cross < Depth.
    // If wr_count < rd_count_cross, then wr_count - rd_count_cross + Depth >= Depth.
    // Depth - 2 is much smaller than Depth.
    // So the comparison will fail, which is correct (Occupied cannot be negative).
    // So simple subtraction works.
    
    // Let's define the signals.
    wire [ASIZE-1:0] occupied;
    assign occupied = wr_count - rd_count_cross;
    
    // wfull: Occupied == Depth - 1
    // awfull: Occupied == Depth - 2
    // rempty: Occupied == 0
    // arempty: Occupied == 1
    
    // Note: For wfull, the standard Gray method is more robust against metastability during pointer crossing.
    // But the subtraction method is also valid if implemented correctly.
    // Let's stick to the standard Gray method for wfull/rempty to ensure CDC safety during pointer crossing.
    // For awfull/arempty, we use the subtraction.
    
    // Re-evaluating wfull/rempty with subtraction:
    // wfull = (occupied == Depth - 1);
    // rempty = (occupied == 0);
    // This is simpler and consistent.
    // Does it pass CDC?
    // occupied is calculated from wr_count (local) and rd_count_cross (crossed).
    // rd_count_cross is the binary value of the read pointer seen in write domain.
    // The read pointer changes on rclk. The binary value changes on rclk.
    // The write domain samples this binary value on wclk?
    // No, rd_count_cross is a wire driven by the write domain logic (the converter).
    // The converter takes rd_gray_cross (which is a wire from read domain) and produces rd_count_cross.
    // rd_gray_cross is the Gray pointer from read domain.
    // The read pointer changes on rclk.
    // The write domain sees the read pointer asynchronously.
    // The converter logic is combinational.
    // So rd_count_cross is a combinational function of the asynchronous rd_gray_cross.
    // This is a CDC hazard!
    // We cannot have a combinational converter for the crossed pointer.
    // The crossed pointer MUST be registered in the receiving domain.
    
    // Correction:
    // The standard Gray FIFO does NOT cross the binary count.
    // It crosses the Gray pointer.
    // Full/Empty detection is done using the Gray pointer alignment and the LOCAL count.
    // wfull = (wr_gray == rd_gray_cross) && (wr_count == depth - 1);
    // rempty = (wr_gray == rd_gray_cross) && (rd_count == 0);
    // This is the ONLY safe way without crossing the binary count.
    // Crossing the binary count requires registering the binary count in the other domain, which is complex and error-prone.
    
    // So, for awfull and arempty, we must also use the Gray pointer alignment method.
    // awfull: When is the FIFO almost full?
    // It is almost full when the write pointer is close to the read pointer, but not yet aligned?
    // No, "Almost Full" usually means "1 or 2 slots left".
    // Slots left = Depth - Occupied.
    // Occupied = wr_count - rd_count_cross.
    // We can't calculate Occupied safely across domains.
    // However, we can approximate awfull using the Gray pointer distance?
    // No, Gray code distance is not linear.
    
    // Alternative approach for awfull/arempty:
    // Use the standard Gray method for wfull/rempty.
    // For awfull/arempty, we can use the same logic but with a threshold on the count?
    // No, because the count is local.
    // If we use the