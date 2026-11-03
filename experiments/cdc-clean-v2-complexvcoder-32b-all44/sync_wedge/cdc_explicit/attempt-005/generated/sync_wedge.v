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

    wire synced;

    // Instantiate the sync_stage module
    sync_stage #(
        .STAGES(STAGES)
    ) sync_stage_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .async_in(serial_i),
        .synced_out(synced)
    );

    // Instantiate the edge_detector module
    edge_detector edge_detector_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .en_i(en_i),
        .serial_in(synced),
        .r_edge_o(r_edge_o),
        .f_edge_o(f_edge_o)
    );

    // Assign the synchronized output
    assign serial_o = synced;

endmodule

module sync_stage #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_in,
    output synced_out
);

    reg [STAGES-1:0] sync_stages;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stages <= {STAGES{1'b0}};
        end else begin
            sync_stages <= {sync_stages[STAGES-2:0], async_in};
        end
    end

    assign synced_out = sync_stages[STAGES-1];

endmodule

module edge_detector (
    input  clk_i,
    input  rst_ni,
    input  en_i,
    input  serial_in,
    output r_edge_o,
    output f_edge_o
);

    reg  prev_bit;
    reg  r_edge;
    reg  f_edge;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            prev_bit <= 1'b0;
            r_edge <= 1'b0;
            f_edge <= 1'b0;
        end else begin
            prev_bit <= serial_in;
            r_edge <= en_i && serial_in && !prev_bit;
            f_edge <= en_i && !serial_in && prev_bit;
        end
    end

    assign r_edge_o = r_edge;
    assign f_edge_o = f_edge;

endmodule
