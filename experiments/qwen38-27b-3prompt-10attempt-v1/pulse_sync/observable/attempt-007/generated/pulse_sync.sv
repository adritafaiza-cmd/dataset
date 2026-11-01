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

    // Synchronizer for pulseA_i into clk_b domain
    reg [STAGES-1:0] sync_reg;
    reg sync_d;
    reg sync_q;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_reg <= {STAGES{1'b0}};
            sync_d   <= 1'b0;
            sync_q   <= 1'b0;
        end else begin
            sync_reg <= {sync_reg[STAGES-2:0], pulseA_i};
            sync_d   <= sync_reg[STAGES-1];
            sync_q   <= sync_d;
        end
    end

    // Detect rising edge of synchronized signal
    wire sync_rise = sync_d & ~sync_q;

    // Busy flag in clk_b domain
    reg busy_b;
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            busy_b <= 1'b0;
        else if (sync_rise && !busy_b)
            busy_b <= 1'b1;
        else if (busy_b && !sync_rise)
            busy_b <= 1'b0;
    end

    // Generate one-pulse output in clk_b domain
    reg pulseB_reg;
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            pulseB_reg <= 1'b0;
        else if (sync_rise && !busy_b)
            pulseB_reg <= 1'b1;
        else
            pulseB_reg <= 1'b0;
    end

    // Synchronize busy_b back to clk_a domain
    reg [STAGES-1:0] busy_sync_reg;
    reg busy_sync_d;
    reg busy_sync_q;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            busy_sync_reg <= {STAGES{1'b0}};
            busy_sync_d   <= 1'b0;
            busy_sync_q   <= 1'b0;
        end else begin
            busy_sync_reg <= {busy_sync_reg[STAGES-2:0], busy_b};
            busy_sync_d   <= busy_sync_reg[STAGES-1];
            busy_sync_q   <= busy_sync_d;
        end
    end

    // Busy output in clk_a domain
    reg busy_a;
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            busy_a <= 1'b0;
        else if (busy_sync_q)
            busy_a <= 1'b1;
        else if (!busy_sync_q && !pulseA_i)
            busy_a <= 1'b0;
    end

    // Detect falling edge of busy_sync_q to clear busy_a
    wire busy_sync_fall = ~busy_sync_q & busy_sync_d;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            busy_a <= 1'b0;
        else if (busy_sync_q)
            busy_a <= 1'b1;
        else if (busy_sync_fall)
            busy_a <= 1'b0;
    end

    assign pulseB_o = pulseB_reg;
    assign busy_o   = busy_a;

endmodule
