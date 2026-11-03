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
reg              ready_next;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dout <= {DWIDTH{1'b0}};
        dready_o <= 1'b0;
        ready_reg <= 1'b0;
        for (int i = 0; i < STAGES; i = i + 1) begin
            sync_reg[i] <= {DWIDTH{1'b0}};
        end
    end else begin
        // Synchronize din through a multi-stage shift register
        sync_reg[0] <= din;
        for (int i = 1; i < STAGES; i = i + 1) begin
            sync_reg[i] <= sync_reg[i-1];
        end

        // Capture the synchronized data when dready_i is high
        if (dready_i) begin
            dout <= sync_reg[STAGES-1];
            ready_next <= 1'b1;
        end else begin
            ready_next <= 1'b0;
        end

        // Pulse dready_o for one clock cycle when a new value is captured and dready_i is high
        ready_reg <= ready_next;
        dready_o <= ready_next & ~ready_reg;
    end
end

endmodule
