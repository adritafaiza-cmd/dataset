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
    reg sync_out;
    reg d1;
    reg d2;
    reg r_edge;
    reg f_edge;

    // Instantiate the sync_chain module
    sync_chain #(
        .STAGES(STAGES)
    ) sync_chain_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .async_in(serial_i),
        .sync_out(sync_out)
    );

    // Assign the synchronized output
    assign serial_o = sync_out;

    // Detect rising and falling edges
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            d1 <= 1'b0;
            d2 <= 1'b0;
            r_edge <= 1'b0;
            f_edge <= 1'b0;
        end else begin
            d1 <= sync_out;
            d2 <= d1;
            r_edge <= en_i & (d2 & !d1);
            f_edge <= en_i & (!d2 & d1);
        end
    end

    // Assign edge detect outputs
    assign r_edge_o = r_edge;
    assign f_edge_o = f_edge;

endmodule

module sync_chain #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_in,
    output sync_out
);

    // Internal register chain
    reg [STAGES-1:0] reg_chain;

    // Synchronize the asynchronous input
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            reg_chain <= {STAGES{1'b0}};
        end else begin
            reg_chain[0] <= async_in;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                reg_chain[i] <= reg_chain[i-1];
            end
        end
    end

    // Assign the final synchronized output
    assign sync_out = reg_chain[STAGES-1];

endmodule
