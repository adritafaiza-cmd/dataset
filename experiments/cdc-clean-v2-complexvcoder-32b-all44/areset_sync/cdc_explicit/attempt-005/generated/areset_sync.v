module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    // Internal signals for synchronization stages
    reg [STAGES-1:0] sync_stages;

    // First stage directly driven by async_rst_i
    always @(posedge clk or posedge async_rst_i) begin
        if (async_rst_i) begin
            sync_stages[0] <= 1'b1;
        end else begin
            sync_stages[0] <= 1'b0;
        end
    end

    // Subsequent stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_sync_stages
            always @(posedge clk or posedge sync_stages[i-1]) begin
                if (sync_stages[i-1]) begin
                    sync_stages[i] <= 1'b1;
                end else begin
                    sync_stages[i] <= 1'b0;
                end
            end
        end
    endgenerate

    // Assign the final synchronized reset output
    assign sync_rst_o = sync_stages[STAGES-1];

endmodule
