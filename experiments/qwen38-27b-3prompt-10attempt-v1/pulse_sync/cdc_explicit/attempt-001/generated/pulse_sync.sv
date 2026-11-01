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
    integer i;
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            sync_a <= {STAGES{1'b0}};
        else begin
            sync_a[0] <= pulseA_i;
            for (i = 1; i < STAGES; i = i + 1)
                sync_a[i] <= sync_a[i-1];
        end
    end

    // Domain B: level synchronizer
    reg [STAGES-1:0] sync_b;
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            sync_b <= {STAGES{1'b0}};
        else begin
            sync_b[0] <= sync_a[STAGES-1];
            for (i = 1; i < STAGES; i = i + 1)
                sync_b[i] <= sync_b[i-1];
        end
    end

    // Domain B: pulse detection and busy flag
    reg busy_b;
    reg pulse_b;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            busy_b  <= 1'b0;
            pulse_b <= 1'b0;
        end else begin
            if (sync_b[STAGES-1] && !busy_b) begin
                busy_b  <= 1'b1;
                pulse_b <= 1'b1;
            end else if (busy_b) begin
                busy_b  <= 1'b0;
                pulse_b <= 1'b0;
            end else begin
                pulse_b <= 1'b0;
            end
        end
    end

    assign pulseB_o = pulse_b;
    assign busy_o   = busy_b;

endmodule
