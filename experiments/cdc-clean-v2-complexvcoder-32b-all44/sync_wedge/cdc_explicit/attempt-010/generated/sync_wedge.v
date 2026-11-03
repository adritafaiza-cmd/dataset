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

    // Internal signals
    reg sync_chain_out;
    reg sync_chain_out_reg;
    reg sync_chain_out_reg2;
    reg d_edge;
    reg q_edge;
    reg rising_edge;
    reg falling_edge;
    reg r_edge;
    reg f_edge;
    reg enable;

    // Instantiate the sync_chain module
    sync_chain #(
        .STAGES(STAGES)
    ) sync_chain_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .async_i(serial_i),
        .sync_o(sync_chain_out)
    );

    // Assignments
    assign serial_o = sync_chain_out;
    assign r_edge_o = r_edge;
    assign f_edge_o = f_edge;

    // Synchronize and detect edges
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain_out_reg <= 1'b0;
            sync_chain_out_reg2 <= 1'b0;
            d_edge <= 1'b0;
            q_edge <= 1'b0;
            rising_edge <= 1'b0;
            falling_edge <= 1'b0;
            r_edge <= 1'b0;
            f_edge <= 1'b0;
            enable <= 1'b0;
        end else begin
            sync_chain_out_reg <= sync_chain_out;
            sync_chain_out_reg2 <= sync_chain_out_reg;
            d_edge <= sync_chain_out_reg;
            q_edge <= sync_chain_out_reg2;
            rising_edge <= ~q_edge & d_edge;
            falling_edge <= q_edge & ~d_edge;
            r_edge <= enable & rising_edge;
            f_edge <= enable & falling_edge;
            enable <= en_i;
        end
    end

endmodule

module sync_chain #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_i,
    output sync_o
);

    // Internal signal array for the sync chain
    reg [STAGES-1:0] sync_chain;

    // Synchronize the asynchronous input to the destination clock domain
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= {STAGES{1'b0}};
        end else begin
            sync_chain[0] <= async_i;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_chain[i] <= sync_chain[i-1];
            end
        end
    end

    // Output the last stage of the sync chain
    assign sync_o = sync_chain[STAGES-1];

endmodule
