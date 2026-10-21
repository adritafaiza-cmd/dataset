module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    logic [STAGES-1:0] sync_pipe;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_pipe <= {STAGES{ResetValue}};
        else
            sync_pipe <= {sync_pipe[STAGES-2:0], serial_i};
    end

    assign serial_o = sync_pipe[STAGES-1];

endmodule<|im_end|>
