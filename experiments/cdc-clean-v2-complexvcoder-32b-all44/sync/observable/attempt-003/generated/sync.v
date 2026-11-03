module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal signal to hold the synchronization chain
    logic [STAGES:0] sync_chain;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            // Reset the synchronization chain to the ResetValue
            sync_chain <= {STAGES+1{ResetValue}};
        end else begin
            // Shift the input through the synchronization chain
            sync_chain <= {sync_chain[STAGES-1:0], serial_i};
        end
    end

    // Assign the final stage of the synchronization chain to the output
    assign serial_o = sync_chain[STAGES];

endmodule
