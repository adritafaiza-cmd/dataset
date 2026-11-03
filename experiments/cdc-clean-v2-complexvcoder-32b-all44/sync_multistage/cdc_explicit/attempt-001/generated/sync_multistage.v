module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    logic [STAGES-1:0] sync_stages;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stages <= {STAGES{ResetValue}};
        end else begin
            sync_stages[0] <= serial_i;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_stages[i] <= sync_stages[i-1];
            end
        end
    end

    assign serial_o = sync_stages[STAGES-1];

endmodule
