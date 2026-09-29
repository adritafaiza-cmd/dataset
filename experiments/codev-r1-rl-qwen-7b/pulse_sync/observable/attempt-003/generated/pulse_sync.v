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
    reg [1:0] sync_ack;

    // clk_b domain signals
    reg [1:0] sync_req;
    reg sync_req_prev;
    reg ack;

    // Synchronize ack from clk_b to clk_a
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_ack <= 0;
        end else begin
            sync_ack <= {sync_ack[0], ack};
        end
    end

    // Set request when pulse arrives and not busy
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            req <= 0;
        end else begin
            if (pulseA_i && !req) begin
                req <= 1;
            end else if (sync_ack[1]) begin
                req <= 0;
            end
        end
    end

    assign busy_o = req;

    // Synchronize req to clk_b
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_req <= 0;
        end else begin
            sync_req <= {sync_req[0], req};
        end
    end

    // Edge detection for pulseB
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_req_prev <= 0;
        end else begin
            sync_req_prev <= sync_req[1];
        end
    end

    wire pulseB = sync_req[1] && !sync_req_prev;

    // Generate ack in clk_b
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            ack <= 0;
        end else begin
            if (pulseB) begin
                ack <= 1;
            end else if (!sync_req[1]) begin
                ack <= 0;
            end
        end
    end

    assign pulseB_o = pulseB;

endmodule
