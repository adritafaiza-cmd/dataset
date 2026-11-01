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
    reg             out_reg;

    // Synchronize rst into clk domain
    always @(posedge clk) begin
        sync_reg <= {sync_reg[WIDTH-2:0], rst};
    end

    // Count down from N-1 to 0 after sync_reg[WIDTH-1] goes high
    // When counter reaches 0, deassert out
    reg [WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            out_reg <= 1'b1;
            counter <= {WIDTH{1'b0}};
        end
        else if (sync_reg[WIDTH-1]) begin
            if (counter == {WIDTH{1'b0}}) begin
                out_reg <= 1'b0;
            end
            else begin
                counter <= counter - 1'b1;
                out_reg <= 1'b1;
            end
        end
        else begin
            out_reg <= 1'b1;
            counter <= {WIDTH{1'b0}};
        end
    end

    assign out = out_reg;

endmodule
