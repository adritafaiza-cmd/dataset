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

    // Synchronize the asynchronous input bit
    wire [STAGES-1:0] sync_serial;
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : sync_stage
            wire sync_stage_out;
            always @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni)
                    sync_stage_out <= 1'b0;
                else
                    sync_stage_out <= sync_serial[i];
            end
        end
    endgenerate

    assign sync_serial[0] = serial_i;
    assign sync_serial[STAGES-1] = sync_serial[STAGES-2];

    // Synchronize the enable signal
    wire [STAGES-1:0] sync_en;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : sync_en_stage
            wire sync_en_out;
            always @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni)
                    sync_en_out <= 1'b0;
                else
                    sync_en_out <= sync_en[i];
            end
        end
    endgenerate

    assign sync_en[0] = en_i;
    assign sync_en[STAGES-1] = sync_en[STAGES-2];

    // Synchronize the reset signal for internal logic stability
    wire sync_rst_n;
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_rst_n <= 1'b0;
        else
            sync_rst_n <= rst_ni;
    end

    // Detect edges on the synchronized data
    // Rising edge: current is 1, previous was 0
    // Falling edge: current is 0, previous was 1
    wire sync_serial_prev;
    reg sync_serial_prev_reg;

    always @(posedge clk_i or negedge sync_rst_n) begin
        if (!sync_rst_n)
            sync_serial_prev_reg <= 1'b0;
        else
            sync_serial_prev_reg <= sync_serial[STAGES-1];
    end

    assign r_edge_o = (sync_serial[STAGES-1] & ~sync_serial_prev_reg) & sync_en[STAGES-1];
    assign f_edge_o = (~sync_serial[STAGES-1] & sync_serial_prev_reg) & sync_en[STAGES-1];

    // Output the synchronized bit
    assign serial_o = sync_serial[STAGES-1];

endmodule<|im_end|>
