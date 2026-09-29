module sync_reset #(
    parameter N = 2
) (
    input clk,
    input rst,
    output out
);

generate
    if (N == 1) begin : gen_single
        reg sync_reg;
        always @(posedge clk or posedge rst) begin
            if (rst) begin
                sync_reg <= 1'b1;
            end else begin
                sync_reg <= 1'b0;
            end
        end
        assign out = sync_reg;
    end else begin : gen_multiple
        reg [N-1 :0] sync_reg;
        always @(posedge clk or posedge rst) begin
            if (rst) begin
                sync_reg <= {N{1'b1}};
            end else begin
                sync_reg <= {sync_reg[N-2 :0], 1'b0};
            end
        end
        assign out = sync_reg[N-1];
    end
endgenerate

endmodule
