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

    // Internal signals
    reg [DWIDTH-1:0] sync_reg [0:STAGES-1];
    reg              dready_o_reg;
    reg              dready_o_next;

    // Synchronization chain
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < STAGES; i = i + 1) begin
                sync_reg[i] <= {DWIDTH{1'b0}};
            end
            dready_o_reg <= 1'b0;
        end else begin
            // Shift data through the synchronization stages
            sync_reg[0] <= din;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
            // Output the last stage of the synchronization chain
            dout <= sync_reg[STAGES-1];

            // Pulse dready_o when dready_i is high
            dready_o_next <= dready_i;
            if (dready_i && !dready_o_reg) begin
                dready_o_reg <= 1'b1;
            end else if (dready_o_reg) begin
                dready_o_reg <= 1'b0;
            end
        end
    end

    // Assign the output handshake signal
    assign dready_o = dready_o_reg;

endmodule
