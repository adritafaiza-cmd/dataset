// Mux-based data synchronizer. Verilog rewrite of tweak_circuits data_sync.vhd.
// Designed by Mitu Raj, Chipmunk Logic.

module data_sync #(
    parameter STAGES = 2,
    parameter DWIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    input                  dready_i,
    output reg [DWIDTH-1:0] dout,
    output reg             dready_o
);

    (* ASYNC_REG = "TRUE" *)
    reg [STAGES-1:0] flipflops;
    wire dready_sync = flipflops[STAGES-1];

    always @(posedge clk) begin
        if (!rstn)
            flipflops <= {STAGES{1'b0}};
        else
            flipflops <= {flipflops[STAGES-2:0], dready_i};
    end

    always @(posedge clk) begin
        if (!rstn) begin
            dout <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            if (dready_sync)
                dout <= din;
            dready_o <= dready_sync;
        end
    end

endmodule
