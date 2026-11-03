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

    reg [DWIDTH-1:0] sync_stages [0:STAGES-1];
    reg                dready_i_reg;
    reg                dready_o_reg;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
            dready_i_reg <= 1'b0;
            dready_o_reg <= 1'b0;
            for (int i = 0; i < STAGES; i = i + 1) begin
                sync_stages[i] <= {DWIDTH{1'b0}};
            end
        end else begin
            // Register dready_i into dready_i_reg
            dready_i_reg <= dready_i;

            // Synchronize din through STAGES of flip-flops
            sync_stages[0] <= din;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_stages[i] <= sync_stages[i-1];
            end

            // Handshake logic
            if (dready_i_reg && !dready_o_reg) begin
                dready_o_reg <= 1'b1;
            end else if (dready_o_reg && !dready_i_reg) begin
                dready_o_reg <= 1'b0;
                dout <= sync_stages[STAGES-1];
            end
        end
    end

endmodule
