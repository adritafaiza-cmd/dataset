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

    // Domain A: handshake state
    // req_a: request to domain B (set on pulse, cleared when ack_a returns)
    // ack_a: acknowledgment from domain B (set when B sees req, cleared when B done)
    
    reg req_a;
    reg ack_a;
    
    // Domain B: handshake state
    // req_b: synchronized version of req_a
    // ack_b: acknowledgment to domain A (set when B processes, cleared when A clears req)
    
    reg req_b;
    reg ack_b;
    
    // Synchronizers for req_a -> req_b (2-stage)
    reg [1:0] req_sync;
    
    // Synchronizers for ack_b -> ack_a (2-stage)
    reg [1:0] ack_sync;
    
    // Domain A logic
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            req_a <= 1'b0;
            ack_a <= 1'b0;
        end else begin
            // Set req_a when pulse arrives and not busy
            if (pulseA_i && !req_a) begin
                req_a <= 1'b1;
            end
            // Clear req_a when ack_a is high (B has processed)
            else if (ack_a) begin
                req_a <= 1'b0;
            end
            
            // Synchronize ack_b to ack_a
            ack_a <= ack_sync[1];
        end
    end
    
    // Synchronizer for ack_b -> ack_a
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            ack_sync <= 2'b00;
        end else begin
            ack_sync <= {ack_sync[0], ack_b};
        end
    end
    
    // Domain B logic
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_b <= 1'b0;
            ack_b <= 1'b0;
        end else begin
            // Synchronize req_a to req_b
            req_b <= req_sync[1];
            
            // Set ack_b when req_b is high (B sees the request)
            if (req_b) begin
                ack_b <= 1'b1;
            end
            // Clear ack_b when req_b goes low (A has cleared req)
            else begin
                ack_b <= 1'b0;
            end
        end
    end
    
    // Synchronizer for req_a -> req_b
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_sync <= 2'b00;
        end else begin
            req_sync <= {req_sync[0], req_a};
        end
    end
    
    // Generate pulseB_o: rising edge of req_b
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
