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

    reg [STAGES-1:0] sync_chain;
    reg serial_o_reg;
    reg r_edge_reg;
    reg f_edge_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= {STAGES{1'b0}};
            serial_o_reg <= 1'b0;
            r_edge_reg <= 1'b0;
            f_edge_reg <= 1'b0;
        end else begin
            // Synchronize the input bit into the local clock domain
            sync_chain <= {sync_chain[STAGES-2:0], serial_i};

            // Register the synchronized output
            serial_o_reg <= sync_chain[STAGES-1];

            // Detect rising and falling edges
            if (en_i) begin
                r_edge_reg <= !serial_o_reg & sync_chain[STAGES-1];
                f_edge_reg <= serial_o_reg & !sync_chain[STAGES-1];
            end else begin
                r_edge_reg <= 1'b0;
                f_edge_reg <= 1'b0;
            end
        end
    end

    assign serial_o = serial_o_reg;
    assign r_edge_o = r_edge_reg;
    assign f_edge_o = f_edge_reg;

endmodule
