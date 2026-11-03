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
    wire synced_serial;
    reg  d1;
    reg  d2;

    // Instantiate the sync_chain module
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

    // Edge detection logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            d1 <= 1'b0;
            d2 <= 1'b0;
        end else begin
            d1 <= synced_serial;
            d2 <= d1;
        end
    end

    // Rising edge detection
    assign r_edge_o = en_i & (~d2 & d1);

    // Falling edge detection
    assign f_edge_o = en_i & (d2 & ~d1);

endmodule

// sync_chain module implementation
module sync_chain #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_in,
    output synced_out
);

    // Internal signals
    reg [STAGES-1:0] sync_reg;

    // Synchronization chain
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {STAGES{1'b0}};
        end else begin
            sync_reg[0] <= async_in;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    // Output the last stage of the synchronization chain
    assign synced_out = sync_reg[STAGES-1];

endmodule
