module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,

    output wire out
);

    (* ASYNC_REG = "TRUE" *)
    reg [N-1:0] sync;

    initial sync = {N{1'b1}};

    always @(posedge clk)
        sync <= {sync[N-2:0], rst};

    assign out = sync[N-1];

endmodule