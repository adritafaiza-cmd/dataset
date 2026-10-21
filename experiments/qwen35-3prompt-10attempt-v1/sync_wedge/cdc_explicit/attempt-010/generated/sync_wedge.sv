```verilog
`timescale 1ns/1ps

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

    // Internal registers for synchronization
    reg [STAGES-1:0] sync_reg;
    reg [STAGES-1:0] sync_reg_prev;
    reg [STAGES-1:0] sync_reg_curr;

    // Edge detection logic
    reg r_edge_int;
    reg f_edge_int;

    // Synchronize the input serial signal and generate edges
    // This block handles the CDC crossing from the asynchronous serial_i domain
    // to the synchronous clk_i domain.
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= '{default: 1'b0};
            sync_reg_prev <= '{default: 1'b0};
            sync_reg_curr <= '{default: 1'b0};
            r_edge_int <= 1'b0;
            f_edge_int <= 1'b0;
            serial_o <= 1'b0;
        end else begin
            // Shift register logic
            sync_reg_curr <= sync_reg;
            sync_reg <= sync_reg[STAGES-1:1] || (en_i ? serial_i : 1'b0);
            
            // Handle edge detection based on the synchronized stream
            // We compare the current stage (sync_reg_curr) with the previous stage (sync_reg_prev)
            // to detect transitions within the synchronized domain.
            
            // Rising edge: 0 -> 1
            if (sync_reg_prev[STAGES-1] == 1'b0 && sync_reg_curr[STAGES-1] == 1'b1) begin
                r_edge_int <= 1'b1;
            end else begin
                r_edge_int <= 1'b0;
            end

            // Falling edge: 1 -> 0
            if (sync_reg_prev[STAGES-1] == 1'b1 && sync_reg_curr[STAGES-1] == 1'b0) begin
                f_edge_int <= 1'b1;
            end else begin
                f_edge_int <= 1'b0;
            end

            // Output the synchronized bit
            serial_o <= sync_reg_curr[STAGES-1];
        end
    end

    // Output registers for edge pulses
    // These ensure the edge signals are synchronized to clk_i and pulse for one cycle
    reg r_edge_reg;
    reg f_edge_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_reg <= 1'b0;
            f_edge_reg <= 1'b0;
        end else begin
            r_edge_reg <= r_edge_int;
            f_edge_reg <= f_edge_int;
        end
    end

    // Assign final outputs
    assign r_edge_o = r_edge_reg;
    assign f_edge_o = f_edge_reg;

endmodule
```<|im_end|>
