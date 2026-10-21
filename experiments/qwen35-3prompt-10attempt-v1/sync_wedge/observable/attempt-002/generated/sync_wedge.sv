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

    // Synchronizer chain for the data bit
    logic [STAGES-1:0] sync_data;
    
    // Synchronizer chain for the enable signal (to gate the edge detection logic)
    logic [STAGES-1:0] sync_en;

    // Synchronizer chain for the reset signal (though rst_ni is usually global, 
    // ensuring it is stable in the domain is good practice if used locally, 
    // but here we assume rst_ni is already stable or handled by top-level.
    // We will use rst_ni directly for the flip-flops as per standard async reset behavior).

    // Stage 1
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_data[0] <= 1'b0;
        else
            sync_data[0] <= serial_i;
    end

    // Stage 2
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_data[1] <= 1'b0;
        else
            sync_data[1] <= sync_data[0];
    end

    // Stage 1 for Enable
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_en[0] <= 1'b0;
        else
            sync_en[0] <= en_i;
    end

    // Stage 2 for Enable
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_en[1] <= 1'b0;
        else
            sync_en[1] <= sync_en[0];
    end

    // Edge Detection Logic
    // We use the fully synchronized data (sync_data[1]) to detect edges.
    // We use the fully synchronized enable (sync_en[1]) to gate the output.
    // r_edge_o: Rising edge (0 -> 1)
    // f_edge_o: Falling edge (1 -> 0)
    
    // Note: To prevent glitches, we typically sample the previous state.
    // Since we are in the same clock domain as sync_data[1], we can use a register
    // to hold the previous value of sync_data[1].
    
    logic prev_sync_data;
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            prev_sync_data <= 1'b0;
            r_edge_o       <= 1'b0;
            f_edge_o       <= 1'b0;
            serial_o       <= 1'b0;
        end
        else begin
            prev_sync_data <= sync_data[1];
            
            if (sync_en[1]) begin
                if (sync_data[1] && !prev_sync_data) begin
                    // Rising Edge
                    r_edge_o <= 1'b1;
                    f_edge_o <= 1'b0;
                end
                else if (!sync_data[1] && prev_sync_data) begin
                    // Falling Edge
                    r_edge_o <= 1'b0;
                    f_edge_o <= 1'b1;
                end
                else begin
                    // No Edge
                    r_edge_o <= 1'b0;
                    f_edge_o <= 1'b0;
                end
            end
            else begin
                // Disabled
                r_edge_o <= 1'b0;
                f_edge_o <= 1'b0;
            end
        end
    end

    // Output the synchronized bit
    assign serial_o = sync_data[1];

endmodule
```<|im_end|>
