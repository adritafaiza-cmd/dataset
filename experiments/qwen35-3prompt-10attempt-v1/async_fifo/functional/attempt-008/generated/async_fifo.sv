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

    localparam INT_ASIZE = ASIZE;
    localparam INT_DEPTH = 1 << ASIZE;

    // Write domain signals
    reg [INT_ASIZE-1:0] wptr;
    reg [INT_ASIZE-1:0] wptr_next;
    reg [INT_ASIZE-1:0] wgray;
    reg [INT_ASIZE-1:0] wgray_next;
    reg wfull_reg;
    reg awfull_reg;

    // Read domain signals
    reg [INT_ASIZE-1:0] rptr;
    reg [INT_ASIZE-1:0] rptr_next;
    reg [INT_ASIZE-1:0] rgray;
    reg [INT_ASIZE-1:0] rgray_next;
    reg rempty_reg;
    reg arempty_reg;

    // Cross-domain pointers (Gray encoded)
    wire [INT_ASIZE-1:0] wptr_gray;
    wire [INT_ASIZE-1:0] rptr_gray;

    // FIFO Memory
    reg [DSIZE-1:0] mem [INT_DEPTH-1:0];

    // --- Write Domain Logic ---

    // Generate Gray code from binary pointer
    assign wptr_gray = wptr ^ (wptr >> 1);
    assign rptr_gray = rptr ^ (rptr >> 1);

    // Write Pointer Logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 1'b0;
            wgray <= 1'b0;
        end else begin
            if (winc && !wfull) begin
                wptr_next = wptr + 1'b1;
                // Update Gray code for next state
                wgray_next = wptr_next ^ (wptr_next >> 1);
            end else begin
                wptr_next = wptr;
                wgray_next = wgray;
            end
            wptr <= wptr_next;
            wgray <= wgray_next;
        end
    end

    // Full Logic: wptr == rptr (in Gray)
    assign wfull = (wgray == rgray);

    // Almost Full Logic: wptr is one less than rptr (wrapping)
    // This happens when wptr + 1 == rptr (modulo 2^ASIZE)
    // In Gray code, this is detected by checking if wgray + 1 == rgray
    // However, simpler logic in binary domain:
    // awfull is true if (wptr + 1) == rptr
    assign awfull = (wptr + 1'b1) == rptr;

    // Write Data Logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            // Memory doesn't strictly need reset if we only write on valid cycles,
            // but good practice to clear or keep last value. 
            // Spec says "Writes attempted while full must not alter FIFO contents".
            // It doesn't mandate memory reset, but standard practice is to clear.
            // We will leave memory as is or clear it. Let's clear for safety.
            for (int i = 0; i < INT_DEPTH; i = i + 1)
                mem[i] <= 1'b0;
        end else if (winc && !wfull) begin
            mem[wptr] <= wdata;
        end
    end

    // --- Read Domain Logic ---

    // Read Pointer Logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 1'b0;
            rgray <= 1'b0;
        end else begin
            if (rinc && !rempty) begin
                rptr_next = rptr + 1'b1;
                rgray_next = rptr_next ^ (rptr_next >> 1);
            end else begin
                rptr_next = rptr;
                rgray_next = rgray;
            end
            rptr <= rptr_next;
            rgray <= rgray_next;
        end
    end

    // Empty Logic: wptr == rptr (in Gray)
    assign rempty = (wgray == rgray);

    // Almost Empty Logic: rptr is one less than wptr (wrapping)
    // This happens when rptr + 1 == wptr
    assign arempty = (rptr + 1'b1) == wptr;

    // Read Data Logic
    // Spec: "FALLTHROUGH does not select a combinational memory read."
    // It implies the data is registered.
    // If FALLTHROUGH is TRUE, rdata presents the current oldest unread word 
    // without requiring an additional registered-read cycle.
    // This usually means rdata is updated when the pointer moves, OR 
    // it is updated on the read clock edge regardless of whether a read occurred,
    // but the spec says "rdata may be updated by an accepted read" if FALSE.
    // If TRUE, it suggests rdata is available immediately after the pointer moves?
    // Actually, standard async FIFO with fallthrough:
    // The data is read from memory at the read clock edge.
    // If FALLTHROUGH is TRUE, the output rdata is the data at the current rptr.
    // If FALLTHROUGH is FALSE, rdata is updated only when rinc is high and !rempty.
    // However, the spec says: "rdata presents the current oldest unread word without requiring an additional registered-read cycle."
    // This implies that even if rinc is low, if the pointer hasn't moved, rdata should still be valid?
    // No, "without requiring an additional registered-read cycle" usually refers to the fact that 
    // you don't need to wait for a read pulse to see the data if you just want the current head.
    // But in a synchronous read domain, rdata is naturally registered.
    // The distinction is:
    // FALSE: rdata updates ONLY on (rinc && !rempty).
    // TRUE: rdata updates on every clock edge (or at least tracks the head pointer continuously).
    // Given "rdata may be updated by an accepted read" for FALSE, it implies for TRUE it updates more often.
    // Standard implementation for FALLTHROUGH=TRUE: rdata is updated every clock cycle to reflect the current head.
    // Standard implementation for FALLTHROUGH=FALSE: rdata is updated only when a read occurs.

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 1'b0;
        end else begin
            if (FALLTHROUGH) begin
                // Update data every clock cycle to reflect current head pointer
                rdata <= mem[rptr];
            end else begin
                // Update data only when a read is accepted
                if (rinc && !rempty) begin
                    rdata <= mem[rptr];
                end
            end
        end
    end

endmodule
```<|im_end|>
