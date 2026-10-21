```verilog
`timescale 1ns/1ps

module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  wire        clk,
    input  wire        async_rst_i,
    output reg         sync_rst_o
);

    localparam DEASSERT_DEPTH = 1 << CHAINS;

    // Internal state to track the number of consecutive clock cycles
    // since the reset was deasserted on the async domain.
    reg [CHAINS-1:0] deassert_count;

    // Logic to detect the transition of async_rst_i
    // We need to know when the reset goes from asserted to deasserted.
    // If RST_POL is 1 (active high), reset is asserted when async_rst_i is 1.
    // If RST_POL is 0 (active low), reset is asserted when async_rst_i is 0.
    
    // Determine the current assertion state of the async reset
    wire async_rst_asserted = (RST_POL) ? async_rst_i : (~async_rst_i);
    
    // Detect the edge where reset transitions from asserted to deasserted
    wire rst_deasserted_edge = (async_rst_asserted) & (~async_rst_asserted);
    // Wait, the above logic is inverted. Let's re-evaluate.
    // We want to detect: Old State = Asserted, New State = Deasserted.
    
    reg [CHAINS-1:0] prev_async_rst_asserted;
    reg rst_deasserted_edge;

    always @(posedge clk) begin
        prev_async_rst_asserted <= async_rst_asserted;
        
        // Detect transition: Was Asserted, Now Deasserted
        rst_deasserted_edge = (prev_async_rst_asserted) & (~async_rst_asserted);
    end

    // Synchronizer chain for the deassertion edge
    // We count up to DEASSERT_DEPTH to ensure the signal is stable in the new domain
    // before releasing the reset.
    
    reg [CHAINS-1:0] sync_count;

    always @(posedge clk) begin
        if (rst_deasserted_edge) begin
            // Reset the counter when we see the deassertion edge
            sync_count <= 0;
        end else if (sync_count < DEASSERT_DEPTH - 1) begin
            // Increment counter until it reaches the depth
            sync_count <= sync_count + 1;
        end
        // If sync_count reaches DEASSERT_DEPTH - 1, it stays there until reset is re-asserted
        // or we decide to release.
    end

    // Generate the output reset signal
    // The reset should be asserted while:
    // 1. The async reset is currently asserted.
    // 2. OR, the deassertion edge has been detected but the synchronizer chain hasn't completed.
    
    // Note: The requirement is "reset assert promptly but release cleanly".
    // "Assert promptly": If async_rst is high (assuming active high), sync_rst must be high immediately.
    // "Release cleanly": If async_rst goes low, we wait for CHAINS cycles before going low.
    
    // Logic:
    // If async_rst is asserted -> sync_rst is asserted.
    // If async_rst is deasserted -> sync_rst is asserted ONLY if the synchronizer chain is not done.
    
    always @(posedge clk) begin
        if (async_rst_asserted) begin
            // Reset is currently active, force output high
            sync_rst_o <= 1'b1;
        end else begin
            // Reset is currently inactive.
            // Check if we have synchronized the deassertion event.
            // If sync_count has reached the full depth, we can release the reset.
            // Otherwise, keep it asserted to prevent glitches.
            if (sync_count < DEASSERT_DEPTH - 1) begin
                sync_rst_o <= 1'b1;
            end else begin
                sync_rst_o <= 1'b0;
            end
        end
    end

endmodule
```<|im_end|>
