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
    reg ack_a;

    // Domain B: level synchronizer
    reg [STAGES-1:0] sync_b;
    reg ack_b;

    // Busy flag in domain A
    reg busy_a;

    // Generate pulseB_o in domain B
    wire pulseB_o;
    wire busy_o;

    // Domain A logic
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_a <= {STAGES{1'b0}};
            ack_a  <= 1'b0;
            busy_a <= 1'b0;
        end else begin
            // Synchronize ack_b from domain B
            sync_a <= {sync_a[STAGES-2:0], ack_b};

            // Detect rising edge of synchronized ack_b to clear busy
            if (sync_a[STAGES-1] && !sync_a[STAGES-2]) begin
                busy_a <= 1'b0;
            end

            // Set busy when pulseA_i arrives and not already busy
            if (pulseA_i && !busy_a) begin
                busy_a <= 1'b1;
            end
        end
    end

    // Drive ack_a to domain B when busy
    assign ack_a = busy_a;

    // Domain B logic
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_b <= {STAGES{1'b0}};
            ack_b  <= 1'b0;
        end else begin
            // Synchronize ack_a from domain A
            sync_b <= {sync_b[STAGES-2:0], ack_a};

            // Detect rising edge of synchronized ack_a to generate pulseB_o
            if (sync_b[STAGES-1] && !sync_b[STAGES-2]) begin
                ack_b <= 1'b1;
            end

            // Detect falling edge of synchronized ack_a to clear ack_b
            if (!sync_b[STAGES-1] && sync_b[STAGES-2]) begin
                ack_b <= 1'b0;
            end
        end
    end

    // pulseB_o is a one-cycle pulse on the rising edge of sync_b[STAGES-1]
    assign pulseB_o = sync_b[STAGES-1] && !sync_b[STAGES-2];

    // busy_o is high while a pulse is in flight (in domain B, mirror of busy_a)
    assign busy_o = ack_b;

endmodule
