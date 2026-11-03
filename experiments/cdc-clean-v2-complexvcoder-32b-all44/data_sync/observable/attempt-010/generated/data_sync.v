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

reg [DWIDTH-1:0] sync_ff [STAGES-1:0];
reg              ready_ff;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dout <= {DWIDTH{1'b0}};
        dready_o <= 1'b0;
        ready_ff <= 1'b0;
        for (integer i = 0; i < STAGES; i = i + 1) begin
            sync_ff[i] <= {DWIDTH{1'b0}};
        end
    end else begin
        // Shift input through the synchronization stages
        sync_ff[0] <= din;
        for (integer i = 1; i < STAGES; i = i + 1) begin
            sync_ff[i] <= sync_ff[i-1];
        end
        // Output the last stage of the synchronization
        dout <= sync_ff[STAGES-1];
        // Set the ready flag when the data is synchronized
        ready_ff <= sync_ff[STAGES-1] != sync_ff[STAGES-2];
        // Indicate readiness when synchronized data is valid and dready_i is high
        dready_o <= ready_ff & dready_i;
    end
end

endmodule
