module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Ensure at least 2 stages for safe CDC
    localparam int unsigned N = (STAGES < 2) ? 2 : STAGES;

    logic [N-1:0] sync_reg;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {N{ResetValue}};
        end else begin
            sync_reg[0] <= serial_i;
            for (int i = 1; i < N; i++) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign serial_o = sync_reg[N-1];

endmodule
