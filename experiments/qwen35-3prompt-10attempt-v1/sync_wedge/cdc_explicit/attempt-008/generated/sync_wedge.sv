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

    // Synchronize the asynchronous serial input to the clock domain
    wire sync_serial;
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : sync_stage
            wire sync_tmp;
            always @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni)
                    sync_tmp <= 1'b0;
                else
                    sync_tmp <= serial_i;
            end
            assign sync_serial = (i == STAGES - 1) ? sync_tmp : sync_tmp;
        end
    endgenerate

    // Internal synchronized signal for edge detection logic
    wire sync_serial_next;
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_serial_next <= 1'b0;
        else
            sync_serial_next <= sync_serial;
    end

    // Edge Detection Logic
    // Rising edge: current is 1, previous was 0
    wire rising_edge = (sync_serial_next) & (~sync_serial);
    // Falling edge: current is 0, previous was 1
    wire falling_edge = (~sync_serial_next) & (sync_serial);

    // Generate single-cycle pulses for edges
    // Using a 2-stage pipeline to ensure the pulse is clean and synchronized
    wire r_edge_pulse;
    wire f_edge_pulse;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_pulse <= 1'b0;
            f_edge_pulse <= 1'b0;
        end else begin
            // Capture the edge status at the current cycle
            r_edge_pulse <= rising_edge;
            f_edge_pulse <= falling_edge;
        end
    end

    // Final output assignment
    // The pulse is already one cycle wide due to the register delay above
    assign r_edge_o = r_edge_pulse;
    assign f_edge_o = f_edge_pulse;
    assign serial_o = sync_serial;

endmodule<|im_end|>
