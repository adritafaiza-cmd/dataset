module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    wire [N-1:0] reg_array;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_array <= {N{1'b1}};
        end else begin
            reg_array <= {reg_array[N-2:0], 1'b0};
        end
    end

    assign out = reg_array[N-1];

endmodule
