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

    // Domain A: level synchronizer
    reg [STAGES-1:0] sync_a;
    reg             level_a;

    // Domain B: level synchronizer
    reg [STAGES-1:0] sync_b;
    reg             level_b;
    reg             level_b_d;

    // Generate pulseB_o by detecting rising edge of level_b
    assign pulseB_o = level_b & ~level_b_d;

    // busy_o is high while a pulse is in flight (level_a is high)
    assign busy_o = level_a;

    // Domain A logic
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_a  <= {STAGES{1'b0}};
            level_a <= 1'b0;
        end else begin
            // Shift register for synchronization
            sync_a <= {sync_a[STAGES-2:0], level_a};
            
            // Set level_a when pulseA_i is high and not busy
            // Clear level_a when it has been synchronized to domain B
            if (pulseA_i && !level_a)
                level_a <= 1'b1;
            else if (sync_a[STAGES-1] && !level_a)
                level_a <= 1'b0;
        end
    end

    // Domain B logic
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_b    <= {STAGES{1'b0}};
            level_b   <= 1'b0;
            level_b_d <= 1'b0;
        end else begin
            // Shift register for synchronization
            sync_b <= {sync_b[STAGES-2:0], level_b};
            
            // Set level_b when level_a has been synchronized
            // Clear level_b when it has been synchronized back to domain A
            if (sync_b[STAGES-1] && !level_b)
                level_b <= 1'b1;
            else if (sync_a[STAGES-1] && !level_b)
                level_b <= 1'b0;
            
            level_b_d <= level_b;
        end
    end

endmodule
