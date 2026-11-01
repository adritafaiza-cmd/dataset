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

    // Domain A: level signal to hold until acknowledged
    reg level_a;
    reg level_a_sync1;
    reg level_a_sync2;

    // Domain B: level signal synchronized to B
    reg level_b;
    reg level_b_sync1;
    reg level_b_sync2;

    // Domain B: edge detection
    reg level_b_prev;
    wire pulseB_o;

    // Domain A: busy signal (level_a high means in flight)
    wire busy_o;

    // Synchronize level_a from A to B
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            level_a_sync1 <= 1'b0;
            level_a_sync2 <= 1'b0;
        end else begin
            level_a_sync1 <= level_a;
            level_a_sync2 <= level_a_sync1;
        end
    end

    // Synchronize level_b from B to A
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            level_b_sync1 <= 1'b0;
            level_b_sync2 <= 1'b0;
        end else begin
            level_b_sync1 <= level_b;
            level_b_sync2 <= level_b_sync1;
        end
    end

    // Domain A: set level_a on pulse if not busy
    assign busy_o = level_a;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            level_a <= 1'b0;
        end else begin
            if (pulseA_i && !level_a) begin
                level_a <= 1'b1;
            end else if (level_a && level_b_sync2) begin
                level_a <= 1'b0;
            end
        end
    end

    // Domain B: set level_b when synchronized level_a is high
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            level_b <= 1'b0;
        end else begin
            if (level_a_sync2 && !level_b) begin
                level_b <= 1'b1;
            end else if (level_b && !level_a_sync2) begin
                level_b <= 1'b0;
            end
        end
    end

    // Domain B: edge detect on level_b to produce pulse
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            level_b_prev <= 1'b0;
        end else begin
            level_b_prev <= level_b;
        end
    end

    assign pulseB_o = level_b & ~level_b_prev;

endmodule
