module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    reg [STAGES-1:0] sync_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {STAGES{ResetValue}};
        end else begin
            sync_reg <= {sync_reg[STAGES-2:0], serial_i};
        end
    end

    assign serial_o = sync_reg[STAGES-1];

endmodule
