module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    logic [STAGES-1:0] serial_sync;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            serial_sync <= {STAGES{ResetValue}};
        end else begin
            serial_sync[0] <= serial_i;
            for (int i = 1; i < STAGES; i++) begin
                serial_sync[i] <= serial_sync[i-1];
            end
        end
    end

    assign serial_o = serial_sync[STAGES-1];

endmodule
