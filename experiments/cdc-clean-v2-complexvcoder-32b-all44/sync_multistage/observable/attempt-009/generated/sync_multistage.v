module sync_multistage #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    logic [STAGES-2:0] sync_ff;

    genvar i;
    generate
        if (STAGES > 0) begin : gen_sync_stages
            ff_stage #(.ResetValue(ResetValue)) ff_stage_0 (
                .clk_i  (clk_i),
                .rst_ni (rst_ni),
                .d      (serial_i),
                .q      (sync_ff[0])
            );

            for (i = 1; i < STAGES-1; i = i + 1) begin : gen_sync_stage
                ff_stage #(.ResetValue(ResetValue)) ff_stage_i (
                    .clk_i  (clk_i),
                    .rst_ni (rst_ni),
                    .d      (sync_ff[i-1]),
                    .q      (sync_ff[i])
                );
            end

            if (STAGES > 1) begin : gen_final_stage
                ff_stage #(.ResetValue(ResetValue)) ff_stage_last (
                    .clk_i  (clk_i),
                    .rst_ni (rst_ni),
                    .d      (sync_ff[STAGES-2]),
                    .q      (serial_o)
                );
            end else begin : gen_single_stage
                assign serial_o = sync_ff[0];
            end
        end else begin : gen_no_stages
            assign serial_o = serial_i;
        end
    endgenerate

endmodule

module ff_stage #(
    parameter bit ResetValue = 1'b0
) (
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
