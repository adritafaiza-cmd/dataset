module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    // Internal signals for synchronization stages
    wire [N-1:0] synced_rst;

    // Instantiate N stages of synchronization
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_sync_stages
            if (i == 0) begin
                sync_reset_stage sync_stage_0 (
                    .clk(clk),
                    .rst(rst),
                    .in(rst),
                    .out(synced_rst[0])
                );
            end else begin
                sync_reset_stage sync_stage_i (
                    .clk(clk),
                    .rst(rst),
                    .in(synced_rst[i-1]),
                    .out(synced_rst[i])
                );
            end
        end
    endgenerate

    // Assign the final synchronized reset to the output
    assign out = synced_rst[N-1];

endmodule

// Single stage of synchronization for reset signal
module sync_reset_stage
(
    input  wire clk,
    input  wire rst,
    input  wire in,
    output wire out
);

    reg sync_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_reg <= 1'b1;
        end else begin
            sync_reg <= in;
        end
    end

    assign out = sync_reg;

endmodule
