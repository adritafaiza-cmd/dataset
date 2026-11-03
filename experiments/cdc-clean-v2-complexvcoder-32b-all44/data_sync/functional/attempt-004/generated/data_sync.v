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

reg [DWIDTH-1:0] sync_reg [STAGES-1:0];

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dout <= {DWIDTH{1'b0}};
        dready_o <= 1'b0;
        for (int i = 0; i < STAGES; i = i + 1) begin
            sync_reg[i] <= {DWIDTH{1'b0}};
        end
    end else begin
        if (dready_i) begin
            sync_reg[0] <= din;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
        dout <= sync_reg[STAGES-1];
        dready_o <= sync_reg[STAGES-2] != sync_reg[STAGES-1];
    end
end

endmodule
