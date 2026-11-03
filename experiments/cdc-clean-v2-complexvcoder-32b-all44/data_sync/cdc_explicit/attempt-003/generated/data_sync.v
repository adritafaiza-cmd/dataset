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
    reg                dready_i_sync;
    reg                dready_i_sync2;
    reg                dready_o_reg;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dready_o_reg <= 0;
            dready_i_sync <= 0;
            dready_i_sync2 <= 0;
            for (int i = 0; i < STAGES; i = i + 1) begin
                sync_stages[i] <= 0;
            end
        end else begin
            // Synchronize dready_i through two flip-flops
            dready_i_sync <= dready_i;
            dready_i_sync2 <= dready_i_sync;

            // Synchronize din through STAGES of flip-flops
            sync_stages[0] <= din;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_stages[i] <= sync_stages[i-1];
            end

            // Output the synchronized data
            dout <= sync_stages[STAGES-1];

            // Pulse dready_o when synchronized dready_i indicates a new source value
            if (dready_i_sync2 && !dready_o_reg) begin
                dready_o_reg <= 1;
            end else begin
                dready_o_reg <= 0;
            end
        end
    end

    assign dready_o = dready_o_reg;

endmodule
