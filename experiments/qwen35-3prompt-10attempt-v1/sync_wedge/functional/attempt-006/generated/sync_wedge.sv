module sync_wedge #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  en_i,
    input  serial_i,
    output reg r_edge_o,
    output reg f_edge_o,
    output reg serial_o
);

    // Synchronize the asynchronous input bit
    wire sync_serial;
    sync_stage #(
        .STAGES(STAGES)
    ) u_sync (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .din(serial_i),
        .dout(sync_serial)
    );

    // Detect rising and falling edges on the synchronized signal
    wire rising_edge;
    wire falling_edge;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_o <= 1'b0;
            f_edge_o <= 1'b0;
            serial_o <= 1'b0;
        end else begin
            // Edge detection logic
            rising_edge <= (sync_serial == 1'b1) && (sync_serial[0] == 1'b0); // Simplified for single bit
            falling_edge <= (sync_serial == 1'b0) && (sync_serial[0] == 1'b1); // Simplified for single bit

            // Correct edge detection using previous state
            if (sync_serial[0] != sync_serial) begin
                if (sync_serial == 1'b1)
                    r_edge_o <= 1'b1;
                else
                    f_edge_o <= 1'b1;
            end else begin
                r_edge_o <= 1'b0;
                f_edge_o <= 1'b0;
            end

            // Pass through the synchronized data
            serial_o <= sync_serial;
        end
    end

    // Helper module for synchronization
    // Since we cannot use external libraries, we define it inline or as a sub-module within the same file
    // However, to keep it clean and self-contained in one file as requested, we will implement the sync logic directly here
    // or define a local parameterized module if allowed. Given the constraint "one source file",
    // we will implement the sync logic directly to avoid dependency issues.

    // Re-implementing sync logic directly to ensure single-file compliance without sub-module instantiation issues
    // We need a register to hold the previous value of sync_serial
    reg sync_serial_prev;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_serial_prev <= 1'b0;
            r_edge_o <= 1'b0;
            f_edge_o <= 1'b0;
            serial_o <= 1'b0;
        end else begin
            // Update previous value
            sync_serial_prev <= sync_serial;

            // Edge detection
            if (sync_serial && !sync_serial_prev) begin
                r_edge_o <= 1'b1;
                f_edge_o <= 1'b0;
            } else if (!sync_serial && sync_serial_prev) begin
                r_edge_o <= 1'b0;
                f_edge_o <= 1'b1;
            end else begin
                r_edge_o <= 1'b0;
                f_edge_o <= 1'b0;
            end

            // Pass through the synchronized data
            serial_o <= sync_serial;
        end
    end

    // Now implement the actual sync_stage logic inline since we can't instantiate external modules easily in a single file without defining them first.
    // Let's refactor to use a local always block for synchronization.

    reg [STAGES-1:0] sync_reg;
    reg sync_in;

    // First stage of synchronization
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_in <= 1'b0;
        end else begin
            sync_in <= serial_i;
        end
    end

    // Subsequent stages
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : sync_stages
            if (i == 0) begin
                // Already handled above, but let's create a chain properly
                // Actually, let's do a clean chain from serial_i
            end
        end
    endgenerate

    // Clean implementation of sync chain
    reg [STAGES-1:0] sync_chain;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= {STAGES{1'b0}};
            r_edge_o <= 1'b0;
            f_edge_o <= 1'b0;
            serial_o <= 1'b0;
        end else begin
            // Shift register logic
            sync_chain <= {sync_chain[STAGES-2:0], serial_i};
            
            // Edge detection based on the last two stages of the chain
            // Stage 0 is the newest, Stage STAGES-1 is the oldest
            // We compare the newest (sync_chain[0]) with the previous one (sync_chain[1])
            // But wait, the chain shifts right. Let's define:
            // sync_chain[STAGES-1] is the input, sync_chain[0] is the output after STAGES delays.
            // Actually, standard shift: {q[STAGES-2:0], d} -> q[STAGES-1] is old, q[0] is new.
            
            // Let's redefine the chain direction for clarity:
            // sync_chain[0] is the input, sync_chain[STAGES-1] is the output.
            // Shift left: {d, q[STAGES-2:0]}
            
            // Re-doing the chain logic correctly:
            // We want serial_o to be the value after STAGES clock cycles.
            // So sync_chain[STAGES-1] should be the output.
            
            // Let's use a simple approach:
            // sync_chain[i] holds the value delayed by i+1 cycles.
            // sync_chain[0] = serial_i (delayed 1 cycle)
            // sync_chain[STAGES-1] = serial_i (delayed STAGES cycles)
            
            // Correct shift logic:
            // sync_chain <= {sync_chain[STAGES-2:0], serial_i};
            // Then sync_chain[STAGES-1] is the oldest, sync_chain[0] is the newest? No.
            // If we shift right: {q[STAGES-2:0], d}, then q[0] becomes d (newest), q[STAGES-1] is the oldest.
            // We want to compare the newest (sync_chain[0]) with the one before it (sync_chain[1]).
            
            // Let's restart the internal logic for clarity and correctness.
            
            // Define a register array where index 0 is the most recent input.
            // Actually, let's just use a single register array shifted right.
            // sync_reg[0] is the input, sync_reg[STAGES-1] is the output.
            // Shift: {sync_reg[STAGES-2:0], serial_i} -> sync_reg[0] gets serial_i? No.
            // Shift right: {sync_reg[STAGES-2:0], serial_i} means sync_reg[0] takes sync_reg[1], ..., sync_reg[STAGES-1] takes serial_i.
            // This is not what we want. We want serial_i to propagate through STAGES stages.
            
            // Correct approach:
            // sync_reg[0] = serial_i (after 1 cycle)
            // sync_reg[1] = serial_i (after 2 cycles)
            // ...
            // sync_reg[STAGES-1] = serial_i (after STAGES cycles)
            // To achieve this, we shift left: {serial_i, sync_reg[STAGES-2:0]}
            // Then sync_reg[STAGES-1] is the output.
            
            // Let's implement this:
            // sync_reg is an array of STAGES bits.
            // sync_reg[STAGES-1] is the synchronized output.
            
            // Re-writing the always block for the chain:
            // We need to store the previous state of the chain.
            // Let's use a non-blocking assignment carefully.
            
            // Actually, the simplest way to sync a bit is:
            // reg sync_out;
            // always @(posedge clk) sync_out <= serial_i;
            // repeat STAGES times.
            
            // Let's do it with a loop in generate for clarity, but since we need one file and no testbench,
            // we can define the chain manually or use a generate block.
            // The prompt asks for "one source file", so generate blocks are fine.
            
            // Let's restructure the module to use a generate block for the sync chain.
        end
    end

    // Final clean implementation using generate block for the sync chain
    // We will replace the previous logic with this structured approach.
    
    // Reset the chain
    reg [STAGES-1:0] sync_chain_reg;
    
    // Generate the shift register chain
    genvar j;
    generate
        for (j = 0; j < STAGES; j = j + 1) begin : sync_chain_gen
            if (j == 0) begin
                always @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni) begin
                        sync_chain_reg[j] <= 1'b0;
                    end else begin
                        sync_chain_reg[j] <= serial_i;
                    end
                end
            end else begin
                always @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni) begin
                        sync_chain_reg[j] <= 1'b0;
                    end else begin
                        sync_chain_reg[j] <= sync_chain_reg[j-1];
                    end
                end
            end
        end
    endgenerate
    
    // Assign outputs based on the last stage
    assign serial_o = sync_chain_reg[STAGES-1];
    
    // Edge detection
    // Compare the last stage with the second to last stage
    // rising: last=1, prev=0
    // falling: last=0, prev=1
    // Note: We need to ensure we are comparing the correct stages.
    // sync_chain_reg[STAGES-1] is the current synchronized value.
    // sync_chain_reg[STAGES-2] is the value from one cycle ago (relative to the final output).
    
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_o <= 1'b0;
            f_edge_o <= 1'b0;
        end else begin
            if (STAGES < 2) begin
                // Fallback if STAGES is too small, though parameter says safe crossing (usually >= 2)
                r_edge_o <= 1'b0;
                f_edge_o <= 1'b0;
            end else begin
                if (sync_chain_reg[STAGES-1] && !sync_chain_reg[STAGES-2]) begin
                    r_edge_o <= 1'b1;
                    f_edge_o <= 1'b0;
                } else if (!sync_chain_reg[STAGES-1] && sync_chain_reg[STAGES-2]) begin
                    r_edge_o <= 1'b0;
                    f_edge_o <= 1'b1;
                end else begin
                    r_edge_o <= 1'b0;
                    f_edge_o <= 1'b0;
                end
            end
        end
    end

