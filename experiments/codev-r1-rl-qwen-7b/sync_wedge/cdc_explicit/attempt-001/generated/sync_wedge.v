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
    reg serial_synced_prev;

    wire serial_synced = sync_reg[STAGES-1];

    // Synchronizer chain
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {STAGES{1'b0}};
        end else begin
            sync_reg <= {sync_reg[STAGES-2:0], serial_i};
        end
    end

    // Previous value for edge detection
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            serial_synced_prev <= 1'b0;
        end else begin
            serial_synced_prev <= serial_synced;
        end
    end

    // Edge detection
    assign r_edge_o = en_i & (serial_synced & ~serial_synced_prev);
    assign f_edge_o = en_i & (~serial_synced & serial_synced_prev);

    // Output the synchronized bit
    assign serial_o = serial_synced;

endmodule
