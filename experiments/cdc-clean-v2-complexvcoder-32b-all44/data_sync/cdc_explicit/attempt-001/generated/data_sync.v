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
    reg [DWIDTH-1:0] sync_reg [STAGES-1:0];

    // Synchronization logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < STAGES; i = i + 1) begin
                sync_reg[i] <= {DWIDTH{1'b0}};
            end
            dout <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            // Shift data through the synchronizer stages
            sync_reg[0] <= din;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
            // Output the synchronized data
            dout <= sync_reg[STAGES-1];
            // Pulse dready_o when dready_i is high
            if (dready_i) begin
                dready_o <= 1'b1;
            end else begin
                dready_o <= 1'b0;
            end
        end
    end

endmodule
