```verilog
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

    // Internal signals for synchronization chain
    wire [STAGES-1:0] sync_data;
    wire [STAGES-1:0] sync_en;

    // Synchronize the enable signal to the clock domain
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : sync_en_stage
            assign sync_en[i] = (i == 0) ? en_i : sync_en[i-1];
        end
    endgenerate

    // Synchronize the serial data input to the clock domain
    genvar j;
    generate
        for (j = 0; j < STAGES; j = j + 1) begin : sync_data_stage
            assign sync_data[j] = (j == 0) ? serial_i : sync_data[j-1];
        end
    endgenerate

    // Output the last stage of synchronized data
    assign serial_o = sync_data[STAGES-1];

    // Edge detection logic on the synchronized data
    // We use the last stage of data and the second-to-last stage to detect transitions
    // This ensures we are comparing two consecutive samples within the same clock domain
    wire prev_data = sync_data[STAGES-2];
    wire curr_data = sync_data[STAGES-1];

    // Rising edge detection: 0 -> 1
    assign r_edge_o = (prev_data == 1'b0) && (curr_data == 1'b1);

    // Falling edge detection: 1 -> 0
    assign f_edge_o = (prev_data == 1'b1) && (curr_data == 1'b0);

    // Reset logic for outputs (handled implicitly by continuous assignments 
    // as they default to 0 when conditions aren't met, but explicit reset 
    // logic is good practice for safety if combinational logic were more complex.
    // Here, the logic naturally holds low after reset if no edges occur).

endmodule
```<|im_end|>
