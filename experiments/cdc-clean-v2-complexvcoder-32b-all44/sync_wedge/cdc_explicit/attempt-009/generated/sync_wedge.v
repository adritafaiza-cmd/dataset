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
    reg [STAGES-1:0] sync_chain;
    reg              synced_serial;
    reg              synced_serial_d;

    // Instantiate the sync_chain module
    sync_chain #(
        .STAGES(STAGES)
    ) sync_chain_inst (
        .clk_i     (clk_i),
        .rst_ni    (rst_ni),
        .async_in  (serial_i),
        .synced_out(synced_serial)
    );

    // Register the synced_serial to detect edges
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            synced_serial_d <= 1'b0;
        end else begin
            synced_serial_d <= synced_serial;
        end
    end

    // Assign the outputs
    assign serial_o = synced_serial;
    assign r_edge_o = en_i & (synced_serial & ~synced_serial_d);
    assign f_edge_o = en_i & (~synced_serial & synced_serial_d);

endmodule

module sync_chain #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_in,
    output synced_out
);

    // Internal signals
    reg [STAGES-1:0] sync_chain;

    // Synchronize the async_in into the clk_i domain
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= {STAGES{1'b0}};
        end else begin
            sync_chain <= {sync_chain[STAGES-2:0], async_in};
        end
    end

    // Output the most synchronized stage
    assign synced_out = sync_chain[STAGES-1];

endmodule
