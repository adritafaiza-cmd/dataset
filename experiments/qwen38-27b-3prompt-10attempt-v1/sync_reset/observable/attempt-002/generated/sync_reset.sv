module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    localparam WIDTH = (N > 0) ? N : 1;

    reg [WIDTH-1:0] sync_reg;
    reg             rst_active;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_reg   <= {WIDTH{1'b1}};
            rst_active <= 1'b1;
        end else begin
            sync_reg   <= {sync_reg[WIDTH-2:0], 1'b0};
            if (sync_reg[WIDTH-1] == 1'b0)
                rst_active <= 1'b0;
        end
    end

    assign out = rst_active;

endmodule
