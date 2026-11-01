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

    // Domain A: level set on pulse, cleared when domain B acknowledges
    reg level_a;
    reg ack_a;
    reg ack_a_d1;
    reg ack_a_d2;

    // Domain B: level set when synchronized level_a is high, cleared on pulse
    reg level_b;
    reg ack_b;
    reg ack_b_d1;
    reg ack_b_d2;

    // Synchronize level_a into domain B
    reg level_a_sync1;
    reg level_a_sync2;

    // Synchronize ack_b into domain A
    reg ack_b_sync1;
    reg ack_b_sync2;

    // Domain A logic
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            level_a <= 1'b0;
            ack_a   <= 1'b0;
        end else begin
            // Set level_a on pulse if not already busy
            if (pulseA_i && !level_a)
                level_a <= 1'b1;
            // Clear level_a when ack_b is synchronized back
            if (ack_b_sync2)
                level_a <= 1'b0;
        end
    end

    // Synchronize ack_b into domain A
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            ack_b_sync1 <= 1'b0;
            ack_b_sync2 <= 1'b0;
        end else begin
            ack_b_sync1 <= ack_b;
            ack_b_sync2 <= ack_b_sync1;
        end
    end

    // Synchronize level_a into domain B
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            level_a_sync1 <= 1'b0;
            level_a_sync2 <= 1'b0;
        end else begin
            level_a_sync1 <= level_a;
            level_a_sync2 <= level_a_sync1;
        end
    end

    // Domain B logic
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            level_b <= 1'b0;
            ack_b   <= 1'b0;
        end else begin
            // Set level_b when synchronized level_a is high
            if (level_a_sync2 && !level_b)
                level_b <= 1'b1;
            // Clear level_b and set ack_b when level_b is high (pulse out)
            if (level_b) begin
                level_b <= 1'b0;
                ack_b   <= 1'b1;
            end
            // Clear ack_b when level_b is low and ack_b was set
            if (!level_b && ack_b)
                ack_b   <= 1'b0;
        end
    end

    // Outputs
    assign pulseB_o = level_b;
    assign busy_o   = level_a;

endmodule
