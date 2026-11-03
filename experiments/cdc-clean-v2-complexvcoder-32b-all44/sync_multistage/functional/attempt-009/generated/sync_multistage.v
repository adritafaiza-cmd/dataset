module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal signals for pipeline stages
    logic [STAGES-1:0] stage_reg;

    // Generate synchronization stages
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : gen_sync_stages
            if (i == 0) begin : first_stage
                sync_stage sync_stage_0 (
                    .clk_i    (clk_i),
                    .rst_ni   (rst_ni),
                    .d        (serial_i),
                    .q        (stage_reg[i])
                );
            end else if (i == STAGES - 1) begin : last_stage
                sync_stage sync_stage_last (
                    .clk_i    (clk_i),
                    .rst_ni   (rst_ni),
                    .d        (stage_reg[i-1]),
                    .q        (serial_o)
                );
            end else begin : middle_stage
                sync_stage sync_stage_mid (
                    .clk_i    (clk_i),
                    .rst_ni   (rst_ni),
                    .d        (stage_reg[i-1]),
                    .q        (stage_reg[i])
                );
            end
        end
    endgenerate

endmodule

// Single stage of the synchronizer
module sync_stage (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic d,
    output logic q
);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            q <= ResetValue;
        end else begin
            q <= d;
        end
    end

endmodule
