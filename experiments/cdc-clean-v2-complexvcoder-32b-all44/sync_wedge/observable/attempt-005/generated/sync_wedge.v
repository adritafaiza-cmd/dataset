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

    reg [STAGES-1:0] synced_serial;
    reg prev_serial;
    reg r_edge;
    reg f_edge;

    // Synchronize the input signal into the clk_i domain using a multi-stage synchronizer chain
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            synced_serial <= {STAGES{1'b0}};
        end else begin
            synced_serial <= {synced_serial[STAGES-2:0], serial_i};
        end
    end

    // Detect rising and falling edges of the synchronized signal
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            prev_serial <= 1'b0;
            r_edge <= 1'b0;
            f_edge <= 1'b0;
        end else begin
            prev_serial <= synced_serial[STAGES-1];
            r_edge <= en_i && (!prev_serial && synced_serial[STAGES-1]);
            f_edge <= en_i && (prev_serial && !synced_serial[STAGES-1]);
        end
    end

    // Assign outputs
    assign serial_o = synced_serial[STAGES-1];
    assign r_edge_o = r_edge;
    assign f_edge_o = f_edge;

endmodule
