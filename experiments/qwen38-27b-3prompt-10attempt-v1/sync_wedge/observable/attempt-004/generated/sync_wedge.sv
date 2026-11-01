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
    reg [STAGES-1:0] sync_reg_d;
    reg              serial_reg;
    reg              serial_reg_d;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {STAGES{1'b0}};
        end else begin
            sync_reg <= {sync_reg[STAGES-2:0], serial_i};
        end
    end

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            serial_reg <= 1'b0;
        end else begin
            serial_reg <= sync_reg[STAGES-1];
        end
    end

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            serial_reg_d <= 1'b0;
        end else begin
            serial_reg_d <= serial_reg;
        end
    end

    assign serial_o = serial_reg;
    assign r_edge_o = en_i & serial_reg & ~serial_reg_d;
    assign f_edge_o = en_i & ~serial_reg & serial_reg_d;

endmodule
