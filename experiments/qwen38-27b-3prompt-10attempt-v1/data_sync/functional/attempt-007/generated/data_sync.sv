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

    // Use a safe minimum of 2 stages for metastability resolution
    localparam SYNC_STAGES = (STAGES < 2) ? 2 : STAGES;

    // Synchronizer flip-flops
    reg [DWIDTH-1:0] sync_reg [0:SYNC_STAGES-1];
    reg              ready_reg [0:SYNC_STAGES-1];

    // Capture new data when dready_i is high
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync_reg[0] <= {DWIDTH{1'b0}};
            ready_reg[0] <= 1'b0;
        end else begin
            if (dready_i) begin
                sync_reg[0] <= din;
                ready_reg[0] <= 1'b1;
            end else begin
                ready_reg[0] <= 1'b0;
            end
        end
    end

    // Propagate through remaining stages
    integer i;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= {DWIDTH{1'b0}};
                ready_reg[i] <= 1'b0;
            end
        end else begin
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
                ready_reg[i] <= ready_reg[i-1];
            end
        end
    end

    // Output assignment
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            dout <= sync_reg[SYNC_STAGES-1];
            dready_o <= ready_reg[SYNC_STAGES-1];
        end
    end

endmodule
