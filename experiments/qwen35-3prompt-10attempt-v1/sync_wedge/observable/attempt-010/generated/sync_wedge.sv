```verilog
`timescale 1ns/1ps

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

    // Synchronizer chain for the data bit
    logic [STAGES-1:0] sync_data;
    
    // Synchronizer chain for the enable signal (optional but good practice)
    logic [STAGES-1:0] sync_en;

    // Edge detection flags
    logic r_edge_temp;
    logic f_edge_temp;

    // --- Synchronizer Logic ---
    
    // Data Synchronizer
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : data_sync_stage
            if (i == 0)
                assign sync_data[i] = serial_i;
            else
                assign sync_data[i] = sync_data[i-1];
        end
    endgenerate

    // Enable Synchronizer
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : en_sync_stage
            if (i == 0)
                assign sync_en[i] = en_i;
            else
                assign sync_en[i] = sync_en[i-1];
        end
    endgenerate

    // --- Edge Detection Logic ---
    
    // We perform edge detection on the last stage of the synchronizer
    // to ensure we are operating in the same clock domain as the output.
    
    // Rising Edge: Current is 1, Previous was 0
    assign r_edge_temp = sync_data[STAGES-1] & ~sync_data[STAGES-2];
    
    // Falling Edge: Current is 0, Previous was 1
    assign f_edge_temp = ~sync_data[STAGES-1] & sync_data[STAGES-2];

    // Output edge flags (masked by local enable)
    assign r_edge_o = sync_en[STAGES-1] ? r_edge_temp : 1'b0;
    assign f_edge_o = sync_en[STAGES-1] ? f_edge_temp : 1'b0;

    // Output the synchronized data
    assign serial_o = sync_data[STAGES-1];

endmodule
```<|im_end|>
