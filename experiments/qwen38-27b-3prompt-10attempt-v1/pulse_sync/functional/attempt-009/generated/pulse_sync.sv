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

    // Domain A: latch the pulse and generate a level signal
    reg level_a;
    reg busy_a;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            level_a <= 1'b0;
            busy_a  <= 1'b0;
        end else begin
            if (pulseA_i && !busy_a) begin
                level_a <= 1'b1;
                busy_a  <= 1'b1;
            end else if (level_a && !busy_a) begin
                // This shouldn't happen in normal operation, but safe
                level_a <= 1'b0;
            end
        end
    end

    // Domain B: synchronize the level signal
    reg [STAGES-1:0] level_b_sync;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            level_b_sync <= {STAGES{1'b0}};
        end else begin
            level_b_sync <= {level_b_sync[STAGES-2:0], level_a};
        end
    end

    // Domain B: detect rising edge of synchronized level to generate pulse
    reg level_b_prev;
    reg busy_b;

    wire level_b = level_b_sync[STAGES-1];
    wire pulseB_o = level_b & ~level_b_prev;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            level_b_prev <= 1'b0;
            busy_b       <= 1'b0;
        end else begin
            level_b_prev <= level_b;
            if (pulseB_o) begin
                busy_b <= 1'b0;
            end else if (busy_b) begin
                busy_b <= 1'b0;
            end
        end
    end

    // Domain B: when pulse is detected, clear the level in domain A
    // We need to synchronize the clear signal back to domain A
    reg clear_b;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            clear_b <= 1'b0;
        end else begin
            if (pulseB_o) begin
                clear_b <= 1'b1;
            end else begin
                clear_b <= 1'b0;
            end
        end
    end

    // Synchronize clear signal to domain A
    reg [STAGES-1:0] clear_a_sync;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            clear_a_sync <= {STAGES{1'b0}};
        end else begin
            clear_a_sync <= {clear_a_sync[STAGES-2:0], clear_b};
        end
    end

    wire clear_a = clear_a_sync[STAGES-1];

    // Update level_a and busy_a when clear is received
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            level_a <= 1'b0;
            busy_a  <= 1'b0;
        end else begin
            if (clear_a) begin
                level_a <= 1'b0;
                busy_a  <= 1'b0;
            end else if (pulseA_i && !busy_a) begin
                level_a <= 1'b1;
                busy_a  <= 1'b1;
            end
        end
    end

    assign pulseB_o = level_b & ~level_b_prev;
    assign busy_o   = busy_b;

endmodule
