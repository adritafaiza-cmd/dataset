module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal signals to hold the pipeline stages
    logic [STAGES-1:0] pipeline;

    // First stage directly takes the asynchronous input
    sync_stage stage_0 (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .serial_i (serial_i),
        .serial_o (pipeline[0])
    );

    // Generate the remaining pipeline stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_pipeline_stages
            sync_stage stage_i (
                .clk_i    (clk_i),
                .rst_ni   (rst_ni),
                .serial_i (pipeline[i-1]),
                .serial_o (pipeline[i])
            );
        end
    endgenerate

    // The final stage output is the synchronized output
    assign serial_o = pipeline[STAGES-1];

endmodule

module sync_stage (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            serial_o <= ResetValue;
        end else begin
            serial_o <= serial_i;
        end
    end

endmodule
