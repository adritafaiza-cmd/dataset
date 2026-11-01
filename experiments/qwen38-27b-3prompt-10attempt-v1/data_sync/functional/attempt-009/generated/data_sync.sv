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

    // Choose a safe crossing depth: at least 2 stages for metastability
    // We use the STAGES parameter but ensure minimum of 2
    localparam SYNC_STAGES = (STAGES < 2) ? 2 : STAGES;

    // Synchronizer flip-flops
    reg [DWIDTH-1:0] sync_reg [0:SYNC_STAGES-1];
    reg              ready_sync [0:SYNC_STAGES-1];

    // Pipeline registers for data and ready
    reg [DWIDTH-1:0] pipe_data [0:SYNC_STAGES-1];
    reg              pipe_ready [0:SYNC_STAGES-1];

    integer i;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i]   <= {DWIDTH{1'b0}};
                ready_sync[i] <= 1'b0;
                pipe_data[i]  <= {DWIDTH{1'b0}};
                pipe_ready[i] <= 1'b0;
            end
            dout     <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            // First stage: capture input when dready_i is high
            sync_reg[0]   <= din;
            ready_sync[0] <= dready_i;

            // Propagate through remaining stages
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i]   <= sync_reg[i-1];
                ready_sync[i] <= ready_sync[i-1];
            end

            // Output the synchronized data and ready
            dout     <= sync_reg[SYNC_STAGES-1];
            dready_o <= ready_sync[SYNC_STAGES-1];
        end
    end

endmodule
