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

reg [DWIDTH-1:0] sync_out;
reg              sync_valid;

ff_chain #(
    .STAGES(STAGES),
    .DWIDTH(DWIDTH)
) sync_ff_chain (
    .clk      (clk),
    .rstn     (rstn),
    .din      (din),
    .dready_i (dready_i),
    .dout     (sync_out),
    .dready_o (sync_valid)
);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dout <= {DWIDTH{1'b0}};
        dready_o <= 1'b0;
    end else begin
        dout <= sync_out;
        dready_o <= sync_valid;
    end
end

endmodule

module ff_chain #(
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

reg [DWIDTH-1:0] ff_out [0:STAGES-1];
reg              valid [0:STAGES-1];

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        for (integer i = 0; i < STAGES; i = i + 1) begin
            ff_out[i] <= {DWIDTH{1'b0}};
            valid[i] <= 1'b0;
        end
    end else begin
        ff_out[0] <= din;
        valid[0] <= dready_i;
        for (integer i = 1; i < STAGES; i = i + 1) begin
            ff_out[i] <= ff_out[i-1];
            valid[i] <= valid[i-1];
        end
    end
end

assign dout = ff_out[STAGES-1];
assign dready_o = valid[STAGES-1];

endmodule
