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

    wire sync_serial;
    reg  prev_sync_serial;

    // Instantiate the sync_chain module to synchronize the asynchronous serial_i input
    sync_chain #(
        .STAGES(STAGES)
    ) sync_chain_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .async_in(serial_i),
        .sync_out(sync_serial)
    );

    // Register the synchronized serial signal
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            prev_sync_serial <= 1'b0;
        end else if (en_i) begin
            prev_sync_serial <= sync_serial;
        end
    end

    // Detect rising and falling edges
    assign r_edge_o = en_i & (sync_serial & ~prev_sync_serial);
    assign f_edge_o = en_i & (~sync_serial & prev_sync_serial);

    // Output the synchronized serial signal
    assign serial_o = sync_serial;

endmodule

module sync_chain #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_in,
    output sync_out
);

    reg [STAGES-1:0] sync_chain_reg;

    // Chain of flip-flops to synchronize the asynchronous input
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain_reg <= {STAGES{1'b0}};
        end else begin
            sync_chain_reg[0] <= async_in;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_chain_reg[i] <= sync_chain_reg[i-1];
            end
        end
    end

    // The synchronized output is the last stage of the chain
    assign sync_out = sync_chain_reg[STAGES-1];

endmodule
