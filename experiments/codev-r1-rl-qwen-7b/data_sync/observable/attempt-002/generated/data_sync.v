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

    reg [STAGES-1:0] sync;
    reg dready_sync_prev;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync <= 0;
            dready_sync_prev <= 0;
            dout <= 0;
            dready_o <= 0;
        end else begin
            // Synchronize dready_i through STAGES
            sync <= {sync[STAGES-2:0], dready_i};
            dready_sync_prev <= sync[STAGES-1];
            
            // Detect rising edge of synchronized valid
            if (sync[STAGES-1] && !dready_sync_prev) begin
                dout <= din;
                dready_o <= 1;
            end else begin
                dready_o <= 0;
            end
        end
    end

endmodule
