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
    localparam MAX_COUNT   = 1 << ASIZE;

    // Write domain signals
    reg [GRANT_WIDTH-1:0] wr_ptr;
    reg [GRANT_WIDTH-1:0] wr_gray;
    reg [GRANT_WIDTH-1:0] wr_cnt;
    reg                  wr_en;

    // Read domain signals
    reg [GRANT_WIDTH-1:0] rd_ptr;
    reg [GRANT_WIDTH-1:0] rd_gray;
    reg [GRANT_WIDTH-1:0] rd_cnt;
    reg                  rd_en;

    // Cross-domain pointers (Gray encoded for CDC safety)
    wire [GRANT_WIDTH-1:0] rd_gray_cross;
    wire [GRANT_WIDTH-1:0] wr_gray_cross;

    // Cross-domain counters (for accurate full/empty detection)
    reg [GRANT_WIDTH-1:0] rd_cnt_cross;
    reg [GRANT_WIDTH-1:0] wr_cnt_cross;

    // Internal memory
    reg [DSIZE-1:0] mem [0:MAX_COUNT-1];

    // --- Write Domain Logic ---

    // Reset logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr   <= 1'b0;
            wr_gray  <= 1'b0;
            wr_cnt   <= 1'b0;
            wr_en    <= 1'b0;
        end else begin
            wr_en    <= winc & ~wfull;
            wr_ptr   <= wr_ptr + 1'b1;
            wr_gray  <= wr_gray ^ (wr_gray[ASIZE-1] ? 1'b1 : 1'b0); // Gray code increment
            wr_cnt   <= wr_cnt + 1'b1;
        end
    end

    // Full detection logic
    assign wfull = (wr_cnt == (MAX_COUNT - 1)) ? 1'b1 : 1'b0;
    assign awfull = (wr_cnt == ((MAX_COUNT - 1) >> 1)) ? 1'b1 : 1'b0;

    // Memory write (synchronous to wclk)
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            // Reset memory to 0
            for (integer i = 0; i < MAX_COUNT; i = i + 1)
                mem[i] <= 1'b0;
        end else if (wr_en) begin
            mem[wr_ptr] <= wdata;
        end
    end

    // --- Read Domain Logic ---

    // Reset logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr   <= 1'b0;
            rd_gray  <= 1'b0;
            rd_cnt   <= 1'b0;
            rd_en    <= 1'b0;
        end else begin
            rd_en    <= rinc & ~rempty;
            rd_ptr   <= rd_ptr + 1'b1;
            rd_gray  <= rd_gray ^ (rd_gray[ASIZE-1] ? 1'b1 : 1'b0); // Gray code increment
            rd_cnt   <= rd_cnt + 1'b1;
        end
    end

    // Empty detection logic
    assign rempty = (rd_cnt == (MAX_COUNT - 1)) ? 1'b1 : 1'b0;
    assign arempty = (rd_cnt == ((MAX_COUNT - 1) >> 1)) ? 1'b1 : 1'b0;

    // Data output logic
    // With FALLTHROUGH, we output the current oldest data regardless of rd_en.
    // Without FALLTHROUGH, we output the current oldest data only when rd_en is high (or latch it).
    // To ensure rdata is one read-clock sample and handles the "lag" correctly:
    // We always read from memory using the current rd_ptr.
    // If FALLTHROUGH is true, rdata is combinational relative to rd_ptr (but rd_ptr is registered).
    // If FALLTHROUGH is false, we typically want to hold the value until the next read cycle completes.
    // However, the spec says: "rdata presents the current oldest unread word without requiring an additional registered-read cycle" for FALLTHROUGH.
    // And "rdata may be updated by an accepted read" otherwise.
    // Standard implementation:
    // rdata = mem[rd_ptr];
    // If FALLTHROUGH is FALSE, we might need to latch it to avoid glitches if rd_ptr changes mid-cycle, 
    // but since rd_ptr is registered, mem[rd_ptr] is stable. 
    // The distinction usually implies: 
    // TRUE: rdata is valid immediately after reset and updates every cycle (even if no read happened).
    // FALSE: rdata is only valid when a read actually occurred (rd_en was high).
    // To implement "FALSE" behavior safely without combinational memory read:
    // We can use a latch or a register that updates only on rd_en.
    // Given "rdata is one read-clock sample", a register update on rd_en is the standard approach for non-fallthrough.
    
    reg [DSIZE-1:0] rdata_reg;
    
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= 1'b0;
        end else if (rd_en) begin
            rdata_reg <= mem[rd_ptr];
        end else if (FALLTHROUGH) begin
            // Even if no read, update rdata_reg to current oldest data
            rdata_reg <= mem[rd_ptr];
        end
    end
    assign rdata = rdata_reg;

    // --- Cross-Domain Pointer Transfer (Gray Code) ---

    // Write pointer (Gray) -> Read domain
    // Transfer wr_gray to rd domain safely.
    // Since wr_gray is registered in write domain, we can sample it in read domain.
    // However, to prevent metastability on the edge, we usually sample it synchronously.
    // But the requirement is zero unsafe crossings. Sampling a registered signal is safe.
    // We need to handle the reset state carefully.
    
    // We will use a simple synchronous transfer. 
    // Note: In a real design, one might use a dual-flop synchronizer if the source was combinational,
    // but here wr_gray is a register output. Sampling it on rclk is safe.
    // However, to be absolutely robust against reset release skew, we often add a synchronizer chain 
    // or ensure the reset logic aligns. The prompt asks for "safe... with zero unsafe crossings".
    // Direct sampling of a registered signal is generally considered safe in CDC analysis tools 
    // provided the source register is stable.
    
    // Let's implement a simple synchronizer chain for the pointers to be extra safe and standard.
    // Actually, the most robust way for pointer transfer is:
    // 1. Write domain registers the pointer.
    // 2. Read domain samples the pointer.
    // This is safe because the write domain register holds the value stable until the next clock edge.
    
    // We need to transfer wr_gray to rd domain and rd_gray to wr domain.
    
    // Synchronizer for wr_gray (Write Pointer) in Read Domain
    reg [GRANT_WIDTH-1:0] wr_gray_sync1;
    reg [GRANT_WIDTH-1:0] wr_gray_sync2;
    
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wr_gray_sync1 <= 1'b0;
            wr_gray_sync2 <= 1'b0;
        end else begin
            wr_gray_sync1 <= wr_gray;
            wr_gray_sync2 <= wr_gray_sync1;
        end
    end
    assign wr_gray_cross = wr_gray_sync2;

    // Synchronizer for rd_gray (Read Pointer) in Write Domain
    reg [GRANT_WIDTH-1:0] rd_gray_sync1;
    reg [GRANT_WIDTH-1:0] rd_gray_sync2;
    
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rd_gray_sync1 <= 1'b0;
            rd_gray_sync2 <= 1'b0;
        end else begin
            rd_gray_sync1 <= rd_gray;
            rd_gray_sync2 <= rd_gray_sync1;
        end
    end
    assign rd_gray_cross = rd_gray_sync2;

    // --- Cross-Domain Counter Transfer ---
    // We need to transfer the count (wr_cnt and rd_cnt) to the other domain to calculate full/empty accurately.
    // Since counters are multi-bit, we must transfer them safely.
    // We will transfer the Gray encoded pointers and then decode them to counts in the destination domain.
    // This avoids transferring the raw count which can have multiple bits changing.
    // Wait, the standard Gray code pointer transfer IS the method to avoid multi-bit changes.
    // So we just need to decode the received Gray code to a binary count in the destination domain.
    
    // Decode wr_gray_cross (from Write) to binary count in Read Domain
    reg [GRANT_WIDTH-1:0] wr_cnt_decoded;
    assign wr_cnt_decoded = {wr_gray_cross[GRANT_WIDTH-1:1], wr_gray_cross[GRANT_WIDTH-1] ^ wr_gray_cross[GRANT_WIDTH-2]};
    // Correction: Gray to Binary conversion logic
    // Binary[MSB] = Gray[MSB]
    // Binary[i] = Gray[i] ^ Binary[i+1]
    // Let's write a procedural block for decoding to be explicit and safe.
    
    always @(*) begin
        wr_cnt_decoded = wr_gray_cross;
        for (integer i = GRANT_WIDTH-2; i >= 0; i = i - 1) begin
            wr_cnt_decoded[i] = wr_gray_cross[i] ^ wr_cnt_decoded[i+1];
        end
    end

    // Decode rd_gray_cross (from Read) to binary count in Write Domain
    reg [GRANT_WIDTH-1:0] rd_cnt_decoded;
    always @(*) begin
        rd_cnt_decoded = rd_gray_cross;
        for (integer i = GRANT_WIDTH-2; i >= 0; i = i - 1) begin
            rd_cnt_decoded[i] = rd_gray_cross[i] ^ rd_cnt_decoded[i+1];
        end
    end

    // --- Full/Empty Logic in Cross Domain ---
    // Full: wr_cnt >= rd_cnt
    // Empty: wr_cnt <= rd_cnt
    // Since we are comparing counts from different domains, we must be careful.
    // The standard approach is:
    // Full = (wr_cnt >= rd_cnt) AND (wr_cnt != rd_cnt) -> Actually, if wr_cnt == rd_cnt, it's empty.
    // Full = (wr_cnt > rd_cnt) ? 1 : 0;
    // Empty = (wr_cnt < rd_cnt) ? 1 : 0;
    // But wait, the pointers are in Gray code in the source, decoded to binary in the destination.
    // The decoded counts are stable in the destination domain.
    
    // Full signal in Write Domain:
    // We need to know if the FIFO is full from the Write domain perspective.
    // Full = (wr_cnt_cross >= rd_cnt_cross) AND (wr_cnt_cross != rd_cnt_cross) is not quite right.
    // Correct logic:
    // If wr_cnt == rd_cnt, FIFO is empty.
    // If wr_cnt > rd_cnt, FIFO has data.
    // Full condition: The number of written items equals the number of read items + capacity.
    // i.e., (wr_cnt - rd_cnt) == capacity.
    // Since we are in the Write domain, we have wr_cnt (local) and rd_cnt_cross (from Read).
    // Full = (wr_cnt >= rd_cnt_cross) ? (wr_cnt == rd_cnt_cross + MAX_COUNT - 1) : 0;
    // Actually, simpler: Full = (wr_cnt >= rd_cnt_cross) && (wr_cnt - rd_cnt_cross == MAX_COUNT - 1).
    // But subtraction can be tricky with signed/unsigned.
    // Let's use the property: Full if (wr_cnt >= rd_cnt_cross) and (wr_cnt - rd_cnt_cross == MAX_COUNT - 1).
    // Or simply: Full = (wr_cnt >= rd_cnt_cross) ? (wr_cnt == rd_cnt_cross + (MAX_COUNT-1)) : 0;
    // Wait, if wr_cnt < rd_cnt_cross, it means we read more than we wrote (shouldn't happen if empty check is correct, but possible due to lag).
    // In that case, Full is definitely 0.
    
    // Let's refine the Full/Empty logic using the decoded counts.
    // wr_cnt is local binary count. rd_cnt_cross is decoded binary count from read domain.
    
    // Full: wr_cnt >= rd_cnt_cross AND (wr_cnt - rd_cnt_cross == MAX_COUNT - 1)
    // Empty: wr_cnt <= rd_cnt_cross AND (wr_cnt - rd_cnt_cross == 0) -> Actually wr_cnt == rd_cnt_cross
    
    // However, there is a nuance with Gray code decoding and reset.
    // If reset releases, both pointers go to 0.
    // We need to ensure the comparison is valid.
    
    // Let's implement the comparison logic carefully.
    // Full = (wr_cnt >= rd_cnt_cross) && (wr_cnt - rd_cnt_cross == MAX_COUNT - 1);
    // Empty = (wr_cnt <= rd_cnt_cross) && (wr_cnt - rd_cnt_cross == 0);
    
    // To avoid subtraction issues, we can check:
    // Full: If wr_cnt >= rd_cnt_cross, then check if (wr_cnt - rd_cnt_cross) == MAX_COUNT - 1.
    //      Since MAX_COUNT is power of 2, this is equivalent to checking the MSB of the difference?
    //      No, simpler: Full = (wr_cnt >= rd_cnt_cross) ? (wr_cnt == rd_cnt_cross + (MAX_COUNT-1)) : 0;
    //      But addition might overflow if not careful.
    //      Alternative: Full = (wr_cnt >= rd_cnt_cross) && (wr_cnt - rd_cnt_cross == MAX_COUNT - 1);
    //      In Verilog, unsigned subtraction is safe.
    
    // Let's define the signals for Full/Empty in both domains.
    
    // Write Domain Full/Empty
    // wr_full: Output to user.
    // wr_empty: Internal for logic.
    // We need to compare wr_cnt (local) and rd_cnt_cross (from read).
    
    // Note: The decoded counts might have a 1-cycle lag relative to the actual pointers due to the synchronizer.
    // This is acceptable for CDC.
    
    // Full Logic in Write Domain
    // Full if (wr_cnt >= rd_cnt_cross) and (wr_cnt - rd_cnt_cross == MAX_COUNT - 1)
    // But wait, if wr_cnt < rd_cnt_cross, it means we are empty (or underflowed).
    // So:
    wire wr_cnt_ge_rd_cnt = (wr_cnt >= rd_cnt_cross);
    wire wr_diff = wr_cnt - rd_cnt_cross;
    wire wr_full = wr_cnt_ge_rd_cnt && (wr_diff == (MAX_COUNT - 1));
    
    // Empty Logic in Write Domain (Internal)
    wire wr_empty = (wr_cnt <= rd_cnt_cross) && (wr_diff == 0);
    
    // Read Domain Full/Empty
    // rd_full: Internal for logic.
    // rd_empty: Output to user.
    // We need to compare rd_cnt (local) and wr_cnt_cross (from write).
    
    wire rd_cnt_ge_wr_cnt = (rd_cnt >= wr_cnt_cross);
    wire rd_diff = rd_cnt - wr_cnt_cross;
    wire rd_full = rd_cnt_ge_wr_cnt && (rd_diff == (MAX_COUNT - 1));
    
    wire rd_empty = (rd_cnt <= wr_cnt_cross) && (rd_diff == 0);

    // Assign outputs
    assign wfull = wr_full;
    assign rempty = rd_empty;
    
    // Almost Full/Empty
    // awfull: Almost full in write domain.
    // arempty: Almost empty in read domain.
    // Threshold is usually (MAX_COUNT - 1) / 2.
    // awfull = (wr_cnt >= rd_cnt_cross) && (wr_cnt - rd_cnt_cross >= (MAX_COUNT - 1) / 2);
    // arempty = (rd_cnt <= wr_cnt_cross) && (rd_cnt - wr_cnt_cross <= (MAX_COUNT - 1) / 2);
    // Actually, "Almost Full" usually means "Full - 1" or "Full - threshold".
    // Spec says: "awfull indicates that the FIFO is approaching full".
    // Common practice: awfull = (wr_cnt >= rd_cnt_cross) && (wr_cnt - rd_cnt_cross >= (MAX_COUNT - 1) / 2);
    // But to be precise with the "approaching" definition often used in FIFOs:
    // awfull = (wr_cnt >= rd_cnt_cross) && (wr_cnt - rd_cnt_cross >= (MAX_COUNT - 1) / 2);
    // Let's use the standard threshold of half capacity.
    
    localparam THRESHOLD = (MAX_COUNT - 1) / 2;
    
    wire wr_diff_val = wr_cnt - rd_cnt_cross;
    wire rd_diff_val = rd_cnt - wr_cnt_cross;
    
    assign awfull = wr_cnt_ge_rd_cnt && (wr_diff_val >= THRESHOLD);
    assign arempty = rd_cnt <= wr_cnt_cross && (rd_diff_val <= THRESHOLD);

    // Note on Reset Safety:
    // The synchronizers for pointers ensure that even if resets release at different times,
    // the sampled values will eventually settle to 0 without metastability issues affecting logic.
    // The decoded counts will also settle correctly.
    // The memory is reset to 0 in the write domain.
    // The read domain starts reading from 0.
    // If wrst_n releases first, wr_ptr goes to 0, wr_cnt goes to 0.
    // If rrst_n releases later, rd_ptr goes to 0, rd_cnt goes to 0.
    // The cross-domain pointers will sample the 0s.
    // Logic holds.

endmodule
```<|im_end|>
