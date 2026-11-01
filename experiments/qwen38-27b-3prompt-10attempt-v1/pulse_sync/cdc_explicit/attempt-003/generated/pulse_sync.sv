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

    // Domain B: handshake acknowledge
    reg req_b;
    reg ack_b;

    // Synchronizers for req (A -> B)
    reg [STAGES-1:0] req_sync;

    // Synchronizers for ack (B -> A)
    reg [STAGES-1:0] ack_sync;

    // Domain A logic
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            req_a <= 1'b0;
            ack_a <= 1'b0;
        end else begin
            // Detect ack from domain B (synchronized)
            ack_a <= ack_sync[STAGES-1];

            // Generate request when pulse arrives and not already requesting
            if (pulseA_i && !req_a) begin
                req_a <= 1'b1;
            end else if (ack_a) begin
                req_a <= 1'b0;
            end
        end
    end

    // Synchronize req_a from domain A to domain B
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_sync <= {STAGES{1'b0}};
        end else begin
            req_sync <= {req_sync[STAGES-2:0], req_a};
        end
    end

    // Domain B logic
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_b <= 1'b0;
            ack_b <= 1'b0;
        end else begin
            // Detect req from domain A (synchronized)
            req_b <= req_sync[STAGES-1];

            // Generate acknowledge when request is seen
            if (req_b && !ack_b) begin
                ack_b <= 1'b1;
            end else if (!req_b) begin
                ack_b <= 1'b0;
            end
        end
    end

    // Synchronize ack_b from domain B to domain A
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            ack_sync <= {STAGES{1'b0}};
        end else begin
            ack_sync <= {ack_sync[STAGES-2:0], ack_b};
        end
    end

    // Generate pulseB_o: one-cycle pulse when req_b transitions from 0 to 1
    reg req_b_prev;
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_b_prev <= 1'b0;
        end else begin
            req_b_prev <= req_b;
        end
    end

    assign pulseB_o = req_b & ~req_b_prev;

    // busy_o is high while a pulse is in flight (req_a is high in domain A)
    assign busy_o = req_a;

endmodule
