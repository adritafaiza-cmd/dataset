module pulse_sync #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  pulseA_i,
    output pulseB_o,
    output busy_o
);

wire async_pulse_out;

// Instantiate the async_cross module
async_cross #(
    .STAGES(STAGES)
) async_cross_inst (
    .clk_a(clk_a),
    .rstn_a(rstn_a),
    .clk_b(clk_b),
    .rstn_b(rstn_b),
    .async_pulse_in(pulseA_i),
    .async_pulse_out(async_pulse_out)
);

// Instantiate the pulse_generator module
pulse_generator pulse_generator_inst (
    .clk_b(clk_b),
    .rstn_b(rstn_b),
    .pulse_in(async_pulse_out),
    .pulse_out(pulseB_o),
    .busy_o(busy_o)
);

endmodule

module async_cross #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  async_pulse_in,
    output async_pulse_out
);

reg [STAGES-1:0] sync_stages;

always @(posedge clk_a or negedge rstn_a) begin
    if (!rstn_a) begin
        sync_stages <= {STAGES{1'b0}};
    end else begin
        sync_stages[0] <= async_pulse_in;
        sync_stages[1:STAGES-1] <= sync_stages[0:STAGES-2];
    end
end

always @(posedge clk_b or negedge rstn_b) begin
    if (!rstn_b) begin
        async_pulse_out <= 1'b0;
    end else begin
        async_pulse_out <= sync_stages[STAGES-1];
    end
end

endmodule

module pulse_generator (
    input  clk_b,
    input  rstn_b,
    input  pulse_in,
    output pulse_out,
    output busy_o
);

reg pulse_reg;
reg busy_reg;

always @(posedge clk_b or negedge rstn_b) begin
    if (!rstn_b) begin
        pulse_reg <= 1'b0;
        busy_reg  <= 1'b0;
    end else begin
        if (!busy_reg && pulse_in) begin
            pulse_reg <= 1'b1;
            busy_reg  <= 1'b1;
        end else if (pulse_reg) begin
            pulse_reg <= 1'b0;
            busy_reg  <= 1'b0;
        end
    end
end

assign pulse_out = pulse_reg;
assign busy_o    = busy_reg;

endmodule
