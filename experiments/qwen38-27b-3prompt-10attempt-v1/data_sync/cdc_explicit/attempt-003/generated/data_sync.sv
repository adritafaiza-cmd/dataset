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

    // Ensure at least 2 stages for safe synchronization
    localparam SYNC_STAGES = (STAGES < 2) ? 2 : STAGES;

    // Synchronizer flip-flops for the handshake signal
    reg [SYNC_STAGES-1:0] sync_ff;

    // Internal register to hold the data
    reg [DWIDTH-1:0] data_reg;

    // Edge detection for the synchronized handshake
    wire sync_edge = sync_ff[1] & ~sync_ff[0];

    // Synchronize the handshake signal
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync_ff <= {SYNC_STAGES{1'b0}};
        end else begin
            sync_ff[0] <= dready_i;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_ff[i] <= sync_ff[i-1];
            end
        end
    end

    // Capture data when synchronized handshake edge is detected
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            data_reg <= {DWIDTH{1'b0}};
            dout     <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            if (sync_edge) begin
                data_reg <= din;
                dready_o <= 1'b1;
            end else begin
                dready_o <= 1'b0;
            end
            dout <= data_reg;
        end
    end

endmodule
