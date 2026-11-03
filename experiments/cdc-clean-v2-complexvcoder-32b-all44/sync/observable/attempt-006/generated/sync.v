module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal shift register
    logic [STAGES-1:0] sync_reg;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            // Reset all stages to ResetValue on low reset
            sync_reg <= {STAGES{ResetValue}};
        end else begin
            // Shift the value of serial_i into the first stage
            // and shift the values through sync_reg
            sync_reg <= {sync_reg[STAGES-2:0], serial_i};
        end
    end

    // Output the value of the last stage of sync_reg
    assign serial_o = sync_reg[STAGES-1];

endmodule
