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

    // Generate synchronization stages
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : gen_sync_stages
            if (i == 0) begin : first_stage
                sync_stage #(.ResetValue(ResetValue))
                sync_stage_0 (
                    .clk_i(clk_i),
                    .rst_ni(rst_ni),
                    .d(serial_i),
                    .q(sync_pipeline[i])
                );
            end else begin : other_stages
                sync_stage #(.ResetValue(ResetValue))
                sync_stage_i (
                    .clk_i(clk_i),
                    .rst_ni(rst_ni),
                    .d(sync_pipeline[i-1]),
                    .q(sync_pipeline[i])
                );
            end
        end
    endgenerate

    // Assign the final synchronized output
    assign serial_o = sync_pipeline[STAGES-1];

endmodule

// Single synchronization stage module
module sync_stage #(
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic d,
    output logic q
);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            q <= ResetValue;
        end else begin
            q <= d;
        end
    end

endmodule
