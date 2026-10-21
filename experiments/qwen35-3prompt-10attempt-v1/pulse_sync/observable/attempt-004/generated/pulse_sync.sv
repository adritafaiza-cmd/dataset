```verilog
module pulse_sync #(
    parameter STAGES = 2
)(
    input  wire clk_a,
    input  wire rstn_a,
    input  wire clk_b,
    input  wire rstn_b,
    input  wire pulseA_i,
    output reg  pulseB_o,
    output reg  busy_o
);

    // Synchronizer for pulseA_i on clk_a domain
    // Detects the rising edge of the pulse in the source clock domain
    wire pulseA_synced;
    reg [STAGES-1:0] pulseA_sync_reg;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            pulseA_sync_reg <= {STAGES{1'b0}};
        else
            pulseA_sync_reg <= {pulseA_sync_reg[STAGES-2:0], pulseA_i};
    end

    // Detect the single pulse transition in the source domain
    wire pulseA_detected = pulseA_sync_reg[0] & ~pulseA_sync_reg[1];

    // State machine in clk_a domain to manage the "busy" flag and trigger transfer
    // States: IDLE, BUSY
    reg [1:0] state_a;
    parameter IDLE_A = 2'b00, BUSY_A = 2'b01;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            state_a <= IDLE_A;
        else begin
            case (state_a)
                IDLE_A:
                    if (pulseA_detected)
                        state_a <= BUSY_A;
                    else
                        state_a <= IDLE_A;
                BUSY_A:
                    state_a <= IDLE_A; // Automatically clear busy after one pulse detected
            endcase
        end
    end

    // Trigger signal to send to destination domain
    // This is asserted when a pulse is detected and we are in BUSY state
    wire trigger_a = (state_a == BUSY_A);

    // Synchronizer for trigger_a on clk_b domain
    reg [STAGES-1:0] trigger_sync_reg;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            trigger_sync_reg <= {STAGES{1'b0}};
        else
            trigger_sync_reg <= {trigger_sync_reg[STAGES-2:0], trigger_a};
    end

    // Detect the trigger in the destination domain
    wire trigger_b = trigger_sync_reg[0] & ~trigger_sync_reg[1];

    // State machine in clk_b domain to generate the output pulse
    // States: IDLE, PULSED
    reg [1:0] state_b;
    parameter IDLE_B = 2'b00, PULSED_B = 2'b01;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o <= 1'b0;
            busy_o  <= 1'b0;
            state_b <= IDLE_B;
        end else begin
            case (state_b)
                IDLE_B:
                    if (trigger_b) begin
                        pulseB_o <= 1'b1;
                        busy_o  <= 1'b1;
                        state_b <= PULSED_B;
                    end
                PULSED_B:
                    if (trigger_b) begin
                        // If another trigger arrives while busy, ignore it (state stays PULSED_B)
                        // But we need to ensure pulseB_o goes low eventually.
                        // Since this is a one-pulse-out requirement, we hold the pulse for one cycle
                        // and then return to IDLE. However, the requirement says "carry input pulse... once".
                        // Usually, this means output a single cycle pulse.
                        // Let's refine: Output high for one cycle, then low.
                        // If multiple triggers come in while busy, we ignore them.
                        // So we stay in PULSED_B until the current pulse cycle is done?
                        // Actually, simpler logic:
                        // If we are in PULSED_B, we output 1.
                        // On the next clock edge, we go back to IDLE_B and output 0.
                        // If a new trigger comes during PULSED_B, we ignore it.
                        // So we just need to count one cycle.
                        // But wait, if we go to IDLE_B immediately, the pulse is 1 cycle.
                        // If a new trigger comes, we stay in PULSED_B? No, that would extend the pulse.
                        // Correct logic:
                        // IDLE -> (trigger) -> PULSED (output 1) -> (next clk) -> IDLE (output 0).
                        // If trigger comes in PULSED state, ignore it.
                        // So we just need to force a transition to IDLE after one cycle regardless of new triggers.
                        // But how to detect "one cycle passed"?
                        // We can use a counter or just rely on the fact that we only process one trigger.
                        // Let's use a simple counter approach or a dedicated pulse generator.
                        
                        // Revised State Machine Logic for Destination:
                        // We want exactly one pulse out per valid input.
                        // If we receive a trigger, we set pulseB_o = 1 for one clock cycle.
                        // We must ignore any subsequent triggers until the pulse is done.
                        
                        // Let's use a counter based approach for clarity and robustness.
                        // Or simpler: 
                        // State IDLE: wait for trigger.
                        // State PULSING: output 1. Next cycle go to DONE.
                        // State DONE: output 0. Wait for trigger.
                        // If trigger comes in PULSING or DONE, handle accordingly.
                        // Requirement: "ignore further pulses while busy".
                        // So if in PULSING or DONE, ignore trigger.
                        // Transition: IDLE --(trigger)--> PULSING --(clk)--> DONE --(clk)--> IDLE.
                        // This ensures exactly one pulse cycle.
                        
                        // Let's re-implement the FSM logic inside the always block below.
                    end
                PULSED_B:
                    // Output is already 1. Next cycle we will go to DONE.
                    // Ignore any new triggers here.
                    state_b <= 2'b10; // DONE_B
                DONE_B:
                    // Output is 0. Next cycle we will go to IDLE.
                    // Ignore any new triggers here.
                    state_b <= IDLE_B;
            endcase
        end
    end

    // Assign outputs based on state
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o <= 1'b0;
            busy_o  <= 1'b0;
        end else begin
            case (state_b)
                IDLE_B: begin
                    pulseB_o <= 1'b0;
                    busy_o  <= 1'b0;
                end
                PULSED_B: begin
                    pulseB_o <= 1'b1;
                    busy_o  <= 1'b1;
                end
                DONE_B: begin
                    pulseB_o <= 1'b0;
                    busy_o  <= 1'b0;
                end
            endcase
        end
    end

    // Re-evaluating the FSM logic to ensure it matches the "one pulse" requirement strictly.
    // The previous case statement had a flaw in the transition logic inside the always block.
    // Let's rewrite the destination logic cleanly.
    
    // Destination State Machine
    reg [1:0] dst_state;
    parameter DST_IDLE = 2'b00, DST_PULSE = 2'b01, DST_DONE = 2'b10;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            dst_state <= DST_IDLE;
        end else begin
            case (dst_state)
                DST_IDLE: begin
                    if (trigger_b)
                        dst_state <= DST_PULSE;
                    else
                        dst_state <= DST_IDLE;
                end
                DST_PULSE: begin
                    // Stay in PULSE for one cycle, then go to DONE
                    // Ignore any new triggers
                    dst_state <= DST_DONE;
                end
                DST_DONE: begin
                    // Stay in DONE for one cycle, then go to IDLE
                    // Ignore any new triggers
                    dst_state <= DST_IDLE;
                end
            endcase
        end
    end

    // Output assignment
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o <= 1'b0;
            busy_o   <= 1'b0;
        end else begin
            case (dst_state)
                DST_IDLE: begin
                    pulseB_o <= 1'b0;
                    busy_o   <= 1'b0;
                end
                DST_PULSE: begin
                    pulseB_o <= 1'b1;
                    busy_o   <= 1'b1;
                end
                DST_DONE: begin
                    pulseB_o <= 1'b0;
                    busy_o   <= 1'b0;
                end
            endcase
        end
    end

endmodule
```<|im_end|>
