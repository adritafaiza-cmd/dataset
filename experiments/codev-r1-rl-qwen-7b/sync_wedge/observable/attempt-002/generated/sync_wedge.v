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
    reg prev_serial;

    // Synchronizer chain
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= '0;
        end else begin
            sync_reg <= {sync_reg[STAGES-2:0], serial_i};
        end
    end

    // Previous value for edge detection
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            prev_serial <= 1'b0;
        end else begin
            prev_serial <= sync_reg[STAGES-1];
        end
    end

    assign serial_o = sync_reg[STAGES-1];
    assign r_edge_o = (sync_reg[STAGES-1] && !prev_serial) && en_i;
    assign f_edge_o = (!sync_reg[STAGES-1] && prev_serial) && en_i;

endmodule
