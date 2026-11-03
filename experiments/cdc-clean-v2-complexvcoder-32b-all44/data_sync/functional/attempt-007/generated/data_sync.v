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

reg [DWIDTH-1:0] synced_din [0:STAGES];
reg              ready_reg;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        for (int i = 0; i <= STAGES; i = i + 1) begin
            synced_din[i] <= {DWIDTH{1'b0}};
        end
        dout <= {DWIDTH{1'b0}};
        dready_o <= 1'b0;
        ready_reg <= 1'b0;
    end else begin
        // Shift din through the synchronization pipeline
        synced_din[0] <= din;
        for (int i = 1; i <= STAGES; i = i + 1) begin
            synced_din[i] <= synced_din[i-1];
        end

        // Update dout and dready_o based on the ready handshake
        if (dready_i && !ready_reg) begin
            dout <= synced_din[STAGES];
            dready_o <= 1'b1;
            ready_reg <= 1'b1;
        end else if (ready_reg) begin
            dready_o <= 1'b0;
            ready_reg <= 1'b0;
        end
    end
end

endmodule
