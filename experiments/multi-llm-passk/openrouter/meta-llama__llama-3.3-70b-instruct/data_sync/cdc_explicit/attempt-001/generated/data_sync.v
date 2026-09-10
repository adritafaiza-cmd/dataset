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
reg             sync_valid [STAGES-1:0];

always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
        for (int i = 0; i < STAGES; i++) begin
            sync_reg[i] <= {DWIDTH{1'b0}};
            sync_valid[i] <= 1'b0;
        end
        dready_o <= 1'b0;
    end else begin
        sync_reg[0] <= din;
        sync_valid[0] <= dready_i;
        for (int i = 1; i < STAGES; i++) begin
            sync_reg[i] <= sync_reg[i-1];
            sync_valid[i] <= sync_valid[i-1];
        end
        if (sync_valid[STAGES-1]) begin
            dout <= sync_reg[STAGES-1];
            dready_o <= 1'b1;
        end else begin
            dready_o <= 1'b0;
        end
    end
end

always @(posedge clk) begin
    if (dready_o) begin
        dready_o <= 1'b0;
    end
end

endmodule
