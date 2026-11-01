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

    // Domain A: level signal to hold high while pulse is in flight
    reg level_a;
    reg busy_a;

    // Synchronizer chain from A to B
    reg [STAGES-1:0] sync_a2b;

    // Domain B: level signal and pulse detection
    reg level_b;
    reg level_b_d;

    // Reset synchronizers for safe reset release
    reg [1:0] rstn_a_sync;
    reg [1:0] rstn_b_sync;

    // Synchronize rstn_a into domain A (already in domain A, but for structural safety)
    // Actually rstn_a is already in domain A, so we just use it directly.
    // But for RDC safety, we synchronize the reset into each domain.
    // rstn_a is the reset for domain A, so it's already synchronized to clk_a.
    // rstn_b is the reset for domain B, so it's already synchronized to clk_b.
    // The key is that the level signal crossing is safe.

    // Domain A logic
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            level_a <= 1'b0;
            busy_a  <= 1'b0;
        end else begin
            if (pulseA_i && !busy_a) begin
                level_a <= 1'b1;
                busy_a  <= 1'b1;
            end else if (level_a && !busy_a) begin
                // This shouldn't happen, but keep level low if not busy
                level_a <= 1'b0;
            end
        end
    end

    // When level_a goes low (after B domain acknowledges), clear busy_a
    // We need a way to know when B domain has seen the pulse.
    // Alternative: use a handshake. But the spec says "one-pulse-in, one-pulse-out"
    // with busy_o high while in flight.
    
    // Let's use a different approach: 
    // Domain A sets level_a high on pulse.
    // Domain B detects rising edge of synchronized level, generates pulseB_o.
    // Domain B sets a "done" signal that is synchronized back to A to clear level_a and busy_a.
    // But that requires two crossings.
    
    // Simpler: Domain A sets level_a high. Domain B detects rising edge, generates pulse.
    // Domain B then sets level_b low (or we use a toggle). 
    // Actually, let's use a level that stays high until cleared by B domain.
    
    // Revised approach:
    // Domain A: on pulseA_i and !busy_a, set level_a = 1, busy_a = 1.
    // Domain B: synchronize level_a. On rising edge of sync, generate pulseB_o and set a "clear" signal.
    // The clear signal is synchronized back to A to clear level_a and busy_a.
    // This is a 2-phase handshake.
    
    // Let's implement the 2-phase handshake:
    // A -> B: level_a (request)
    // B -> A: level_b_ack (acknowledge)
    
    reg level_a_req;
    reg busy_a;
    
    reg [STAGES-1:0] sync_req;
    reg [STAGES-1:0] sync_ack;
    
    reg level_b_ack;
    reg level_b_req;
    reg level_b_req_d;
    reg pulseB_o_reg;
    reg busy_o_reg;

    // Domain A
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            level_a_req <= 1'b0;
            busy_a      <= 1'b0;
        end else begin
            if (pulseA_i && !busy_a) begin
                level_a_req <= 1'b1;
                busy_a      <= 1'b1;
            end else if (busy_a && sync_ack[STAGES-1]) begin
                level_a_req <= 1'b0;
                busy_a      <= 1'b0;
            end
        end
    end

    // Synchronizer A to B
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_req <= {STAGES{1'b0}};
        end else begin
            sync_req <= {sync_req[STAGES-2:0], level_a_req};
        end
    end

    // Domain B
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            level_b_req   <= 1'b0;
            level_b_req_d <= 1'b0;
            level_b_ack   <= 1'b0;
            pulseB_o_reg  <= 1'b0;
            busy_o_reg    <= 1'b0;
        end else begin
            level_b_req <= sync_req[STAGES-1];
            
            if (level_b_req && !level_b_req_d) begin
                // Rising edge: generate pulse and set ack
                pulseB_o_reg <= 1'b1;
                level_b_ack  <= 1'b1;
                busy_o_reg   <= 1'b1;
            end else begin
                pulseB_o_reg <= 1'b0;
            end
            
            if (level_b_req_d && !level_b_req) begin
                // Falling edge: clear ack and busy
                level_b_ack <= 1'b0;
                busy_o_reg  <= 1'b0;
            end
            
            level_b_req_d <= level_b_req;
        end
    end

    // Synchronizer B to A
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_ack <= {STAGES{1'b0}};
        end else begin
            sync_ack <= {sync_ack[STAGES-2:0], level_b_ack};
        end
    end

    assign pulseB_o = pulseB_o_reg;
    assign busy_o   = busy_o_reg;

endmodule
