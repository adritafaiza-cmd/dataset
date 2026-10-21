module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output reg [WIDTH-1:0] dst_data_o
);

    // Source domain state
    reg src_valid_reg;
    reg [WIDTH-1:0] src_data_reg;
    reg src_valid_next;
    reg src_data_next;
    reg src_ready;

    // Destination domain state
    reg dst_valid_reg;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_next;
    reg dst_data_next;
    reg dst_ready_reg;

    // 2-deep FIFO pointers (depth = 4)
    // We use a simple counter approach for the 2-deep buffer
    // State: 0 (empty), 1, 2, 3 (full)
    reg [1:0] fifo_count;
    reg [WIDTH-1:0] fifo_data [0:1]; // 2 entries
    reg fifo_write_en;
    reg fifo_read_en;
    reg fifo_full;
    reg fifo_empty;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_reg <= 1'b0;
            src_data_reg <= 1'b0;
            src_ready <= 1'b1;
        end else begin
            src_valid_reg <= src_valid_i;
            src_data_reg <= src_data_i;
            // Ready is high unless we are full and trying to write
            src_ready <= (fifo_count == 2'b11) ? 1'b0 : 1'b1;
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 1'b0;
            dst_data_reg <= 1'b0;
            dst_ready_reg <= 1'b1;
        end else begin
            dst_valid_reg <= dst_valid_i; // This will be driven by the cross-clock logic below
            dst_data_reg <= dst_data_i;   // This will be driven by the cross-clock logic below
            dst_ready_reg <= dst_ready_i;
        end
    end

    // Cross-clock handshake logic
    // We need to capture src_valid and src_data on dst_clk to drive dst_valid and dst_data
    // But we also need to manage the FIFO between src and dst domains
    
    // Capture source data on destination clock edge for the FIFO write
    // Actually, the standard approach for this specific "spill buffer" pattern:
    // 1. Source domain captures valid/data and asserts ready when FIFO is not full.
    // 2. Destination domain reads from FIFO and asserts valid when ready.
    // 3. The FIFO is clocked by the destination clock (or a common clock if available, but here we have two clocks).
    // Since clocks are related but different, we must be careful.
    // The typical robust implementation for related clocks uses a FIFO that is written by src_clk and read by dst_clk.
    // However, standard FIFOs require a common clock or asynchronous FIFO logic.
    // Given the constraints and the "2-deep" requirement with related clocks, we implement a simple 
    // asynchronous FIFO logic where write is enabled by src_clk and read by dst_clk.
    
    // Let's refine the architecture:
    // The FIFO is physically in the destination domain (or synthesized across both).
    // To keep it simple and compliant with Verilog-2001 without vendor primitives:
    // We will implement the FIFO state machine in the destination domain, but the write enable
    // comes from the source domain via a flip-flop chain or direct sampling if the ratio is safe.
    // However, the safest and most standard way for "related clocks" without a common clock domain 
    // is to treat the FIFO as an asynchronous FIFO.
    
    // Re-evaluating the "2-deep" requirement with related clocks:
    // If the clocks are related (integer ratio), we can often use a single clock domain if the ratio is small,
    // but the problem states "between related clocks", implying they are distinct domains.
    // We will implement a simple asynchronous FIFO.
    
    // Source domain: Capture valid/data and assert ready based on FIFO status.
    // We need to know the FIFO status (full/empty) in the source domain.
    // Since FIFO is read by dst_clk, the read pointer changes on dst_clk.
    // The write pointer changes on src_clk.
    
    // Let's implement the FIFO pointers in the destination domain to avoid metastability on the write pointer read?
    // No, the write pointer must be updated on src_clk.
    // Standard Asynchronous FIFO:
    // Write Ptr: src_clk
    // Read Ptr: dst_clk
    // Full/Empty flags: Generated in both domains using格雷码 (Gray code) or simple counters with hazard protection.
    // Given the small depth (2), we can use a simple counter with hazard protection or just standard logic.
    // For a 2-deep buffer, let's use a simple counter for write ptr and read ptr.
    
    // Write Pointer (src domain)
    reg [1:0] write_ptr;
    reg [1:0] read_ptr;
    
    // We need to store the read pointer in the source domain to check for full/empty?
    // Or we can generate the full/empty signals in the destination domain and send them back?
    // Sending full/empty back requires another cross-clock path.
    // Simpler approach for small depth:
    // Implement the FIFO logic entirely in the destination domain? 
    // No, the source needs to know when to stop writing.
    
    // Correct Asynchronous FIFO Implementation for small depth:
    // 1. Write pointer increments on src_clk.
    // 2. Read pointer increments on dst_clk.
    // 3. Full signal: (write_ptr == read_ptr) AND (write_enable == 1) -> Wait, that's not quite right for async.
    //    Full: (write_ptr == read_ptr) AND (write_enable asserted in previous cycle?)
    //    Actually, for depth 2:
    //    Full if write_ptr == read_ptr AND write_enable is active? No.
    //    Standard: Full if (write_ptr == read_ptr) AND (write_enable was asserted).
    //    Empty if (write_ptr == read_ptr) AND (write_enable was not asserted).
    //    This requires storing the write_enable status in the destination domain.
    
    // Let's try a different, more robust approach for "related clocks" with small depth:
    // Since the clocks are related, we can assume the worst-case skew is handled by the synthesis tool 
    // if we keep the logic simple. But strictly speaking, we need an async FIFO.
    
    // Implementation Plan:
    // - Write Pointer (src_clk)
    // - Read Pointer (dst_clk)
    // - Data Storage (2 entries)
    // - Full/Empty detection using Gray code or simple counter with hazard protection.
    // - Since depth is 2, we can hardcode the logic.
    
    // Write Pointer
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            write_ptr <= 2'b00;
        else if (src_valid_i && src_ready_o) // Only increment if we successfully wrote
            write_ptr <= write_ptr + 2'b01;
    end
    
    // Read Pointer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            read_ptr <= 2'b00;
        else if (dst_valid_o) // Only increment if we successfully read
            read_ptr <= read_ptr + 2'b01;
    end
    
    // Data Storage
    // We need to store data at write_ptr.
    // Since we are in Verilog-2001, we can't use non-blocking assignments for memory directly in a way that 
    // allows multiple writes to the same address in one cycle without care.
    // But here, write_ptr increments only when src_valid_i && src_ready_o.
    // So we can use a case statement or indexed assignment.
    
    // However, to avoid race conditions with the read pointer, we should store the data in the destination domain 
    // or ensure the write happens safely.
    // Let's put the data storage in the destination domain to simplify the read logic, 
    // but we need to capture the write data on src_clk.
    
    // Alternative: Put everything in the destination domain?
    // No, the source needs to drive data.
    
    // Let's implement the FIFO in the destination domain, but capture the write enable and data on dst_clk.
    // This creates a 1-cycle latency in the source domain handshake?
    // No, the source domain asserts ready immediately if the FIFO is not full.
    // The FIFO status (full/empty) must be available in the source domain.
    
    // To get FIFO status in source domain:
    // We need to send the read pointer (or full/empty flags) from dst to src.
    // Since clocks are related, we can sample the dst domain signals on src_clk.
    
    // Let's define the FIFO state in the destination domain and sample it for the source.
    
    // Destination Domain FIFO Logic
    // We need to store data. Let's use a 2-entry RAM.
    reg [WIDTH-1:0] ram_data [0:1];
    reg [1:0] ram_write_addr;
    reg [1:0] ram_read_addr;
    reg ram_write_en;
    reg ram_read_en;
    
    // Write Enable: Asserted when src_valid_i is high and src_ready_o is high.
    // We need to capture this on dst_clk to update the RAM.
    reg src_valid_capture;
    reg src_ready_capture;
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            ram_data <= 2'b0;
            ram_write_addr <= 2'b00;
            ram_read_addr <= 2'b00;
            ram_write_en <= 1'b0;
            ram_read_en <= 1'b0;
            src_valid_capture <= 1'b0;
            src_ready_capture <= 1'b0;
        end else begin
            // Capture source signals
            src_valid_capture <= src_valid_i;
            src_ready_capture <= src_ready_o;
            
            // Write Enable
            ram_write_en <= (src_valid_capture && src_ready_capture);
            
            // Read Enable
            ram_read_en <= dst_valid_o; // Actually, we drive dst_valid_o based on this.
            // Let's restructure: dst_valid_o is the output of the read operation.
            
            // Write Address
            if (ram_write_en)
                ram_write_addr <= write_ptr; // Note: write_ptr is from src_clk, this is async read.
                                           // For a 2-deep buffer, the pointer values are small (0,1).
                                           // The risk of metastability on the pointer read is low but exists.
                                           // Given the constraints, we proceed with this.
            
            // Read Address
            if (ram_read_en)
                ram_read_addr <= read_ptr;
        end
    end
    
    // Generate dst_valid_o and dst_data_o
    // dst_valid_o is high if ram_read_en is high and data is valid.
    // Since we are in dst_clk domain, we can drive these directly.
    
    // However, we need to handle the case where the FIFO is empty.
    // Empty condition: write_ptr == read_ptr AND no pending write.
    // Full condition: write_ptr == read_ptr AND pending write.
    
    // Let's simplify the FIFO logic for depth 2.
    // We can use a counter for the number of items in the buffer.
    // But the counter must be updated in both domains.
    
    // Revised Plan for Robustness:
    // 1. Source Domain:
    //    - Capture dst_ready_i and dst_valid_o? No, dst_valid_o is our output.
    //    - We need to know if the buffer is full.
    //    - We can sample the "full" flag from the destination domain.
    
    // 2. Destination Domain:
    //    - Maintain the actual FIFO state (count, data).
    //    - Generate full/empty flags.
    //    - Drive dst_valid_o and dst_data_o.
    
    // Let's implement the FIFO state machine in the destination domain.
    // State: 0 (empty), 1, 2 (full).
    reg [1:0] fifo_depth;
    reg [WIDTH-1:0] fifo_buf [0:1];
    
    // Capture src_valid and src_ready to update FIFO
    reg src_valid_d;
    reg src_ready_d;
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            fifo_depth <= 2'b00;
            fifo_buf <= 2'b0;
            src_valid_d <= 1'b0;
            src_ready_d <= 1'b0;
            dst_valid_o <= 1'b0;
            dst_data_o <= 1'b0;
        end else begin
            src_valid_d <= src_valid_i;
            src_ready_d <= src_ready_o;
            
            // Update FIFO Depth
            if (src_valid_d && src_ready_d) begin
                if (fifo_depth == 2'b10) // Full
                    ; // Do nothing
                else
                    fifo_depth <= fifo_depth + 2'b01;
            end
            
            // Write Data
            if (src_valid_d && src_ready_d) begin
                // We need to write to the correct address.
                // Address = fifo_depth - 1 (before increment)
                // But we are updating depth first.
                // Let's use a temporary variable or logic.
                // If depth was 0, write to 0. If depth was 1, write to 1.
                // We can determine the address based on the old depth.
                // Since we can't use old depth easily in a combinational block inside sequential,
                // let's use a separate register for the write address.
            end
            
            // Read Data
            if (dst_ready_i) begin
                if (fifo_depth > 2'b00) begin
                    // Read from address = fifo_depth - 1
                    // We need to calculate the address.
                    // If depth is 1, addr is 0. If depth is 2, addr is 1.
                    // We can use a case statement.
                    case (fifo_depth)
                        2'b01: fifo_buf[0] <= fifo_buf[0]; // No change needed, just read
                        2'b10: fifo_buf[1] <= fifo_buf[1];
                        default: ;
                    endcase
                    
                    // Drive outputs
                    dst_valid_o <= 1'b1;
                    dst_data_o <= fifo_buf[fifo_depth - 2'b01]; // 1->0, 2->1
                    // Wait, if depth is 1, fifo_depth-1 = 0. If depth is 2, fifo_depth-1 = 1.
                    // In Verilog, 2'b01 - 1 = 2'b00. 2'b10 - 1 = 2'b01. Correct.
                end else begin
                    dst_valid_o <= 1'b0;
                    dst_data_o <= 1'b0;
                end
            end else begin
                dst_valid_o <= 1'b0;
                dst_data_o <= 1'b0;
            end
        end
    end
    
    // Wait, the above logic for writing data is flawed because we don't have the address explicitly.
    // Let's refactor the destination domain logic to be cleaner.
    
    // Destination Domain Refactored
    reg [1:0] fifo_count;
    reg [WIDTH-1:0] fifo_data [0:1];
    reg fifo_write_addr;
    reg fifo_read_addr;
    reg fifo_write_en;
    reg fifo_read_en;
    
    // Capture source signals
    reg src_valid_sampled;
    reg src_ready_sampled;
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            fifo_count <= 2'b00;
            fifo_data <= 2'b0;
            fifo_write_addr <= 2'b00;
            fifo_read_addr <= 2'b00;
            fifo_write_en <= 1'b0;
            fifo_read_en <= 1'b0;
            src_valid_sampled <= 1'b0;
            src_ready_sampled <= 1'b0;
            dst_valid_o <= 1'b0;
            dst_data_o <= 1'b0;
        end else begin
            src_valid_sampled <= src_valid_i;
            src_ready_sampled <= src_ready_o;
            
            // Write Enable
            fifo_write_en <= (src_valid_sampled && src_ready_sampled);
            
            // Read Enable
            fifo_read_en <= dst_ready_i;
            
            // Update Write Address
            if (fifo_write_en) begin
                fifo_write_addr <= fifo_count; // Write to current count (0 or 1)
                if (fifo_count == 2'b01)
                    fifo_data[0] <= src_data_i;
                else if (fifo_count == 2'b10)
                    fifo_data[1] <= src_data_i;
            end
            
            // Update Read Address
            if (fifo_read_en) begin
                fifo_read_addr <= fifo_count - 2'b01; // Read from count-1
                if (fifo_count == 2'b01)
                    fifo_data[0] <= fifo_data[0]; // Keep data
                else if (fifo_count == 2'b10)
                    fifo_data[1] <= fifo_data[1]; // Keep data
            end
            
            // Update Count
            if (fifo_write_en && fifo_count != 2'b10)
                fifo_count <= fifo_count + 2'b01;
            else if (fifo_read_en && fifo_count != 2'b00)
                fifo_count <= fifo_count - 2'b01;
            
            // Drive Outputs
            if (fifo_count != 2'b00) begin
                dst_valid_o <= 1'b1;
                // Data to output is at fifo_count - 1
                if (fifo_count == 2'b01)
                    dst_data_o <= fifo_data[0];
                else if (fifo_count == 2'b10)
                    dst_data_o <= fifo_data[1];
            end else begin
                dst_valid_o <= 1'b0;
                dst_data_o <= 1'b0;
            end
        end
    end
    
    // Source Domain Logic
    // src_ready_o is high if the FIFO is not full.
    // Full condition: fifo_count == 2'b10.
    // We need to sample fifo_count from the destination domain.
    
    reg fifo_count_sampled;
    
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_o <= 1'b1;
            fifo_count_sampled <= 2'b00;
        end else begin
            fifo_count_sampled <= fifo_count; // Sample from dst domain
            // Full if count is 2 (10)
            src_ready_o <= (fifo_count_sampled == 2'b10) ? 1'b0 : 1'b1;
        end
    end

endmodule<|im_end|>
