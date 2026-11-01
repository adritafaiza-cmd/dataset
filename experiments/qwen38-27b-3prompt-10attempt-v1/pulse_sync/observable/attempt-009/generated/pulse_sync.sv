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
    reg req_a;
    reg ack_a;
    reg busy_a;

    // Internal state in domain B
    reg req_b;
    reg ack_b;
    reg busy_b;

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
            req_a  <= 1'b0;
            ack_a  <= 1'b0;
            busy_a <= 1'b0;
        end else begin
            ack_a <= ack_sync[STAGES-1];

            if (busy_a) begin
                if (ack_a) begin
                    busy_a <= 1'b0;
                    req_a  <= 1'b0;
                end
            end else begin
                if (pulseA_i) begin
                    busy_a <= 1'b1;
                    req_a  <= 1'b1;
                end
            end
        end
    end

    // Domain B logic
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_b  <= 1'b0;
            ack_b  <= 1'b0;
            busy_b <= 1'b0;
        end else begin
            req_b <= req_sync[STAGES-1];

            if (busy_b) begin
                if (!req_b) begin
                    busy_b <= 1'b0;
                    ack_b  <= 1'b0;
                end
            end else begin
                if (req_b) begin
                    busy_b <= 1'b1;
                    ack_b  <= 1'b1;
                end
            end
        end
    end

    // Output pulse in domain B: one cycle when req_b transitions from 0 to 1
    reg req_b_d;
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            req_b_d <= 1'b0;
        else
            req_b_d <= req_b;
    end

    assign pulseB_o = req_b & ~req_b_d;
    assign busy_o   = busy_b;

endmodule
