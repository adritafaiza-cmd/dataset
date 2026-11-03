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
    reg synced_serial;
    reg d_ff1;
    reg d_ff2;
    reg d_ff3;

    // Instantiate the sync_cell module
    sync_cell sync_cell_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .data_i(serial_i),
        .data_o(synced_serial)
    );

    // Edge detection logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            d_ff1 <= 0;
            d_ff2 <= 0;
            d_ff3 <= 0;
        end else begin
            d_ff1 <= synced_serial;
            d_ff2 <= d_ff1;
            d_ff3 <= d_ff2;
        end
    end

    // Assign outputs
    assign serial_o = d_ff2;
    assign r_edge_o = en_i & d_ff2 & ~d_ff3;
    assign f_edge_o = en_i & ~d_ff2 & d_ff3;

endmodule

module sync_cell (
    input  clk_i,
    input  rst_ni,
    input  data_i,
    output data_o
);

    // Internal flip-flops
    reg d_ff1;
    reg d_ff2;

    // Synchronization logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            d_ff1 <= 0;
            d_ff2 <= 0;
        end else begin
            d_ff1 <= data_i;
            d_ff2 <= d_ff1;
        end
    end

    // Output the synchronized signal
    assign data_o = d_ff2;

endmodule
