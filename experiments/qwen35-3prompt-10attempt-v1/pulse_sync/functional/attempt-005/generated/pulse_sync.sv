module pulse_sync #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  pulseA_i,
    output pulseB_o,
    output busy_o
);

    localparam WIDTH = STAGES;
    reg [WIDTH-1:0] shift_reg;
    reg busy;

    // Capture pulse from domain A using a FIFO-like shift register
    // The register acts as a single-stage buffer where a '1' indicates a pulse is in flight
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            shift_reg <= 0;
            busy <= 0;
        end else begin
            // Shift left and insert new bit at LSB
            shift_reg <= {shift_reg[WIDTH-2:0], pulseA_i};
            // If any bit in the register is high, we are busy
            busy <= shift_reg | 1'b0;
        end
    end

    // Read the oldest bit (MSB) into domain B
    // If MSB is 1, it means a pulse was captured in domain A and is now being output
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o <= 0;
            busy_o <= 0;
        end else begin
            // Output the MSB of the shift register
            pulseB_o <= shift_reg[WIDTH-1];
            busy_o <= busy;
        end
    end

endmodule<|im_end|>
