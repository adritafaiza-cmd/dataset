module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    wire [N-1:0] synced_rst;

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_sync_ffs
            if (i == 0) begin : first_ff
                DFF ff1 (
                    .clk(clk),
                    .rst(rst),
                    .d(rst),
                    .q(synced_rst[0])
                );
            end else begin : other_ffs
                DFF ff (
                    .clk(clk),
                    .rst(rst),
                    .d(synced_rst[i-1]),
                    .q(synced_rst[i])
                );
            end
        end
    endgenerate

    assign out = synced_rst[N-1];

endmodule

module DFF (
    input  wire clk,
    input  wire rst,
    input  wire d,
    output reg  q
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= 1'b1;
        else
            q <= d;
    end

endmodule
