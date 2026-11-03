module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal signals for pipeline stages
    logic [STAGES-1:0] sync_pipeline;

    // First stage synchronizer
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_pipeline[0] <= ResetValue;
        end else begin
            sync_pipeline[0] <= serial_i;
        end
    end

    // Generate additional stages if STAGES > 1
    genvar i;
    generate
        if (STAGES > 1) begin
            for (i = 1; i < STAGES; i = i + 1) begin : gen_pipeline_stages
                always_ff @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni) begin
                        sync_pipeline[i] <= ResetValue;
                    end else begin
                        sync_pipeline[i] <= sync_pipeline[i-1];
                    end
                end
            end
        end
    endgenerate

    // Assign the final stage to the output
    assign serial_o = sync_pipeline[STAGES-1];

endmodule
