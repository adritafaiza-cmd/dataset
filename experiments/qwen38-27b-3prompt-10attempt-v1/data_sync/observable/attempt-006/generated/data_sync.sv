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

    reg [DWIDTH-1:0] din_sync [0:STAGES-1];
    reg              dready_i_sync [0:STAGES-1];

    integer i;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < STAGES; i = i + 1) begin
                din_sync[i] <= {DWIDTH{1'b0}};
                dready_i_sync[i] <= 1'b0;
            end
            dout <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            din_sync[0] <= din;
            dready_i_sync[0] <= dready_i;
            for (i = 1; i < STAGES; i = i + 1) begin
                din_sync[i] <= din_sync[i-1];
                dready_i_sync[i] <= dready_i_sync[i-1];
            end
            dout <= din_sync[STAGES-1];
            dready_o <= dready_i_sync[STAGES-1];
        end
    end

endmodule
