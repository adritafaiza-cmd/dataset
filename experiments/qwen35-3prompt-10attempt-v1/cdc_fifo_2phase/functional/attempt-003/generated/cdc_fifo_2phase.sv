```verilog
`timescale 1ns/1ps

module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    // Internal registers for pointers and flags
    reg [ADDR_WIDTH-1:0] write_ptr;
    reg [ADDR_WIDTH-1:0] read_ptr;
    reg [ADDR_WIDTH-1:0] read_ptr_next;
    reg [ADDR_WIDTH-1:0] write_ptr_next;
    reg                  empty_flag;
    reg                  full_flag;
    reg                  read_ptr_changed;
    reg                  write_ptr_changed;
    reg [WIDTH-1:0]      fifo_mem [DEPTH-1:0];

    // Output registers for destination domain
    reg [WIDTH-1:0]      dst_data_reg;
    reg                  dst_valid_reg;

    // ------------------------------------------------------------------
    // Source Domain Logic
    // ------------------------------------------------------------------
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            write_ptr <= '0;
            write_ptr_next <= '0;
            empty_flag <= 1'b1;
            full_flag <= 1'b0;
        end else begin
            // Update write pointer based on valid/ready handshake
            if (src_valid_i && src_ready_o) begin
                write_ptr_next <= write_ptr + 1'b1;
            end else begin
                write_ptr_next <= write_ptr;
            end

            // Check for full condition (circular buffer logic)
            if (write_ptr == read_ptr && !read_ptr_changed) begin
                full_flag <= 1'b1;
            end else if (write_ptr == read_ptr && read_ptr_changed) begin
                full_flag <= 1'b0;
                read_ptr_changed <= 1'b0;
            end else begin
                full_flag <= 1'b0;
            end

            // Update write pointer register
            write_ptr <= write_ptr_next;
        end
    end

    // Determine src_ready_o
    assign src_ready_o = src_valid_i && !full_flag;

    // Write data to memory when valid and ready
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_mem <= '0;
        end else if (src_valid_i && src_ready_o) begin
            fifo_mem[write_ptr] <= src_data_i;
        end
    end

    // ------------------------------------------------------------------
    // Destination Domain Logic
    // ------------------------------------------------------------------
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_ptr <= '0;
            read_ptr_next <= '0;
            dst_valid_reg <= 1'b0;
            dst_data_reg <= '0;
            empty_flag <= 1'b1;
        end else begin
            // Update read pointer based on valid/ready handshake
            if (dst_valid_o && dst_ready_i) begin
                read_ptr_next <= read_ptr + 1'b1;
            end else begin
                read_ptr_next <= read_ptr;
            end

            // Check for empty condition
            if (read_ptr == write_ptr && !write_ptr_changed) begin
                empty_flag <= 1'b1;
            end else if (read_ptr == write_ptr && write_ptr_changed) begin
                empty_flag <= 1'b0;
                write_ptr_changed <= 1'b0;
            end else begin
                empty_flag <= 1'b0;
            end

            // Update read pointer register
            read_ptr <= read_ptr_next;
        end
    end

    // Determine dst_valid_o
    assign dst_valid_o = !empty_flag;

    // Read data from memory when valid
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= '0;
            dst_valid_reg <= 1'b0;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_data_reg <= fifo_mem[read_ptr];
            dst_valid_reg <= 1'b1;
        end else begin
            dst_data_reg <= '0;
            dst_valid_reg <= 1'b0;
        end
    end

    // ------------------------------------------------------------------
    // Cross-Clock Pointers and Flags (Gray Code Encoding)
    // ------------------------------------------------------------------
    // Write pointer update in source domain triggers read pointer change detection
    // Read pointer update in dest domain triggers write pointer change detection
    
    // We use a simple 2-phase handshake with pointer comparison
    // Since we need to detect changes across clocks, we sample the pointers
    // and compare them in the respective domains.

    // Source domain: Detect if read_ptr has changed (from dest domain perspective)
    // We store the read_ptr value in the source domain to compare against current read_ptr
    reg [ADDR_WIDTH-1:0] read_ptr_sampled;
    
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            read_ptr_sampled <= '0;
        end else begin
            read_ptr_sampled <= read_ptr;
        end
    end

    // Destination domain: Detect if write_ptr has changed (from src domain perspective)
    // We store the write_ptr value in the dest domain to compare against current write_ptr
    reg [ADDR_WIDTH-1:0] write_ptr_sampled;
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            write_ptr_sampled <= '0;
        end else begin
            write_ptr_sampled <= write_ptr;
        end
    end

    // Update change flags based on sampled values
    // Note: The logic inside the pointer update blocks above already handles the basic empty/full
    // detection, but we need to ensure the flags are updated correctly across clock domains.
    // The standard approach is to update the flags in the domain where the pointer is being read.

    // Re-implementing the flag logic more robustly for cross-clock pointers:
    
    // In Source Domain:
    // We need to know if read_ptr has changed since the last time we checked.
    // We compare current read_ptr with read_ptr_sampled (which was captured in previous src_clk cycle).
    // However, the read_ptr is updated in dst_clk domain.
    // So, we need to capture the read_ptr in src_clk domain and compare.
    
    // Let's refine the logic:
    // 1. Capture read_ptr in src domain.
    // 2. Compare captured read_ptr with current read_ptr to detect change.
    
    reg [ADDR_WIDTH-1:0] read_ptr_prev;
    
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            read_ptr_prev <= '0;
        end else begin
            read_ptr_prev <= read_ptr;
        end
    end

    // Update read_ptr_changed flag in source domain
    // This flag indicates if the read pointer has moved since the last src_clk edge
    // But wait, read_ptr moves on dst_clk. So we need to detect if it moved between two src_clk edges.
    // Actually, the standard way is:
    // - In src domain, we have a register for read_ptr (let's call it read_ptr_src_reg)
    // - In dst domain, we have a register for write_ptr (let's call it write_ptr_dst_reg)
    // - We compare these registers to the actual pointers to detect changes.

    // Revised approach for robust cross-clock pointer tracking:
    
    // Source Domain Registers
    reg [ADDR_WIDTH-1:0] read_ptr_src_reg;
    reg                  read_ptr_changed_src;
    
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            read_ptr_src_reg <= '0;
            read_ptr_changed_src <= 1'b0;
        end else begin
            read_ptr_src_reg <= read_ptr;
            if (read_ptr_src_reg != read_ptr) begin
                read_ptr_changed_src <= 1'b1;
            end else begin
                read_ptr_changed_src <= 1'b0;
            end
        end
    end

    // Destination Domain Registers
    reg [ADDR_WIDTH-1:0] write_ptr_dst_reg;
    reg                  write_ptr_changed_dst;
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            write_ptr_dst_reg <= '0;
            write_ptr_changed_dst <= 1'b0;
        end else begin
            write_ptr_dst_reg <= write_ptr;
            if (write_ptr_dst_reg != write_ptr) begin
                write_ptr_changed_dst <= 1'b1;
            end else begin
                write_ptr_changed_dst <= 1'b0;
            end
        end
    end

    // Update empty/full flags using the change detection signals
    // Empty: read_ptr == write_ptr AND no pending writes (read_ptr hasn't caught up yet? No)
    // Empty: read_ptr == write_ptr AND read_ptr_changed is false (meaning we are at the same position and nothing new happened)
    // Full: write_ptr == read_ptr AND write_ptr_changed is false
    
    // Correct logic for empty/full with cross-clock pointers:
    // Empty condition: read_ptr == write_ptr AND read_ptr_changed == 0
    // Full condition: write_ptr == read_ptr AND write_ptr_changed == 0
    
    // However, the flags need to be stable. Let's use the change detection to update the flags.
    
    reg                  empty_flag_src;
    reg                  full_flag_dst;
    
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            empty_flag_src <= 1'b1;
        end else begin
            if (read_ptr == write_ptr && !read_ptr_changed_src) begin
                empty_flag_src <= 1'b1;
            end else begin
                empty_flag_src <= 1'b0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            full_flag_dst <= 1'b0;
        end else begin
            if (write_ptr == read_ptr && !write_ptr_changed_dst) begin
                full_flag_dst <= 1'b1;
            end else begin
                full_flag_dst <= 1'b0;
            end
        end
    end

    // Final assignments for src_ready_o and dst_valid_o
    // src_ready_o is determined in source domain
    assign src_ready_o = src_valid_i && !full_flag_dst;
    
    // dst_valid_o is determined in destination domain
    assign dst_valid_o = !empty_flag_src;

    // Data output is already handled by the register logic in destination domain
    // dst_data_o is assigned to dst_data_reg
    assign dst_data_o = dst_data_reg;

endmodule
```<|im_end|>
