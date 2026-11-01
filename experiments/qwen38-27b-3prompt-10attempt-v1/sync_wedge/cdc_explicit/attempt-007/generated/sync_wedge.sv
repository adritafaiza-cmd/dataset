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

    // Synchronizer chain
    reg [STAGES-1:0] sync_reg;

    // Edge detection registers
    reg serial_d1;
    reg serial_d2;

    // Synchronized output
    assign serial_o = sync_reg[STAGES-1];

    // Synchronizer
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_reg <= {STAGES{1'b0}};
        else
            sync_reg <= {sync_reg[STAGES-2:0], serial_i};
    end

    // Edge detection
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            serial_d1 <= 1'b0;
            serial_d2 <= 1'b0;
        end
        else begin
            serial_d1 <= serial_o;
            serial_d2 <= serial_d1;
        end
    end

    // Rising edge: current is 1, previous was 0
    assign r_edge_o = en_i & serial_o & ~serial_d1;

    // Falling edge: current is 0, previous was 1
    assign f_edge_o = en_i & ~serial_o & serial_d1;

endmodule
