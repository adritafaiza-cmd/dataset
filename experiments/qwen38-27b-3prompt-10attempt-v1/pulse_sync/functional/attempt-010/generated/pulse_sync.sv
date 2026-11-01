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

    // Domain A: handshake request
    reg req_a;
    reg ack_a;

    // Domain B: handshake response
    reg req_b;
    reg ack_b;

    // Synchronizers
    reg [STAGES-1:0] req_sync;
    reg [STAGES-1:0] ack_sync;

    // Generate pulseB_o from req_b edge
    reg req_b_d;
    wire pulseB_o = req_b & ~req_b_d;

    // busy_o is high when req_a is asserted (pulse in flight)
    assign busy_o = req_a;

    // Domain A logic
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            req_a <= 1'b0;
            ack_a <= 1'b0;
        end else begin
            if (pulseA_i && !req_a && !ack_a)
                req_a <= 1'b1;
            if (req_a && ack_a) begin
                req_a <= 1'b0;
                ack_a <= 1'b0;
            end
        end
    end

    // Synchronize req_a to domain B
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            req_sync <= {STAGES{1'b0}};
        else
            req_sync <= {req_sync[STAGES-2:0], req_a};
    end

    // Domain B logic
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_b <= 1'b0;
            ack_b <= 1'b0;
            req_b_d <= 1'b0;
        end else begin
            req_b <= req_sync[STAGES-1];
            req_b_d <= req_b;

            if (req_b && !ack_b)
                ack_b <= 1'b1;
            if (req_b && ack_b) begin
                req_b <= 1'b0;
                ack_b <= 1'b0;
            end
        end
    end

    // Synchronize ack_b to domain A
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            ack_sync <= {STAGES{1'b0}};
        else
            ack_sync <= {ack_sync[STAGES-2:0], ack_b};
    end

    // Update ack_a from synchronized ack_b
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            ack_a <= 1'b0;
        else
            ack_a <= ack_sync[STAGES-1];
    end

endmodule
