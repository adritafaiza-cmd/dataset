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

    sync_stage #(
        .STAGES(STAGES),
        .DWIDTH(DWIDTH)
    ) sync_stage_inst (
        .clk(clk),
        .rstn(rstn),
        .din(din),
        .dready_i(dready_i),
        .dout_sync(dout),
        .dready_sync(dready_o)
    );

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

    reg [DWIDTH-1:0] sync_reg [0:STAGES-1];
    reg              ready_reg [0:STAGES-1];

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout_sync <= {DWIDTH{1'b0}};
            dready_sync <= 1'b0;
            for (int i = 0; i < STAGES; i = i + 1) begin
                sync_reg[i] <= {DWIDTH{1'b0}};
                ready_reg[i] <= 1'b0;
            end
        end else begin
            sync_reg[0] <= din;
            ready_reg[0] <= dready_i;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
                ready_reg[i] <= ready_reg[i-1];
            end
            dout_sync <= sync_reg[STAGES-1];
            dready_sync <= ready_reg[STAGES-1];
        end
    end

endmodule
