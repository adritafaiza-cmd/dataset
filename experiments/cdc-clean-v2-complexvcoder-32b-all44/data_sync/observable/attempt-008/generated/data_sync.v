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

    // Internal synchronization registers
    reg [DWIDTH-1:0] sync_reg [0:STAGES-1];
    reg              ready_reg [0:STAGES-1];

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Reset all stages to 0 on reset
            for (integer i = 0; i < STAGES; i = i + 1) begin
                sync_reg[i] <= {DWIDTH{1'b0}};
                ready_reg[i] <= 1'b0;
            end
            dout <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            // Shift input data and ready signal through the stages
            sync_reg[0] <= din;
            ready_reg[0] <= dready_i;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
                ready_reg[i] <= ready_reg[i-1];
            end
            // Output the final synchronized data and ready signal
            dout <= sync_reg[STAGES-1];
            dready_o <= ready_reg[STAGES-1];
        end
    end

endmodule
