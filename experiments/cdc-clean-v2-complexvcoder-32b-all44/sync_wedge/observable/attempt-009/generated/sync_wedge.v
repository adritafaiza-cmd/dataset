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

    reg synced_serial;
    reg d_edge_detect;
    reg q_edge_detect;

    // Instantiate the synchronizer flip-flops
    ff_sync #(
        .STAGES(STAGES)
    ) sync_ff (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .d(serial_i),
        .q(synced_serial)
    );

    // Assign the synchronized signal to the output
    assign serial_o = synced_serial;

    // Edge detection logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            d_edge_detect <= 0;
            q_edge_detect <= 0;
            r_edge_o <= 0;
            f_edge_o <= 0;
        end else if (en_i) begin
            d_edge_detect <= synced_serial;
            q_edge_detect <= d_edge_detect;

            // Detect rising edge
            r_edge_o <= synced_serial & ~q_edge_detect;

            // Detect falling edge
            f_edge_o <= ~synced_serial & q_edge_detect;
        end else begin
            r_edge_o <= 0;
            f_edge_o <= 0;
        end
    end

endmodule

module ff_sync #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  d,
    output q
);

    reg [STAGES-1:0] ff_array;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ff_array <= {STAGES{1'b0}};
        end else begin
            ff_array[0] <= d;
            for (int i = 1; i < STAGES; i = i + 1) begin
                ff_array[i] <= ff_array[i-1];
            end
        end
    end

    assign q = ff_array[STAGES-1];

endmodule
