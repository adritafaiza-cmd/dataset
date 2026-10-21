```verilog
`timescale 1ns/1ps

module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  wire clk,
    input  wire async_rst_i,
    output wire sync_rst_o
);

    localparam DEASSERT_DEPTH = CHAINS;
    localparam POLARITY = RST_POL;

    // Internal state to track the number of consecutive clock cycles 
    // since the asynchronous reset was deasserted.
    reg [DEASSERT_DEPTH - 1:0] deassert_count;

    // Synchronize the deassertion event (active edge of the reset signal)
    // to the destination clock domain.
    wire rst_deasserted_sync;

    // Generate the synchronized deassertion signal
    // If POLARITY is 1 (active high reset), we detect the falling edge (0->1 transition of active low, or 1->0 of active high? 
    // Wait, standard convention: 
    // If RST_POL=1, the signal is active HIGH. Deassertion is 0 -> 1.
    // If RST_POL=0, the signal is active LOW. Deassertion is 1 -> 0.
    
    // Let's define the "deassertion" condition based on polarity
    wire rst_is_active;
    assign rst_is_active = (POLARITY == 1'b1) ? async_rst_i : ~async_rst_i;

    // Detect the transition from Active to Deasserted
    wire rst_deassert_edge;
    assign rst_deassert_edge = (rst_is_active == 1'b0) && (rst_deasserted_sync == 1'b1);

    // Synchronize the deassertion edge
    reg rst_deasserted_sync;
    always @(posedge clk) begin
        if (rst_is_active) begin
            rst_deasserted_sync <= 1'b1;
        end else begin
            rst_deasserted_sync <= 1'b0;
        end
    end

    // Count the number of clock cycles since deassertion
    // We only increment the counter when the reset is NOT active.
    // If the reset becomes active again, we reset the counter.
    always @(posedge clk) begin
        if (rst_is_active) begin
            deassert_count <= 0;
        end else begin
            if (rst_deassert_edge) begin
                deassert_count <= 0;
            end else begin
                deassert_count <= deassert_count + 1;
            end
        end
    end

    // Determine the output reset signal
    // If the counter has not reached the required depth, the reset remains asserted.
    // Once the counter reaches DEASSERT_DEPTH, the reset is deasserted.
    always @(posedge clk) begin
        if (rst_is_active) begin
            sync_rst_o <= POLARITY;
        end else begin
            if (deassert_count < DEASSERT_DEPTH) begin
                sync_rst_o <= POLARITY;
            end else begin
                sync_rst_o <= ~POLARITY;
            end
        end
    end

endmodule
```<|im_end|>
