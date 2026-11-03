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

    wire synced_serial;
    reg  serial_d1;

    // Instantiate the synchronization chain
    sync_chain #(
        .STAGES(STAGES)
    ) sync_chain_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .async_in(serial_i),
        .synced_out(synced_serial)
    );

    // Assign the synchronized output
    assign serial_o = synced_serial;

    // Detect rising and falling edges
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            serial_d1 <= 1'b0;
            r_edge_o  <= 1'b0;
            f_edge_o  <= 1'b0;
        end else begin
            serial_d1 <= synced_serial;
            if (en_i) begin
                r_edge_o <= synced_serial & ~serial_d1;
                f_edge_o <= ~synced_serial & serial_d1;
            end else begin
                r_edge_o <= 1'b0;
                f_edge_o <= 1'b0;
            end
        end
    end

endmodule

module sync_chain #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_in,
    output synced_out
);

    reg [STAGES-1:0] sync_chain;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= {STAGES{1'b0}};
        end else begin
            sync_chain[0] <= async_in;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_chain[i] <= sync_chain[i-1];
            end
        end
    end

    assign synced_out = sync_chain[STAGES-1];

endmodule
