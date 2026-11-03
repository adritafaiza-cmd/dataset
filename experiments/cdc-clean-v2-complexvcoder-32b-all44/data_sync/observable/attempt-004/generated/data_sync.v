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

reg [DWIDTH-1:0] dout_sync;
reg              dready_sync;

sync_stage #(
    .STAGES(STAGES),
    .DWIDTH(DWIDTH)
) sync_stage_inst (
    .clk(clk),
    .rstn(rstn),
    .din(din),
    .dready_i(dready_i),
    .dout_sync(dout_sync),
    .dready_sync(dready_sync)
);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dout     <= {DWIDTH{1'b0}};
        dready_o <= 1'b0;
    end else begin
        dout     <= dout_sync;
        dready_o <= dready_sync;
    end
end

endmodule

module sync_stage #(
    parameter STAGES = 2,
    parameter DWIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    input                  dready_i,
    output reg [DWIDTH-1:0] dout_sync,
    output reg             dready_sync
);

reg [DWIDTH-1:0] synced_din [0:STAGES];
reg              synced_dready_i [0:STAGES];

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dout_sync     <= {DWIDTH{1'b0}};
        dready_sync   <= 1'b0;
        for (integer i = 0; i <= STAGES; i = i + 1) begin
            synced_din[i]     <= {DWIDTH{1'b0}};
            synced_dready_i[i] <= 1'b0;
        end
    end else begin
        synced_din[0]     <= din;
        synced_dready_i[0] <= dready_i;
        for (integer i = 1; i <= STAGES; i = i + 1) begin
            synced_din[i]     <= synced_din[i-1];
            synced_dready_i[i] <= synced_dready_i[i-1];
        end
        dout_sync     <= synced_din[STAGES];
        dready_sync   <= synced_dready_i[STAGES];
    end
end

endmodule
