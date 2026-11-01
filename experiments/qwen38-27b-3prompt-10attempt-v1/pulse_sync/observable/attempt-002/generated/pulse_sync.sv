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

    // Synchronizer registers for the request signal (A -> B)
    reg [STAGES-1:0] req_sync;

    // Synchronizer registers for the acknowledge signal (B -> A)
    reg [STAGES-1:0] ack_sync;

    // State in domain A
    reg req_a;
    reg ack_a;

    // State in domain B
    reg req_b;
    reg ack_b;

    // Synchronize request from A to B
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            req_sync <= {STAGES{1'b0}};
        else
            req_sync <= {req_sync[STAGES-2:0], req_a};
    end

    // Synchronize acknowledge from B to A
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            ack_sync <= {STAGES{1'b0}};
        else
            ack_sync <= {ack_sync[STAGES-2:0], ack_b};
    end

    // Domain A logic
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            req_a <= 1'b0;
            ack_a <= 1'b0;
        end else begin
            ack_a <= ack_sync[STAGES-1];
            if (pulseA_i && !req_a && !ack_a)
                req_a <= 1'b1;
            else if (ack_a && req_a)
                req_a <= 1'b0;
        end
    end

    // Domain B logic
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_b <= 1'b0;
            ack_b <= 1'b0;
        end else begin
            req_b <= req_sync[STAGES-1];
            if (req_b && !ack_b)
                ack_b <= 1'b1;
            else if (!req_b && ack_b)
                ack_b <= 1'b0;
        end
    end

    // Outputs
    assign pulseB_o = req_b && !ack_b;
    assign busy_o   = req_a;

endmodule
