```verilog
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

    // Internal signals for the pipeline stages
    // We use a shift register approach where data moves from stage 0 to stage STAGES-1
    // and the last stage drives the output.
    
    reg [DWIDTH-1:0] data_pipe [0:STAGES-1];
    reg [STAGES-1:0]  ready_pipe;

    // Logic for the first stage (captures din)
    // The first stage always accepts data on the rising edge of clk if not reset.
    // It does not depend on dready_i for capturing, but the downstream stages 
    // will control when the data is actually pushed forward.
    // However, a common pattern for "ready" synchronization is:
    // Stage 0: Captures din immediately (or on ready). 
    // To ensure the output is only valid when the consumer is ready, 
    // we typically chain the 'ready' signal backwards or use a specific handshake protocol.
    
    // Given the requirement: "Bring each new input value into the local clock domain coherently 
    // and indicate when it is ready."
    // Standard approach: 
    // 1. Data enters stage 0.
    // 2. Data moves from stage i to i+1 only if stage i+1 is ready (or simply on every clock if we assume 
    //    the consumer is the one asserting ready_i).
    // 
    // Let's implement a standard FIFO-like synchronizer where:
    // - din is captured into stage 0.
    // - Data shifts through the pipeline.
    // - The output is valid only when the data has traversed all STAGES.
    // - The 'dready_o' is asserted when the data is stable at the output.
    //
    // To handle the 'dready_i' correctly in the source domain:
    // We assume the producer (din source) wants to send data. 
    // The synchronizer should accept data continuously (or gated by dready_i if strict handshake is needed).
    // Usually, for a simple synchronizer, we capture din on every clock (or when dready_i is high).
    // If dready_i is an input from the *other* domain, it might be glitchy. 
    // However, the prompt says "dready_i enter the clk domain", implying it's an input signal we must respect.
    // 
    // Robust Design Strategy:
    // 1. Capture din into the first stage. To prevent overwriting valid data being shifted out, 
    //    we can gate the capture with dready_i (if the producer is waiting for the consumer to be ready) 
    //    OR we can just capture din and let the pipeline drain.
    // 
    // Interpretation of "indicate when it is ready":
    // The output dready_o should be high when the data at dout is stable and valid.
    // The data moves through the pipeline. Once it reaches the last stage, it is ready.
    // 
    // Implementation Detail:
    // Stage 0 captures din.
    // Stage i captures data from Stage i-1.
    // To ensure the output is ready, we need to know if the pipeline is full or if data has arrived.
    // Since we don't have a write pointer, we assume a simple shift register.
    // 
    // Refined Logic:
    // - Always capture din into stage 0? No, that might overwrite data if the consumer isn't ready.
    // - Better: Capture din into stage 0 only if the pipeline isn't "full" or simply always capture 
    //   and rely on the fact that the consumer pulls data. But without a read pointer, we can't know 
    //   if the consumer is pulling.
    // 
    // Alternative Standard Pattern (Async FIFO style simplified):
    // We treat this as a depth-STAGES buffer.
    // We need a 'full' flag? No, the prompt implies a simple synchronizer.
    // Let's assume the producer sends data whenever dready_i is high (handshake).
    // But dready_i is an input from the *other* domain. If the other domain asserts dready_i, 
    // it means "I am ready to accept data".
    // So, we should capture din only when dready_i is high.
    // 
    // Wait, the interface has:
    // din (input)
    // dready_i (input) -> This is likely "Is the consumer ready?" coming from the other domain.
    // dready_o (output) -> This is "Is the producer ready?" going to the other domain.
    // 
    // Correct Handshake Flow:
    // 1. Consumer (other domain) asserts dready_i.
    // 2. Producer (our module) sees dready_i, captures din into the pipeline.
    // 3. Data shifts through STAGES.
    // 4. When data reaches the last stage, we assert dready_o.
    // 5. Consumer sees dready_o, reads dout, deasserts dready_i.
    // 
    // However, the prompt says "dready_i enter the clk domain". This suggests dready_i is a signal 
    // we need to synchronize or at least sample safely.
    // 
    // Let's implement a robust synchronizer:
    // - Use a shift register for data.
    // - Use a shift register for the 'ready' status to propagate the 'ready' signal from the consumer 
    //   back to the producer logic safely.
    // 
    // Actually, a simpler and very common interpretation for "data synchronizer" with ready signals:
    // The data is pushed through the pipeline. The 'dready_o' is asserted when the data has been 
    // in the pipeline for STAGES cycles.
    // The 'dready_i' is used to gate the input capture.
    // 
    // Logic:
    // - If rstn is low, clear everything.
    // - On rising edge of clk:
    //   - If rstn is high AND dready_i is high:
    //       Capture din into stage 0.
    //       Shift data from stage i to i+1.
    //       Shift 'ready' status? 
    // 
    // Let's refine the 'ready' propagation.
    // We want dready_o to be high when the data at the last stage is valid.
    // If we just shift data, the last stage is always valid once data enters.
    // But we need to handle the case where the pipeline is empty.
    // 
    // Proposed State:
    // We maintain a 'valid' flag for each stage.
    // Stage 0: valid = (dready_i was high in previous cycle? No, we capture on dready_i).
    // Let's assume the standard "Handshake Synchronizer":
    // 1. Consumer asserts dready_i.
    // 2. Producer captures data.
    // 3. Data moves through pipeline.
    // 4. Producer asserts dready_o.
    // 5. Consumer reads data and deasserts dready_i.
    // 
    // To implement this safely across domains:
    // - dready_i is sampled.
    // - Data is captured when dready_i is high.
    // - Data shifts through the pipeline.
    // - dready_o is asserted when the data has reached the last stage.
    // 
    // We need to track if the pipeline is full or if data is present.
    // Since we don't have a read pointer, we assume the consumer pulls data immediately when dready_o is high.
    // 
    // Implementation:
    // - data_pipe[0] captures din when dready_i is high.
    // - data_pipe[i] captures data_pipe[i-1] on every clock (once data is in).
    // - We need a 'valid' flag for each stage to know if data exists.
    // - dready_o is valid if data_pipe[STAGES-1] is valid.
    // 
    // Wait, if we just shift data, the last stage will hold garbage until data arrives.
    // So we need a 'valid' bit per stage.
    // 
    // Revised Logic:
    // - valid_pipe[0] = dready_i (sampled).
    // - valid_pipe[i] = valid_pipe[i-1] (shifted).
    // - If valid_pipe[STAGES-1] is high, then dready_o = 1.
    // - Data shifts only if valid_pipe[i-1] is high? Or just shift data and rely on valid flags?
    //   Shifting data only when valid is safer to avoid garbage propagation.
    // 
    // Let's combine:
    // - On rising edge:
    //   - If rstn: clear all data and valid flags.
    //   - Else:
    //     - valid_pipe[0] = dready_i;
    //     - data_pipe[0] = (valid_pipe[0]) ? din : data_pipe[0]; // Hold if not ready
    //     - For i = 1 to STAGES-1:
    //       - valid_pipe[i] = valid_pipe[i-1];
    //       - data_pipe[i] = (valid_pipe[i-1]) ? data_pipe[i-1] : data_pipe[i];
    //     - dready_o = valid_pipe[STAGES-1];
    // 
    // This looks correct. It ensures data only moves if the previous stage had valid data.
    // And the first stage only accepts new data if dready_i is high.
    // The output is ready only when the data has traversed all STAGES.
    
    reg [DWIDTH-1:0] data_pipe [0:STAGES-1];
    reg              valid_pipe [0:STAGES-1];

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Reset state
            for (integer i = 0; i < STAGES; i = i + 1) begin
                data_pipe[i] <= 0;
                valid_pipe[i] <= 1'b0;
            end
            dout <= 0;
            dready_o <= 1'b0;
        end else begin
            // Stage 0 Logic
            // Capture data only if the consumer (other domain) is ready (dready_i)
            // We sample dready_i directly. Since it enters the domain, we assume it's stable enough 
            // or we rely on the fact that glitches won't cause immediate corruption if we hold data.
            // However, to be safe against metastability on dready_i, we could add a small sync, 
            // but the prompt implies dready_i is already in the domain or we just sample it.
            // Given "dready_i enter the clk domain", we sample it.
            
            valid_pipe[0] <= dready_i;
            
            if (dready_i) begin
                data_pipe[0] <= din;
            end else begin
                // Hold data if not ready
                data_pipe[0] <= data_pipe[0];
            end

            // Stages 1 to STAGES-1
            for (integer i = 1; i < STAGES; i = i + 1) begin
                valid_pipe[i] <= valid_pipe[i-1];
                if (valid_pipe[i-1]) begin
                    data_pipe[i] <= data_pipe[i-1];
                end else begin
                    data_pipe[i] <= data_pipe[i];
                end
            end

            // Output Logic
            // Data is ready at the last stage if valid_pipe[STAGES-1] is high
            if (valid_pipe[STAGES-1]) begin
                dout <= data_pipe[STAGES-1];
                dready_o <= 1'b1;
            end else begin
                dout <= 0; // Or keep previous, but 0 is safe for idle
                dready_o <= 1'b0;
            end
        end
    end

endmodule
```<|im_end|>
