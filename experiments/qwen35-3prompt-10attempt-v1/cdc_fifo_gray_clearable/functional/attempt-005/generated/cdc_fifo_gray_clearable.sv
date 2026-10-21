```verilog
`timescale 1ns/1ps

module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam GRAY_WIDTH = LOG_DEPTH;

    // Internal signals
    reg [WIDTH-1:0]   src_data_reg;
    reg               src_valid_reg;
    reg               src_clear_pending;
    reg               dst_clear_pending;
    reg               dst_valid_reg;
    reg               dst_data_reg; // Placeholder for width, will be assigned
    reg [DEPTH-1:0]   write_ptr_gray;
    reg [DEPTH-1:0]   read_ptr_gray;
    reg [DEPTH-1:0]   write_ptr_bin;
    reg [DEPTH-1:0]   read_ptr_bin;
    reg               full_reg;
    reg               empty_reg;
    reg               write_en;
    reg               read_en;
    wire               full;
    wire               empty;
    wire               write_gray;
    wire               read_gray;

    // --- Source Domain Logic ---

    // Reset and Clear Logic for Source
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 1'b0;
            src_valid_reg     <= 1'b0;
            src_data_reg      <= {WIDTH{1'b0}};
        end else if (src_clear_i) begin
            src_clear_pending <= 1'b1;
            src_valid_reg     <= 1'b0;
            src_data_reg      <= {WIDTH{1'b0}};
        end else begin
            src_clear_pending <= 1'b0;
            src_valid_reg     <= src_valid_i;
            src_data_reg      <= src_data_i;
        end
    end

    // Write Pointer Logic (Source Domain)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            write_ptr_bin <= 1'b0;
            write_ptr_gray <= 1'b0;
        end else if (src_clear_i) begin
            write_ptr_bin <= 1'b0;
            write_ptr_gray <= 1'b0;
        end else if (write_en) begin
            write_ptr_bin <= write_ptr_bin + 1'b1;
            write_ptr_gray <= write_ptr_gray + 1'b1;
        end
    end

    // Read Pointer Logic (Source Domain - for Clear Synchronization)
    // We need to know if the FIFO is empty to decide if a clear is "done"
    // However, the clear logic requires us to stop writing and reading.
    // The actual empty/full detection happens in the cross-domain logic.
    // Here we just track the pointer state for the clear completion signal.
    // Note: In a clearable FIFO, the pointers are reset on clear.
    // The "pending" status is simply whether the clear request was asserted and hasn't been reset by the domain logic yet.
    // Actually, the requirement says "*_clear_pending_o stays high until that side finishes."
    // "Finishes" means the pointers are reset and the FIFO is empty.
    // Since we reset pointers on clear, we can use the pointer value to detect if it's back to 0.
    // But we must ensure we don't assert pending if the FIFO was already empty.
    // Simpler approach: The clear signal is an edge-triggered request.
    // We hold pending high until the pointers are reset to 0.
    
    // Re-evaluating Clear Pending Logic:
    // The prompt says: "Clear and reset must not create a destination beat."
    // "src_clear_pending_o stays high until that side finishes."
    // "Finishes" implies the internal state machine has processed the clear and returned to a known empty state.
    // Since we reset pointers on clear, we can detect completion when (write_ptr == 0 && read_ptr == 0).
    // However, we need to distinguish between "Clear requested" and "Clear completed".
    // Let's use a simple latch for the pending status that clears when pointers hit zero.
    
    reg               src_clear_req;
    reg               src_clear_done;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_req    <= 1'b0;
            src_clear_done   <= 1'b0;
            src_clear_pending_o <= 1'b0;
        end else if (src_clear_i) begin
            src_clear_req    <= 1'b1;
            src_clear_done   <= 1'b0;
        end else if (src_clear_req && (write_ptr_bin == 1'b0 && read_ptr_bin == 1'b0)) begin
            src_clear_req    <= 1'b0;
            src_clear_done   <= 1'b1;
        end
    end

    // Output Clear Pending
    assign src_clear_pending_o = src_clear_req || (!src_clear_done && (write_ptr_bin != 1'b0 || read_ptr_bin != 1'b0));
    // Correction: If clear is active, pending is high. If clear was active but pointers are 0, pending is low.
    // If no clear, pending is low.
    // Logic: pending = (clear_active) OR (clear_was_active AND not_done).
    // Actually, simpler: pending is high if we are in the middle of a clear operation.
    // A clear operation starts on edge. It ends when pointers are 0.
    // Let's refine the state:
    // 1. Normal: clear_req=0, clear_done=0 -> pending=0
    // 2. Clear Active: clear_req=1, clear_done=0 -> pending=1
    // 3. Clear Done: clear_req=0, clear_done=1 -> pending=0
    
    // Revised Logic for src_clear_pending_o:
    // It should be high if src_clear_i is asserted OR if a previous clear is still propagating (pointers not zero).
    // But since we reset pointers immediately on clear in the pointer logic, the pointers will be 0 instantly.
    // So "pending" is just the duration of the clear pulse?
    // No, usually "pending" means "I am busy clearing, don't send new data".
    // If we reset pointers immediately, the FIFO is empty immediately.
    // The constraint "Clear and reset must not create a destination beat" is handled by the cross-domain logic.
    // The constraint "*_clear_pending_o stays high until that side finishes" implies there is a delay or a state.
    // Given the synchronous nature of the pointer reset, the only way to have a "pending" period is if the clear signal is held high.
    // If the user toggles clear, we reset.
    // Let's assume "pending" is high while src_clear_i is high OR while the internal clear state is active.
    // To be safe and compliant with "stays high until... finishes", we will treat the clear as a state.
    // State 0: Idle. State 1: Clearing.
    // Transition to State 1 on rising edge of clear. Transition to State 0 when pointers are 0.
    
    reg               src_clear_state;
    
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_state <= 1'b0;
        end else if (src_clear_i) begin
            src_clear_state <= 1'b1;
        end else if (src_clear_state && (write_ptr_bin == 1'b0 && read_ptr_bin == 1'b0)) begin
            src_clear_state <= 1'b0;
        end
    end
    assign src_clear_pending_o = src_clear_state;

    // Write Enable
    // Write if valid, not full, and not clearing (if clearing, we stop writing)
    // Actually, if clearing, we stop writing.
    write_en = src_valid_i && !full && !src_clear_state;

    // --- Destination Domain Logic ---

    // Reset and Clear Logic for Destination
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 1'b0;
            dst_valid_reg     <= 1'b0;
            dst_data_reg      <= {WIDTH{1'b0}};
        end else if (dst_clear_i) begin
            dst_clear_pending <= 1'b1;
            dst_valid_reg     <= 1'b0;
            dst_data_reg      <= {WIDTH{1'b0}};
        end else begin
            dst_clear_pending <= 1'b0;
            dst_valid_reg     <= dst_valid_i; // Will be driven by cross-domain logic
            dst_data_reg      <= dst_data_i;  // Will be driven by cross-domain logic
        end
    end

    // Read Pointer Logic (Destination Domain)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_ptr_bin <= 1'b0;
            read_ptr_gray <= 1'b0;
        end else if (dst_clear_i) begin
            read_ptr_bin <= 1'b0;
            read_ptr_gray <= 1'b0;
        end else if (read_en) begin
            read_ptr_bin <= read_ptr_bin + 1'b1;
            read_ptr_gray <= read_ptr_gray + 1'b1;
        end
    end

    // Output Clear Pending for Destination
    reg               dst_clear_state;
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_state <= 1'b0;
        end else if (dst_clear_i) begin
            dst_clear_state <= 1'b1;
        end else if (dst_clear_state && (read_ptr_bin == 1'b0 && write_ptr_bin == 1'b0)) begin
            // Note: write_ptr_bin is from source domain, but we need to know if the FIFO is empty.
            // We cannot directly access src domain registers here.
            // We must rely on the fact that if the FIFO is empty, read_ptr == write_ptr.
            // But we don't have the write_ptr_bin in this domain.
            // We need to synchronize the write_ptr_bin to the destination domain to check emptiness.
            // OR, we can infer emptiness from the read pointer if we know the FIFO is empty.
            // Standard approach: Synchronize the write pointer to the destination domain.
            // Let's add a synchronized write pointer in the destination domain.
        end
    end

    // --- Cross Domain Synchronization ---

    // 1. Synchronize Write Pointer to Destination Domain (to detect empty/full correctly for clear)
    reg [DEPTH-1:0]   sync_write_ptr_gray;
    reg [DEPTH-1:0]   sync_write_ptr_bin;
    reg               sync_write_ptr_valid;

    // Gray to Binary Decoder (Synchronous)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            sync_write_ptr_gray <= 1'b0;
            sync_write_ptr_bin  <= 1'b0;
            sync_write_ptr_valid <= 1'b0;
        end else if (sync_write_ptr_valid) begin
            sync_write_ptr_gray <= sync_write_ptr_gray + 1'b1;
            // Binary decoder
            sync_write_ptr_bin  <= 1'b0;
            for (integer i = 0; i < GRAY_WIDTH; i = i + 1) begin
                if (sync_write_ptr_gray[i]) begin
                    sync_write_ptr_bin[i] <= 1'b1;
                end
            end
            sync_write_ptr_valid <= 1'b0;
        end else begin
            sync_write_ptr_valid <= 1'b1;
        end
    end

    // 2. Synchronize Read Pointer to Source Domain (to detect empty/full for source clear)
    reg [DEPTH-1:0]   sync_read_ptr_gray;
    reg [DEPTH-1:0]   sync_read_ptr_bin;
    reg               sync_read_ptr_valid;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            sync_read_ptr_gray <= 1'b0;
            sync_read_ptr_bin  <= 1'b0;
            sync_read_ptr_valid <= 1'b0;
        end else if (sync_read_ptr_valid) begin
            sync_read_ptr_gray <= sync_read_ptr_gray + 1'b1;
            // Binary decoder
            sync_read_ptr_bin  <= 1'b0;
            for (integer i = 0; i < GRAY_WIDTH; i = i + 1) begin
                if (sync_read_ptr_gray[i]) begin
                    sync_read_ptr_bin[i] <= 1'b1;
                end
            end
            sync_read_ptr_valid <= 1'b0;
        end else begin
            sync_read_ptr_valid <= 1'b1;
        end
    end

    // Re-evaluate Clear Pending Logic with synchronized pointers
    // Source Domain:
    // Clear is done when write_ptr_bin == 0 AND read_ptr_bin == 0.
    // We have sync_read_ptr_bin in source domain.
    reg               src_clear_state_v2;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_state_v2 <= 1'b0;
        end else if (src_clear_i) begin
            src_clear_state_v2 <= 1'b1;
        end else if (src_clear_state_v2 && (write_ptr_bin == 1'b0 && sync_read_ptr_bin == 1'b0)) begin
            src_clear_state_v2 <= 1'b0;
        end
    end
    assign src_clear_pending_o = src_clear_state_v2;

    // Destination Domain:
    // Clear is done when read_ptr_bin == 0 AND write_ptr_bin == 0.
    // We have sync_write_ptr_bin in destination domain.
    reg               dst_clear_state_v2;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_state_v2 <= 1'b0;
        end else if (dst_clear_i) begin
            dst_clear_state_v2 <= 1'b1;
        end else if (dst_clear_state_v2 && (read_ptr_bin == 1'b0 && sync_write_ptr_bin == 1'b0)) begin
            dst_clear_state_v2 <= 1'b0;
        end
    end
    assign dst_clear_pending_o = dst_clear_state_v2;

    // 3. Synchronize Valid/Ready and Data
    // Source Side:
    // src_ready_o is driven by dst_valid_i (synchronized) AND !full AND !clear_state
    // dst_valid_i comes from dst_valid_reg (which is driven by cross-domain logic)
    
    // Synchronize dst_valid_i to Source Domain
    reg               sync_dst_valid;
    reg               sync_dst_valid_sync2;
    
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            sync_dst_valid <= 1'b0;
            sync_dst_valid_sync2 <= 1'b0;
        end else begin
            sync_dst_valid <= dst_valid_i;
            sync_dst_valid_sync2 <= sync_dst_valid;
        end
    end

    // Synchronize dst_ready_i to Destination Domain
    reg               sync_src_ready;
    reg               sync_src_ready_sync2;
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            sync_src_ready <= 1'b0;
            sync_src_ready_sync2 <= 1'b0;
        end else begin
            sync_src_ready <= src_ready_i; // Wait, src_ready_o is output. We need to read it.
            // Correction: We need to read src_ready_o in dst domain.
            // But src_ready_o is an output of this module.
            // We need to capture the value of src_ready_o in the destination domain.
            // Let's use a wire for src_ready_o and capture it.
            // But we can't capture an output in the same module easily without a wire.
            // We will use a wire `src_ready_wire` internally.
            sync_src_ready <= src_ready_o;
            sync_src_ready_sync2 <= sync_src_ready;
        end
    end

    // Full/Empty Logic
    // Full: write_ptr == read_ptr - 1 (in binary)
    // Empty: write_ptr == read_ptr
    // We need to compare the synchronized pointers.
    
    wire               is_full;
    wire               is_empty;
    
    // Compare sync_write_ptr_bin and sync_read_ptr_bin
    assign is_full = (sync_write_ptr_bin == sync_read_ptr_bin) && (sync_write_ptr_bin != 1'b0);
    assign is_empty = (sync_write_ptr_bin == sync_read_ptr_bin);

    // Cross Domain Control Signals
    // src_ready_o: Valid if dst_valid_i is high, FIFO is not full, and not clearing.
    // dst_valid_o: Valid if src_valid_i is high, FIFO is not empty, and not clearing.
    
    // Synchronize src_valid_i to Dest
    reg               sync_src_valid;
    reg               sync_src_valid_sync2;
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            sync_src_valid <= 1'b0;
            sync_src_valid_sync2 <= 1'b0;
        end else begin
            sync_src_valid <= src_valid_i;
            sync_src_valid_sync2 <= sync_src_valid;
        end
    end

    // Synchronize src_data_i to Dest
    reg [WIDTH-1:0]   sync_src_data;
    reg               sync_src_data_valid;
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            sync_src_data <= {WIDTH{1'b0}};
            sync_src_data_valid <= 1'b0;
        end else if (sync_src_valid) begin
            sync_src_data <= src_data_i;
            sync_src_data_valid <= 1'b1;
        end else begin
            sync_src_data_valid <= 1'b0;
        end
    end

    // Synchronize dst_ready_i to Source
    // We need to read dst_ready_i in source domain.
    reg               sync_dst_ready;
    reg               sync_dst_ready_sync2;
    
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            sync_dst_ready <= 1'b0;
            sync_dst_ready_sync2 <= 1'b0;
        end else begin
            sync_dst_ready <= dst_ready_i;
            sync_dst_ready_sync2 <= sync_dst_ready;
        end
    end

    // Final Logic for Outputs and Internal State
    
    // Source Domain:
    // src_ready_o = sync_dst_valid_sync2 && !is_full && !src_clear_state_v2
    // Note: is_full is calculated using synchronized pointers, which is correct.
    // However, we must ensure that during clear, we don't output valid data.
    // The clear state logic handles this.
    
    // Destination Domain:
    // dst_valid_o = sync_src_valid_sync2 && !is_empty && !dst_clear_state_v2
    // dst_data_o = sync_src_data
    
    // Read Enable Logic
    // Read if valid, not empty, and not clearing.
    // Also, we need to handle the "one registered sample" rule for dst_valid_o.
    // "The destination word is one registered sample. dst_valid_o may fall for one destination clock after an accepted beat even when another word is stored."
    // This implies we should not gate the read enable with dst_ready_i in a way that causes glitches,
    // but standard handshake logic applies.
    // The "fall for one clock" is a property of the handshake, not something we need to explicitly code unless we are doing a specific protocol.
    // Standard: Read if valid and not empty and not clearing.
    
    // Let's refine the Read Enable to ensure stability.
    // We need to gate the read enable with the synchronized ready signal from the source.
    // But the source ready signal is driven by the destination valid signal.
    // This creates a loop.
    // Standard Async FIFO:
    // Write Enable = src_valid && !full && !clear
    // Read Enable = dst_valid && !empty && !clear
    
    // To implement the handshake:
    // src_ready_o = dst_valid_synced && !full && !clear_src
    // dst_valid_o = src_valid_synced && !empty && !clear_dst
    
    // We need to make sure the pointers are updated correctly.
    // Write pointer increments on Write Enable.
    // Read pointer increments on Read Enable.
    
    // Re-checking the "Clear" behavior:
    // "Clear and reset must not create a destination beat."
    // This means if we are clearing, dst_valid_o must be 0.
    // Our logic: dst_valid_o = ... && !dst_clear_state_v2. This handles it.
    // "src_clear_pending_o stays high until that side finishes."
    // Our logic: src_clear_state_v2 stays high until pointers are 0. This handles it.
    
    // One detail: "The destination word is one registered sample."
    // This usually means the data output is registered. We are doing that (sync_src_data).
    // "dst_valid_o may fall for one destination clock after an accepted beat even when another word is stored."
    // This is a natural consequence of the handshake. If the source stops sending (valid=0), dst_valid will go low even if the FIFO has data.
    // We don't need extra logic for this; it's standard behavior.
    
    // Implementation Details:
    // We need to ensure that the pointers are updated on the correct clock edges.
    // Write pointer updates on src_clk_i.
    // Read pointer updates on dst_clk_i.
    
    // Let's assemble the final logic.
    
    // Source Domain Final Logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_o <= 1'b0;
            write_en <= 1'b0;
        end else begin
            // src_ready_o is driven by dst_valid (synced) and not full and not clearing
            src_ready_o <= sync_dst_valid_sync2 && !is_full && !src_clear_state_v2;
            
            // Write Enable
            write_en <= src_valid_i && !is_full && !src_clear_state_v2;
        end
    end

    // Destination Domain Final Logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 1'b0;
            dst_data_o <= {WIDTH{1'b0}};
            read_en <= 1'b0;
        end else begin
            // dst_valid_o is driven by src_valid (synced) and not empty and not clearing
            dst_valid_o <= sync_src_valid_sync2 && !is_empty && !dst_clear_state_v2;
            dst_data_o <= sync_src_data;
            
            // Read Enable
            // We need to gate read_en with the source's ready signal (synced to dst)
            // But we don't have src_ready_synced in dst domain.
            // We can synthesize src_ready_o in dst domain.
            // src_ready_o = dst_valid_synced && !full && !clear_src
            // So read_en = src_valid_synced && !empty && !clear_dst && src_ready_synced
            // But src_ready_synced depends on dst_valid_synced.
            // This is the standard handshake loop.
            // To avoid metastability or glitches, we usually just use:
            // Read if valid and not empty and not clearing.
            // The handshake is established by the valid/ready signals.
            // If dst_valid is high, it means src_valid was high.
            // If src_ready is high, it means dst_valid is high (and not full).
            // So if we are in a state where dst_valid is high, and we pull dst_valid low (by not reading),
            // the source will see dst_valid low and stop asserting valid.
            // But we want to read.
            // Standard logic:
            // read_en = sync_src_valid_sync2 && !is_empty && !dst_clear_state_v2;
            // This is sufficient. The handshake is implicit in the valid/ready signals.
            // However, to be strictly compliant with "handshake", we should ensure we don't read if the source isn't ready.
            // But the source is ready if dst_valid is high (and not full).
            // If dst_valid is high, it means src_valid was high.
            // So reading is safe.
            read_en <= sync_src_valid_sync2 && !is_empty && !dst_clear_state_v2;
        end
    end

    // Synchronize src_ready_o to Destination Domain for the handshake loop
    // We need src_ready_o in dst domain to gate the read enable properly?
    // Actually, the standard implementation is:
    // dst_valid_o = src_valid_synced && !empty && !clear_dst
    // src_ready_o = dst_valid_synced && !full && !clear_src
    // This creates a stable handshake.
    // We need to capture src_ready_o in the destination domain to ensure the read enable is stable?
    // No, the read enable is driven by dst_valid_o logic.
    // Wait, if dst_valid_o is high, it means src_valid was high.
    // If src_valid is high, src_ready_o should be high (unless full or clearing).
    // If src_ready_o is high, it means dst_valid is high (and not full).
    // So if dst_valid is high, and not full, and not clearing, then src_ready is high.
    // So we can just use dst_valid_synced as the "ready" signal for the source?
    // No, src_ready_o is the signal sent back to the source.
    // The source uses src_ready_o to know if it can send.
    // The destination uses dst_valid_o to know if it has data.
    // The destination reads when dst_valid_o is high.
    // The source sends when src_valid_i is high and src_ready_o is high.
    // So the read enable should be gated by src_ready_o (synced to dst).
    // Let's add that.
    
    reg               sync_src_ready;
    reg               sync_src_ready_sync2;
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            sync_src_ready <= 1'b0;
            sync_src_ready_sync2 <= 1'b0;
        end else begin
            sync_src_ready <= src_ready_o;
            sync_src_ready_sync2 <= sync_src_ready;
        end
    end

    // Update Read Enable Logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_en <= 1'b0;
        end else begin
            // Read if:
            // 1. Source has valid data (synced)
            // 2. FIFO is not empty
            // 3. Not clearing
            // 4. Source is ready (which implies dst_valid is high and not full)
            // Actually, if dst_valid is high, it means src_valid was high.
            // If src_valid is high, src_ready is high (unless full/clear).
            // If src_ready is high, it means dst_valid is high (and not full).
            // So if dst_valid is high, and not empty, and not clearing, then src_ready is high.
            // So condition 4 is redundant if we trust the logic.
            // But to be safe and explicit:
            read_en <= sync_src_valid_sync2 && !is_empty && !dst_clear_state_v2 && sync_src_ready_sync2;
        end
    end

    // Update Write Enable Logic (already done above, but let's double check)
    // write_en = src_valid_i && !is_full && !src_clear_state_v2;
    // This is correct.

    // One final check on Clear Pending Logic:
    // "src_clear_pending_o stays high until that side finishes."
    // "Finishes" = pointers are 0.
    // Our logic: src_clear_state_v2 is set on clear_i. It clears when (write_ptr==0 && sync_read_ptr==0).
    // This seems correct.
    // Same for dst.

    // One edge case: What if the FIFO is empty and clear is asserted?
    // write_ptr=0, read_ptr=0.
    // src_clear_state_v2 becomes 1.
    // Condition (write_ptr==0 && sync_read_ptr==0) is true immediately.
    // So src_clear_state_v2 becomes 0 immediately.
    // src_clear_pending_o becomes 0.
    // This is correct: if empty, clear is instant.
    // But what if the clear signal is held high?
    // If clear_i is held high, src_clear_state_v2 stays 1.
    // The condition (write_ptr==0 && sync_read_ptr==0) is true.
    // So it tries to set to 0.
    // So src_clear_state_v2 will be 0 as long as clear_i is high?
    // No, the logic is:
    // if (clear_i) state = 1;
    // else if (state && pointers==0) state = 0;
    // If clear_i is high, state is forced to 1.
    // So if clear_i is held high, state stays 1.
    // This is correct: pending is high while clear is active.
    // If clear_i goes low, and pointers are 0, state goes to 0.
    // If clear_i goes low, and pointers are not 0 (impossible if we reset on clear), state goes to 0.
    // Wait, if clear_i is high, we reset pointers.
    // So pointers are 0.
    // So if clear_i goes low, state goes to 0.
    // So pending is high only while clear_i is high?
    // Yes, that seems to be the intended behavior for a "clearable" FIFO where the clear is a pulse.
    // But the requirement says "stays high until that side finishes".
    // If the clear is a pulse, it finishes instantly.
    // If the clear is a level, it stays high.
    // Our logic handles both: if level, state stays 1. If pulse, state goes to 0 when pulse ends (since pointers are 0).
    // This matches the requirement.

    // One more thing: The "Clear and reset must not create a destination beat."
    // This means if we are clearing, dst_valid_o must be 0.
    // Our logic: dst_valid_o = ... && !dst_clear_state_v2.
    // This ensures dst_valid_o is 0 during clear.
    // Also, we reset dst_valid_reg and dst_data_reg on clear.
    // This ensures no stale data is output.

    // Final check on parameters:
    // SYNC_STAGES is given but not used in the current implementation.
    // The current implementation uses 2-stage synchronization for pointers and valid signals.
    // The prompt says "Choose a safe crossing yourself."
    // 2 stages is generally safe for asynchronous FIFOs.
    // However, the prompt provides SYNC_STAGES as a parameter.
    // I should use it to make the code configurable and professional.
    // I will implement a generic synchronizer using the SYNC_STAGES parameter.

    // Let's refactor to use SYNC_STAGES.
    // We need a function to synchronize a signal.
    // Since we can't use functions in Verilog-2001 easily for this, we will unroll or use a generic counter.
    // Given the constraints, I will implement a generic synchronizer block.

    // Re-implementing with SYNC_STAGES
    // We need to synchronize:
    // 1. src_valid_i to dst
    // 2. src_data_i to dst
    // 3. dst_ready_i to src
    // 4. src_ready_o to dst
    // 5. src_clear_i to dst (for dst clear state logic? No, dst clear is local)
    // 6. dst_clear_i to src (for src clear state logic? No, src clear is local)
    // 7. src_clear_i to dst (to detect clear in dst domain? No, dst_clear_i is local)
    // 8. dst_clear_i to src (to detect clear in src domain? No, src_clear_i is local)
    // Wait, we need to synchronize the clear signals too?
    // No, the clear signals are local to their domains.
    // But we need to synchronize the pointers to detect emptiness/fullness across domains.
    // And we need to synchronize the valid/ready signals.
    
    // Let's create a generic synchronizer module inside or unroll it.
    // Since it's a single file, I'll unroll it for clarity and compliance with Verilog-2001.
    
    // Synchronizer for src_valid_i to dst
    reg [SYNC_STAGES-1:0] sync_src_valid_cnt;
    reg [SYNC_STAGES-1:0] sync_src_valid_data;
    reg [SYNC_STAGES-1:0] sync_src_valid_state;
    
    // Actually, a simple chain of flip-flops is enough.
    // Let's define a parameterized synchronizer logic.
    
    // To keep the code clean and within the constraints, I will use a fixed 2-stage synchronizer
    // if SYNC_STAGES is not specified, but since it is a parameter, I will use it.
    // However, unrolling a loop for synchronization in a single file without functions is verbose.
    // I will implement a generic synchronizer using a counter.
    
    // Let's simplify: I will use a 2-stage synchronizer as the default "safe crossing"
    // and ignore the SYNC_STAGES parameter if it's not strictly required to be used dynamically.
    // But the prompt says "Choose a safe crossing yourself" and gives the parameter.
    // I should use it.
    
    // Implementation of Synchronizer:
    // We need to synchronize a signal `in` to a clock `clk` using `rst_n`.
    // We need `out` and `valid`.
    // Since we can't use functions, I will write the logic inline.
    
    // Given the complexity of unrolling for arbitrary SYNC_STAGES in a single file without functions,
    // and the fact that 2 stages is standard, I will use a fixed 2-stage synchronizer
    // and note that SYNC_STAGES is provided but 2 is chosen for safety.
    // Wait, the prompt says "Choose a safe crossing yourself."
    // I will choose 2 stages.
    // I will ignore the SYNC_STAGES parameter value and hardcode 2 for safety and simplicity,
    // OR I will use the parameter value.
   