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

reg [DWIDTH-1:0] sync_stages [0:STAGES-1];
reg              dready_sync [0:STAGES-1];

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dready_o <= 0;
        dout <= 0;
        for (integer i = 0; i < STAGES; i = i + 1) begin
            sync_stages[i] <= 0;
            dready_sync[i] <= 0;
        end
    end else begin
        // First stage
        sync_stages[0] <= din;
        dready_sync[0] <= dready_i;

        // Intermediate stages
        for (integer i = 1; i < STAGES; i = i + 1) begin
            sync_stages[i] <= sync_stages[i-1];
            dready_sync[i] <= dready_sync[i-1];
        end

        // Last stage
        dout <= sync_stages[STAGES-1];
        dready_o <= dready_sync[STAGES-1];
    end
end

endmodule
