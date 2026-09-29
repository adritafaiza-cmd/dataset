module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    logic [STAGES-1:0] sync_chain;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= {STAGES{ResetValue}};
        end else begin
            sync_chain <= {sync_chain[STAGES-2:0], serial_i};
        end
    end

    assign serial_o = sync_chain[STAGES-1];

endmodule
