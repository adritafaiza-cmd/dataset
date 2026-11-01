module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Ensure at least 2 stages for safe metastability resolution
    localparam int unsigned N_STAGES = (STAGES < 2) ? 2 : STAGES;

    logic [N_STAGES-1:0] sync_ff;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_ff <= {N_STAGES{ResetValue}};
        end else begin
            sync_ff[0] <= serial_i;
            for (int i = 1; i < N_STAGES; i++) begin
                sync_ff[i] <= sync_ff[i-1];
            end
        end
    end

    assign serial_o = sync_ff[N_STAGES-1];

endmodule
