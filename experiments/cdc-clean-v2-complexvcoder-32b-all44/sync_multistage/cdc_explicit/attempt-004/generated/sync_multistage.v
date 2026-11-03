module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal register array for synchronization stages
    logic [STAGES-1:0] sync_reg;

    // First stage of synchronization
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg[0] <= ResetValue;
        end else begin
            sync_reg[0] <= serial_i;
        end
    end

    // Remaining stages of synchronization
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_sync_stages
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    sync_reg[i] <= ResetValue;
                end else begin
                    sync_reg[i] <= sync_reg[i-1];
                end
            end
        end
    endgenerate

    // Assign the final synchronized output
    assign serial_o = sync_reg[STAGES-1];

endmodule
