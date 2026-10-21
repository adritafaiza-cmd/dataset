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

    // Synchronize the asynchronous serial_i signal to the clk_i domain
    // Using a multi-stage synchronizer to ensure CDC compliance
    wire [STAGES-1:0] sync_data;
    wire sync_valid;

    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : sync_stage
            assign sync_data[i] = (i == 0) ? serial_i : sync_data[i-1];
        end
    endgenerate

    // Capture the synchronized data and generate a valid pulse when the signal stabilizes
    // This ensures we only react to stable edges in the destination clock domain
    reg sync_d;
    reg sync_q;
    reg sync_valid_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_d      <= 1'b0;
            sync_q      <= 1'b0;
            sync_valid_reg <= 1'b0;
        end else begin
            sync_d      <= sync_data[STAGES-1];
            sync_q      <= sync_d;
            // Valid pulse: 1 cycle when the current value differs from the previous stable value
            sync_valid_reg <= (sync_d != sync_q) ? 1'b1 : 1'b0;
        end
    end

    // Edge Detection Logic
    // r_edge_o: Rising edge detection (0 -> 1 transition)
    // f_edge_o: Falling edge detection (1 -> 0 transition)
    // Both pulses are 1 cycle wide and gated by en_i
    reg r_edge_tmp;
    reg f_edge_tmp;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_tmp <= 1'b0;
            f_edge_tmp <= 1'b0;
        end else begin
            // Rising Edge: Current is 1, Previous was 0
            r_edge_tmp <= (sync_d == 1'b1) && (sync_q == 1'b0);
            // Falling Edge: Current is 0, Previous was 1
            f_edge_tmp <= (sync_d == 1'b0) && (sync_q == 1'b1);
        end
    end

    // Output assignments gated by enable
    assign r_edge_o = en_i ? r_edge_tmp : 1'b0;
    assign f_edge_o = en_i ? f_edge_tmp : 1'b0;

    // Serial Output: The last stage of the synchronizer
    assign serial_o = sync_data[STAGES-1];

endmodule<|im_end|>
