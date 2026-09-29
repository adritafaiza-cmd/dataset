module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    reg [STAGES-1:0] sync_chain;

    always @(posedge clk_i) begin
        if (!rst_ni) begin
            sync_chain <= {STAGES{ResetValue}};
        end else begin
            sync_chain[0] <= serial_i;
            for (int i = 1; i < STAGES; i++) begin
                sync_chain[i] <= sync_chain[i-1];
            end
        end
    end

    assign serial_o = sync_chain[STAGES-1];

endmodule
