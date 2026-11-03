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

reg [DWIDTH-1:0] sync_stage_0_dout;
reg [DWIDTH-1:0] sync_stage_1_dout;

sync_stage #(
    .DWIDTH(DWIDTH)
) sync_stage_0 (
    .clk(clk),
    .rstn(rstn),
    .din(din),
    .dout(sync_stage_0_dout)
);

sync_stage #(
    .DWIDTH(DWIDTH)
) sync_stage_1 (
    .clk(clk),
    .rstn(rstn),
    .din(sync_stage_0_dout),
    .dout(sync_stage_1_dout)
);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dout <= {DWIDTH{1'b0}};
        dready_o <= 1'b0;
    end else begin
        dout <= sync_stage_1_dout;
        dready_o <= dready_i;
    end
end

endmodule

module sync_stage #(
    parameter DWIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    output reg [DWIDTH-1:0] dout
);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dout <= {DWIDTH{1'b0}};
    end else begin
        dout <= din;
    end
end

endmodule
