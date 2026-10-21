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

    // Synchronized data output
    reg serial_o;
    // Internal state for edge detection
    reg sync_data;
    reg prev_sync_data;

    // Synchronizer chain
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : sync_chain
            reg sync_reg;
            if (i == 0)
                assign sync_reg = serial_i;
            else
                assign sync_reg = sync_data;

            always @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni)
                    sync_reg <= 1'b0;
                else
                    sync_reg <= sync_data;
            end

            if (i == STAGES - 1) begin
                assign serial_o = sync_reg;
                assign sync_data = sync_reg;
            end
        end
    endgenerate

    // Edge detection logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_o <= 1'b0;
            f_edge_o <= 1'b0;
        end else begin
            // Rising edge detection
            if (en_i && (sync_data && !prev_sync_data))
                r_edge_o <= 1'b1;
            else
                r_edge_o <= 1'b0;

            // Falling edge detection
            if (en_i && (!sync_data && prev_sync_data))
                f_edge_o <= 1'b1;
            else
                f_edge_o <= 1'b0;

            // Update previous state
            prev_sync_data <= sync_data;
        end
    end

endmodule
```<|im_end|>
