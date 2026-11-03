module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

reg sync_rst_0;
reg sync_rst_1;
reg [N-1:0] release_counter;
reg out_reg;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        sync_rst_0 <= 1'b1;
        sync_rst_1 <= 1'b1;
        release_counter <= {N{1'b0}};
        out_reg <= 1'b1;
    end else begin
        sync_rst_0 <= rst;
        sync_rst_1 <= sync_rst_0;
        if (sync_rst_1) begin
            out_reg <= 1'b1;
            release_counter <= {N{1'b0}};
        end else if (release_counter < N-1) begin
            release_counter <= release_counter + 1;
        end else begin
            out_reg <= 1'b0;
        end
    end
end

assign out = out_reg;

endmodule
