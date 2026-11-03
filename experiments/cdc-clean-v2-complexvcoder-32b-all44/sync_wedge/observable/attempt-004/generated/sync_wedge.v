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

    // Internal signals
    reg synced_serial;
    reg serial_d1;
    reg serial_d2;

    // Instantiate the sync_stage module
    sync_stage #(
        .STAGES(STAGES)
    ) sync_stage_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .data_in(serial_i),
        .data_out(synced_serial)
    );

    // Assign the output
    assign serial_o = synced_serial;

    // Detect rising and falling edges
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            serial_d1 <= 0;
            serial_d2 <= 0;
            r_edge_o <= 0;
            f_edge_o <= 0;
        end else if (en_i) begin
            serial_d1 <= synced_serial;
            serial_d2 <= serial_d1;
            r_edge_o <= synced_serial & ~serial_d1;
            f_edge_o <= ~synced_serial & serial_d1;
        end
    end

endmodule

module sync_stage #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  data_in,
    output data_out
);

    // Internal register array for synchronization stages
    reg [STAGES-1:0] sync_stage_reg;

    // Synchronize the input data through multiple stages
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stage_reg <= 0;
        end else begin
            sync_stage_reg[0] <= data_in;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_stage_reg[i] <= sync_stage_reg[i-1];
            end
        end
    end

    // Output the last stage of the synchronization register
    assign data_out = sync_stage_reg[STAGES-1];

endmodule
