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

    // Internal signals
    reg [STAGES-1:0] sync_reg_a;
    reg [STAGES-1:0] sync_reg_b;
    reg              pulseA_synced;
    reg              pulseA_edge;
    reg              fifo_wr_en;
    reg              fifo_rd_en;
    reg              fifo_full;
    reg              fifo_empty;
    reg              pulseB_reg;
    reg              pulseB_o_reg;

    // Synchronizer for pulseA_i to clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_reg_a <= {STAGES{1'b0}};
        end else begin
            sync_reg_a <= {sync_reg_a[STAGES-2:0], pulseA_i};
        end
    end

    // Detect rising edge of pulseA_i in clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulseA_edge <= 1'b0;
        end else begin
            pulseA_edge <= sync_reg_a[0] & ~sync_reg_a[1];
        end
    end

    // Write enable for FIFO
    assign fifo_wr_en = pulseA_edge & ~fifo_full;

    // FIFO for pulse synchronization
    async_fifo #(
        .STAGES(STAGES)
    ) fifo_inst (
        .clk_a    (clk_a),
        .rstn_a   (rstn_a),
        .clk_b    (clk_b),
        .rstn_b   (rstn_b),
        .data_in  (fifo_wr_en),
        .data_out (pulseB_reg),
        .full     (fifo_full)
    );

    // Synchronizer for fifo_empty to clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_reg_b <= {STAGES{1'b0}};
        end else begin
            sync_reg_b <= {sync_reg_b[STAGES-2:0], fifo_empty};
        end
    end

    // Read enable for FIFO
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            fifo_rd_en <= 1'b0;
        end else begin
            fifo_rd_en <= ~sync_reg_b[0];
        end
    end

    // Generate pulseB_o for one cycle
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o_reg <= 1'b0;
        end else if (pulseB_reg) begin
            pulseB_o_reg <= 1'b1;
        end else begin
            pulseB_o_reg <= 1'b0;
        end
    end

    // Output assignments
    assign pulseB_o = pulseB_o_reg;
    assign busy_o   = ~fifo_empty;

endmodule

module async_fifo #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  data_in,
    output data_out,
    output full
);

    // Internal signals
    reg [STAGES-1:0] sync_reg_a;
    reg [STAGES-1:0] sync_reg_b;
    reg              fifo_din;
    reg              fifo_dout;
    reg              fifo_full_reg;
    reg              fifo_empty_reg;

    // FIFO storage
    reg              fifo_mem;

    // Write enable for FIFO
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            fifo_full_reg <= 1'b0;
        end else if (data_in & ~fifo_full_reg) begin
            fifo_full_reg <= 1'b1;
            fifo_mem      <= data_in;
        end else if (fifo_rd_en) begin
            fifo_full_reg <= 1'b0;
        end
    end

    // Read enable for FIFO
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            fifo_empty_reg <= 1'b1;
        end else if (fifo_wr_en) begin
            fifo_empty_reg <= 1'b0;
        end else if (fifo_rd_en & ~fifo_empty_reg) begin
            fifo_empty_reg <= 1'b1;
        end
    end

    // Synchronizer for fifo_empty to clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_reg_a <= {STAGES{1'b0}};
        end else begin
            sync_reg_a <= {sync_reg_a[STAGES-2:0], fifo_empty_reg};
        end
    end

    // Synchronizer for fifo_full to clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_reg_b <= {STAGES{1'b0}};
        end else begin
            sync_reg_b <= {sync_reg_b[STAGES-2:0], fifo_full_reg};
        end
    end

    // Output assignments
    assign fifo_empty = sync_reg_a[0];
    assign fifo_full  = sync_reg_b[0];
    assign data_out   = fifo_mem;

endmodule
