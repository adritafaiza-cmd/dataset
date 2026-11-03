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

reg [DWIDTH-1:0] sync_din_out;
reg              sync_dready_i_out;
reg              dready_i_sync;

// Instantiate synchronizer for din
synchronizer #(
    .STAGES(STAGES),
    .DWIDTH(DWIDTH)
) sync_din (
    .clk(clk),
    .rstn(rstn),
    .din(din),
    .dout(sync_din_out)
);

// Instantiate synchronizer for dready_i
synchronizer #(
    .STAGES(STAGES),
    .DWIDTH(1)
) sync_dready_i (
    .clk(clk),
    .rstn(rstn),
    .din(dready_i),
    .dout(sync_dready_i_out)
);

// Register to hold synchronized dready_i
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dready_i_sync <= 0;
    end else begin
        dready_i_sync <= sync_dready_i_out;
    end
end

// Register to hold dout and dready_o
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dout     <= 0;
        dready_o <= 0;
    end else begin
        dout     <= sync_din_out;
        dready_o <= dready_i_sync;
    end
end

endmodule

module synchronizer #(
    parameter STAGES = 2,
    parameter DWIDTH = 1
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    output reg [DWIDTH-1:0] dout
);

reg [DWIDTH-1:0] sync_stages [STAGES:0];

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        for (integer i = 0; i <= STAGES; i = i + 1) begin
            sync_stages[i] <= 0;
        end
    end else begin
        sync_stages[0] <= din;
        for (integer i = 1; i <= STAGES; i = i + 1) begin
            sync_stages[i] <= sync_stages[i-1];
        end
    end
end

assign dout = sync_stages[STAGES];

endmodule
