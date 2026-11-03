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

    reg [DWIDTH-1:0] sync_reg [0:STAGES-1];
    reg              ready_reg;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (integer i = 0; i < STAGES; i = i + 1) begin
                sync_reg[i] <= {DWIDTH{1'b0}};
            end
            ready_reg <= 1'b0;
            dout      <= {DWIDTH{1'b0}};
            dready_o  <= 1'b0;
        end else begin
            sync_reg[0] <= din;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
            if (dready_i) begin
                ready_reg <= 1'b1;
            end
            dout      <= sync_reg[STAGES-1];
            dready_o  <= ready_reg;
        end
    end

endmodule
