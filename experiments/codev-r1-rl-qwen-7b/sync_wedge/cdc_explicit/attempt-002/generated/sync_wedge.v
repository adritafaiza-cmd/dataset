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

    // Synchronizer chain
    reg [STAGES-1:0] sync_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {STAGES{1'b0}};
        end else begin
            sync_reg <= {sync_reg[STAGES-2:0], serial_i};
        end
    end

    assign serial_o = sync_reg[STAGES-1];

    // Edge detection
    reg prev_serial;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            prev_serial <= 1'b0;
        end else begin
            prev_serial <= serial_o;
        end
    end

    assign r_edge_o = (serial_o && !prev_serial) && en_i;
    assign f_edge_o = (!serial_o && prev_serial) && en_i;

endmodule
