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

    reg [DWIDTH-1:0] sync_stage [0:STAGES];
    reg                dready_o_reg;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dready_o <= 0;
            dready_o_reg <= 0;
            for (int i = 0; i <= STAGES; i = i + 1) begin
                sync_stage[i] <= 0;
            end
        end else begin
            // Shift the input through the synchronizer stages
            sync_stage[0] <= din;
            for (int i = 1; i <= STAGES; i = i + 1) begin
                sync_stage[i] <= sync_stage[i-1];
            end

            // Generate the output data and ready signal
            dout <= sync_stage[STAGES];
            dready_o_reg <= dready_i;

            // Pulse dready_o when dready_i is high and dready_o_reg was low
            dready_o <= dready_i & ~dready_o_reg;
        end
    end

endmodule
