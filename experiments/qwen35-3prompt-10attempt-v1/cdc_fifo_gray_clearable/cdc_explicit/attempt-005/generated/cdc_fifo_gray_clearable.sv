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
    reg               src_clear_req;
    reg               dst_clear_req;
    reg               dst_valid_reg;
    reg               dst_clear_pending;
    reg               src_clear_pending;
    reg               src_ready_reg;
    reg               dst_ready_reg;
    
    // Pointers
    reg [LOG_DEPTH-1:0] src_ptr_gray;
    reg [LOG_DEPTH-1:0] dst_ptr_gray;
    reg [LOG_DEPTH-1:0] src_ptr_bin;
    reg [LOG_DEPTH-1:0] dst_ptr_bin;
    
    // Synchronizer registers for pointers
    reg [LOG_DEPTH-1:0] src_ptr_sync_0;
    reg [LOG_DEPTH-1:0] src_ptr_sync_1;
    reg [LOG_DEPTH-1:0] dst_ptr_sync_0;
    reg [LOG_DEPTH-1:0] dst_ptr_sync_1;
    
    // Synchronizer registers for clear requests
    reg               src_clear_sync_0;
    reg               src_clear_sync_1;
    reg               dst_clear_sync_0;
    reg               dst_clear_sync_1;
    
    // Synchronizer registers for ready signals
    reg               dst_ready_sync_0;
    reg               dst_ready_sync_1;
    reg               src_ready_sync_0;
    reg               src_ready_sync_1;

    // ---------------------------------------------------------
    // Source Domain Logic
    // ---------------------------------------------------------
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_data_reg      <= {WIDTH{1'b0}};
            src_valid_reg     <= 1'b0;
            src_clear_req     <= 1'b0;
            src_ptr_bin       <= 0;
            src_ptr_gray      <= 0;
            src_clear_pending_o <= 1'b0;
            src_ready_reg     <= 1'b1;
        end else begin
            // Handle Clear Request
            src_clear_req <= src_clear_i;
            
            // Update Clear Pending Status
            if (src_clear_req) begin
                src_clear_pending_o <= 1'b1;
            end else if (src_ptr_bin == 0) begin
                src_clear_pending_o <= 1'b0;
            end
            
            // Pointer Logic
            if (src_valid_reg && src_ready_reg && !src_clear_req) begin
                src_ptr_bin <= src_ptr_bin + 1'b1;
            end else if (src_clear_req) begin
                src_ptr_bin <= 0;
            end
            
            // Gray Code Generation
            src_ptr_gray <= src_ptr_bin;
            
            // Valid/Ready Logic
            if (src_clear_req) begin
                src_valid_reg <= 1'b0;
                src_ready_reg <= 1'b1;
            end else if (src_ptr_bin == 0) begin
                src_valid_reg <= 1'b0;
                src_ready_reg <= 1'b1;
            end else begin
                src_valid_reg <= src_valid_i;
                src_ready_reg <= dst_ready_i;
            end
            
            // Data Capture
            if (src_valid_i && src_ready_i && !src_clear_req) begin
                src_data_reg <= src_data_i;
            end
        end
    end

    // ---------------------------------------------------------
    // Destination Domain Logic
    // ---------------------------------------------------------
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg     <= 1'b0;
            dst_clear_req     <= 1'b0;
            dst_ptr_bin       <= 0;
            dst_ptr_gray      <= 0;
            dst_clear_pending_o <= 1'b0;
            dst_ready_reg     <= 1'b0;
            dst_data_o        <= {WIDTH{1'b0}};
        end else begin
            // Handle Clear Request
            dst_clear_req <= dst_clear_i;
            
            // Update Clear Pending Status
            if (dst_clear_req) begin
                dst_clear_pending_o <= 1'b1;
            end else if (dst_ptr_bin == 0) begin
                dst_clear_pending_o <= 1'b0;
            end
            
            // Pointer Logic
            if (dst_valid_reg && dst_ready_reg && !dst_clear_req) begin
                dst_ptr_bin <= dst_ptr_bin + 1'b1;
            end else if (dst_clear_req) begin
                dst_ptr_bin <= 0;
            end
            
            // Gray Code Generation
            dst_ptr_gray <= dst_ptr_bin;
            
            // Valid/Ready Logic
            if (dst_clear_req) begin
                dst_valid_reg <= 1'b0;
                dst_ready_reg <= 1'b1;
            end else if (dst_ptr_bin == 0) begin
                dst_valid_reg <= 1'b0;
                dst_ready_reg <= 1'b1;
            end else begin
                dst_valid_reg <= src_valid_reg;
                dst_ready_reg <= src_ready_reg;
            end
            
            // Data Output (Registered)
            if (dst_valid_reg && dst_ready_reg && !dst_clear_req) begin
                dst_data_o <= src_data_reg;
            end
        end
    end

    // ---------------------------------------------------------
    // CDC Synchronizers: Source -> Destination
    // ---------------------------------------------------------
    
    // Pointer Synchronizers (Async FIFO Core)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ptr_sync_0 <= {GRAY_WIDTH{1'b0}};
            src_ptr_sync_1 <= {GRAY_WIDTH{1'b0}};
        end else begin
            src_ptr_sync_0 <= src_ptr_gray;
            src_ptr_sync_1 <= src_ptr_sync_0;
        end
    end

    // Clear Request Synchronizers
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_clear_sync_0 <= 1'b0;
            src_clear_sync_1 <= 1'b0;
        end else begin
            src_clear_sync_0 <= src_clear_req;
            src_clear_sync_1 <= src_clear_sync_0;
        end
    end

    // Ready Signal Synchronizers
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ready_sync_0 <= 1'b0;
            dst_ready_sync_1 <= 1'b0;
        end else begin
            dst_ready_sync_0 <= dst_ready_i;
            dst_ready_sync_1 <= dst_ready_sync_0;
        end
    end

    // ---------------------------------------------------------
    // CDC Synchronizers: Destination -> Source
    // ---------------------------------------------------------

    // Pointer Synchronizers
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ptr_sync_0 <= {GRAY_WIDTH{1'b0}};
            dst_ptr_sync_1 <= {GRAY_WIDTH{1'b0}};
        end else begin
            dst_ptr_sync_0 <= dst_ptr_gray;
            dst_ptr_sync_1 <= dst_ptr_sync_0;
        end
    end

    // Clear Request Synchronizers
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_clear_sync_0 <= 1'b0;
            dst_clear_sync_1 <= 1'b0;
        end else begin
            dst_clear_sync_0 <= dst_clear_req;
            dst_clear_sync_1 <= dst_clear_sync_0;
        end
    end

    // Ready Signal Synchronizers
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_sync_0 <= 1'b0;
            src_ready_sync_1 <= 1'b0;
        end else begin
            src_ready_sync_0 <= src_ready_reg;
            src_ready_sync_1 <= src_ready_sync_0;
        end
    end

    // ---------------------------------------------------------
    // Cross-Domain Logic Implementation
    // ---------------------------------------------------------

    // Source Domain: Update internal state based on synchronized destination signals
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_reg     <= 1'b0;
            src_ready_reg     <= 1'b1;
            src_data_reg      <= {WIDTH{1'b0}};
            src_ptr_bin       <= 0;
            src_ptr_gray      <= 0;
            src_clear_pending_o <= 1'b0;
        end else begin
            // Clear Logic in Source Domain
            if (src_clear_req) begin
                src_clear_pending_o <= 1'b1;
                src_valid_reg       <= 1'b0;
                src_ready_reg       <= 1'b1;
                src_ptr_bin         <= 0;
                src_ptr_gray        <= 0;
                src_data_reg        <= {WIDTH{1'b0}};
            end else if (src_ptr_bin == 0) begin
                src_clear_pending_o <= 1'b0;
                src_valid_reg       <= 1'b0;
                src_ready_reg       <= 1'b1;
            end else begin
                src_clear_pending_o <= 1'b0;
                src_valid_reg       <= src_valid_i;
                src_ready_reg       <= dst_ready_sync_1;
            end

            // Data Capture
            if (src_valid_i && src_ready_sync_1 && !src_clear_req) begin
                src_data_reg <= src_data_i;
            end

            // Pointer Update
            if (src_valid_reg && src_ready_sync_1 && !src_clear_req) begin
                src_ptr_bin <= src_ptr_bin + 1'b1;
            end else if (src_clear_req) begin
                src_ptr_bin <= 0;
            end
            
            // Gray Code Update
            src_ptr_gray <= src_ptr_bin;
        end
    end

    // Destination Domain: Update internal state based on synchronized source signals
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg     <= 1'b0;
            dst_ready_reg     <= 1'b0;
            dst_ptr_bin       <= 0;
            dst_ptr_gray      <= 0;
            dst_clear_pending_o <= 1'b0;
            dst_data_o        <= {WIDTH{1'b0}};
        end else begin
            // Clear Logic in Destination Domain
            if (dst_clear_req) begin
                dst_clear_pending_o <= 1'b1;
                dst_valid_reg       <= 1'b0;
                dst_ready_reg       <= 1'b1;
                dst_ptr_bin         <= 0;
                dst_ptr_gray        <= 0;
                dst_data_o          <= {WIDTH{1'b0}};
            end else if (dst_ptr_bin == 0) begin
                dst_clear_pending_o <= 1'b0;
                dst_valid_reg       <= 1'b0;
                dst_ready_reg       <= 1'b1;
            end else begin
                dst_clear_pending_o <= 1'b0;
                dst_valid_reg       <= src_valid_sync_1;
                dst_ready_reg       <= src_ready_sync_1;
            end

            // Data Output
            if (dst_valid_reg && dst_ready_reg && !dst_clear_req) begin
                dst_data_o <= src_data_sync_1;
            end

            // Pointer Update
            if (dst_valid_reg && dst_ready_reg && !dst_clear_req) begin
                dst_ptr_bin <= dst_ptr_bin + 1'b1;
            end else if (dst_clear_req) begin
                dst_ptr_bin <= 0;
            end
            
            // Gray Code Update
            dst_ptr_gray <= dst_ptr_bin;
        end
    end

    // Additional Synchronizers needed for the cross-domain logic above
    // Source Valid Sync
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync_0 <= 1'b0;
            src_valid_sync_1 <= 1'b0;
        end else begin
            src_valid_sync_0 <= src_valid_reg;
            src_valid_sync_1 <= src_valid_sync_0;
        end
    end

    // Source Data Sync
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_data_sync_0 <= {WIDTH{1'b0}};
            src_data_sync_1 <= {WIDTH{1'b0}};
        end else begin
            src_data_sync_0 <= src_data_reg;
            src_data_sync_1 <= src_data_sync_0;
        end
    end

    // Destination Valid Sync (for source domain)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_valid_sync_0 <= 1'b0;
            dst_valid_sync_1 <= 1'b0;
        end else begin
            dst_valid_sync_0 <= dst_valid_reg;
            dst_valid_sync_1 <= dst_valid_sync_0;
        end
    end

    // Destination Data Sync (for source domain - not strictly needed for logic but good for completeness if used)
    // Actually, source doesn't need destination data, only destination needs source data.
    // The logic above handles the necessary flows.

    // Re-verify the logic flow for clarity and correctness:
    // 1. Source Domain:
    //    - Reads dst_ready_sync_1 to determine if it can push.
    //    - Updates src_ptr_bin and src_ptr_gray.
    //    - Outputs src_ready_o based on internal state and dst_ready_sync_1.
    //    - Handles src_clear_i locally and synchronizes dst_clear_i.
    
    // 2. Destination Domain:
    //    - Reads src_valid_sync_1 and src_ready_sync_1 to determine if it can pop.
    //    - Updates dst_ptr_bin and dst_ptr_gray.
    //    - Outputs dst_valid_o based on internal state and src_valid_sync_1.
    //    - Handles dst_clear_i locally and synchronizes src_clear_i.
    
    // 3. Clear Logic:
    //    - When a clear request arrives in a domain, it sets the pending flag.
    //    - It forces pointers to 0 and clears valid/ready states.
    //    - The pending flag stays high until the pointer returns to 0.
    
    // 4. Reset Logic:
    //    - Active low resets clear all registers and pointers to 0.
    //    - This is safe as it's synchronous to the local clock.

    // Note: The previous block had some redundant logic. Let's consolidate into clean blocks.
    
    // --- Source Domain Consolidated ---
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_data_reg      <= {WIDTH{1'b0}};
            src_valid_reg     <= 1'b0;
            src_clear_req     <= 1'b0;
            src_ptr_bin       <= 0;
            src_ptr_gray      <= 0;
            src_clear_pending_o <= 1'b0;
            src_ready_reg     <= 1'b1;
        end else begin
            // Sync Clear Request
            src_clear_req <= src_clear_sync_1;
            
            // Clear Pending Output
            if (src_clear_req) begin
                src_clear_pending_o <= 1'b1;
            end else if (src_ptr_bin == 0) begin
                src_clear_pending_o <= 1'b0;
            end
            
            // Pointer Logic
            if (src_valid_reg && src_ready_reg && !src_clear_req) begin
                src_ptr_bin <= src_ptr_bin + 1'b1;
            end else if (src_clear_req) begin
                src_ptr_bin <= 0;
            end
            
            // Gray Code
            src_ptr_gray <= src_ptr_bin;
            
            // Valid/Ready Logic
            if (src_clear_req) begin
                src_valid_reg <= 1'b0;
                src_ready_reg <= 1'b1;
            end else if (src_ptr_bin == 0) begin
                src_valid_reg <= 1'b0;
                src_ready_reg <= 1'b1;
            end else begin
                src_valid_reg <= src_valid_i;
                src_ready_reg <= dst_ready_sync_1;
            end
            
            // Data Capture
            if (src_valid_i && src_ready_sync_1 && !src_clear_req) begin
                src_data_reg <= src_data_i;
            end
        end
    end

    // --- Destination Domain Consolidated ---
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg     <= 1'b0;
            dst_clear_req     <= 1'b0;
            dst_ptr_bin       <= 0;
            dst_ptr_gray      <= 0;
            dst_clear_pending_o <= 1'b0;
            dst_ready_reg     <= 1'b0;
            dst_data_o        <= {WIDTH{1'b0}};
        end else begin
            // Sync Clear Request
            dst_clear_req <= dst_clear_sync_1;
            
            // Clear Pending Output
            if (dst_clear_req) begin
                dst_clear_pending_o <= 1'b1;
            end else if (dst_ptr_bin == 0) begin
                dst_clear_pending_o <= 1'b0;
            end
            
            // Pointer Logic
            if (dst_valid_reg && dst_ready_reg && !dst_clear_req) begin
                dst_ptr_bin <= dst_ptr_bin + 1'b1;
            end else if (dst_clear_req) begin
                dst_ptr_bin <= 0;
            end
            
            // Gray Code
            dst_ptr_gray <= dst_ptr_bin;
            
            // Valid/Ready Logic
            if (dst_clear_req) begin
                dst_valid_reg <= 1'b0;
                dst_ready_reg <= 1'b1;
            end else if (dst_ptr_bin == 0) begin
                dst_valid_reg <= 1'b0;
                dst_ready_reg <= 1'b1;
            end else begin
                dst_valid_reg <= src_valid_sync_1;
                dst_ready_reg <= src_ready_sync_1;
            end
            
            // Data Output
            if (dst_valid_reg && dst_ready_reg && !dst_clear_req) begin
                dst_data_o <= src_data_sync_1;
            end
        end
    end

    // --- Synchronizers for Pointers (Source -> Dest) ---
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ptr_sync_0 <= {GRAY_WIDTH{1'b0}};
            src_ptr_sync_1 <= {GRAY_WIDTH{1'b0}};
        end else begin
            src_ptr_sync_0 <= src_ptr_gray;
            src_ptr_sync_1 <= src_ptr_sync_0;
        end
    end

    // --- Synchronizers for Clear Requests (Source -> Dest) ---
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_clear_sync_0 <= 1'b0;
            src_clear_sync_1 <= 1'b0;
        end else begin
            src_clear_sync_0 <= src_clear_req;
            src_clear_sync_1 <= src_clear_sync_0;
        end
    end

    // --- Synchronizers for Ready Signals (Dest -> Src) ---
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_sync_0 <= 1'b0;
            dst_ready_sync_1 <= 1'b0;
        end else begin
            dst_ready_sync_0 <= dst_ready_i;
            dst_ready_sync_1 <= dst_ready_sync_0;
        end
    end

    // --- Synchronizers for Pointers (Dest -> Src) ---
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ptr_sync_0 <= {GRAY_WIDTH{1'b0}};
            dst_ptr_sync_1 <= {GRAY_WIDTH{1'b0}};
        end else begin
            dst_ptr_sync_0 <= dst_ptr_gray;
            dst_ptr_sync_1 <= dst_ptr_sync_0;
        end
    end

    // --- Synchronizers for Clear Requests (Dest -> Src) ---
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_clear_sync_0 <= 1'b0;
            dst_clear_sync_1 <= 1'b0;
        end else begin
            dst_clear_sync_0 <= dst_clear_req;
            dst_clear_sync_1 <= dst_clear_sync_0;
        end
    end

    // --- Synchronizers for Valid Signals (Src -> Dest) ---
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync_0 <= 1'b0;
            src_valid_sync_1 <= 1'b0;
        end else begin
            src_valid_sync_0 <= src_valid_reg;
            src_valid_sync_1 <= src_valid_sync_0;
        end
    end

    // --- Synchronizers for Data (Src -> Dest) ---
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_data_sync_0 <= {WIDTH{1'b0}};
            src_data_sync_1 <= {WIDTH{1'b0}};
        end else begin
            src_data_sync_0 <= src_data_reg;
            src_data_sync_1 <= src_data_sync_0;
        end
    end

    // --- Synchronizers for Ready Signals (Src -> Dest) ---
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ready_sync_0 <= 1'b0;
            src_ready_sync_1 <= 1'b0;
        end else begin
            src_ready_sync_0 <= src_ready_reg;
            src_ready_sync_1 <= src_ready_sync_0;
        end
    end

    // Output assignments
    assign src_ready_o = src_ready_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
```<|im_end|>
