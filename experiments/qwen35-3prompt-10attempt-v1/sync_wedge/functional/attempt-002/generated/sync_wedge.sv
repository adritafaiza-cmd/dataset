module sync_wedge #(
    parameter STAGES = 2
)(
    input  wire clk_i,
    input  wire rst_ni,
    input  wire en_i,
    input  wire serial_i,
    output wire r_edge_o,
    output wire f_edge_o,
    output wire serial_o
);

    // Synchronized data output
    wire [STAGES-1:0] sync_data;

    // Generate synchronization chain
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : sync_chain
            if (i == 0) begin : first_stage
                always @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        sync_data[i] <= 1'b0;
                    else
                        sync_data[i] <= serial_i;
                end
            end else begin : subsequent_stages
                always @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        sync_data[i] <= 1'b0;
                    else
                        sync_data[i] <= sync_data[i-1];
                end
            end
        end
    endgenerate

    // Edge detection logic on the final synchronized stage
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_o <= 1'b0;
            f_edge_o <= 1'b0;
        end else begin
            // Rising edge detection
            if (sync_data[STAGES-1] && !sync_data[STAGES-2])
                r_edge_o <= 1'b1;
            else
                r_edge_o <= 1'b0;

            // Falling edge detection
            if (!sync_data[STAGES-1] && sync_data[STAGES-2])
                f_edge_o <= 1'b1;
            else
                f_edge_o <= 1'b0;
        end
    end

    // Assign synchronized output directly from the last stage
    assign serial_o = sync_data[STAGES-1];

endmodule<|im_end|>