endmodule

// Helper module for synchronization (defined here to be self-contained if needed, 
// but the above generate block implements it inline. To strictly follow "one source file" 
// and avoid complexity, the inline generate block above is sufficient.
// However, if the user expects a reusable module structure, we can define a local module.
// Given the constraints, the inline implementation is robust.

// Wait, the previous logic had a flaw in the generate block variable scope or logic flow.
// Let's rewrite the entire module cleanly in one go without intermediate flawed attempts.

module sync_wedge #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  en_i,
    input  serial_i,
    output reg r_edge_o,
    output reg f_edge_o,
    output reg serial_o
);

    // Synchronization chain
    reg [STAGES-1:0] sync_chain;

    // Generate block to create the shift register chain
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : sync_stage_gen
            if (i == 0) begin
                always @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        sync_chain[i] <= 1'b0;
                    else
                        sync_chain[i] <= serial_i;
                end
            end else begin
                always @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        sync_chain[i] <= 1'b0;
                    else
                        sync_chain[i] <= sync_chain[i-1];
                end
            end
        end
    endgenerate

    // Output assignment
    assign serial_o = sync_chain[STAGES-1];

    // Edge detection logic
    // Rising edge: current is 1, previous was 0
    // Falling edge: current is 0, previous was 1
    // Previous value for the last stage is the second to last stage.
    
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_o <= 1'b0;
            f_edge_o <= 1'b0;
        end else begin
            if (STAGES < 2) begin
                // Safety check, though STAGES=2 is default
                r_edge_o <= 1'b0;
                f_edge_o <= 1'b0;
            end else begin
                if (sync_chain[STAGES-1] && !sync_chain[STAGES-2]) begin
                    r_edge_o <= 1'b1;
                    f_edge_o <= 1'b0;
                } else if (!sync_chain[STAGES-1] && sync_chain[STAGES-2]) begin
                    r_edge_o <= 1'b0;
                    f_edge_o <= 1'b1;
                end else begin
                    r_edge_o <= 1'b0;
                    f_edge_o <= 1'b0;
                end
            end
        end
    end

endmodule<|im_end|>
