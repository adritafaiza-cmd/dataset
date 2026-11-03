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

    // Internal synchronization stages
    reg [STAGES-1:0][DWIDTH-1:0] sync_stages;

    // Synchronization logic for data
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync_stages <= {STAGES{DWIDTH{1'b0}}};
        end else begin
            sync_stages[0] <= din;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_stages[i] <= sync_stages[i-1];
            end
        end
    end

    // Output data and ready signal
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout     <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            dout     <= sync_stages[STAGES-1];
            dready_o <= dready_i;
        end
    end

endmodule
