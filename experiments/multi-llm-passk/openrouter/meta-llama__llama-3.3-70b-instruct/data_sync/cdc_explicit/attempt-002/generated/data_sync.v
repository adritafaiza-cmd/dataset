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

reg [DWIDTH-1:0] sync_data [STAGES-1:0];
reg [STAGES-1:0] sync_valid;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dout <= {DWIDTH{1'b0}};
        dready_o <= 1'b0;
        for (int i = 0; i < STAGES; i++) begin
            sync_data[i] <= {DWIDTH{1'b0}};
            sync_valid[i] <= 1'b0;
        end
    end else begin
        sync_valid[0] <= dready_i;
        sync_data[0] <= din;
        for (int i = 1; i < STAGES; i++) begin
            sync_valid[i] <= sync_valid[i-1];
            sync_data[i] <= sync_data[i-1];
        end
        if (sync_valid[STAGES-1]) begin
            dout <= sync_data[STAGES-1];
            dready_o <= 1'b1;
        end else begin
            dready_o <= 1'b0;
        end
    end
end

endmodule
