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

    // Synchronize the asynchronous input bit into the clk_i domain.
    // Use at least 2 stages for safe CDC.
    reg [STAGES-1:0] sync_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_reg <= {STAGES{1'b0}};
        else
            sync_reg <= {sync_reg[STAGES-2:0], serial_i};
    end

    // The synchronized bit in the clk_i domain.
    wire serial_synced = sync_reg[STAGES-1];

    // Edge detection on the synchronized bit.
    // We need the previous value of the synchronized bit.
    reg serial_prev;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            serial_prev <= 1'b0;
        else
            serial_prev <= serial_synced;
    end

    // Rising edge: current is 1, previous was 0.
    // Falling edge: current is 0, previous was 1.
    wire rising  = serial_synced & ~serial_prev;
    wire falling = ~serial_synced & serial_prev;

    // Gate the edge pulses with en_i.
    assign r_edge_o  = rising  & en_i;
    assign f_edge_o  = falling & en_i;

    // Output the synchronized bit.
    assign serial_o = serial_synced;

endmodule
