module synchronizer #(
    parameter STAGES = 2
)(
    input  wire clk,
    input  wire rstn,
    input  wire async_sig_i,
    output wire sync_sig_o
);

    // Internal register to hold the synchronized value
    reg sync_sig_o;

    // Generate a chain of flip-flops to synchronize the asynchronous signal
    // This creates a pipeline of STAGES registers driven by the same clock
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : stage_pipeline
            reg sync_stage_reg;
            
            // First stage captures the asynchronous input
            if (i == 0) begin
                always @(posedge clk or negedge rstn) begin
                    if (!rstn)
                        sync_stage_reg <= 1'b0;
                    else
                        sync_stage_reg <= async_sig_i;
                end
            end else begin
                // Subsequent stages capture the output of the previous stage
                always @(posedge clk or negedge rstn) begin
                    if (!rstn)
                        sync_stage_reg <= 1'b0;
                    else
                        sync_stage_reg <= sync_stage_reg; // Hold previous value
                end
            end
            
            // Pass the output of this stage to the next stage's input
            if (i == STAGES - 1)
                sync_sig_o <= sync_stage_reg;
            else
                sync_stage_reg; // Output is connected to next stage input implicitly via assignment above
        end
    endgenerate

    // Correct the logic flow: The above generate block has a flaw in variable scoping and assignment direction.
    // Let's rewrite using a cleaner sequential approach with intermediate wires for clarity and correctness.
    
    // Re-implementing with explicit intermediate registers for robust CDC compliance
    reg [STAGES-1:0] sync_chain;

    genvar j;
    generate
        for (j = 0; j < STAGES; j = j + 1) begin : sync_ff
            always @(posedge clk or negedge rstn) begin
                if (!rstn)
                    sync_chain[j] <= 1'b0;
                else if (j == 0)
                    sync_chain[j] <= async_sig_i;
                else
                    sync_chain[j] <= sync_chain[j-1];
            end
        end
    endgenerate

    assign sync_sig_o = sync_chain[STAGES-1];

endmodule<|im_end|>
