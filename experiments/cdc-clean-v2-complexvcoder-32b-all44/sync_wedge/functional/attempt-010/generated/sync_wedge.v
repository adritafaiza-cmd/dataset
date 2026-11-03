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

    wire serial_synced;
    reg  serial_d1;
    reg  serial_d2;
    reg  serial_d3;

    sync_chain #(
        .STAGES(STAGES)
    ) sync_chain_inst (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .async_in   (serial_i),
        .sync_out   (serial_synced)
    );

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            serial_d1 <= 1'b0;
            serial_d2 <= 1'b0;
            serial_d3 <= 1'b0;
        end else begin
            if (en_i) begin
                serial_d1 <= serial_synced;
                serial_d2 <= serial_d1;
                serial_d3 <= serial_d2;
            end
        end
    end

    assign serial_o = serial_synced;
    assign r_edge_o = serial_d2 & ~serial_d3;
    assign f_edge_o = ~serial_d2 & serial_d3;

endmodule

module sync_chain #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_in,
    output sync_out
);

    reg [STAGES-1:0] sync_stage;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stage <= {STAGES{1'b0}};
        end else begin
            sync_stage[0] <= async_in;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_stage[i] <= sync_stage[i-1];
            end
        end
    end

    assign sync_out = sync_stage[STAGES-1];

endmodule
