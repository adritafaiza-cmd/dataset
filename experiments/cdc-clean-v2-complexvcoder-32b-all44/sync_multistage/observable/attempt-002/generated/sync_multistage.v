module sync_multistage #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    logic [STAGES-1:0] sync_stages;

    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : gen_sync_stages
            if (i == 0) begin : first_stage
                sync_stage stage_0 (
                    .clk_i    (clk_i),
                    .rst_ni   (rst_ni),
                    .serial_i (serial_i),
                    .serial_o (sync_stages[i])
                );
            end else begin : other_stages
                sync_stage stage_x (
                    .clk_i    (clk_i),
                    .rst_ni   (rst_ni),
                    .serial_i (sync_stages[i-1]),
                    .serial_o (sync_stages[i])
                );
            end
        end
    endgenerate

    assign serial_o = sync_stages[STAGES-1];

endmodule

module sync_stage (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            serial_o <= ResetValue;
        end else begin
            serial_o <= serial_i;
        end
    end

endmodule
