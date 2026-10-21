```verilog
module pulse_sync #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  pulseA_i,
    output pulseB_o,
    output busy_o
);

    // Synchronizer chain for pulseA_i on clk_b domain
    reg [STAGES-1:0] sync_pulseA;
    
    // Synchronizer chain for busy_o on clk_a domain
    reg [STAGES-1:0] sync_busy;

    // State register in clk_b domain
    reg busy_reg;

    // Synchronizer chain for pulseA_i on clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            sync_pulseA <= {STAGES{1'b0}};
        else
            sync_pulseA <= {sync_pulseA[STAGES-2:0], pulseA_i};
    end

    // Synchronizer chain for busy_o on clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            sync_busy <= {STAGES{1'b0}};
        else
            sync_busy <= {sync_busy[STAGES-2:0], busy_o};
    end

    // Logic in clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            busy_reg <= 1'b0;
            pulseB_o <= 1'b0;
        end else begin
            // Detect rising edge of synchronized pulse
            if (sync_pulseA[STAGES-1] == 1'b0 && sync_pulseA[STAGES-2] == 1'b1) begin
                busy_reg <= 1'b1;
                pulseB_o <= 1'b1;
            end else if (sync_pulseA[STAGES-1] == 1'b1 && sync_pulseA[STAGES-2] == 1'b0) begin
                // Pulse has ended, clear output
                pulseB_o <= 1'b0;
                // Keep busy high until we see the falling edge of the pulse in the next cycle
                // Actually, we need to wait for the full pulse to pass to clear busy
                // But since we only carry one pulse, we can clear busy when the pulse ends
                // However, to be safe and simple, we keep busy high until the pulse is fully synchronized out
                // A common approach is to keep busy high for the duration of the pulse + one cycle
                // Let's refine: busy should be high while the pulse is being transferred
                // We can clear busy when we see the falling edge of the pulse in the sync chain
                // But the sync chain shows the falling edge one cycle after the actual falling edge
                // So we can clear busy when sync_pulseA goes from 1 to 0
                // However, we need to make sure we don't clear busy too early
                // Let's use a different approach: busy is high when the pulse is in flight
                // We can set busy when we see the rising edge, and clear it when we see the falling edge
                // But the falling edge detection in the sync chain is delayed by one cycle
                // So we can clear busy when sync_pulseA[STAGES-1] is 0 and sync_pulseA[STAGES-2] is 0
                // and we were previously busy
                if (busy_reg == 1'b1) begin
                    busy_reg <= 1'b0;
                end
            end else begin
                // No edge detected, keep busy state
                // If we are not busy, stay not busy
                // If we are busy, stay busy until the falling edge is detected
                // The falling edge detection is handled above
                // So we just keep busy_reg as is
                // But we need to make sure we don't clear busy_reg prematurely
                // The logic above clears busy_reg only when we see the falling edge
                // So we don't need to do anything here
            end
        end
    end

    // Assign output signals
    assign busy_o = busy_reg;
    assign pulseB_o = (sync_pulseA[STAGES-1] == 1'b1 && sync_pulseA[STAGES-2] == 1'b0) ? 1'b1 : 1'b0;

endmodule
```<|im_end|>
