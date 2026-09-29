module data_sync #(
    parameter STAGES = 2,
    parameter DWIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    input                  dready_i,
    output [DWIDTH-1:0]    dout,
    output                 dready_o
);

reg [DWIDTH-1:0] sync_reg [0:STAGES-1];
reg dready_reg [0:STAGES-1];

integer i;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        for (i = 0; i < STAGES; i = i + 1) begin
            sync_reg[i] <= 0;
            dready_reg[i] <= 0;
        end
    end else begin
        // Capture data into first stage when handshake is active
        if (dready_i) begin
            sync_reg[0] <= din;
        end
        dready_reg[0] <= dready_i;

        // Shift through synchronization stages
        for (i = 1; i < STAGES; i = i + 1) begin
            sync_reg[i] <= sync_reg[i-1];
            dready_reg[i] <= dready_reg[i-1];
        end
    end
end

// Assign outputs from last stage
assign dout = sync_reg[STAGES-1];
assign dready_o = dready_reg[STAGES-1];

endmodule
