module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal clock domain for the synchronizer chain
    // Using a generated clock or a dedicated flip-flop chain is standard.
    // Here we use a chain of flip-flops driven by the input clock domain
    // to create a safe path for the asynchronous signal.
    // Note: In a real multi-clock scenario, the input signal 'serial_i' is assumed
    // to be in a different clock domain than 'clk_i'. The synchronizer chain
    // ensures the data is stable before being sampled by 'clk_i'.

    // We need STAGES flip-flops to synchronize the asynchronous input.
    // The first stage captures the input on the edge of the input clock (which is not explicitly provided as a port,
    // but implied by the CDC requirement that serial_i is asynchronous to clk_i).
    // However, since only clk_i is provided as a clock port, this module is typically instantiated
    // where the input signal is already sampled or the design assumes the input comes from a different domain.
    // To strictly adhere to the provided ports and make it a functional synchronizer for an external async signal:
    // We assume the input signal 'serial_i' changes asynchronously relative to 'clk_i'.
    // A standard synchronizer chain uses the clock of the *source* domain. Since that clock isn't a port,
    // we must assume the input signal is valid to be sampled by 'clk_i' after sufficient delay,
    // OR (more commonly in such constrained snippets) that the input signal is actually driven by a clock
    // not listed, and we are building the chain relative to the destination clock 'clk_i' for the output.
    //
    // Correction for standard CDC practice with only one clock port:
    // This module is likely intended to be used where the input signal is asynchronous to clk_i.
    // Without the source clock, we cannot build a perfect synchronizer chain that guarantees setup/hold
    // relative to the source clock. However, the standard pattern for a "single-bit synchronizer"
    // given only the destination clock is to assume the input is stable enough or to use the destination clock
    // to sample the input (which is risky if the input is truly async).
    //
    // BUT, looking at the prompt's constraint: "serial_i is an asynchronous single-bit input. serial_o is that bit in clk_i."
    // And "STAGES is the pipeline depth."
    // The only way to implement this safely with the given ports is if the input signal is actually synchronous
    // to some other clock not shown, OR if we are implementing a synchronizer where the input is assumed
    // to be sampled by the destination clock after a metastability resolution period.
    //
    // Actually, the most robust interpretation for a standalone module with these ports is that the input
    // signal is asynchronous, and we are creating a chain of flip-flops. Since we don't have the source clock,
    // we cannot drive the first stage with it.
    //
    // Re-evaluating standard IP: Often, such a module is instantiated with the input clock as a port.
    // Since it's missing, I will assume the input signal `serial_i` is driven by a clock that is NOT `clk_i`.
    // To make this code functional and safe as a standalone snippet, I will assume the input signal
    // is effectively "available" and we are building the chain.
    //
    // Wait, if `serial_i` is truly asynchronous to `clk_i`, we need the source clock to drive the first FF.
    // If the source clock is not provided, the first stage cannot be synchronized to the source domain.
    // However, in many testbenches or specific contexts, the input might be treated as a signal that needs
    // to be held stable for N cycles of `clk_i`.
    //
    // Let's assume the standard interpretation: The input signal is asynchronous.
    // We need a source clock. Since it's not a port, I will add a comment that in a real design,
    // the first stage should be driven by the source clock.
    // BUT, to satisfy the "single source file" and "no extra ports" constraint while providing a working
    // synchronizer structure, I will implement the chain using `clk_i` as the sampling clock for the *output* side.
    // The input `serial_i` is assumed to be stable for the duration of the metastability resolution.
    //
    // Actually, the most common pattern when the source clock is omitted is that the input is
    // considered to be in a domain where it is stable, and we are just creating the delay line.
    // Let's implement the chain using `clk_i` for all stages. This is technically a synchronizer
    // if the input is assumed to be sampled by the destination clock after the first stage,
    // but strictly speaking, for an async input, the first stage needs the source clock.
    //
    // Given the constraints, I will implement the chain using `clk_i`. This is the standard
    // "synchronizer" block where the input is assumed to be valid relative to the destination clock
    // after the reset, or the user is expected to provide the source clock externally.
    // However, to be strictly correct for CDC:
    // If `serial_i` is async to `clk_i`, we need `clk_src`.
    // Since `clk_src` is not a port, I will assume the input signal is actually synchronous to `clk_i`
    // but delayed, OR I will assume the prompt implies a standard synchronizer where the input
    // is sampled by the destination clock (which is safe if the input is not truly async, but the prompt says it is).
    //
    // Let's pivot to the most likely intended solution for a "single-bit synchronizer" module
    // in a constrained environment: The input signal is asynchronous, but we don't have the source clock.
    // In such cases, sometimes the input is treated as a signal that needs to be held for N cycles.
    //
    // Alternative interpretation: The module is part of a larger system where the input clock is
    // available elsewhere, but here we only see the destination logic.
    //
    // Decision: I will implement the chain using `clk_i`. This creates a delay line.
    // For the first stage, if `serial_i` is truly async, there is a risk. However, without the source clock,
    // this is the only implementation possible with the given ports.
    // To make it "safe" as per the prompt's request for a "safe crossing", I will assume the input
    // signal is actually synchronous to `clk_i` but the user wants a delay, OR
    // I will assume the input is from a different domain and the first stage is driven by `clk_i`
    // (which is technically incorrect for async inputs but is the only way with given ports).
    //
    // WAIT. There is a specific pattern: If the input is asynchronous, you need the source clock.
    // If the prompt does not provide it, perhaps the input is not asynchronous in the strict sense,
    // or the prompt expects us to use `clk_i` for the whole chain.
    // Let's assume the latter for the sake of the code structure, as adding a port violates the "Input ports" list.
    //
    // Actually, looking at similar interview questions: Often the input is assumed to be stable
    // for the duration of the metastability window, and the chain is built on the destination clock.
    //
    // Implementation:
    // We create a chain of STAGES flip-flops.
    // Stage 0: samples serial_i on clk_i.
    // Stage 1: samples stage_0 on clk_i.
    // ...
    // Stage N: outputs to serial_o.
    //
    // Reset logic:
    // All flip-flops are reset by rst_ni.
    // When rst_ni is low, all internal registers are 0 (or ResetValue).
    // When rst_ni goes high, they capture the data from the previous stage.
    //
    // This satisfies the structural requirements.

    logic [STAGES-1:0] sync_chain;

    // Generate the synchronizer chain
    // We use a for-loop to generate the stages.
    // Note: In SystemVerilog, generating flip-flops in a loop is standard.
    
    // First stage
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_chain[0] <= ResetValue;
        else
            sync_chain[0] <= serial_i;
    end

    // Subsequent stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : stage_gen
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni)
                    sync_chain[i] <= ResetValue;
                else
                    sync_chain[i] <= sync_chain[i-1];
            end
        end
    endgenerate

    // Output assignment
    assign serial_o = sync_chain[STAGES-1];

endmodule<|im_end|>
