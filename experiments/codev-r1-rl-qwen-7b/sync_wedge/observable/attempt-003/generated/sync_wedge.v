module sync_wedge #(
    parameter STAGES = 2
) (
    input  clk_i,
    input  rst_ni,
    input  en_i,
    input  serial_i,
    output r_edge_o,
    output f_edge_o,
    output serial_o
);

    reg [STAGES-1:0] sync_reg;
    reg serial_prev;

    // Synchronizer chain
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {STAGES{1'b0}};
        end else begin
            sync_reg[0] <= serial_i;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign serial_o = sync_reg[STAGES-1];

    // Edge detection
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            serial_prev <= 1'b0;
        end else begin
            serial_prev <= serial_o;
        end
    end

    assign r_edge_o = en_i & (serial_o & ~serial_prev);
    assign f_edge_o = en_i & (~serial_o & serial_prev);

endmodule
