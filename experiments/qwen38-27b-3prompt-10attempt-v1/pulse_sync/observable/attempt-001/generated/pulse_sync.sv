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

    // Internal state in domain A
    reg req_pending;
    reg ack_received;

    // Internal state in domain B
    reg ack_pending;
    reg req_received;

    // busy_o is in domain A
    assign busy_o = req_pending;

    // pulseB_o is in domain B
    assign pulseB_o = req_received;

    // --- Domain A logic ---
    // Detect rising edge of ack_sync[STAGES-1] to indicate ack received
    wire ack_edge = ack_sync[STAGES-1] & ~ack_sync[STAGES-2];

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            req_pending  <= 1'b0;
            ack_received <= 1'b0;
        end else begin
            // If not busy and a pulse comes in, set req_pending
            if (!req_pending && pulseA_i) begin
                req_pending <= 1'b1;
            end
            // If ack is received, clear req_pending
            else if (req_pending && ack_edge) begin
                req_pending <= 1'b0;
            end
        end
    end

    // Synchronize req_pending from A to B
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_sync <= {STAGES{1'b0}};
        end else begin
            req_sync <= {req_sync[STAGES-2:0], req_pending};
        end
    end

    // --- Domain B logic ---
    // Detect rising edge of req_sync[STAGES-1] to indicate new request
    wire req_edge = req_sync[STAGES-1] & ~req_sync[STAGES-2];

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_received <= 1'b0;
            ack_pending  <= 1'b0;
        end else begin
            // On rising edge of synchronized request, generate pulse and set ack
            if (req_edge) begin
                req_received <= 1'b1;
                ack_pending  <= 1'b1;
            end else begin
                req_received <= 1'b0;
            end
            // Clear ack_pending after one cycle (it's used to generate ack)
            if (ack_pending) begin
                ack_pending <= 1'b0;
            end
        end
    end

    // Synchronize ack_pending from B to A
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            ack_sync <= {STAGES{1'b0}};
        end else begin
            ack_sync <= {ack_sync[STAGES-2:0], ack_pending};
        end
    end

endmodule
