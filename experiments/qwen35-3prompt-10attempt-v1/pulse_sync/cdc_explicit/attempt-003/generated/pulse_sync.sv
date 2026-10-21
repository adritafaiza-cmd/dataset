```verilog
`timescale 1ns/1ps

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

    // Internal signals for clock domain A
    wire [STAGES-1:0] pulseA_d_a;
    wire [STAGES-1:0] busy_a;
    wire pulseA_valid_a;

    // Internal signals for clock domain B
    wire [STAGES-1:0] pulseA_d_b;
    wire [STAGES-1:0] busy_b;
    wire pulseA_valid_b;

    // ---------------------------------------------------------
    // Clock Domain A: Capture the input pulse and generate busy
    // ---------------------------------------------------------

    // Reset synchronization for domain A
    reg rst_a_sync;
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            rst_a_sync <= 1'b0;
        else
            rst_a_sync <= rst_a_sync | ~rstn_a;
    end

    // Stage 0: Capture input pulse and initial busy state
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulseA_d_a[0] <= 1'b0;
            busy_a[0]     <= 1'b0;
        end else begin
            pulseA_d_a[0] <= pulseA_i;
            busy_a[0]     <= pulseA_i;
        end
    end

    // Stages 1 to STAGES-1: Shift pulse and propagate busy
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : stage_a
            always @(posedge clk_a or negedge rstn_a) begin
                if (!rstn_a) begin
                    pulseA_d_a[i] <= 1'b0;
                    busy_a[i]     <= 1'b0;
                end else begin
                    pulseA_d_a[i] <= pulseA_d_a[i-1];
                    busy_a[i]     <= busy_a[i-1] | pulseA_d_a[i-1];
                end
            end
        end
    endgenerate

    // Derive valid pulse signal for domain A (last stage of shift register)
    assign pulseA_valid_a = pulseA_d_a[STAGES-1];

    // ---------------------------------------------------------
    // Clock Domain B: Capture pulse from A and generate output
    // ---------------------------------------------------------

    // Reset synchronization for domain B
    reg rst_b_sync;
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            rst_b_sync <= 1'b0;
        else
            rst_b_sync <= rst_b_sync | ~rstn_b;
    end

    // Stage 0: Capture pulse from A and initial busy state
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseA_d_b[0] <= 1'b0;
            busy_b[0]     <= 1'b0;
        end else begin
            pulseA_d_b[0] <= pulseA_valid_a;
            busy_b[0]     <= pulseA_valid_a;
        end
    end

    // Stages 1 to STAGES-1: Shift pulse and propagate busy
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : stage_b
            always @(posedge clk_b or negedge rstn_b) begin
                if (!rstn_b) begin
                    pulseA_d_b[i] <= 1'b0;
                    busy_b[i]     <= 1'b0;
                end else begin
                    pulseA_d_b[i] <= pulseA_d_b[i-1];
                    busy_b[i]     <= busy_b[i-1] | pulseA_d_b[i-1];
                end
            end
        end
    endgenerate

    // Derive valid pulse signal for domain B (last stage of shift register)
    assign pulseA_valid_b = pulseA_d_b[STAGES-1];

    // ---------------------------------------------------------
    // Output Assignment
    // ---------------------------------------------------------
    assign pulseB_o = pulseA_valid_b;
    assign busy_o   = busy_b[STAGES-1];

endmodule
```<|im_end|>
