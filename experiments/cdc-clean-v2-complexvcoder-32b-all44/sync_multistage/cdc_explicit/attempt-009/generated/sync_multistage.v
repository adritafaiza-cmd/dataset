module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal signal to connect the stages
    logic [STAGES-1:0] sync_stages;

    // First stage directly takes the input
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stages[0] <= ResetValue;
        end else begin
            sync_stages[0] <= serial_i;
        end
    end

    // Generate the remaining stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_sync_stages
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    sync_stages[i] <= ResetValue;
                end else begin
                    sync_stages[i] <= sync_stages[i-1];
                end
            end
        end
    endgenerate

    // Output the last stage
    assign serial_o = sync_stages[STAGES-1];

endmodule
