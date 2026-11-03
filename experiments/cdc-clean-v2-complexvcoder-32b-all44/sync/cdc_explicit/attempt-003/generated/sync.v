module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal synchronization chain
    logic [STAGES-1:0] sync_chain;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            // Initialize the sync_chain to ResetValue
            sync_chain <= {STAGES{ResetValue}};
        end else begin
            // Shift the async input through the synchronization chain
            sync_chain <= {sync_chain[STAGES-2:0], serial_i};
        end
    end

    // Assign the last stage of the sync_chain to the output
    assign serial_o = sync_chain[STAGES-1];

endmodule
