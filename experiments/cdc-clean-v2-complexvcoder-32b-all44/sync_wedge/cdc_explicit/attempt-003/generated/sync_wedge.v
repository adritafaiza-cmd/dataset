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
    reg              synced_serial;
    reg              synced_serial_d;

    // Synchronize the asynchronous signal to the clk_i domain
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= {STAGES{1'b0}};
        end else begin
            sync_chain <= {sync_chain[STAGES-2:0], serial_i};
        end
    end

    // Output the synchronized signal
    assign synced_serial = sync_chain[STAGES-1];

    // Detect rising and falling edges
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            synced_serial_d <= 1'b0;
        end else begin
            synced_serial_d <= synced_serial;
        end
    end

    // Generate edge outputs
    assign serial_o = synced_serial;
    assign r_edge_o = en_i & synced_serial & ~synced_serial_d;
    assign f_edge_o = en_i & ~synced_serial & synced_serial_d;

endmodule
