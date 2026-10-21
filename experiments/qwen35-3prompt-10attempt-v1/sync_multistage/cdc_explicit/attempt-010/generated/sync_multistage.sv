module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Generate pipeline stages for CDC compliance
    // Using a loop to unroll the flip-flops safely
    genvar i;
    logic [STAGES-1:0] sync_pipe;

    generate
        for (i = 0; i < STAGES; i = i + 1) begin : stage_gen
            logic sync_stage;
            
            // First stage: Capture asynchronous input on target clock
            // Reset is synchronized here via the same chain
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni)
                    sync_stage <= ResetValue;
                else
                    sync_stage <= serial_i;
            end

            // Subsequent stages: Simple pipeline delay
            if (i > 0) begin : sub_stage
                always_ff @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        sync_stage <= ResetValue;
                    else
                        sync_stage <= sync_pipe[i-1];
                end
            end
        end
    endgenerate

    // Assign final output
    assign serial_o = sync_pipe[STAGES-1];

endmodule<|im_end|>
