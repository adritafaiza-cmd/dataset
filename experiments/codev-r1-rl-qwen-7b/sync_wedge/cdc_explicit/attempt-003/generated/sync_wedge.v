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
    reg sync_prev;

    // Synchronizer chain
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= {STAGES{1'b0}};
        end else begin
            sync_chain <= {sync_chain[STAGES-2:0], serial_i};
        end
    end

    // Previous value for edge detection
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_prev <= 1'b0;
        end else begin
            sync_prev <= sync_chain[STAGES-1];
        end
    end

    // Edge detection
    assign r_edge_o = en_i & (sync_chain[STAGES-1] & ~sync_prev);
    assign f_edge_o = en_i & (~sync_chain[STAGES-1] & sync_prev);

    // Synchronized output
    assign serial_o = sync_chain[STAGES-1];

endmodule
