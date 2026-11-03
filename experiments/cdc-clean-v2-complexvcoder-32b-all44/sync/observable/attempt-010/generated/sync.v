module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    logic [STAGES-1:0] sync_chain;

    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : gen_dff
            if (i == 0) begin
                dff dff_inst_0 (
                    .clk(clk_i),
                    .rst_n(rst_ni),
                    .d(serial_i),
                    .q(sync_chain[0])
                );
            end else begin
                dff dff_inst (
                    .clk(clk_i),
                    .rst_n(rst_ni),
                    .d(sync_chain[i-1]),
                    .q(sync_chain[i])
                );
            end
        end
    endgenerate

    assign serial_o = sync_chain[STAGES-1];

endmodule

module dff (
    input  logic clk,
    input  logic rst_n,
    input  logic d,
    output logic q
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= ResetValue;
        end else begin
            q <= d;
        end
    end

endmodule
