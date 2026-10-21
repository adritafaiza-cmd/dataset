```verilog
module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signal to handle polarity inversion if needed
    wire rst_active = (RST_POL == 1'b1) ? async_rst_i : ~async_rst_i;

    // Pipeline stage for the release path
    // We use a register array to create the delay chain
    reg [CHAINS-1:0] rst_pipe;

    // Initial state: all zeros (inactive)
    // Since RST_POL=1 means active high, 0 means inactive
    // If RST_POL=0, the logic inassign handles the inversion, 
    // but the pipeline tracks the "active" state relative to the input polarity.
    // To ensure correct behavior regardless of POL, we track the asserted state.
    
    // Logic:
    // 1. If rst_active is high, the output must be high immediately.
    // 2. If rst_active goes low, we must wait for CHAINS clock cycles before 
    //    allowing the output to go low.
    
    // We implement a shift register where the MSB is the output.
    // On reset (rst_active == 1), we force the output high.
    // On de-assertion (rst_active == 0), we shift zeros into the chain.
    
    // Note: To satisfy "sync_rst_o must follow assertion ... immediately",
    // we cannot rely solely on the pipeline output for the active case.
    // We use a multiplexer or direct assignment for the active case,
    // and the pipeline only for the release delay.
    
    // Let's refine the approach:
    // The pipeline will hold the state of the reset.
    // Stage 0 is driven by rst_active.
    // Stages 1..CHAINS-1 shift the value from the previous stage.
    // The output is taken from the last stage (CHAINS-1).
    // However, if rst_active goes high, the output must go high immediately.
    // A simple shift register with rst_active at the input will do this naturally
    // IF we treat the pipeline as a "validity" chain.
    
    // Correct Logic for "Immediate Assert, Delayed Deassert":
    // We need a chain that stays HIGH as long as async_rst_i is HIGH.
    // When async_rst_i goes LOW, the chain takes CHAINS cycles to go LOW.
    
    // Implementation:
    // reg [CHAINS-1:0] rst_chain;
    // Always block:
    //   if (rst_active) begin
    //      rst_chain[0] = 1'b1;
    //      // Shift others? No, if active, everything should be 1 eventually?
    //      // Actually, simpler: 
    //      // If active, force the output high immediately.
    //      // If inactive, shift zeros.
    //   end
    
    // Let's use a standard synchronizer pattern adapted for reset release:
    // We want the output to be 1 if (async_rst_i is 1) OR (the chain hasn't cleared yet).
    
    // Revised Plan:
    // Use a register array `rst_sync_chain`.
    // The first element is driven by `rst_active`.
    // Subsequent elements shift the previous one.
    // The output is the last element.
    // BUT, this doesn't guarantee immediate assertion if the chain was previously 0.
    // Example: Chain is 000. Input goes 1. Next cycle: 100. Output is 0. Fail.
    
    // Solution:
    // The output `sync_rst_o` is 1 if `rst_active` is 1 OR if the chain indicates a pending release.
    // Actually, the requirement is: "sync_rst_o must follow assertion ... immediately".
    // This implies: if async_rst_i becomes 1, sync_rst_o becomes 1 in the very next clock edge (or immediately if combinational, but we are synchronous).
    // In synchronous logic, "immediately" usually means "in the next clock cycle".
    
    // Let's build a chain where:
    // - If rst_active is 1, the chain fills with 1s.
    // - If rst_active is 0, the chain shifts 0s.
    // - The output is the last stage.
    // To fix the "lag on assertion" issue:
    // We can drive the first stage directly from rst_active, and shift.
    // But to get immediate output on assertion, we can OR the input with the last stage?
    // No, that would keep it high forever if input is high.
    
    // Correct Standard Pattern for "Assert Immediate, Deassert Delayed":
    // We need a counter or a shift register that counts down from CHAINS when reset is released.
    // However, the prompt asks for a "synchronizer" style implementation using CHAINS depth.
    // This usually implies a shift register approach.
    
    // Let's try this logic:
    // `rst_pipe` is a shift register of depth CHAINS.
    // On every clock:
    //   If rst_active is high:
    //      Shift in 1.
    //      The output is the last bit.
    //      Problem: If chain was 0...0 and input goes 1, it takes CHAINS cycles to reach output.
    //   If rst_active is low:
    //      Shift in 0.
    //      The output takes CHAINS cycles to go low.
    
    // How to fix the assertion lag?
    // We can make the output `sync_rst_o` = `rst_active` | `rst_pipe[CHAINS-1]`.
    // Wait, if `rst_active` is high, `sync_rst_o` is high.
    // If `rst_active` goes low, `sync_rst_o` depends on `rst_pipe[CHAINS-1]`.
    // The `rst_pipe` will shift 0s. It will take CHAINS cycles for `rst_pipe[CHAINS-1]` to become 0.
    // This satisfies the requirement perfectly!
    
    // Logic Check:
    // Case 1: async_rst_i goes HIGH.
    //   rst_active = 1.
    //   sync_rst_o = 1 | ... = 1. (Immediate)
    // Case 2: async_rst_i goes LOW.
    //   rst_active = 0.
    //   rst_pipe shifts 0s.
    //   It takes CHAINS cycles for the 0 to propagate to the last stage.
    //   sync_rst_o = 0 | rst_pipe[CHAINS-1].
    //   After CHAINS cycles, rst_pipe[CHAINS-1] becomes 0, so sync_rst_o becomes 0.
    //   This matches "release only after clk has observed a safe deassert".
    
    reg [CHAINS-1:0] rst_pipe;

    always @(posedge clk) begin
        if (rst_active) begin
            // Drive the first stage with the active reset signal
            rst_pipe[0] <= rst_active;
            // Shift the rest
            for (integer i = 1; i < CHAINS; i = i + 1) begin
                rst_pipe[i] <= rst_pipe[i-1];
            end
        end else begin
            // Drive the first stage with 0 (deasserted)
            rst_pipe[0] <= 1'b0;
            // Shift the rest
            for (integer i = 1; i < CHAINS; i = i + 1) begin
                rst_pipe[i] <= rst_pipe[i-1];
            end
        end
    end

    // Output logic:
    // Immediate assertion via rst_active
    // Delayed deassertion via the last stage of the pipeline
    assign sync_rst_o = rst_active | rst_pipe[CHAINS-1];

endmodule
```<|im_end|>
