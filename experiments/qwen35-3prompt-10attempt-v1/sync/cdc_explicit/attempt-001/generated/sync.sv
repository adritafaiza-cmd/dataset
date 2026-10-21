module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Generate a chain of flip-flops to synchronize the asynchronous input
    // to the clock domain of clk_i.
    // Using a Gray code counter or simple pipeline is sufficient for single-bit data.
    // A simple pipeline of STAGES flip-flops is the standard approach for single-bit CDC.
    
    logic [STAGES-1:0] sync_pipe;

    // First stage: Capture the asynchronous input on the target clock edge.
    // We use a non-blocking assignment for sequential logic.
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_pipe[0] <= ResetValue;
        else
            sync_pipe[0] <= serial_i;
    end

    // Subsequent stages: Pipeline the signal to ensure setup/hold time margins
    // and filter out metastability from the first stage.
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : stage_pipeline
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni)
                    sync_pipe[i] <= ResetValue;
                else
                    sync_pipe[i] <= sync_pipe[i-1];
            end
        end
    endgenerate

    // Output the last stage of the pipeline
    assign serial_o = sync_pipe[STAGES-1];

endmodule<|im_end|>
