module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Ensure STAGES is at least 2 for safe metastability handling
    localparam int unsigned SAFE_STAGES = (STAGES < 2) ? 2 : STAGES;

    logic [SAFE_STAGES-1:0] sync_reg;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {SAFE_STAGES{ResetValue}};
        end else begin
            sync_reg <= {sync_reg[SAFE_STAGES-2:0], serial_i};
        end
    end

    assign serial_o = sync_reg[SAFE_STAGES-1];

endmodule
