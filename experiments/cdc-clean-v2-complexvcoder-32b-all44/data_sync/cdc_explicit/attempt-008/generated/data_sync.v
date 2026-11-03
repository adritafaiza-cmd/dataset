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

    // Internal synchronization chains
    reg [DWIDTH-1:0] sync_chain [STAGES-1:0];
    reg [STAGES-1:0] sync_ready;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Reset synchronization chains and ready signals
            for (integer i = 0; i < STAGES; i = i + 1) begin
                sync_chain[i] <= {DWIDTH{1'b0}};
                sync_ready[i] <= 1'b0;
            end
            dout <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            // Shift the data through the synchronization chain
            sync_chain[0] <= din;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_chain[i] <= sync_chain[i-1];
            end

            // Shift the ready signals through the synchronization chain
            sync_ready[0] <= dready_i;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_ready[i] <= sync_ready[i-1];
            end

            // Output the data and ready signal from the last stage
            dout <= sync_chain[STAGES-1];
            dready_o <= sync_ready[STAGES-1];
        end
    end

endmodule
