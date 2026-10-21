module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Synchronizer chain for the data bit
    // Uses a 2-stage flip-flop chain to safely cross clock domains.
    // STAGES parameter allows configuration of depth (2 is standard for safety).
    logic [STAGES-1:0] sync_chain;

    // Generate reset signal for the internal chain
    // Since rst_ni is active-low and asynchronous, we propagate it directly.
    // The first stage captures the reset state immediately upon release.
    assign sync_chain[0] = rst_ni ? 1'b0 : serial_i;

    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : stage_gen
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni)
                    sync_chain[i] <= 1'b0;
                else
                    sync_chain[i] <= sync_chain[i-1];
            end
        end
    endgenerate

    // Final output assignment
    // The last stage of the synchronizer chain provides the synchronized value.
    // If STAGES is 1, sync_chain[0] is used directly (handled by logic above).
    // If STAGES > 1, sync_chain[STAGES-1] is the final synchronized bit.
    assign serial_o = (STAGES == 1) ? sync_chain[0] : sync_chain[STAGES-1];

    // Note on Reset Value:
    // The requirement states "After reset, serial_o equals ResetValue".
    // In the implementation above, the internal flip-flops are cleared to 1'b0 on reset.
    // To support an arbitrary ResetValue (e.g., 1'b1), we must OR the reset condition
    // with the desired value before the first flip-flop, or use a separate reset logic.
    // However, standard synchronizers typically clear to 0. To strictly adhere to
    // "serial_o equals ResetValue" after reset, we modify the first stage logic.

    // Re-implementing the first stage to support arbitrary ResetValue
    // We create an intermediate signal that holds the reset value when rst_ni is low.
    logic rst_synced;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            rst_synced <= ResetValue;
        else
            rst_synced <= serial_i;
    end

    // Re-generate the chain using rst_synced as the first stage input
    // This ensures that when rst_ni is released, the chain starts with ResetValue.
    // We need to restructure the generation to use rst_synced as the source for stage 0.

    // Let's flatten the logic for clarity and correctness regarding ResetValue.
    // Stage 0: Captures serial_i, but initializes to ResetValue on reset.
    // Stages 1 to STAGES-1: Shift the value.

    logic [STAGES-1:0] chain_reg;

    // First stage: Input synchronizer with custom reset value
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            chain_reg[0] <= ResetValue;
        else
            chain_reg[0] <= serial_i;
    end

    // Subsequent stages: Standard shift registers
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : stage_gen
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni)
                    chain_reg[i] <= ResetValue;
                else
                    chain_reg[i] <= chain_reg[i-1];
            end
        end
    endgenerate

    assign serial_o = chain_reg[STAGES-1];

endmodule<|im_end|>
