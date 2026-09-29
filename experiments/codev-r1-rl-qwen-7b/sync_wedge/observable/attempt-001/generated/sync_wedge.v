module sync_wedge #(
    parameter STAGES = 2
) (
    input  clk_i,
    input  rst_ni,
    input  en_i,
    input  serial_i,
    output r_edge_o,
    output f_edge_o,
    output serial_o
);

    reg [STAGES-1:0] sync_reg;
    reg prev_serial;

    generate
        genvar i;
        for (i = 0; i < STAGES; i = i + 1) begin : sync_stages
            if (i == 0) begin
                // First stage
                always @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        sync_reg[i] <= 1'b0;
                    else
                        sync_reg[i] <= serial_i;
                end
            end else begin
                // Subsequent stages
                always @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        sync_reg[i] <= 1'b0;
                    else
                        sync_reg[i] <= sync_reg[i-1];
                end
            end
        end
    endgenerate

    // Previous value for edge detection
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            prev_serial <= 1'b0;
        else
            prev_serial <= serial_o;
    end

    assign serial_o = sync_reg[STAGES-1];
    assign r_edge_o = en_i && (serial_o && !prev_serial);
    assign f_edge_o = en_i && (!serial_o && prev_serial);

endmodule
