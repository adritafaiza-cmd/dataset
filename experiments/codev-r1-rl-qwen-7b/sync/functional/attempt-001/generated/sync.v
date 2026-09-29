module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    reg [STAGES-1:0] sync_regs;

    generate
        genvar i;
        for (i = 0; i < STAGES; i = i + 1) begin : gen_sync
            if (i == 0) begin
                // First stage
                always @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni) begin
                        sync_regs[i] <= ResetValue;
                    end else begin
                        sync_regs[i] <= serial_i;
                    end
                end
            end else begin
                // Subsequent stages
                always @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni) begin
                        sync_regs[i] <= ResetValue;
                    end else begin
                        sync_regs[i] <= sync_regs[i-1];
                    end
                end
            end
        end
    endgenerate

    assign serial_o = sync_regs[STAGES-1];

endmodule
