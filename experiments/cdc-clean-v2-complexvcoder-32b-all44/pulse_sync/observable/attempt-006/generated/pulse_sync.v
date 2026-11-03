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

    wire pulseB_raw;
    reg  pulseB_synced;

    // Instantiate the asynchronous crosser module
    async_crosser #(
        .STAGES(STAGES)
    ) crosser (
        .clk_a(clk_a),
        .rstn_a(rstn_a),
        .clk_b(clk_b),
        .rstn_b(rstn_b),
        .pulse_i(pulseA_i),
        .pulse_o(pulseB_raw)
    );

    // Synchronize the pulseB_raw signal to clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_synced <= 0;
        end else begin
            pulseB_synced <= pulseB_raw;
        end
    end

    // Instantiate the busy flag module
    busy_flag busy_flag_inst (
        .clk_a(clk_a),
        .rstn_a(rstn_a),
        .pulse_i(pulseA_i),
        .busy_o(busy_o)
    );

    // Generate pulseB_o on the rising edge of pulseB_synced
    reg pulseB_synced_reg;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_synced_reg <= 0;
            pulseB_o <= 0;
        end else begin
            pulseB_synced_reg <= pulseB_synced;
            if (pulseB_synced && !pulseB_synced_reg) begin
                pulseB_o <= 1;
            end else begin
                pulseB_o <= 0;
            end
        end
    end

endmodule

module async_crosser #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  pulse_i,
    output pulse_o
);

    reg [STAGES-1:0] sync_reg;

    // Synchronize pulse_i from clk_a to clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_reg <= 0;
        end else begin
            sync_reg[0] <= pulse_i;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    // Generate pulse_o on the rising edge of the synchronized signal
    reg sync_reg_reg;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_reg_reg <= 0;
            pulse_o <= 0;
        end else begin
            sync_reg_reg <= sync_reg[STAGES-1];
            if (sync_reg[STAGES-1] && !sync_reg_reg) begin
                pulse_o <= 1;
            end else begin
                pulse_o <= 0;
            end
        end
    end

endmodule

module busy_flag (
    input  clk_a,
    input  rstn_a,
    input  pulse_i,
    output busy_o
);

    reg busy_reg;

    // Set busy flag on pulse_i and clear it when pulse has been crossed
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            busy_reg <= 0;
        end else if (pulse_i) begin
            busy_reg <= 1;
        end else if (busy_reg) begin // Assuming some condition to clear busy, here we just keep it simple
            busy_reg <= 0;
        end
    end

    assign busy_o = busy_reg;

endmodule
