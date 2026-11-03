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

    reg synced_serial;
    reg synced_serial_reg;
    reg r_edge;
    reg f_edge;

    // Instantiate the sync_chain module
    sync_chain #(
        .STAGES(STAGES)
    ) sync_chain_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .async_in(serial_i),
        .sync_out(synced_serial)
    );

    // Edge detection and output generation
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            synced_serial_reg <= 1'b0;
            r_edge <= 1'b0;
            f_edge <= 1'b0;
            serial_o <= 1'b0;
        end else begin
            synced_serial_reg <= synced_serial;
            r_edge <= (synced_serial && !synced_serial_reg) && en_i;
            f_edge <= (!synced_serial && synced_serial_reg) && en_i;
            serial_o <= synced_serial;
        end
    end

    // Assign outputs
    assign r_edge_o = r_edge;
    assign f_edge_o = f_edge;

endmodule

module sync_chain #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_in,
    output sync_out
);

    reg [STAGES-1:0] sync_chain;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= {STAGES{1'b0}};
        end else begin
            sync_chain[0] <= async_in;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_chain[i] <= sync_chain[i-1];
            end
        end
    end

    assign sync_out = sync_chain[STAGES-1];

endmodule
