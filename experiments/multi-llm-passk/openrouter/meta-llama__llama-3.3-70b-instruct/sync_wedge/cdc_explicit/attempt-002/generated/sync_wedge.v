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
reg prev_sync;
reg serial_sync;

always @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
        sync_reg <= {STAGES{1'b0}};
        prev_sync <= 1'b0;
        serial_sync <= 1'b0;
        r_edge_o <= 1'b0;
        f_edge_o <= 1'b0;
        serial_o <= 1'b0;
    end else begin
        sync_reg[0] <= serial_i;
        for (int i = 1; i < STAGES; i++) begin
            sync_reg[i] <= sync_reg[i-1];
        end
        prev_sync <= sync_reg[STAGES-1];
        serial_sync <= sync_reg[STAGES-1];
        if (en_i) begin
            if (serial_sync && !prev_sync) begin
                r_edge_o <= 1'b1;
            end else begin
                r_edge_o <= 1'b0;
            end
            if (!serial_sync && prev_sync) begin
                f_edge_o <= 1'b1;
            end else begin
                f_edge_o <= 1'b0;
            end
        end else begin
            r_edge_o <= 1'b0;
            f_edge_o <= 1'b0;
        end
        serial_o <= serial_sync;
    end
end

endmodule
