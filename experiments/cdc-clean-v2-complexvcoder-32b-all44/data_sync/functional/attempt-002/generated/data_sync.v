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

reg [DWIDTH-1:0] sync_stage [STAGES-1:0];

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dready_o <= 0;
        dout     <= 0;
        for (integer i = 0; i < STAGES; i = i + 1) begin
            sync_stage[i] <= 0;
        end
    end else begin
        // Shift input through the synchronization stages
        sync_stage[0] <= din;
        for (integer i = 1; i < STAGES; i = i + 1) begin
            sync_stage[i] <= sync_stage[i-1];
        end

        // Output the synchronized data
        dout <= sync_stage[STAGES-1];

        // Pulse dready_o when dready_i is high
        if (dready_i) begin
            dready_o <= 1;
        end else begin
            dready_o <= 0;
        end
    end
end

endmodule
