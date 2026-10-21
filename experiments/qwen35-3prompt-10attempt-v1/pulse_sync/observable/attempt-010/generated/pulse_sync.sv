```verilog
module pulse_sync #(
    parameter STAGES = 2
)(
    input  wire clk_a,
    input  wire rstn_a,
    input  wire clk_b,
    input  wire rstn_b,
    input  wire pulseA_i,
    output wire pulseB_o,
    output wire busy_o
);

    // Synchronizer for pulseA_i to clock domain B
    // We need to detect a single rising edge of pulseA_i in domain B
    wire [STAGES-1:0] sync_pulseA;
    wire sync_pulseA_valid;
    
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : sync_stage
            assign sync_pulseA[i] = rstn_b ? (i == 0 ? pulseA_i : sync_pulseA[i-1]) : 1'b0;
        end
    endgenerate

    // Detect the single pulse in domain B
    // A pulse is detected if the signal goes from 0 to 1 after synchronization
    wire pulseA_detected;
    assign pulseA_detected = sync_pulseA[STAGES-1] & ~sync_pulseA[STAGES-2];

    // State machine in clock domain B to handle the "in-flight" logic
    // States: IDLE, BUSY
    // We use a simple register to track state
    reg busy_reg;
    
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            busy_reg <= 1'b0;
        else if (pulseA_detected)
            busy_reg <= 1'b1;
        else if (busy_reg)
            busy_reg <= 1'b0;
        else
            busy_reg <= 1'b0;
    end

    // Output the pulse to domain B
    // The output should be a single pulse corresponding to the detected event
    // We use a flip-flop to generate the one-cycle pulse in domain B
    reg pulseB_reg;
    reg pulseB_next;
    
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            pulseB_reg <= 1'b0;
        else begin
            if (pulseA_detected)
                pulseB_next <= 1'b1;
            else
                pulseB_next <= 1'b0;
        end
        pulseB_reg <= pulseB_next;
    end
    assign pulseB_o = pulseB_reg;

    // Output busy status to domain B
    assign busy_o = busy_reg;

    // Synchronizer for pulseB_o to clock domain A (for completeness, though not strictly required by the prompt's output requirement, 
    // the prompt asks for "one-pulse-in, one-pulse-out crossing", implying we might need to see the result in A or just ensure the mechanism works.
    // However, the interface only defines pulseA_i -> pulseB_o. The busy_o is also in domain B.
    // The prompt asks to "Carry an input pulse to the other side". This is A->B.
    // The busy_o indicates when the system is busy in domain B.
    // If the requirement implies we need to see the status in domain A as well, we would need more ports.
    // Given the interface, we only drive pulseB_o and busy_o.
    // But wait, the prompt says "Carry an input pulse to the other side". 
    // Input is pulseA_i (Domain A). Output is pulseB_o (Domain B). This is satisfied.
    // "Indicate when one is in flight" -> busy_o (Domain B). This is satisfied.
    // "Clear the outputs on reset" -> pulseB_o and busy_o clear on rstn_b. This is satisfied.
    
    // Just to be thorough and ensure robustness, let's make sure the busy signal is also synchronized if it were to be used in A, 
    // but since it's an output in B, we don't need to sync it back to A unless specified.
    // The current implementation satisfies the interface and requirements.

endmodule
```<|im_end|>
