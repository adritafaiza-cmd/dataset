module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    reg synced_rst;
    reg [N-1:0] rst_counter;
    reg out_reg;

    // Instantiate the ff_sync module to synchronize the reset signal
    ff_sync ff_sync_inst (
        .clk(clk),
        .d(rst),
        .q(synced_rst)
    );

    // Synchronize the reset signal and use a counter to control the output
    always @(posedge clk) begin
        if (synced_rst) begin
            rst_counter <= {N{1'b1}}; // Load the counter with all ones when reset is active
            out_reg <= 1'b1; // Assert the output
        end else begin
            if (rst_counter != 0) begin
                rst_counter <= rst_counter - 1; // Decrement the counter
            end
            if (rst_counter == 1) begin
                out_reg <= 1'b0; // Release the output cleanly after N clock edges
            end
        end
    end

    assign out = out_reg;

endmodule

module ff_sync (
    input  wire clk,
    input  wire d,
    output reg  q
);

    reg ff1;

    // Double flip-flop synchronizer
    always @(posedge clk) begin
        ff1 <= d;
        q <= ff1;
    end

endmodule
