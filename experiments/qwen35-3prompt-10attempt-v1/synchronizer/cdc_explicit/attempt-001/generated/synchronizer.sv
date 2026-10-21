module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    // Internal register to hold the synchronized value
    reg sync_sig_o;

    // Generate pipeline stages for CDC compliance
    // Using a counter-based approach to ensure exactly STAGES registers are used
    // regardless of the reset logic, ensuring structural integrity for tools.
    genvar i;
    reg [STAGES-1:0] stage_reg;

    // Initialize the first stage register
    // This ensures the chain starts correctly after reset
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            stage_reg[0] <= 1'b0;
        else
            stage_reg[0] <= async_sig_i;
    end

    // Generate the remaining stages
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : stage_pipeline
            always @(posedge clk or negedge rstn) begin
                if (!rstn)
                    stage_reg[i] <= 1'b0;
                else
                    stage_reg[i] <= stage_reg[i-1];
            end
        end
    endgenerate

    // Assign the final output
    assign sync_sig_o = stage_reg[STAGES-1];

endmodule<|im_end|>
