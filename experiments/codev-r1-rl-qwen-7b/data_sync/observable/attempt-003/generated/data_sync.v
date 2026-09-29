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

    reg [STAGES-1:0] dready_sync;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dready_sync <= 0;
            dout <= 0;
            dready_o <= 0;
        end else begin
            // Synchronizer shift register for dready_i
            dready_sync <= {dready_sync[STAGES-2:0], dready_i};

            // Capture data when synchronized valid arrives
            if (dready_sync[STAGES-1]) begin
                dout <= din;
                dready_o <= 1;
            end else begin
                dready_o <= 0;
            end
        end
    end

endmodule
