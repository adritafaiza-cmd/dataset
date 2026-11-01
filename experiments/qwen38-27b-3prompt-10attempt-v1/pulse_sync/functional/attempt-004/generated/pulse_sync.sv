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

    // Domain B: level synchronizer for ack
    reg [STAGES-1:0] sync_b;
    reg ack_b;

    // Domain A: generate pulse to domain B
    wire req_a = pulseA_i & ~busy_o;
    wire req_a_reg;
    reg req_a_reg;

    // Domain B: detect rising edge of sync_b to generate pulse
    wire sync_b_last = sync_b[0];
    wire sync_b_prev;
    reg sync_b_prev;

    // Domain A: busy logic
    wire busy_a = ack_a;

    // Domain B: busy logic
    wire busy_b = ack_b;

    // busy_o is high if either domain is busy
    assign busy_o = busy_a | busy_b;

    // Domain A: register the request
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            req_a_reg <= 1'b0;
            ack_a <= 1'b0;
        end else begin
            if (req_a) begin
                req_a_reg <= 1'b1;
            end else if (ack_a) begin
                req_a_reg <= 1'b0;
            end
            ack_a <= sync_a[STAGES-1];
        end
    end

    // Domain A: synchronizer for ack from domain B
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_a <= {STAGES{1'b0}};
        end else begin
            sync_a <= {sync_a[STAGES-2:0], ack_b};
        end
    end

    // Domain B: synchronizer for req from domain A
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_b <= {STAGES{1'b0}};
            ack_b <= 1'b0;
            sync_b_prev <= 1'b0;
        end else begin
            sync_b <= {sync_b[STAGES-2:0], req_a_reg};
            sync_b_prev <= sync_b_last;
            if (sync_b_last & ~sync_b_prev) begin
                ack_b <= 1'b1;
            end else if (sync_b_last & sync_b_prev) begin
                ack_b <= 1'b0;
            end
        end
    end

    // Domain B: generate pulse on rising edge of sync_b
    assign pulseB_o = sync_b_last & ~sync_b_prev;

endmodule
