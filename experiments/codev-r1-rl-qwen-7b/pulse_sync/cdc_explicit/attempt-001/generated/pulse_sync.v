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

    // clk_a domain signals
    reg req;
    reg [1:0] ack_sync;

    // Synchronize ack from clk_b (two stages)
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            ack_sync <= 2'b00;
        end else begin
            ack_sync <= {ack_sync[0], ack};
        end
    end

    // req logic
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            req <= 1'b0;
        end else begin
            if (pulseA_i && !req) begin
                req <= 1'b1;
            end else if (ack_sync[1]) begin
                req <= 1'b0;
            end
        end
    end

    assign busy_o = req;

    // clk_b domain signals
    reg [1:0] req_sync;
    reg req_prev;
    reg ack;

    // Synchronize req to clk_b
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_sync <= 2'b00;
        end else begin
            req_sync <= {req_sync[0], req};
        end
    end

    // Edge detection for pulseB
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_prev <= 1'b0;
        end else begin
            req_prev <= req_sync[1];
        end
    end

    assign pulseB_o = req_sync[1] && !req_prev;

    // Generate ack (registered version of pulseB)
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            ack <= 1'b0;
        end else begin
            ack <= pulseB_o;
        end
    end

endmodule
