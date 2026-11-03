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

    wire sync_serial_o;
    reg d_ff;
    reg r_edge_ff;
    reg f_edge_ff;

    // Instantiate the synchronization chain
    ff_sync_chain #(
        .STAGES(STAGES)
    ) sync_chain (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .d_i(serial_i),
        .q_o(sync_serial_o)
    );

    // Output the synchronized signal
    assign serial_o = sync_serial_o;

    // Detect rising and falling edges
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            d_ff <= 1'b0;
            r_edge_ff <= 1'b0;
            f_edge_ff <= 1'b0;
        end else begin
            d_ff <= sync_serial_o;
            r_edge_ff <= en_i & ~d_ff & sync_serial_o;
            f_edge_ff <= en_i & d_ff & ~sync_serial_o;
        end
    end

    // Assign edge outputs
    assign r_edge_o = r_edge_ff;
    assign f_edge_o = f_edge_ff;

endmodule

module ff_sync_chain #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  d_i,
    output q_o
);

    reg [STAGES-1:0] sync_ffs;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_ffs <= {STAGES{1'b0}};
        end else begin
            sync_ffs[0] <= d_i;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_ffs[i] <= sync_ffs[i-1];
            end
        end
    end

    assign q_o = sync_ffs[STAGES-1];

endmodule
