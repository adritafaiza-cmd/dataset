module sync_wedge #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  en_i,
    input  serial_i,
    output r_edge_o,
    output f_edge_o,
    output serial_o
);

    reg [STAGES-1:0] sync_reg;
    reg              serial_d1;
    reg              serial_d2;
    reg              rising_edge;
    reg              falling_edge;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {STAGES{1'b0}};
            serial_d1 <= 1'b0;
            serial_d2 <= 1'b0;
            rising_edge <= 1'b0;
            falling_edge <= 1'b0;
        end else begin
            // Multi-stage synchronizer
            sync_reg[0] <= serial_i;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end

            // Edge detection
            serial_d1 <= sync_reg[STAGES-1];
            serial_d2 <= serial_d1;
            rising_edge <= en_i & ~serial_d2 & serial_d1;
            falling_edge <= en_i & serial_d2 & ~serial_d1;
        end
    end

    assign serial_o = sync_reg[STAGES-1];
    assign r_edge_o = rising_edge;
    assign f_edge_o = falling_edge;

endmodule
