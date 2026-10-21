```verilog
`timescale 1ns / 1ps

module data_sync #(
    parameter STAGES = 2,
    parameter DWIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    input                  dready_i,
    output reg [DWIDTH-1:0] dout,
    output reg             dready_o
);

    // Internal signals for the FIFO chain
    // We use a shift-register style approach where data moves from stage to stage
    // and the last stage indicates readiness.
    
    // Array to hold the data at each stage
    reg [DWIDTH-1:0] stage_data [0:STAGES-1];
    
    // Array to hold the ready status at each stage
    // stage_ready[i] indicates if data at stage i is ready to be consumed by stage i+1
    reg [STAGES-1:0] stage_ready;

    // Logic to propagate data and ready signals through the chain
    // Stage 0 receives din and dready_i
    // Stage STAGES-1 outputs dout and dready_o

    // Always block for the data and ready propagation chain
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Reset state: all data zero, all ready signals low (idle)
            for (integer i = 0; i < STAGES; i = i + 1) begin
                stage_data[i] <= 0;
                stage_ready[i] <= 1'b0;
            end
        end else begin
            // Propagate data from previous stage to current stage
            // Stage 0 gets input from din
            // Other stages get data from the previous stage
            for (integer i = 0; i < STAGES; i = i + 1) begin
                if (i == 0) begin
                    // First stage captures input data
                    stage_data[i] <= din;
                end else begin
                    // Subsequent stages capture data from the previous stage
                    stage_data[i] <= stage_data[i-1];
                end
            end

            // Propagate ready signals
            // The last stage (STAGES-1) is ready if the input dready_i is high
            // and all previous stages have valid data.
            // Actually, in a simple shift register synchronizer:
            // Stage i is ready if stage i-1 has data AND stage i-1 was ready to pass it?
            // Standard approach: 
            // Stage 0 is ready if dready_i is high.
            // Stage i is ready if stage_data[i-1] is valid (which it always is after one cycle) 
            // and stage_ready[i-1] was high? 
            // 
            // Let's refine the logic for a robust synchronizer:
            // We want to ensure data is stable.
            // Stage 0: Data is din. Ready is dready_i.
            // Stage 1: Data is stage_data[0]. Ready is stage_ready[0].
            // ...
            // Stage k: Data is stage_data[k-1]. Ready is stage_ready[k-1].
            //
            // However, we need to handle the case where dready_i goes low.
            // If dready_i is low, stage_ready[0] becomes low.
            // Then stage_ready[1] becomes low (because stage_ready[0] is low).
            // This cascades correctly.
            
            // Calculate ready for each stage
            // Stage 0 ready depends on dready_i
            // Stage i ready depends on stage_ready[i-1]
            
            // We can compute this iteratively or with a loop.
            // Note: In Verilog, we must be careful with sequential dependencies in combinational logic 
            // inside an always block triggered by clock edge. 
            // Since we are updating stage_data and stage_ready in the same clock cycle,
            // we should calculate the new ready values based on the *current* state of the previous stage's ready signal.
            // But wait, stage_ready[i] should reflect whether the data at stage_data[i] is ready to be taken by the next stage.
            // The next stage (i+1) will take data from stage_data[i] on the next clock edge IF stage_ready[i] is high.
            // So stage_ready[i] should be driven by stage_ready[i-1] (from the previous cycle? or current?)
            // 
            // Correct logic for a pipeline:
            // stage_ready[i] = stage_ready[i-1] (from the previous cycle's perspective of the chain)
            // But since we update everything in one go, we need to be careful.
            // Actually, the standard way is:
            // stage_ready[i] <= stage_ready[i-1];
            // But stage_ready[0] <= dready_i;
            // This creates a ripple.
            // If dready_i goes high, stage_ready[0] goes high next cycle.
            // Then stage_ready[1] goes high the cycle after.
            // This is exactly what we want for synchronization.
            
            // Let's implement the ready propagation carefully.
            // We need to store the previous ready state? 
            // No, simply:
            // stage_ready[0] <= dready_i;
            // stage_ready[1] <= stage_ready[0]; // This uses the value from the previous cycle because stage_ready[0] is updated in this cycle?
            // Wait, in an always @(posedge clk) block, all RHS values are from the previous cycle (non-blocking assignment).
            // So stage_ready[1] <= stage_ready[0] will take the OLD value of stage_ready[0].
            // This is correct for a shift register behavior.
            
            // However, we must ensure that if dready_i is low, the whole chain resets to low.
            // If dready_i is low, stage_ready[0] becomes 0.
            // stage_ready[1] becomes old stage_ready[0].
            // This might cause a glitch if dready_i toggles rapidly? 
            // No, because we are synchronizing. The data moves one stage per clock.
            // The ready signal also moves one stage per clock.
            // If dready_i is low, stage_ready[0] is low.
            // stage_ready[1] will be low in the next cycle (taking the low from stage_ready[0] of this cycle).
            // So the "low" propagates correctly.
            
            // One edge case: If dready_i goes high, stage_ready[0] goes high.
            // stage_ready[1] will be high in the next cycle.
            // This is correct.
            
            // Implementation:
            stage_ready[0] <= dready_i;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                stage_ready[i] <= stage_ready[i-1];
            end
            
            // Output assignments
            dout <= stage_data[STAGES-1];
            dready_o <= stage_ready[STAGES-1];
        end
    end

endmodule
```<|im_end|>
