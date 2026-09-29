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

    reg [DWIDTH-1:0] data_reg;
    reg dready_reg;
    reg dready_sync [0:STAGES-1];
    integer i;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            data_reg <= 0;
            dready_reg <= 0;
            dready_o <= 0;
            dout <= 0;
            for (i = 0; i < STAGES; i = i + 1) begin
                dready_sync[i] <= 0;
            end
        end else begin
            // Capture data and control signal when dready_i is asserted
            if (dready_i) begin
                data_reg <= din;
                dready_reg <= 1;
            end else begin
                dready_reg <= 0;
            end

            // Synchronize the control signal through stages
            dready_sync[0] <= dready_reg;
            for (i = 1; i < STAGES; i = i + 1) begin
                dready_sync[i] <= dready_sync[i-1];
            end

            // Output synchronized data and pulse dready_o
            if (dready_sync[STAGES-1]) begin
                dout <= data_reg;
                dready_o <= 1;
            end else begin
                dready_o <= 0;
            end
        end
    end

endmodule
