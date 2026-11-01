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

    localparam SAFE_STAGES = (STAGES < 2) ? 2 : STAGES;

    reg [DWIDTH-1:0] sync_reg [0:SAFE_STAGES-1];
    reg              ready_reg [0:SAFE_STAGES-1];

    integer i;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < SAFE_STAGES; i = i + 1) begin
                sync_reg[i]  <= {DWIDTH{1'b0}};
                ready_reg[i] <= 1'b0;
            end
            dout     <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            // Stage 0: capture input when ready
            sync_reg[0]  <= din;
            ready_reg[0] <= dready_i;

            // Propagate through remaining stages
            for (i = 1; i < SAFE_STAGES; i = i + 1) begin
                sync_reg[i]  <= sync_reg[i-1];
                ready_reg[i] <= ready_reg[i-1];
            end

            // Output from the last stage
            dout     <= sync_reg[SAFE_STAGES-1];
            dready_o <= ready_reg[SAFE_STAGES-1];
        end
    end

endmodule
