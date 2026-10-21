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
    localparam MASK = 1 << WIDTH;

    reg [WIDTH-1:0] shift_reg_a;
    reg [WIDTH-1:0] shift_reg_b;
    reg busy_reg;

    // Domain A: Capture pulseA_i and shift through FIFO
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            shift_reg_a <= 0;
            busy_reg    <= 0;
        end else begin
            // Shift register left, insert new bit at LSB
            shift_reg_a <= {shift_reg_a[WIDTH-2:0], pulseA_i};
            
            // Check if a pulse was detected at the MSB (entry point)
            if (shift_reg_a[WIDTH-1] && !shift_reg_a[WIDTH-2]) begin
                busy_reg <= 1;
            end
        end
    end

    // Domain B: Shift through FIFO and capture output
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            shift_reg_b <= 0;
            busy_reg    <= 0;
            pulseB_o    <= 0;
        end else begin
            // Shift register left, insert new bit at LSB
            shift_reg_b <= {shift_reg_b[WIDTH-2:0], shift_reg_a[WIDTH-1]};
            
            // Output is the MSB of the B-side register
            pulseB_o    <= shift_reg_b[WIDTH-1];
            
            // Update busy signal based on whether the last stage is emptying
            // If the MSB of B is 1 and the bit entering B (from A) is 0, the pulse has passed
            if (shift_reg_b[WIDTH-1] && !shift_reg_a[WIDTH-1]) begin
                busy_reg <= 0;
            end
        end
    end

    assign busy_o = busy_reg;

endmodule<|im_end|>
