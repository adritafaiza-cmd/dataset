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

    // Ensure at least 2 stages for safe CDC
    localparam SYNC_STAGES = (STAGES < 2) ? 2 : STAGES;

    // Synchronizer chain
    reg [SYNC_STAGES-1:0] sync_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_reg <= {SYNC_STAGES{1'b0}};
        else
            sync_reg <= {sync_reg[SYNC_STAGES-2:0], serial_i};
    end

    // Synchronized output
    assign serial_o = sync_reg[SYNC_STAGES-1];

    // Edge detection
    reg serial_d;
    reg r_edge;
    reg f_edge;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            serial_d <= 1'b0;
            r_edge   <= 1'b0;
            f_edge   <= 1'b0;
        end
        else begin
            serial_d <= serial_o;
            r_edge   <= serial_o & ~serial_d;
            f_edge   <= ~serial_o & serial_d;
        end
    end

    // Gated outputs
    assign r_edge_o = r_edge & en_i;
    assign f_edge_o = f_edge & en_i;

endmodule
