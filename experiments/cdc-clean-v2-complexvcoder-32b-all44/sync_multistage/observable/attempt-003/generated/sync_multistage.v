module sync_multistage #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal signal to hold the synchronization chain
    logic [STAGES-1:0] sync_chain;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            // Initialize all stages to the ResetValue on reset
            sync_chain <= {STAGES{ResetValue}};
        end else begin
            // Shift the input through the synchronization stages
            sync_chain[0] <= serial_i;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_chain[i] <= sync_chain[i-1];
            end
        end
    end

    // Assign the final synchronized value to the output
    assign serial_o = sync_chain[STAGES-1];

endmodule
