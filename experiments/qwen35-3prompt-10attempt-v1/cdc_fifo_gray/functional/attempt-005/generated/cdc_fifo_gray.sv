```verilog
`timescale 1ns/1ps

module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output reg [WIDTH-1:0] dst_data_o,
    output reg             dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam GRAY_WIDTH = $clog2(DEPTH);

    // Internal registers for source domain
    reg [LOG_DEPTH-1:0] src_ptr;
    reg [LOG_DEPTH-1:0] src_full_ptr;
    reg [LOG_DEPTH-1:0] src_count;
    reg [WIDTH-1:0] src_data_reg;
    reg src_valid_reg;
    reg src_full_reg;

    // Internal registers for destination domain
    reg [LOG_DEPTH-1:0] dst_ptr;
    reg [LOG_DEPTH-1:0] dst_empty_ptr;
    reg [LOG_DEPTH-1:0] dst_count;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg dst_empty_reg;

    // Cross-domain pointers (Gray encoded for stability)
    reg [LOG_DEPTH-1:0] src_gray_ptr;
    reg [LOG_DEPTH-1:0] dst_gray_ptr;

    // CDC Registers for pointers (Gray to Binary conversion happens in logic)
    // We use a simple 2-stage synchronizer for the pointer values themselves
    // to ensure the binary pointers in the other domain are stable.
    
    // Source Domain: Store binary pointers, convert to Gray for crossing
    // Destination Domain: Store binary pointers, convert to Gray for crossing

    // --- Source Domain Logic ---
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= 0;
            src_full_ptr <= 0;
            src_count <= 0;
            src_data_reg <= 0;
            src_valid_reg <= 0;
            src_full_reg <= 0;
        end else begin
            src_data_reg <= src_data_i;
            src_valid_reg <= src_valid_i;
            
            // Full check: if count == DEPTH
            src_full_reg <= (src_count == DEPTH);
            
            if (src_valid_i && src_ready_o) begin
                if (src_full_reg) begin
                    // FIFO Full, do not increment
                end else begin
                    src_ptr <= src_ptr + 1'b1;
                    src_count <= src_count + 1'b1;
                end
            end
        end
    end

    // --- Destination Domain Logic ---
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= 0;
            dst_empty_ptr <= 0;
            dst_count <= 0;
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
            dst_empty_reg <= 0;
        end else begin
            dst_data_reg <= dst_data_reg; // Hold data
            dst_valid_reg <= dst_valid_reg; // Hold valid state logic
            
            // Empty check: if count == 0
            dst_empty_reg <= (dst_count == 0);
            
            if (dst_valid_reg && dst_ready_i) begin
                if (dst_empty_reg) begin
                    // FIFO Empty, do not decrement
                end else begin
                    dst_ptr <= dst_ptr + 1'b1;
                    dst_count <= dst_count + 1'b1;
                end
            end
        end
    end

    // --- Output Logic ---
    always @(*) begin
        src_ready_o = !src_full_reg && src_valid_i;
        dst_valid_o = dst_valid_reg && !dst_empty_reg;
        dst_data_o = dst_data_reg;
    end

    // --- Pointer Conversion and Synchronization ---
    
    // Helper function to convert Binary to Gray
    function [LOG_DEPTH-1:0] bin_to_gray;
        input [LOG_DEPTH-1:0] bin;
        begin
            bin_to_gray = {bin[LOG_DEPTH-2:0], bin[LOG_DEPTH-1] ^ bin[LOG_DEPTH-2]};
        end
    end

    // Helper function to convert Gray to Binary
    function [LOG_DEPTH-1:0] gray_to_bin;
        input [LOG_DEPTH-1:0] gray;
        begin
            gray_to_bin = gray;
            for (integer i = LOG_DEPTH-2; i >= 0; i = i - 1) begin
                gray_to_bin[i] = gray[i] ^ gray[i+1];
            end
        end
    end

    // Synchronize Source Binary Pointer to Destination Domain
    // We need to read src_ptr (binary) in dst_clk domain.
    // Since src_ptr changes every cycle, we must sync the value.
    // However, standard practice for FIFO pointers is to sync the Gray encoded version
    // to avoid metastability on the transition edge, then convert back to binary.
    
    // Stage 1: Sync src_gray_ptr
    reg [LOG_DEPTH-1:0] src_gray_sync_1;
    reg [LOG_DEPTH-1:0] src_gray_sync_2;
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_gray_sync_1 <= 0;
            src_gray_sync_2 <= 0;
        end else begin
            src_gray_sync_1 <= src_gray_ptr;
            src_gray_sync_2 <= src_gray_sync_1;
        end
    end

    // Synchronize Destination Binary Pointer to Source Domain
    reg [LOG_DEPTH-1:0] dst_gray_sync_1;
    reg [LOG_DEPTH-1:0] dst_gray_sync_2;
    
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_gray_sync_1 <= 0;
            dst_gray_sync_2 <= 0;
        end else begin
            dst_gray_sync_1 <= dst_gray_ptr;
            dst_gray_sync_2 <= dst_gray_sync_1;
        end
    end

    // --- Cross Domain Control Signals ---

    // 1. Determine if FIFO is Full (in Source Domain)
    // We need to compare src_ptr with dst_ptr.
    // src_ptr is binary. dst_ptr is binary (in src domain).
    // We convert dst_gray_sync_2 to binary to get dst_ptr in src domain.
    // Note: The pointer comparison logic must be robust.
    
    reg src_full_calc;
    reg src_empty_calc;
    reg dst_full_calc;
    reg dst_empty_calc;

    // Calculate Full/Empty in Source Domain using synchronized dst pointer
    always @(*) begin
        if (src_rst_ni) begin
            src_full_calc = 1'b1;
            src_empty_calc = 1'b1;
        end else begin
            // Convert synchronized dst gray pointer to binary
            wire [LOG_DEPTH-1:0] dst_ptr_synced = gray_to_bin(dst_gray_sync_2);
            
            // Full: src_ptr == dst_ptr (wrapping around logic handled by count usually, 
            // but for pointer comparison: if src_ptr == dst_ptr, it's full if we are at end)
            // Actually, standard logic: Full if src_ptr == dst_ptr AND count == DEPTH?
            // No, simpler: Full if src_ptr == dst_ptr (assuming circular buffer logic where 
            // we only increment if not full).
            // Let's use the count register for precise full/empty detection to avoid edge cases.
            
            // Full: src_count == DEPTH
            src_full_calc = (src_count == DEPTH);
            
            // Empty: dst_count == 0
            // We need dst_count in source domain.
            // dst_count is in dst domain. We need to sync it.
            // Wait, the standard way is:
            // Full in Src: src_ptr == dst_ptr (synchronized)
            // Empty in Dst: dst_ptr == src_ptr (synchronized)
            // But we have separate count registers.
            // Let's rely on the count registers for the actual full/empty status 
            // and use pointers only for the cross-domain handshake.
            
            // Re-evaluating strategy:
            // To know if we can write: We need to know if FIFO is full.
            // Full condition: src_ptr == dst_ptr (when dst_ptr is the write pointer in src domain).
            // But dst_ptr is the read pointer.
            // Correct logic:
            // Write Pointer (src_ptr) vs Read Pointer (dst_ptr_synced).
            // If src_ptr == dst_ptr_synced, then FIFO is either Full or Empty.
            // We distinguish using counts.
            
            // Full: src_ptr == dst_ptr_synced AND src_count == DEPTH
            // Empty: dst_ptr == src_ptr_synced AND dst_count == 0
            
            // However, the pointers cross asynchronously.
            // We need to generate 'full' signal in src domain and 'empty' signal in dst domain.
            
            // Src Full Signal:
            // We need to know if dst_ptr (in src domain) has caught up to src_ptr.
            // If src_ptr == dst_ptr_synced, it means the read pointer has reached the write pointer.
            // If src_count == DEPTH, it is Full.
            src_full_calc = (src_ptr == dst_ptr_synced) && (src_count == DEPTH);
            
            // Src Empty Signal:
            // If dst_ptr (in src domain) has passed src_ptr? No.
            // Empty means dst_ptr == src_ptr AND dst_count == 0.
            // But we need to know if dst_ptr is behind src_ptr.
            // Actually, the standard implementation uses the count to drive full/empty locally,
            // and the pointers to drive the cross-domain ready/valid.
            
            // Let's refine:
            // src_ready_o = !src_full_calc
            // dst_valid_o = !dst_empty_calc
            
            // src_full_calc: Is the FIFO full?
            // We know src_count. We need to know if dst_ptr == src_ptr.
            // If dst_ptr == src_ptr, and src_count == DEPTH -> Full.
            // If dst_ptr == src_ptr, and src_count != DEPTH -> Empty.
            
            // dst_empty_calc: Is the FIFO empty?
            // We know dst_count. We need to know if src_ptr == dst_ptr.
            // If src_ptr == dst_ptr, and dst_count == 0 -> Empty.
            
            // So we need src_ptr in dst domain and dst_ptr in src domain.
            
            // src_ptr in dst domain:
            wire [LOG_DEPTH-1:0] src_ptr_synced = gray_to_bin(src_gray_sync_2);
            
            // dst_ptr in src domain:
            wire [LOG_DEPTH-1:0] dst_ptr_synced_src = gray_to_bin(dst_gray_sync_2);
            
            // Full in Src Domain:
            // Condition: src_ptr == dst_ptr_synced_src AND src_count == DEPTH
            // But wait, if src_ptr == dst_ptr_synced_src, it could be empty too.
            // So:
            src_full_calc = (src_ptr == dst_ptr_synced_src) && (src_count == DEPTH);
            
            // Empty in Dst Domain:
            // Condition: dst_ptr == src_ptr_synced AND dst_count == 0
            dst_empty_calc = (dst_ptr == src_ptr_synced) && (dst_count == 0);
        end
    end

    // Generate Cross Domain Ready/Valid
    // src_ready_o is generated in src domain based on src_full_calc
    // dst_valid_o is generated in dst domain based on dst_empty_calc
    
    // However, there is a nuance: 
    // src_ready_o should be high if NOT full.
    // dst_valid_o should be high if NOT empty.
    
    // We need to drive src_ready_o in src domain.
    // We need to drive dst_valid_o in dst domain.
    
    // The logic above calculates src_full_calc and dst_empty_calc.
    // src_full_calc is valid in src domain (uses src_ptr and synced dst_ptr).
    // dst_empty_calc is valid in dst domain (uses dst_ptr and synced src_ptr).
    
    // Assignments:
    // src_ready_o = ~src_full_calc;
    // dst_valid_o = ~dst_empty_calc;
    
    // But we must ensure the assignment happens in the correct clock domain.
    // src_ready_o is an output of the module, driven by src logic.
    // dst_valid_o is an output of the module, driven by dst logic.
    
    // Let's restructure the always blocks for outputs to be clear.
    
    // Src Domain Output Logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_o <= 1'b1; // Reset state: ready
        end else begin
            // Calculate full status
            wire [LOG_DEPTH-1:0] dst_ptr_synced_src = gray_to_bin(dst_gray_sync_2);
            wire is_full = (src_ptr == dst_ptr_synced_src) && (src_count == DEPTH);
            src_ready_o <= !is_full;
        end
    end

    // Dst Domain Output Logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 1'b0; // Reset state: invalid
        end else begin
            // Calculate empty status
            wire [LOG_DEPTH-1:0] src_ptr_synced = gray_to_bin(src_gray_sync_2);
            wire is_empty = (dst_ptr == src_ptr_synced) && (dst_count == 0);
            dst_valid_o <= !is_empty;
        end
    end

    // Update Gray Pointers
    // src_gray_ptr is updated in src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_ptr <= 0;
        end else begin
            src_gray_ptr <= bin_to_gray(src_ptr);
        end
    end

    // dst_gray_ptr is updated in dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_ptr <= 0;
        end else begin
            dst_gray_ptr <= bin_to_gray(dst_ptr);
        end
    end

endmodule
```<|im_end|>
