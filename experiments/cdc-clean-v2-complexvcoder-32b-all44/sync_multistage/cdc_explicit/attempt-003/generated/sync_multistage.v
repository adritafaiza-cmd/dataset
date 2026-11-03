module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal synchronization pipeline
    logic [STAGES-1:0] sync_stage;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stage <= {STAGES{ResetValue}};
        end else begin
            sync_stage[0] <= serial_i;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_stage[i] <= sync_stage[i-1];
            end
        end
    end

    assign serial_o = sync_stage[STAGES-1];

endmodule
