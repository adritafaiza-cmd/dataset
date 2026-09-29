module data_sync #(
    parameter STAGES = 2,
    parameter DWIDTH = 8
)(
    input clk,
    input rstn,
    input [DWIDTH-1:0] din,
    input dready_i,
    output reg [DWIDTH-1:0] dout,
    output reg dready_o
);

    reg [DWIDTH-1:0] sync_data [0:STAGES];
    reg valid_sync [0:STAGES];
    integer i;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync_data[0] <= 0;
            valid_sync[0] <= 0;
            for (i = 1; i <= STAGES; i = i + 1) begin
                sync_data[i] <= 0;
                valid_sync[i] <= 0;
            end
            dout <= 0;
            dready_o <= 0;
        end else begin
            // Capture data when dready_i is active
            if (dready_i) begin
                sync_data[0] <= din;
                valid_sync[0] <= 1;
            end else begin
                valid_sync[0] <= 0;
            end

            // Shift through synchronization stages
            for (i = 1; i <= STAGES; i = i + 1) begin
                sync_data[i] <= sync_data[i-1];
                valid_sync[i] <= valid_sync[i-1];
            end

            // Assign outputs
            dout <= sync_data[STAGES];
            dready_o <= valid_sync[STAGES];
        end
    end

endmodule
