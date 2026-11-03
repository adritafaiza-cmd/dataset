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
    reg synced_o;
    reg synced_d1;
    reg synced_d2;
    reg r_edge_d1;
    reg f_edge_d1;

    // Instantiate the sync_cell module
    sync_cell sync_cell_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .serial_i(serial_i),
        .synced_o(synced_o)
    );

    // Sequential logic for edge detection and synchronization
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            synced_d1 <= 0;
            synced_d2 <= 0;
            r_edge_d1 <= 0;
            f_edge_d1 <= 0;
        end else if (en_i) begin
            synced_d1 <= synced_o;
            synced_d2 <= synced_d1;

            // Detect rising edge
            r_edge_d1 <= (~synced_d1 & synced_d2);

            // Detect falling edge
            f_edge_d1 <= (synced_d1 & ~synced_d2);
        end
    end

    // Assign outputs
    assign r_edge_o = r_edge_d1;
    assign f_edge_o = f_edge_d1;
    assign serial_o = synced_o;

endmodule

module sync_cell (
    input  clk_i,
    input  rst_ni,
    input  serial_i,
    output synced_o
);

    // Internal signals
    reg sync_reg1;
    reg sync_reg2;

    // Sequential logic for synchronization
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg1 <= 0;
            sync_reg2 <= 0;
        end else begin
            sync_reg1 <= serial_i;
            sync_reg2 <= sync_reg1;
        end
    end

    // Assign output
    assign synced_o = sync_reg2;

endmodule
