module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    wire rst_sync1;
    wire rst_sync2;

    reset_sync_stage stage1 (
        .clk    (clk),
        .rst_in (rst),
        .rst_out(rst_sync1)
    );

    reset_sync_stage stage2 (
        .clk    (clk),
        .rst_in (rst_sync1),
        .rst_out(rst_sync2)
    );

    assign out = rst_sync2;

endmodule

module reset_sync_stage (
    input  wire clk,
    input  wire rst_in,
    output reg  rst_out
);

    always @(posedge clk) begin
        rst_out <= rst_in;
    end

endmodule
