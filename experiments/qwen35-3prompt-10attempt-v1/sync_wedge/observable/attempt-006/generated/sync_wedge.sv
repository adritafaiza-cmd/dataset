```verilog
`timescale 1ns / 1ps

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

    // Synchronous registers for the multi-stage synchronizer
    // We use STAGES flip-flops to cross the clock domain safely
    logic [STAGES-1:0] sync_reg;
    
    // Output registers for the synchronized data and edge flags
    logic serial_sync;
    logic r_edge_sync;
    logic f_edge_sync;

    // Synchronize the input serial bit
    // First stage captures the input on the local clock
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_reg <= {STAGES{1'b0}};
        else
            sync_reg <= {sync_reg[STAGES-2:0], serial_i};
    end

    // Extract the most significant bit (last stage) as the synchronized data
    assign serial_sync = sync_reg[STAGES-1];

    // Edge detection logic
    // Rising edge: current bit is 1, previous bit was 0
    // Falling edge: current bit is 0, previous bit was 1
    // We compare the current stage (sync_reg[STAGES-1]) with the previous stage (sync_reg[STAGES-2])
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_sync <= 1'b0;
            f_edge_sync <= 1'b0;
        end
        else begin
            // Only update edge flags if enabled
            if (en_i) begin
                if (sync_reg[STAGES-1] && !sync_reg[STAGES-2])
                    r_edge_sync <= 1'b1;
                else if (!sync_reg[STAGES-1] && sync_reg[STAGES-2])
                    f_edge_sync <= 1'b1;
                else
                    r_edge_sync <= 1'b0;
                    f_edge_sync <= 1'b0;
            end
            else begin
                // Disable edge detection when en_i is low
                r_edge_sync <= 1'b0;
                f_edge_sync <= 1'b0;
            end
        end
    end

    // Drive outputs
    assign r_edge_o = r_edge_sync;
    assign f_edge_o = f_edge_sync;
    assign serial_o = serial_sync;

endmodule
```<|im_end|>
