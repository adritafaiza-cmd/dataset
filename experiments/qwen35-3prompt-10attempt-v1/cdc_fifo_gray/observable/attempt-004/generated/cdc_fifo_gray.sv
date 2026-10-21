```verilog
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
    localparam GRAY_WIDTH = LOG_DEPTH;

    // Internal signals
    reg [GRAY_WIDTH-1:0] src_ptr_gray;
    reg [GRAY_WIDTH-1:0] dst_ptr_gray;
    reg [LOG_DEPTH-1:0] src_ptr_bin;
    reg [LOG_DEPTH-1:0] dst_ptr_bin;
    reg [WIDTH*DEPTH-1:0] memory;
    reg [LOG_DEPTH-1:0] read_count;
    reg [LOG_DEPTH-1:0] write_count;
    reg [LOG_DEPTH-1:0] read_count_sync;
    reg [LOG_DEPTH-1:0] write_count_sync;
    reg src_valid_sync;
    reg src_valid_sync_2;
    reg dst_ready_sync;
    reg dst_ready_sync_2;
    reg dst_valid_sync;
    reg dst_valid_sync_2;
    reg write_enable;
    reg read_enable;
    reg empty_flag;
    reg full_flag;

    // Clock Domain Crossing: Source Side (Write Pointer & Valid)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr_gray <= '0;
            src_ptr_bin <= '0;
            src_valid_sync <= 1'b0;
            src_valid_sync_2 <= 1'b0;
            write_count <= '0;
        end else begin
            src_ptr_gray <= src_ptr_gray;
            src_ptr_bin <= src_ptr_bin;
            
            // Synchronize src_valid_i
            src_valid_sync <= src_valid_i;
            src_valid_sync_2 <= src_valid_sync;
            
            // Calculate write count for flow control
            write_count <= src_ptr_bin;
        end
    end

    // Clock Domain Crossing: Destination Side (Read Pointer & Ready)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr_gray <= '0;
            dst_ptr_bin <= '0;
            dst_ready_sync <= 1'b0;
            dst_ready_sync_2 <= 1'b0;
            dst_valid_sync <= 1'b0;
            dst_valid_sync_2 <= 1'b0;
            read_count <= '0;
        end else begin
            dst_ptr_gray <= dst_ptr_gray;
            dst_ptr_bin <= dst_ptr_bin;
            
            // Synchronize dst_ready_i
            dst_ready_sync <= dst_ready_i;
            dst_ready_sync_2 <= dst_ready_sync;
            
            // Calculate read count for flow control
            read_count <= dst_ptr_bin;
        end
    end

    // Gray Code to Binary Conversion
    function [LOG_DEPTH-1:0] gray_to_bin;
        input [GRAY_WIDTH-1:0] gray;
        reg [LOG_DEPTH-1:0] bin;
        integer i;
        
        bin = 0;
        for (i = 0; i < LOG_DEPTH; i = i + 1) begin
            bin[i] = gray[i] ^ bin[i+1];
        end
        gray_to_bin = bin;
    endfunction

    // Binary to Gray Code Conversion
    function [GRAY_WIDTH-1:0] bin_to_gray;
        input [LOG_DEPTH-1:0] bin;
        reg [GRAY_WIDTH-1:0] gray;
        integer i;
        
        gray = 0;
        gray[0] = bin[0];
        for (i = 1; i < LOG_DEPTH; i = i + 1) begin
            gray[i] = bin[i] ^ bin[i-1];
        end
        bin_to_gray = gray;
    endfunction

    // Write Logic (Source Domain)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_o <= 1'b1;
            write_enable <= 1'b0;
            empty_flag <= 1'b1;
            full_flag <= 1'b0;
        end else begin
            src_ready_o <= 1'b1;
            
            // Flow Control: Not Full
            if (write_count < (DEPTH - 1)) begin
                write_enable <= 1'b1;
                empty_flag <= 1'b0;
                full_flag <= 1'b0;
            end else if (write_count == (DEPTH - 1)) begin
                write_enable <= 1'b0;
                full_flag <= 1'b1;
                empty_flag <= 1'b0;
            end else begin
                write_enable <= 1'b0;
                full_flag <= 1'b1;
                empty_flag <= 1'b0;
            end
            
            // Update pointer if writing
            if (write_enable && src_valid_i && src_ready_o) begin
                src_ptr_gray <= src_ptr_gray + 1'b1;
                src_ptr_bin <= gray_to_bin(src_ptr_gray);
            end
        end
    end

    // Read Logic (Destination Domain)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 1'b0;
            dst_data_o <= '0;
            read_enable <= 1'b0;
            empty_flag <= 1'b1;
            full_flag <= 1'b0;
        end else begin
            dst_valid_o <= 1'b0;
            
            // Flow Control: Not Empty
            if (read_count < write_count) begin
                read_enable <= 1'b1;
                empty_flag <= 1'b0;
                full_flag <= 1'b0;
            end else if (read_count == write_count) begin
                read_enable <= 1'b0;
                full_flag <= 1'b0;
                empty_flag <= 1'b1;
            end
            
            // Update pointer if reading
            if (read_enable && dst_ready_i) begin
                dst_ptr_gray <= dst_ptr_gray + 1'b1;
                dst_ptr_bin <= gray_to_bin(dst_ptr_gray);
            end
        end
    end

    // Data Output Logic (Destination Domain)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 1'b0;
            dst_data_o <= '0;
        end else begin
            // Check if there is data to read
            if (read_count < write_count) begin
                // Calculate address from read pointer and count
                // Address = read_ptr + count_offset
                // Since we use binary pointers, we need to handle the wrap-around carefully
                // However, a simpler approach for FIFO depth calculation:
                // The actual data index is (read_ptr_bin + (write_ptr_bin - read_ptr_bin)) % DEPTH
                // But since we store write_count and read_count as binary, 
                // the difference (write_count - read_count) gives the number of valid items.
                // We need the specific index.
                
                // Let's use the gray pointers to determine the index relative to read pointer
                // Index = (write_ptr_gray - read_ptr_gray) in binary
                // Since we have write_count and read_count as binary snapshots:
                // We can reconstruct the index by comparing the gray codes or using the binary difference
                
                // Simpler approach: Use the binary difference directly if we ensure no overflow issues
                // But standard FIFO implementation uses the gray code difference for pointer comparison
                // Here, we will use the binary difference logic:
                // data_index = write_count - read_count; 
                // This works because both are binary representations of the same counter logic.
                
                // However, to be precise with the gray code pointers:
                // We need to convert the gray pointers back to binary to get the absolute position
                // But we already have write_count and read_count as binary.
                // The issue is that write_count and read_count are updated asynchronously.
                // We must use the synchronized versions or the current gray pointers.
                
                // Correct approach for data selection:
                // The data is at index: (write_ptr_bin - read_ptr_bin) modulo DEPTH
                // But since write_ptr_bin and read_ptr_bin are from different domains, 
                // we cannot subtract them directly in the destination domain without synchronization.
                
                // Instead, we use the synchronized counts which are updated in the destination domain
                // read_count_sync and write_count_sync are updated in the destination domain?
                // No, write_count is updated in source domain.
                
                // Revised Strategy:
                // 1. Synchronize write_count to destination domain.
                // 2. Synchronize read_count to source domain (for write enable).
                // 3. In destination domain, use synchronized write_count and local read_count.
                
                // Let's restructure the synchronization for counts.
                
                // For now, let's assume the standard method:
                // Synchronize write_count to dst domain.
                // Synchronize read_count to src domain.
                
                // We will add these synchronizers below.
                
                // Temporary placeholder logic - will be replaced by synchronized counts
                // data_index = write_count_sync - read_count;
                // if (data_index < 0) data_index = DEPTH + data_index;
                
                // Actually, let's implement the count synchronization properly.
            end
        end
    end

    // Re-implementing the logic with proper count synchronization
    
    // Synchronize write_count to destination domain
    reg [LOG_DEPTH-1:0] write_count_dst_sync;
    reg [LOG_DEPTH-1:0] write_count_dst_sync_2;
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            write_count_dst_sync <= '0;
            write_count_dst_sync_2 <= '0;
        end else begin
            write_count_dst_sync <= write_count;
            write_count_dst_sync_2 <= write_count_dst_sync;
        end
    end

    // Synchronize read_count to source domain
    reg [LOG_DEPTH-1:0] read_count_src_sync;
    reg [LOG_DEPTH-1:0] read_count_src_sync_2;
    
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            read_count_src_sync <= '0;
            read_count_src_sync_2 <= '0;
        end else begin
            read_count_src_sync <= read_count;
            read_count_src_sync_2 <= read_count_src_sync;
        end
    end

    // Final Write Logic with synchronized counts
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_o <= 1'b1;
            write_enable <= 1'b0;
            empty_flag <= 1'b1;
            full_flag <= 1'b0;
        end else begin
            src_ready_o <= 1'b1;
            
            // Flow Control: Not Full
            // Use synchronized read_count to determine if full
            if (read_count_src_sync_2 < write_count) begin
                write_enable <= 1'b1;
                empty_flag <= 1'b0;
                full_flag <= 1'b0;
            end else if (read_count_src_sync_2 == write_count) begin
                write_enable <= 1'b0;
                full_flag <= 1'b1;
                empty_flag <= 1'b0;
            end else begin
                // Should not happen if logic is correct, but safety check
                write_enable <= 1'b0;
                full_flag <= 1'b1;
                empty_flag <= 1'b0;
            end
            
            // Update pointer if writing
            if (write_enable && src_valid_i && src_ready_o) begin
                src_ptr_gray <= src_ptr_gray + 1'b1;
                src_ptr_bin <= gray_to_bin(src_ptr_gray);
            end
        end
    end

    // Final Read Logic with synchronized counts
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 1'b0;
            dst_data_o <= '0;
            read_enable <= 1'b0;
            empty_flag <= 1'b1;
            full_flag <= 1'b0;
        end else begin
            dst_valid_o <= 1'b0;
            
            // Flow Control: Not Empty
            // Use synchronized write_count to determine if empty
            if (write_count_dst_sync_2 > read_count) begin
                read_enable <= 1'b1;
                empty_flag <= 1'b0;
                full_flag <= 1'b0;
            end else if (write_count_dst_sync_2 == read_count) begin
                read_enable <= 1'b0;
                full_flag <= 1'b0;
                empty_flag <= 1'b1;
            end else begin
                // Should not happen
                read_enable <= 1'b0;
                full_flag <= 1'b0;
                empty_flag <= 1'b1;
            end
            
            // Update pointer if reading
            if (read_enable && dst_ready_i) begin
                dst_ptr_gray <= dst_ptr_gray + 1'b1;
                dst_ptr_bin <= gray_to_bin(dst_ptr_gray);
            end
        end
    end

    // Data Output Logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 1'b0;
            dst_data_o <= '0;
        end else begin
            if (read_enable && dst_ready_i) begin
                // Calculate data index
                // index = write_count_dst_sync_2 - read_count;
                // Handle wrap-around for subtraction
                reg [LOG_DEPTH-1:0] data_index;
                if (write_count_dst_sync_2 >= read_count) begin
                    data_index = write_count_dst_sync_2 - read_count;
                end else begin
                    data_index = DEPTH + write_count_dst_sync_2 - read_count;
                end
                
                // Address calculation
                // The data is stored at (read_ptr_bin + data_index) % DEPTH
                // But read_ptr_bin is the current read pointer.
                // Actually, the data is stored at (write_ptr_bin - read_ptr_bin) relative to read pointer?
                // No, the data is stored at absolute address: write_ptr_bin.
                // But we read from read_ptr_bin.
                // The data we want is at address: (read_ptr_bin + data_index) % DEPTH
                
                // However, since we are using binary pointers, we can simply do:
                // address = read_ptr_bin + data_index;
                // if (address >= DEPTH) address = address - DEPTH;
                
                reg [LOG_DEPTH-1:0] addr;
                if (read_count + data_index < DEPTH) begin
                    addr = read_count + data_index;
                end else begin
                    addr = read_count + data_index - DEPTH;
                end
                
                dst_data_o <= memory[addr * WIDTH +: WIDTH];
                dst_valid_o <= 1'b1;
            end else begin
                dst_valid_o <= 1'b0;
                dst_data_o <= '0;
            end
        end
    end

    // Memory Write Logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            memory <= '0;
        end else begin
            if (write_enable && src_valid_i && src_ready_o) begin
                memory[src_ptr_bin * WIDTH +: WIDTH] <= src_data_i;
            end
        end
    end

endmodule
```<|im_end|>
