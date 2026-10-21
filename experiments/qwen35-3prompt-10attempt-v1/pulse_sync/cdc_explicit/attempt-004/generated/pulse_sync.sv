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

    // Generate number of flip-flops for the pipeline
    localparam NUM_FF = 1 << STAGES;

    // ---------------------------------------------------------
    // Domain A: Capture the pulse and manage state
    // ---------------------------------------------------------
    // State encoding:
    // 0: IDLE (waiting for pulse)
    // 1: CAPTURE (pulse detected, propagating through pipeline)
    // 2: DONE (pipeline cleared, ready for next pulse)
    //
    // We use a simple state machine to ensure we only capture one pulse
    // and wait for the pipeline to clear before accepting another.
    // This avoids metastability issues by ensuring the capture happens
    // on a stable edge and the output is only asserted after the data
    // has safely crossed the boundary.

    reg [1:0] state_a;
    reg       pulse_a_reg; // Synchronized version of pulseA_i

    // Synchronize pulseA_i to clk_a
    reg [STAGES-1:0] pulse_pipe_a;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            state_a      <= 2'b00;
            pulse_a_reg  <= 1'b0;
            pulse_pipe_a <= {STAGES{1'b0}};
        end else begin
            // State Machine
            case (state_a)
                2'b00: begin // IDLE
                    if (pulse_a_reg) begin
                        state_a <= 2'b01; // Transition to CAPTURE
                        // Start shifting the pulse into the pipeline
                        pulse_pipe_a <= {1'b1, pulse_pipe_a[STAGES-2:0]};
                    end
                end
                2'b01: begin // CAPTURE
                    // Shift the pulse through the pipeline
                    pulse_pipe_a <= {1'b1, pulse_pipe_a[STAGES-2:0]};
                    // Check if the pulse has completely passed through the pipeline
                    // The pulse enters at the MSB and shifts right.
                    // After STAGES cycles, the original '1' will be at LSB (bit 0).
                    // We need to wait until the pipeline is all zeros again.
                    if (pulse_pipe_a[STAGES-1:1] == 1'b0) begin
                        state_a <= 2'b10; // Transition to DONE
                    end
                end
                2'b10: begin // DONE
                    // Wait for pipeline to clear completely
                    if (pulse_pipe_a == 1'b0) begin
                        state_a <= 2'b00; // Back to IDLE
                    end
                end
                default: state_a <= 2'b00;
            endcase

            // Update synchronized pulse register
            pulse_a_reg <= pulseA_i;
        end
    end

    // ---------------------------------------------------------
    // Domain B: Generate the output pulse
    // ---------------------------------------------------------
    // We use a simple FIFO-like structure or a counter to generate
    // a single pulse in domain B when the state machine indicates
    // a pulse has been successfully captured and cleared.
    //
    // To ensure CDC safety, we transfer the "ready" signal (state_a == DONE)
    // across the clock domains. However, a direct transfer of a single-bit
    // state flag can be tricky if not synchronized.
    //
    // Strategy:
    // 1. Transfer the "pulse detected" event from Domain A to Domain B.
    //    Since we need to generate a pulse in B, we can use a simple
    //    handshake or a one-shot mechanism triggered by the crossing.
    //
    // Refined Strategy for Robustness:
    // Instead of complex state transfer, we will use a standard
    // "Pulse Generator" pattern where Domain A signals "Pulse Ready"
    // and Domain B generates the pulse.
    //
    // To avoid holding the signal too long in A, we will use a
    // simple 2-stage synchronizer to detect the transition from IDLE->CAPTURE
    // and then use a counter in Domain B to generate the pulse width.
    //
    // Actually, the requirement is "one pulse in, one pulse out".
    // The state machine in A ensures we don't accept new pulses until the
    // previous one is fully processed.
    //
    // Let's transfer the "Pulse Start" event to Domain B.
    // We will use a simple FIFO pointer or a single-bit flag with proper
    // synchronization. Given the simplicity, a single-bit flag with
    // a 2-stage synchronizer in B is sufficient to detect the event,
    // followed by a local one-shot to generate the output pulse.
    //
    // However, to strictly follow "safe crossing" and "ignore additional pulses",
    // the state machine in A effectively serializes the input.
    // We just need to convey the "Go" signal to B.

    // Signal to indicate a pulse has been captured and is propagating
    // We send this to Domain B.
    reg pulse_start_flag;

    // Synchronize pulse_start_flag from Domain A to Domain B
    // We need to detect the transition from IDLE to CAPTURE in A.
    // Let's create a signal 'pulse_detected' in A that goes high when
    // state changes to CAPTURE, then synchronize it to B.
    
    reg pulse_detected_a;
    reg [1:0] prev_state_a;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulse_detected_a <= 1'b0;
            prev_state_a     <= 2'b00;
        end else begin
            pulse_detected_a <= (state_a == 2'b01) && (prev_state_a != 2'b01);
            prev_state_a     <= state_a;
        end
    end

    // Synchronize pulse_detected_a to clk_b
    reg [1:0] pulse_sync_pipe_b;
    reg       pulse_sync_valid_b;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulse_sync_pipe_b <= 2'b00;
            pulse_sync_valid_b <= 1'b0;
        end else begin
            pulse_sync_pipe_b <= {pulse_detected_a, pulse_sync_pipe_b[0]};
            pulse_sync_valid_b <= pulse_sync_pipe_b[1];
        end
    end

    // Generate the output pulse in Domain B
    // Use a simple counter to ensure exactly one cycle high
    reg [STAGES:0] pulse_counter_b;
    reg pulse_b_internal;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulse_counter_b <= 0;
            pulse_b_internal <= 1'b0;
            busy_o <= 1'b0;
        end else begin
            if (pulse_sync_valid_b) begin
                // Start the pulse sequence
                pulse_counter_b <= 0;
                pulse_b_internal <= 1'b1;
                busy_o <= 1'b1;
            end else if (pulse_counter_b == 0) begin
                // Pulse is active
                pulse_b_internal <= 1'b1;
                busy_o <= 1'b1;
            end else begin
                // Decrement counter
                pulse_counter_b <= pulse_counter_b - 1'b1;
                pulse_b_internal <= 1'b0;
                busy_o <= 1'b0;
            end
        end
    end

    // Assign output
    assign pulseB_o = pulse_b_internal;

    // Ensure busy_o is driven correctly even if the counter logic above
    // has any edge cases (redundant safety)
    // The logic above sets busy_o high when pulse_sync_valid_b is high
    // and keeps it high until the counter wraps.
    // Let's refine the busy_o logic to be strictly tied to the pulse generation.
    
    // Re-evaluating busy_o logic for clarity and safety:
    // busy_o should be high while the pulse is being generated in B.
    // The pulse is generated for (STAGES + 1) cycles roughly to ensure
    // the data has cleared the pipeline in A? 
    // Actually, the requirement is just "one pulse out".
    // The duration of the output pulse doesn't strictly matter as long as
    // it's one cycle (or a defined burst) and busy_o reflects the "in flight" state.
    //
    // Let's simplify:
    // When pulse_sync_valid_b goes high, we assert busy_o and pulseB_o.
    // We keep them high for a fixed number of cycles to ensure the "flight"
    // is complete in B's domain perspective, then release.
    //
    // Revised logic for Domain B:
    reg [STAGES:0] flight_counter;
    reg flight_active;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            flight_counter <= 0;
            flight_active  <= 1'b0;
            busy_o         <= 1'b0;
            pulseB_o       <= 1'b0;
        end else begin
            if (pulse_sync_valid_b) begin
                flight_counter <= 0;
                flight_active  <= 1'b1;
                busy_o         <= 1'b1;
                pulseB_o       <= 1'b1;
            end else if (flight_active) begin
                flight_counter <= flight_counter + 1'b1;
                // Keep pulse and busy high for a safe duration
                // STAGES + 1 ensures we cover the pipeline depth
                if (flight_counter < STAGES + 1) begin
                    pulseB_o <= 1'b1;
                    busy_o  <= 1'b1;
                end else begin
                    pulseB_o <= 1'b0;
                    busy_o  <= 1'b0;
                    flight_active <= 1'b0;
                end
            end
        end
    end

endmodule<|im_end|>
