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

    // Internal registers for synchronization
    reg [DWIDTH-1:0] sync_reg [0:STAGES-1];
    reg              ready_reg;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Initialize sync_reg and ready_reg to 0 on reset
            for (integer i = 0; i < STAGES; i = i + 1) begin
                sync_reg[i] <= {DWIDTH{1'b0}};
            end
            ready_reg <= 1'b0;
            dready_o  <= 1'b0;
        end else begin
            // Shift din into sync_reg through STAGES of flip-flops
            sync_reg[0] <= din;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end

            // If dready_i is high, set ready_reg to 1
            if (dready_i) begin
                ready_reg <= 1'b1;
            end

            // Assign the last stage of sync_reg to dout
            dout <= sync_reg[STAGES-1];

            // If ready_reg is high, pulse dready_o high for one clock cycle and then set it low
            if (ready_reg) begin
                dready_o  <= 1'b1;
                ready_reg <= 1'b0;
            end else begin
                dready_o <= 1'b0;
            end
        end
    end

endmodule
