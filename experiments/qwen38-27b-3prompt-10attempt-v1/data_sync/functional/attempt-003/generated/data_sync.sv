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

    localparam SYNC_STAGES = (STAGES < 2) ? 2 : STAGES;

    reg [SYNC_STAGES-1:0] sync_reg;
    reg [SYNC_STAGES-1:0] valid_reg;

    integer i;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync_reg <= {SYNC_STAGES{1'b0}};
            valid_reg <= {SYNC_STAGES{1'b0}};
            dout <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            sync_reg[0] <= dready_i;
            valid_reg[0] <= dready_i;

            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
                valid_reg[i] <= valid_reg[i-1];
            end

            if (valid_reg[SYNC_STAGES-1]) begin
                dout <= din;
                dready_o <= 1'b1;
            end else begin
                dready_o <= 1'b0;
            end
        end
    end

endmodule
