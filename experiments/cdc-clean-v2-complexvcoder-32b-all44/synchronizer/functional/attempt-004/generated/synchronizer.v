module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    wire [STAGES-1:0] pipeline_stages;

    // First stage directly connects to the asynchronous input
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pipeline_stages[0] <= 1'b0;
        end else begin
            pipeline_stages[0] <= async_sig_i;
        end
    end

    // Generate the rest of the pipeline stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_pipeline
            always @(posedge clk or negedge rstn) begin
                if (!rstn) begin
                    pipeline_stages[i] <= 1'b0;
                end else begin
                    pipeline_stages[i] <= pipeline_stages[i-1];
                end
            end
        end
    endgenerate

    // Assign the final stage to the output
    assign sync_sig_o = pipeline_stages[STAGES-1];

endmodule
