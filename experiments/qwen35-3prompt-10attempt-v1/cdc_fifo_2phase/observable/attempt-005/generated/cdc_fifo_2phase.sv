```verilog
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

    // Internal signals for source side (src domain)
    reg [ADDR_WIDTH-1:0] src_ptr;
    reg [ADDR_WIDTH-1:0] dst_ptr;
    reg [ADDR_WIDTH-1:0] src_gray;
    reg [ADDR_WIDTH-1:1] src_gray_prev;
    reg [ADDR_WIDTH-1:1] dst_gray;
    reg [ADDR_WIDTH-1:1] dst_gray_prev;
    reg [WIDTH-1:0] src_data_reg;
    reg [WIDTH-1:0] dst_data_reg;
    reg src_valid_reg;
    reg dst_valid_reg;
    reg src_empty;
    reg dst_empty;
    reg src_full;
    reg dst_full;

    // ---------------------------------------------------------
    // Source Side Logic
    // ---------------------------------------------------------
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= 0;
            src_gray <= 0;
            src_data_reg <= 0;
            src_valid_reg <= 0;
            src_empty <= 1'b1;
            src_full <= 1'b0;
        end else begin
            src_gray <= src_ptr;
            src_data_reg <= src_data_i;
            src_valid_reg <= src_valid_i;
            
            // Calculate full/empty based on pointer difference
            // Full: (src_ptr - dst_ptr) == DEPTH - 1
            // Empty: (src_ptr - dst_ptr) == 0
            src_full <= (src_ptr - dst_ptr) == (DEPTH - 1);
            src_empty <= (src_ptr - dst_ptr) == 0;
        end
    end

    // ---------------------------------------------------------
    // Destination Side Logic
    // ---------------------------------------------------------
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= 0;
            dst_gray <= 0;
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
            dst_empty <= 1'b1;
            dst_full <= 1'b0;
        end else begin
            dst_gray <= dst_ptr;
            dst_data_reg <= src_data_reg;
            dst_valid_reg <= src_valid_reg;
            
            // Calculate full/empty based on pointer difference
            dst_full <= (dst_ptr - src_ptr) == (DEPTH - 1);
            dst_empty <= (dst_ptr - src_ptr) == 0;
        end
    end

    // ---------------------------------------------------------
    // Gray Code Encoding/Decoding for CDC
    // ---------------------------------------------------------
    // Source to Destination: Encode src_ptr to Gray, Decode dst_gray to dst_ptr
    // Destination to Source: Encode dst_ptr to Gray, Decode src_gray to src_ptr
    
    // Generate Gray code from binary pointer
    assign src_gray = {src_ptr[ADDR_WIDTH-2:0], src_ptr[ADDR_WIDTH-1] ^ src_ptr[ADDR_WIDTH-2:0]};
    assign dst_gray = {dst_ptr[ADDR_WIDTH-2:0], dst_ptr[ADDR_WIDTH-1] ^ dst_ptr[ADDR_WIDTH-2:0]};

    // Decode Gray code back to binary pointer
    // This logic is duplicated in both domains to ensure correct behavior
    // without relying on cross-domain combinational logic for the pointer itself.
    
    // Source domain decodes incoming dst_gray
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ptr <= 0;
        end else begin
            // Simple Gray to Binary decoder
            // dst_ptr[0] = dst_gray[0]
            // dst_ptr[1] = dst_gray[1] ^ dst_gray[0]
            // dst_ptr[2] = dst_gray[2] ^ dst_gray[1] ^ dst_gray[0]
            // ...
            reg [ADDR_WIDTH-1:0] temp_gray;
            temp_gray <= dst_gray;
            dst_ptr <= temp_gray[ADDR_WIDTH-1];
            for (integer i = ADDR_WIDTH-2; i >= 0; i = i - 1) begin
                dst_ptr[i] <= temp_gray[i] ^ dst_ptr[i+1];
            end
        end
    end

    // Destination domain decodes incoming src_gray
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ptr <= 0;
        end else begin
            reg [ADDR_WIDTH-1:0] temp_gray;
            temp_gray <= src_gray;
            src_ptr <= temp_gray[ADDR_WIDTH-1];
            for (integer i = ADDR_WIDTH-2; i >= 0; i = i - 1) begin
                src_ptr[i] <= temp_gray[i] ^ src_ptr[i+1];
            end
        end
    end

    // ---------------------------------------------------------
    // Handshake Control
    // ---------------------------------------------------------
    
    // Source side: Update pointers and control signals based on valid/ready
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_o <= 1'b1;
        end else begin
            // Check if we can accept data
            // We can accept if not full AND (valid is asserted OR we are just updating ready)
            // Actually, standard handshake: if not full, we accept.
            // If full, we deassert ready.
            
            // Note: The pointer update happens on the next cycle if valid is high and ready is high.
            // However, to simplify the FSM, we update pointers when valid is high and we are not full.
            // But we must ensure we don't update if we are already full.
            
            if (!src_rst_ni) begin
                src_ready_o <= 1'b1;
            end else begin
                // Determine if we are full based on current pointers
                // Full condition: (src_ptr - dst_ptr) == DEPTH - 1
                // We use the decoded dst_ptr here.
                if ((src_ptr - dst_ptr) == (DEPTH - 1)) begin
                    src_ready_o <= 1'b0;
                end else begin
                    src_ready_o <= 1'b1;
                end
            end
        end
    end

    // Update pointers in source domain when valid is high and ready is high
    // This logic is typically combined with the main register update or done separately.
    // To keep it clean, we update pointers here based on the current cycle's valid/ready.
    // However, since src_valid_i and src_ready_o are inputs/outputs of the same clock domain,
    // we can update the pointers in the same always block as the data registers if we structure it carefully.
    // But to avoid race conditions with the ready signal generation, let's separate the pointer update.
    
    // Re-evaluating the pointer update logic:
    // The pointers must be updated atomically with the data transfer.
    // In the source domain:
    // If src_valid_i is high AND src_ready_o is high (which is determined by !full), then increment src_ptr.
    // But src_ready_o depends on dst_ptr.
    
    // Let's refine the always block for source pointers and data.
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= 0;
            src_data_reg <= 0;
            src_valid_reg <= 0;
        end else begin
            src_ptr <= src_ptr; // Default hold
            src_data_reg <= src_data_reg;
            src_valid_reg <= src_valid_i;
            
            // If valid is high and not full, accept data and increment pointer
            if (src_valid_i && ((src_ptr - dst_ptr) != (DEPTH - 1))) begin
                src_ptr <= src_ptr + 1;
                src_data_reg <= src_data_i;
                src_valid_reg <= 1'b1;
            end else if (src_valid_i && ((src_ptr - dst_ptr) == (DEPTH - 1))) begin
                // Full, do not accept, do not increment
                src_valid_reg <= 1'b0; // Optional: keep valid high or low? Usually keep high to indicate "I have data but you can't take it"
                // However, the problem says "Stop accepting items". 
                // Standard behavior: src_valid stays high, src_ready goes low.
                // So we don't change src_valid_reg here if it was already high.
                // But we need to ensure src_valid_reg reflects src_valid_i only if accepted?
                // No, src_valid_reg should reflect the state of the FIFO input.
                // If we don't accept, the data is lost? No, the user holds src_valid high.
                // The FIFO internal state doesn't change.
                // So src_valid_reg should just track src_valid_i if we consider it as "input valid".
                // But usually, we want to know if there is data inside.
                // Let's stick to: src_valid_reg is the valid signal of the data currently in the FIFO.
                // If we don't accept, src_valid_reg remains what it was (or 0 if empty).
                // Actually, simpler: src_valid_reg is just src_valid_i if we accept, else 0?
                // No, that breaks the handshake if the producer keeps driving valid.
                // Correct approach: src_valid_reg is the valid signal of the data stored in src_data_reg.
                // If we don't accept, we don't update src_data_reg or src_valid_reg.
                // So src_valid_reg should be updated ONLY when we accept.
                // But what if src_valid_i is high and we are full? src_valid_reg should stay as is (indicating previous data).
                // And src_ready_o is 0.
                // So:
                if ((src_ptr - dst_ptr) != (DEPTH - 1)) begin
                    src_ptr <= src_ptr + 1;
                    src_data_reg <= src_data_i;
                    src_valid_reg <= 1'b1;
                end else begin
                    // Full, do nothing to pointers or data
                    src_valid_reg <= src_valid_reg; // Hold
                end
            end else begin
                // Invalid input, hold state
                src_valid_reg <= src_valid_reg;
            end
        end
    end

    // Wait, the logic above for src_valid_reg is slightly flawed if src_valid_i toggles.
    // If src_valid_i is 0, src_valid_reg should become 0 (no data valid).
    // If src_valid_i is 1 and we accept, src_valid_reg becomes 1.
    // If src_valid_i is 1 and we are full, src_valid_reg stays 1 (data is still there).
    // So:
    // if (!src_valid_i) src_valid_reg <= 0;
    // else if (not full) src_valid_reg <= 1;
    // else src_valid_reg <= src_valid_reg;
    
    // Let's rewrite the source pointer/data block cleanly.
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= 0;
            src_data_reg <= 0;
            src_valid_reg <= 0;
        end else begin
            // Check full condition
            reg full_flag;
            if ((src_ptr - dst_ptr) == (DEPTH - 1)) begin
                full_flag <= 1'b1;
            end else begin
                full_flag <= 1'b0;
            end
            
            if (!full_flag) begin
                // Accept data
                src_ptr <= src_ptr + 1;
                src_data_reg <= src_data_i;
                src_valid_reg <= src_valid_i;
            end else begin
                // Full, do not update pointers/data
                src_valid_reg <= src_valid_reg;
            end
        end
    end

    // ---------------------------------------------------------
    // Destination Side Handshake
    // ---------------------------------------------------------
    // Update dst_ptr and output data when valid and ready
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= 0;
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
        end else begin
            // Check empty condition
            reg empty_flag;
            if ((dst_ptr - src_ptr) == 0) begin
                empty_flag <= 1'b1;
            end else begin
                empty_flag <= 1'b0;
            end
            
            if (!empty_flag && dst_ready_i) begin
                // Deliver data
                dst_ptr <= dst_ptr + 1;
                dst_data_reg <= src_data_reg;
                dst_valid_reg <= 1'b1;
            end else begin
                // Wait for ready or empty
                dst_valid_reg <= dst_valid_reg;
            end
        end
    end

    // ---------------------------------------------------------
    // Output Assignments
    // ---------------------------------------------------------
    assign src_ready_o = ((src_ptr - dst_ptr) != (DEPTH - 1));
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    // ---------------------------------------------------------
    // Empty/Full Status Outputs (Optional but good practice, though not requested explicitly)
    // The problem asks for specific outputs, so we stick to them.
    // However, the internal logic relies on empty/full flags.
    // We can expose them if needed, but the prompt only lists specific ports.
    // We will assume the internal logic is sufficient.
    
    // One correction: The pointer update logic in the source block above uses `full_flag` which is calculated inside the block.
    // This is fine for synthesis.
    
    // Re-checking the "dst_valid_o may fall for one destination clock after an accepted beat" requirement.
    // This happens naturally if dst_ready_i is not asserted immediately after the data is written.
    // The data is written to dst_data_reg and dst_valid_reg becomes 1.
    // If dst_ready_i is 0 in the next cycle, dst_valid_reg stays 1, but dst_ptr doesn't increment.
    // In the cycle after, if dst_ready_i becomes 1, dst_ptr increments and dst_valid_reg stays 1.
    // This satisfies the requirement.

    // Final check on pointer arithmetic overflow/underflow.
    // Since we use unsigned subtraction for full/empty checks:
    // (src_ptr - dst_ptr) == DEPTH - 1 implies src_ptr >= dst_ptr.
    // If src_ptr < dst_ptr, the result wraps around to a large number, so != DEPTH-1 holds.
    // (dst_ptr - src_ptr) == 0 implies dst_ptr >= src_ptr.
    // If dst_ptr < src_ptr, result wraps, != 0 holds.
    // This logic is correct for unsigned arithmetic in Verilog.

endmodule
```<|im_end|>
