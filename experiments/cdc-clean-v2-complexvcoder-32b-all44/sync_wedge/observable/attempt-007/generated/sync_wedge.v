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
    reg synced_serial_prev;

    // Instantiate the sync_chain module
    sync_chain #(
        .STAGES(STAGES)
    ) sync_chain_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .serial_i(serial_i),
        .serial_o(synced_serial)
    );

    // Sequential logic to detect edges and update internal signals
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            synced_serial <= 1'b0;
            synced_serial_prev <= 1'b0;
        end else if (en_i) begin
            synced_serial_prev <= synced_serial;
        end
    end

    // Combinational logic to detect rising and falling edges
    assign r_edge_o = synced_serial & ~synced_serial_prev;
    assign f_edge_o = ~synced_serial & synced_serial_prev;

    // Assign the synchronized serial output
    assign serial_o = synced_serial;

endmodule

module sync_chain #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  serial_i,
    output serial_o
);

    // Internal register array for synchronization stages
    reg [STAGES-1:0] stage_reg;

    // Sequential logic to shift the serial input through the synchronization stages
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            stage_reg <= {STAGES{1'b0}};
        end else begin
            stage_reg[0] <= serial_i;
            for (int i = 1; i < STAGES; i = i + 1) begin
                stage_reg[i] <= stage_reg[i-1];
            end
        end
    end

    // Output the value from the last stage of the synchronization chain
    assign serial_o = stage_reg[STAGES-1];

endmodule
