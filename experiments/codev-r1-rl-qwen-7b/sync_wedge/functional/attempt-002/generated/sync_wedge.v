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
    reg prev_serial;

    // Synchronizer logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= {STAGES{1'b0}};
        end else begin
            if (STAGES == 1) begin
                sync_chain <= serial_i;
            end else begin
                sync_chain <= {sync_chain[STAGES-2:0], serial_i};
            end
        end
    end

    assign serial_o = sync_chain[STAGES-1];

    // Previous value for edge detection
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            prev_serial <= 1'b0;
        end else begin
            prev_serial <= serial_o;
        end
    end

    // Edge detection
    assign r_edge_o = en_i && (serial_o && !prev_serial);
    assign f_edge_o = en_i && (!serial_o && prev_serial);

endmodule
