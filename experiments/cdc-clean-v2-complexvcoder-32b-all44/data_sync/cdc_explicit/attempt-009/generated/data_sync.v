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

reg [DWIDTH-1:0] synced_din_1;
reg [DWIDTH-1:0] synced_din_2;

// Synchronization stage 1
sync_stage #(
    .DWIDTH(DWIDTH)
) sync_stage_1 (
    .clk(clk),
    .rstn(rstn),
    .din(din),
    .dout(synced_din_1)
);

// Synchronization stage 2
sync_stage #(
    .DWIDTH(DWIDTH)
) sync_stage_2 (
    .clk(clk),
    .rstn(rstn),
    .din(synced_din_1),
    .dout(synced_din_2)
);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dout <= {DWIDTH{1'b0}};
        dready_o <= 1'b0;
    end else begin
        dout <= synced_din_2;
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
