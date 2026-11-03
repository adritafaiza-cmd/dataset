module sync_multistage #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal signal array to hold the stages of the synchronizer
    logic [STAGES-1:0] sync_ff;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            // Reset the synchronizer chain to the specified reset value
            sync_ff <= {STAGES{ResetValue}};
        end else begin
            // Shift the asynchronous input through the synchronizer chain
            sync_ff[0] <= serial_i;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_ff[i] <= sync_ff[i-1];
            end
        end
    end

    // Assign the final stage of the synchronizer chain to the output
    assign serial_o = sync_ff[STAGES-1];

endmodule
