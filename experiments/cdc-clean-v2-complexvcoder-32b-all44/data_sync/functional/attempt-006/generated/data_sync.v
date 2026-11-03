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

reg [DWIDTH-1:0] sync_stages [STAGES-1:0];

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dready_o <= 0;
        dout <= 0;
        for (int i = 0; i < STAGES; i = i + 1) begin
            sync_stages[i] <= 0;
        end
    end else begin
        if (dready_i) begin
            sync_stages[0] <= din;
        end else begin
            sync_stages[0] <= sync_stages[0];
        end

        for (int i = 1; i < STAGES; i = i + 1) begin
            sync_stages[i] <= sync_stages[i-1];
        end

        dout <= sync_stages[STAGES-1];
        dready_o <= sync_stages[STAGES-1] != sync_stages[STAGES-2];
    end
end

endmodule
