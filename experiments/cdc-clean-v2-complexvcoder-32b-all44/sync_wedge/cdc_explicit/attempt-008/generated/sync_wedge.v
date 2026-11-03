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
    reg [STAGES-1:0] sync_chain;
    reg              synced_d1;
    reg              synced_d2;

    // Instantiate sync_stage modules
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : gen_sync_stages
            if (i == 0) begin : first_stage
                sync_stage stage (
                    .clk_i  (clk_i),
                    .rst_ni (rst_ni),
                    .async_i(serial_i),
                    .sync_o (sync_chain[i])
                );
            end else begin : subsequent_stages
                sync_stage stage (
                    .clk_i  (clk_i),
                    .rst_ni (rst_ni),
                    .async_i(sync_chain[i-1]),
                    .sync_o (sync_chain[i])
                );
            end
        end
    endgenerate

    // Assign the final synchronized output
    assign serial_o = sync_chain[STAGES-1];

    // Detect rising and falling edges
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            synced_d1 <= 0;
            synced_d2 <= 0;
        end else begin
            synced_d1 <= serial_o;
            synced_d2 <= synced_d1;
        end
    end

    // Generate rising and falling edge pulses
    assign r_edge_o = en_i & (~synced_d2 & synced_d1);
    assign f_edge_o = en_i & (synced_d2 & ~synced_d1);

endmodule

module sync_stage (
    input  clk_i,
    input  rst_ni,
    input  async_i,
    output sync_o
);

    reg sync_reg1;
    reg sync_reg2;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg1 <= 0;
            sync_reg2 <= 0;
        end else begin
            sync_reg1 <= async_i;
            sync_reg2 <= sync_reg1;
        end
    end

    assign sync_o = sync_reg2;

endmodule
