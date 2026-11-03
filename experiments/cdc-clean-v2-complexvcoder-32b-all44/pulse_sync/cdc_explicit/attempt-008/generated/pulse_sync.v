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
    reg [STAGES-1:0] pulseA_synced;
    reg [STAGES-1:0] pulseB_synced;
    reg pulseA_edge;
    reg pulseA_pulse;
    reg pulseA_pulse_reg;
    reg pulseA_pulse_reg_reg;
    reg pulseB_pulse;
    reg pulseB_pulse_reg;
    reg pulseB_pulse_reg_reg;
    reg busy;

    // Asynchronous FIFO to cross pulseA_i from clk_a to clk_b
    async_ffs #(.STAGES(STAGES)) ffs_a2b (
        .clk_a(clk_a),
        .rstn_a(rstn_a),
        .clk_b(clk_b),
        .rstn_b(rstn_b),
        .data_in(pulseA_i),
        .data_out(pulseA_synced[0])
    );

    // Generate synced pulseA signal
    generate
        genvar i;
        for (i = 0; i < STAGES-1; i = i + 1) begin : gen_sync_chain_a2b
            always @(posedge clk_b or negedge rstn_b) begin
                if (!rstn_b) begin
                    pulseA_synced[i+1] <= 1'b0;
                end else begin
                    pulseA_synced[i+1] <= pulseA_synced[i];
                end
            end
        end
    endgenerate

    // Detect edge of synced pulseA signal
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseA_edge <= 1'b0;
        end else begin
            pulseA_edge <= pulseA_synced[STAGES-1] & ~pulseA_synced[STAGES-2];
        end
    end

    // Generate pulseB signal
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_pulse <= 1'b0;
        end else if (pulseA_edge) begin
            pulseB_pulse <= 1'b1;
        end else begin
            pulseB_pulse <= 1'b0;
        end
    end

    // Register pulseB signal
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_pulse_reg <= 1'b0;
        end else begin
            pulseB_pulse_reg <= pulseB_pulse;
        end
    end

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_pulse_reg_reg <= 1'b0;
        end else begin
            pulseB_pulse_reg_reg <= pulseB_pulse_reg;
        end
    end

    // Assign pulseB_o
    assign pulseB_o = pulseB_pulse_reg & ~pulseB_pulse_reg_reg;

    // Asynchronous FIFO to cross pulseB_o from clk_b to clk_a
    async_ffs #(.STAGES(STAGES)) ffs_b2a (
        .clk_a(clk_b),
        .rstn_a(rstn_b),
        .clk_b(clk_a),
        .rstn_b(rstn_a),
        .data_in(pulseB_o),
        .data_out(pulseB_synced[0])
    );

    // Generate synced pulseB signal
    generate
        genvar j;
        for (j = 0; j < STAGES-1; j = j + 1) begin : gen_sync_chain_b2a
            always @(posedge clk_a or negedge rstn_a) begin
                if (!rstn_a) begin
                    pulseB_synced[j+1] <= 1'b0;
                end else begin
                    pulseB_synced[j+1] <= pulseB_synced[j];
                end
            end
        end
    endgenerate

    // Generate busy signal
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            busy <= 1'b0;
        end else if (pulseA_i) begin
            busy <= 1'b1;
        end else if (pulseB_synced[STAGES-1]) begin
            busy <= 1'b0;
        end
    end

    assign busy_o = busy;

endmodule

module async_ffs #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  data_in,
    output reg data_out
);

    reg [STAGES-1:0] sync_chain;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_chain <= {STAGES{1'b0}};
        end else begin
            sync_chain[0] <= data_in;
            sync_chain[1:STAGES-1] <= sync_chain[0:STAGES-2];
        end
    end

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            data_out <= 1'b0;
        end else begin
            data_out <= sync_chain[STAGES-1];
        end
    end

endmodule
