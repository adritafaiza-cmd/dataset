module pulse_sync #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  pulseA_i,
    output pulseB_o,
    output busy_o
);

reg [STAGES-1:0] fifo_wr;
reg [STAGES-1:0] fifo_rd;
reg [STAGES-1:0] fifo_wr_sync;
reg [STAGES-1:0] fifo_rd_sync;

reg pulseA_i_sync;

always @(posedge clk_a or negedge rstn_a) begin
    if (!rstn_a) begin
        fifo_wr <= 0;
        pulseA_i_sync <= 0;
    end else begin
        pulseA_i_sync <= pulseA_i;
        if (pulseA_i_sync && !fifo_wr[0]) begin
            fifo_wr <= {fifo_wr[STAGES-2:0], 1'b1};
        end
    end
end

always @(posedge clk_b or negedge rstn_b) begin
    if (!rstn_b) begin
        fifo_rd <= 0;
    end else begin
        if (fifo_wr_sync[0] && !fifo_rd[0]) begin
            fifo_rd <= {fifo_rd[STAGES-2:0], 1'b1};
        end else if (fifo_rd[0]) begin
            fifo_rd <= {fifo_rd[STAGES-2:0], 1'b0};
        end
    end
end

always @(posedge clk_a or negedge rstn_a) begin
    if (!rstn_a) begin
        fifo_wr_sync <= 0;
    end else begin
        fifo_wr_sync <= fifo_wr;
    end
end

always @(posedge clk_b or negedge rstn_b) begin
    if (!rstn_b) begin
        fifo_rd_sync <= 0;
    end else begin
        fifo_rd_sync <= fifo_rd;
    end
end

assign busy_o = fifo_wr_sync[STAGES-1] | fifo_rd_sync[STAGES-1];
assign pulseB_o = fifo_wr_sync[0] & ~fifo_rd_sync[0];

endmodule
