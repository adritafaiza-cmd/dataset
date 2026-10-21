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

    // Internal signals for the synchronizer chain
    wire [STAGES-1:0] sync_data;
    wire [STAGES-1:0] sync_prev;

    // Synchronizer chain to bring serial_i into clk_i domain
    // Using a simple flip-flop chain for metastability resolution
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : sync_stage
            if (i == 0) begin : first_stage
                always @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        sync_data[i] <= 1'b0;
                    else
                        sync_data[i] <= serial_i;
                end
            end else begin : subsequent_stages
                always @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni)
                        sync_data[i] <= 1'b0;
                    else
                        sync_data[i] <= sync_data[i-1];
                end
            end
        end
    endgenerate

    // Store previous stage value for edge detection
    // We use the last stage of the synchronizer to detect edges
    // The previous value is stored in a register that also gets synchronized
    reg sync_prev_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_prev_reg <= 1'b0;
        else
            sync_prev_reg <= sync_data[STAGES-1];
    end

    // Edge detection logic
    // Rising edge: current is 1, previous was 0
    // Falling edge: current is 0, previous was 1
    assign r_edge_o = (sync_data[STAGES-1] && !sync_prev_reg) && en_i;
    assign f_edge_o = (!sync_data[STAGES-1] && sync_prev_reg) && en_i;

    // Output the synchronized bit
    assign serial_o = sync_data[STAGES-1];

endmodule
```<|im_end|>
