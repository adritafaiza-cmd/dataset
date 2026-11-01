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

    // Use at least 2 stages for safe metastability resolution
    localparam SYNC_STAGES = (STAGES < 2) ? 2 : STAGES;

    reg [SYNC_STAGES-1:0] sync_reg;
    reg [DWIDTH-1:0]      data_reg;

    // Synchronize the handshake signal
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync_reg <= {SYNC_STAGES{1'b0}};
        end else begin
            sync_reg <= {sync_reg[SYNC_STAGES-2:0], dready_i};
        end
    end

    // Capture data when the synchronized handshake indicates a new value
    // and present it on dout with a pulse on dready_o
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout     <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
            data_reg <= {DWIDTH{1'b0}};
        end else begin
            dready_o <= 1'b0;
            if (sync_reg[SYNC_STAGES-1]) begin
                dout     <= din;
                dready_o <= 1'b1;
                data_reg <= din;
            end
        end
    end

endmodule
