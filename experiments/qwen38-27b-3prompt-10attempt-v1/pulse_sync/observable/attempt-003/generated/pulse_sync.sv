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

    // Internal signals
    wire req_b;   // Request seen in domain B
    wire ack_a;   // Acknowledge seen in domain A
    wire busy_b;  // Busy in domain B
    wire busy_a;  // Busy in domain A

    // Synchronize request from A to B
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            req_sync <= {STAGES{1'b0}};
        else begin
            req_sync[0] <= pulseA_i;
            for (integer i = 1; i < STAGES; i = i + 1)
                req_sync[i] <= req_sync[i-1];
        end
    end
    assign req_b = req_sync[STAGES-1];

    // Synchronize acknowledge from B to A
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            ack_sync <= {STAGES{1'b0}};
        else begin
            ack_sync[0] <= busy_b;
            for (integer i = 1; i < STAGES; i = i + 1)
                ack_sync[i] <= ack_sync[i-1];
        end
    end
    assign ack_a = ack_sync[STAGES-1];

    // Domain B: detect rising edge of req_b, generate pulseB_o and busy_b
    reg req_b_d;
    reg busy_b_reg;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_b_d    <= 1'b0;
            busy_b_reg <= 1'b0;
        end else begin
            req_b_d <= req_b;
            if (req_b && !req_b_d && !busy_b_reg) begin
                busy_b_reg <= 1'b1;
            end else if (busy_b_reg && ack_a) begin
                busy_b_reg <= 1'b0;
            end
        end
    end

    assign pulseB_o = req_b && !req_b_d && !busy_b_reg;
    assign busy_b   = busy_b_reg;

    // Domain A: busy_o indicates when a pulse is in flight
    // busy_o is high when we have sent a request but haven't received ack yet
    // We track this by looking at pulseA_i and ack_a
    reg busy_a_reg;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            busy_a_reg <= 1'b0;
        else begin
            if (pulseA_i && !busy_a_reg)
                busy_a_reg <= 1'b1;
            else if (busy_a_reg && ack_a)
                busy_a_reg <= 1'b0;
        end
    end

    assign busy_o = busy_a_reg;

endmodule
