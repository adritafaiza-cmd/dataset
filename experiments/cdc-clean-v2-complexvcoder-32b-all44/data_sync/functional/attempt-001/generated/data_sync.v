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

    reg [DWIDTH-1:0] sync_stages [STAGES-1:0];
    reg                dready_i_reg;
    reg                dready_o_reg;
    reg                dready_i_reg_prev;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < STAGES; i = i + 1) begin
                sync_stages[i] <= {DWIDTH{1'b0}};
            end
            dready_o_reg <= 1'b0;
        end else begin
            // Shift the value of din through the sync_stages
            sync_stages[0] <= din;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_stages[i] <= sync_stages[i-1];
            end

            // Update dready_i_reg with the value of dready_i
            dready_i_reg <= dready_i;

            // Detect rising edge of dready_i_reg
            if (!dready_i_reg_prev && dready_i_reg) begin
                dready_o_reg <= 1'b1;
            end else begin
                dready_o_reg <= 1'b0;
            end

            // Save previous value of dready_i_reg
            dready_i_reg_prev <= dready_i_reg;
        end
    end

    // Assign the value of the last stage in sync_stages to dout
    assign dout = sync_stages[STAGES-1];

    // Assign the value of dready_o_reg to dready_o
    assign dready_o = dready_o_reg;

endmodule
