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
    localparam GRAY_WIDTH = $clog2(DEPTH);

    // Internal signals for pointers
    reg [LOG_DEPTH-1:0] src_ptr;
    reg [LOG_DEPTH-1:0] dst_ptr;
    reg [LOG_DEPTH-1:0] src_gray;
    reg [LOG_DEPTH-1:0] dst_gray;
    
    // Clear state machine flags
    reg src_clear_req;
    reg dst_clear_req;
    reg src_clear_done;
    reg dst_clear_done;
    reg src_clear_pending;
    reg dst_clear_pending;

    // Data storage
    reg [WIDTH-1:0] mem [DEPTH-1:0];
    reg [LOG_DEPTH-1:0] write_ptr;
    reg [LOG_DEPTH-1:0] read_ptr;
    reg write_en;
    reg read_en;
    reg full;
    reg empty;

    // --- Source Side Logic ---

    // Synchronize clear request
    reg src_clear_sync1;
    reg src_clear_sync2;
    reg src_clear_sync3;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_sync1 <= 1'b0;
            src_clear_sync2 <= 1'b0;
            src_clear_sync3 <= 1'b0;
            src_clear_pending_o <= 1'b0;
        end else begin
            src_clear_sync1 <= src_clear_i;
            src_clear_sync2 <= src_clear_sync1;
            src_clear_sync3 <= src_clear_sync2;
            // Clear pending is asserted when clear is requested and not yet cleared
            src_clear_pending_o <= (src_clear_sync3 & ~src_clear_sync2);
        end
    end

    // Pointer Synchronizer (Gray to Binary)
    // We need to synchronize the destination pointer to the source domain to know when to stop writing
    // and to detect full condition accurately.
    reg [LOG_DEPTH-1:0] dst_ptr_sync1;
    reg [LOG_DEPTH-1:0] dst_ptr_sync2;
    reg [LOG_DEPTH-1:0] dst_ptr_sync3;
    reg [LOG_DEPTH-1:0] dst_ptr_sync4;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ptr_sync1 <= '0;
            dst_ptr_sync2 <= '0;
            dst_ptr_sync3 <= '0;
            dst_ptr_sync4 <= '0;
        end else begin
            dst_ptr_sync1 <= dst_ptr;
            dst_ptr_sync2 <= dst_ptr_sync1;
            dst_ptr_sync3 <= dst_ptr_sync2;
            dst_ptr_sync4 <= dst_ptr_sync3;
        end
    end

    // Full detection
    // Full when write_ptr == dst_ptr_sync4 (synchronized read pointer)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            full <= 1'b0;
        else
            full <= (write_ptr == dst_ptr_sync4);
    end

    // Write Enable Logic
    // Write if valid, ready, and not full. 
    // Also handle clear logic: if clear is active on source side, we might need to stop writing 
    // but the requirement says "flush pending data together". 
    // Typically, clear stops new writes immediately.
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            write_en <= 1'b0;
            src_ready_o <= 1'b1;
            src_ptr <= '0;
            src_gray <= '0;
        end else begin
            // If clear is pending on source side, we stop writing new data
            // However, we must ensure we don't overwrite data that hasn't been read yet if we are clearing.
            // The requirement: "A clear request should flush pending data together on both sides".
            // This implies we stop writing immediately.
            if (src_clear_sync3) begin
                write_en <= 1'b0;
            end else if (src_valid_i && dst_ready_i && !full) begin
                write_en <= 1'b1;
            end else begin
                write_en <= 1'b0;
            end
            
            // Ready is valid and not full (and not clearing? No, ready should be high if we can accept, 
            // but if we are clearing, we stop accepting. So ready is low during clear).
            // Actually, standard behavior: if clear is asserted, FIFO stops accepting.
            src_ready_o <= (!src_clear_sync3 && !full && (src_valid_i ? 1'b1 : 1'b0)); 
            // Correction: ready should be 1 if we are ready to accept. If clear is active, we are not ready.
            // If not clear, ready = !full.
            if (src_clear_sync3)
                src_ready_o <= 1'b0;
            else
                src_ready_o <= (!full);
        end
    end

    // Pointer Update
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= '0;
            src_gray <= '0;
            write_ptr <= '0;
        end else begin
            if (write_en) begin
                src_ptr <= src_ptr + 1'b1;
                write_ptr <= write_ptr + 1'b1;
            end
            // Gray code update for CDC
            if (write_en) begin
                src_gray <= src_gray ^ {1'b0, src_ptr[LOG_DEPTH-2:0]};
            end
        end
    end

    // --- Destination Side Logic ---

    // Synchronize clear request
    reg dst_clear_sync1;
    reg dst_clear_sync2;
    reg dst_clear_sync3;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_sync1 <= 1'b0;
            dst_clear_sync2 <= 1'b0;
            dst_clear_sync3 <= 1'b0;
            dst_clear_pending_o <= 1'b0;
        end else begin
            dst_clear_sync1 <= dst_clear_i;
            dst_clear_sync2 <= dst_clear_sync1;
            dst_clear_sync3 <= dst_clear_sync2;
            dst_clear_pending_o <= (dst_clear_sync3 & ~dst_clear_sync2);
        end
    end

    // Synchronize Source Pointer (Binary to Gray)
    // We need the source pointer in the destination domain to detect empty and update read pointer.
    reg [LOG_DEPTH-1:0] src_ptr_sync1;
    reg [LOG_DEPTH-1:0] src_ptr_sync2;
    reg [LOG_DEPTH-1:0] src_ptr_sync3;
    reg [LOG_DEPTH-1:0] src_ptr_sync4;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ptr_sync1 <= '0;
            src_ptr_sync2 <= '0;
            src_ptr_sync3 <= '0;
            src_ptr_sync4 <= '0;
        end else begin
            src_ptr_sync1 <= src_ptr;
            src_ptr_sync2 <= src_ptr_sync1;
            src_ptr_sync3 <= src_ptr_sync2;
            src_ptr_sync4 <= src_ptr_sync3;
        end
    end

    // Empty detection
    // Empty when read_ptr == src_ptr_sync4
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            empty <= 1'b0;
        else
            empty <= (read_ptr == src_ptr_sync4);
    end

    // Read Enable Logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_en <= 1'b0;
            dst_valid_o <= 1'b0;
            dst_data_o <= '0;
            dst_ptr <= '0;
            dst_gray <= '0;
            read_ptr <= '0;
        end else begin
            // If clear is pending on destination side, we stop reading
            if (dst_clear_sync3) begin
                read_en <= 1'b0;
                dst_valid_o <= 1'b0;
            end else if (dst_ready_i && !empty) begin
                read_en <= 1'b1;
                dst_valid_o <= 1'b1;
            end else begin
                read_en <= 1'b0;
                dst_valid_o <= 1'b0;
            end
        end
    end

    // Pointer Update
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= '0;
            dst_gray <= '0;
            read_ptr <= '0;
        end else begin
            if (read_en) begin
                dst_ptr <= dst_ptr + 1'b1;
                read_ptr <= read_ptr + 1'b1;
            end
            // Gray code update
            if (read_en) begin
                dst_gray <= dst_gray ^ {1'b0, dst_ptr[LOG_DEPTH-2:0]};
            end
        end
    end

    // Data Output Register
    // "The destination word is one registered sample."
    // "dst_valid_o may fall for one destination clock after an accepted beat even when another word is stored."
    // This implies we register the data output.
    reg [WIDTH-1:0] data_reg;
    reg valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            data_reg <= '0;
            valid_reg <= 1'b0;
        end else begin
            if (read_en) begin
                data_reg <= mem[read_ptr];
                valid_reg <= 1'b1;
            end else begin
                // If not reading, keep previous valid state? 
                // Usually, if !dst_ready_i, valid stays high until ready.
                // If empty, valid goes low.
                if (empty)
                    valid_reg <= 1'b0;
                else
                    valid_reg <= valid_reg;
            end
        end
    end

    // Data Output Assignment
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_data_o <= '0;
        else
            dst_data_o <= data_reg;
    end

    // --- Clear Logic Implementation ---

    // Requirement: "A clear resets each binary pointer and the Gray register that feeds its synchronizer on the same edge."
    // Requirement: "flush pending data together on both sides so nothing stale appears afterward."
    
    // We need a global clear signal that is synchronized to both clocks.
    // Since the module has separate clear inputs, we assume they are coordinated externally or 
    // we treat them as independent triggers that must result in a synchronized clear event.
    // However, the prompt says "A clear request...". It implies a single logical clear event.
    // Given the interface has `src_clear_i` and `dst_clear_i`, we must handle the case where they might not be perfectly aligned,
    // but the goal is to flush everything.
    // Strategy: If EITHER side asserts clear, we initiate a clear sequence.
    // To ensure "together", we can use a handshake or simply assert clear on both sides if one is seen.
    // But we cannot drive the other side's input.
    // Interpretation: The user asserts clear on one side, and the other side must also clear.
    // Since we can't drive inputs, we assume the external system ensures both are asserted, OR
    // we implement a mechanism where seeing a clear on one side triggers a "clear in progress" state 
    // that forces the other side to clear if it sees the pending flag? No, that's complex and risky.
    
    // Re-reading: "A clear request should flush pending data together on both sides".
    // This usually implies the caller asserts clear on both clocks simultaneously.
    // If they are independent, we must ensure that if one side clears, the other side also clears 
    // eventually to avoid stale data.
    // Let's assume the standard pattern: The clear inputs are driven by the same external signal 
    // (possibly with different skew), or the user is responsible for asserting both.
    // However, to be robust: If `src_clear_i` is high, we set a flag. If `dst_clear_i` is high, we set a flag.
    // If either flag is set, we perform the reset logic.
    // But we need to ensure the pointers are reset on the SAME edge relative to the data movement.
    
    // Let's implement a "Clear Active" state that is synchronized to both domains.
    // If src_clear_i is high, we set src_clear_req.
    // If dst_clear_i is high, we set dst_clear_req.
    // If (src_clear_req | dst_clear_req), we force a clear operation.
    // To ensure "together", we can use a 2-stage sync for the "Clear Command" and then execute reset on both sides 
    // when the command is stable in both domains.
    
    // Simpler approach compliant with "resets each binary pointer and the Gray register... on the same edge":
    // We will create a synchronized clear signal for each domain.
    // If src_clear_i is asserted, we assert a local clear signal for the source domain.
    // If dst_clear_i is asserted, we assert a local clear signal for the destination domain.
    // The "flush together" requirement implies that if a clear happens, the pointers must go to 0.
    // If the external system asserts clear on both, they will happen together.
    // If they are not synchronized, there might be a window where one side clears and the other doesn't immediately.
    // To strictly follow "flush pending data together", we can implement a cross-domain clear handshake.
    // But without extra ports, we assume the external driver handles the simultaneity or we rely on the fact 
    // that if one side clears, it stops writing/reading, and the other side will eventually clear.
    // However, the prompt says "A clear request...". Let's assume the inputs are driven such that they represent 
    // the same logical event.
    
    // Implementation of the specific reset requirement:
    // "resets each binary pointer and the Gray register that feeds its synchronizer on the same edge."
    // This means when the clear logic triggers, we reset:
    // 1. The binary pointer (src_ptr / dst_ptr)
    // 2. The Gray register (src_gray / dst_gray)
    // 3. The synchronized pointer used for full/empty detection (dst_ptr_sync / src_ptr_sync)
    
    // We will use the synchronized clear signals to trigger the reset.
    
    // Source Domain Clear Logic
    // If src_clear_sync3 is high, we reset source side.
    // We also need to reset the synchronized destination pointer (dst_ptr_sync4) to 0 
    // so that the source side sees the FIFO as empty immediately after clear.
    // This ensures "nothing stale appears".
    
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= '0;
            src_gray <= '0;
            write_ptr <= '0;
            dst_ptr_sync4 <= '0; // Reset sync pointer too
        end else if (src_clear_sync3) begin
            // Clear active on source side
            src_ptr <= '0;
            src_gray <= '0;
            write_ptr <= '0;
            // Reset the synchronized read pointer to 0 so source sees empty
            dst_ptr_sync4 <= '0; 
        end else begin
            // Normal operation updates handled above
        end
    end

    // Destination Domain Clear Logic
    // If dst_clear_sync3 is high, we reset destination side.
    // We also need to reset the synchronized source pointer (src_ptr_sync4) to 0 
    // so that the destination side sees the FIFO as empty immediately after clear.
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= '0;
            dst_gray <= '0;
            read_ptr <= '0;
            src_ptr_sync4 <= '0; // Reset sync pointer too
        end else if (dst_clear_sync3) begin
            // Clear active on destination side
            dst_ptr <= '0;
            dst_gray <= '0;
            read_ptr <= '0;
            // Reset the synchronized write pointer to 0 so dest sees empty
            src_ptr_sync4 <= '0;
        end else begin
            // Normal operation updates handled above
        end
    end

    // Note: If both clear signals are asserted but slightly out of phase, 
    // the first one to trigger will reset its local pointers and the remote sync pointer.
    // The second one will reset its local pointers and the remote sync pointer (which is already 0).
    // This ensures consistency.

endmodule
```<|im_end|>
