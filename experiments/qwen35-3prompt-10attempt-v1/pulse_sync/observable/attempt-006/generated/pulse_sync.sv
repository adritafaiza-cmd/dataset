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

    // Synchronizer chain for pulseA_i on clk_b
    reg [STAGES-1:0] sync_pulseA;
    reg [STAGES-1:0] sync_busy;

    // Synchronizer chain for busy_o on clk_a
    reg [STAGES-1:0] sync_busy_a;

    // State machine to track if a pulse is in flight
    // State 0: Idle (no pulse in flight)
    // State 1: Busy (pulse in flight)
    reg [1:0] state;

    // --- Clock Domain A Logic (Source Side) ---
    // 1. Synchronize the incoming pulse
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            sync_pulseA <= {STAGES{1'b0}};
        else begin
            sync_pulseA[0] <= pulseA_i;
            sync_pulseA[1:STAGES-1] <= sync_pulseA[0:STAGES-2];
        end
    end

    // 2. Detect the start of a pulse
    // We look for a rising edge in the synchronized signal
    reg pulseA_detected;
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            pulseA_detected <= 1'b0;
        else begin
            pulseA_detected <= sync_pulseA[0] & ~sync_pulseA[1];
        end
    end

    // 3. State Machine
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            state <= 2'b00;
        else begin
            case (state)
                2'b00: // Idle
                    if (pulseA_detected)
                        state <= 2'b01; // Transition to Busy
                    else
                        state <= 2'b00;
                2'b01: // Busy
                    state <= 2'b01; // Stay Busy
                default:
                    state <= 2'b00;
            endcase
        end
    end

    // 4. Generate output pulse on clk_a (one-shot)
    // We need to generate a single cycle pulse when transitioning from Idle to Busy
    reg pulseA_out_a;
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            pulseA_out_a <= 1'b0;
        else begin
            // Pulse high only when transitioning from Idle (00) to Busy (01)
            if (state == 2'b00 && pulseA_detected)
                pulseA_out_a <= 1'b1;
            else
                pulseA_out_a <= 1'b0;
        end
    end

    // 5. Synchronize the generated pulse to Clock Domain B
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            sync_busy <= {STAGES{1'b0}};
        else begin
            sync_busy[0] <= pulseA_out_a;
            sync_busy[1:STAGES-1] <= sync_busy[0:STAGES-2];
        end
    end

    // --- Clock Domain B Logic (Destination Side) ---
    // 1. Synchronize the busy signal back to Clock Domain A
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            sync_busy_a <= {STAGES{1'b0}};
        else begin
            sync_busy_a[0] <= sync_busy[STAGES-1]; // Take the last stage of sync_busy
            sync_busy_a[1:STAGES-1] <= sync_busy_a[0:STAGES-2];
        end
    end

    // 2. Output logic
    // pulseB_o is the synchronized pulse
    // busy_o indicates if a pulse is currently in flight (synchronized back to A)
    assign pulseB_o = sync_busy[STAGES-1];
    assign busy_o = sync_busy_a[STAGES-1];

endmodule
```<|im_end|>
