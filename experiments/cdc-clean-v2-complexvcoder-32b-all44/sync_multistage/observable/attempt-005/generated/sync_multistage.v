module sync_multistage #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal signals for synchronization stages
    logic [STAGES-1:0] sync_stages;

    // Instantiate the first sync stage
    sync_stage #(.ResetValue(ResetValue)) stage_0 (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .in     (serial_i),
        .out    (sync_stages[0])
    );

    // Instantiate the remaining sync stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_sync_stages
            sync_stage #(.ResetValue(ResetValue)) stage_i (
                .clk_i  (clk_i),
                .rst_ni (rst_ni),
                .in     (sync_stages[i-1]),
                .out    (sync_stages[i])
            );
        end
    endgenerate

    // Assign the output of the last stage to the module output
    assign serial_o = sync_stages[STAGES-1];

endmodule

module sync_stage #(
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic in,
    output logic out
);

    // Synchronize the input into the clk_i domain with reset
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            out <= ResetValue;
        end else begin
            out <= in;
        end
    end

endmodule
