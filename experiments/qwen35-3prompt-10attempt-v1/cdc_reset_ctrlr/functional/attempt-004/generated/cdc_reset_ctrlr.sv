```verilog
module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  wire a_clk_i,
    input  wire a_rst_ni,
    input  wire a_clear_i,
    output reg  a_clear_o,
    input  wire a_clear_ack_i,
    output reg  a_isolate_o,
    input  wire a_isolate_ack_i,
    input  wire b_clk_i,
    input  wire b_rst_ni,
    input  wire b_clear_i,
    output reg  b_clear_o,
    input  wire b_clear_ack_i,
    output reg  b_isolate_o,
    input  wire b_isolate_ack_i
);

    localparam STATE_IDLE = 2'b00;
    localparam STATE_ISOLATING = 2'b01;
    localparam STATE_CLEARING = 2'b10;
    localparam STATE_DONE = 2'b11;

    // State machine for the control logic
    reg [1:0] state;
    reg [1:0] next_state;
    
    // Handshake signals for peer completion
    reg a_peer_active;
    reg a_peer_done;
    reg b_peer_active;
    reg b_peer_done;

    // Synchronizers for cross-domain signals
    // a_clear_i -> b domain
    reg [SYNC_STAGES-1:0] a_clear_sync_b;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync_b;
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync_b;
    
    // b_clear_i -> a domain
    reg [SYNC_STAGES-1:0] b_clear_sync_a;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync_a;
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync_a;

    // Peer status registers in local domains
    reg a_peer_active_reg;
    reg a_peer_done_reg;
    reg b_peer_active_reg;
    reg b_peer_done_reg;

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            state <= STATE_IDLE;
            a_clear_o <= 1'b0;
            a_isolate_o <= 1'b0;
            a_peer_active <= 1'b0;
            a_peer_done <= 1'b0;
        end else begin
            state <= next_state;
            a_clear_o <= (state == STATE_CLEARING);
            a_isolate_o <= (state == STATE_ISOLATING || state == STATE_CLEARING);
            
            // Update local peer status based on b domain signals
            a_peer_active <= b_peer_active_reg;
            a_peer_done <= b_peer_done_reg;
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            state <= STATE_IDLE;
            b_clear_o <= 1'b0;
            b_isolate_o <= 1'b0;
            b_peer_active <= 1'b0;
            b_peer_done <= 1'b0;
        end else begin
            state <= next_state;
            b_clear_o <= (state == STATE_CLEARING);
            b_isolate_o <= (state == STATE_ISOLATING || state == STATE_CLEARING);
            
            // Update local peer status based on a domain signals
            b_peer_active <= a_peer_active_reg;
            b_peer_done <= a_peer_done_reg;
        end
    end

    // Synchronizer logic for A domain inputs in B domain
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_clear_sync_b <= {SYNC_STAGES{1'b0}};
            a_clear_ack_sync_b <= {SYNC_STAGES{1'b0}};
            a_isolate_ack_sync_b <= {SYNC_STAGES{1'b0}};
        end else begin
            a_clear_sync_b <= {a_clear_sync_b[SYNC_STAGES-2:0], a_clear_i};
            a_clear_ack_sync_b <= {a_clear_ack_sync_b[SYNC_STAGES-2:0], a_clear_ack_i};
            a_isolate_ack_sync_b <= {a_isolate_ack_sync_b[SYNC_STAGES-2:0], a_isolate_ack_i};
        end
    end

    // Synchronizer logic for B domain inputs in A domain
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_clear_sync_a <= {SYNC_STAGES{1'b0}};
            b_clear_ack_sync_a <= {SYNC_STAGES{1'b0}};
            b_isolate_ack_sync_a <= {SYNC_STAGES{1'b0}};
        end else begin
            b_clear_sync_a <= {b_clear_sync_a[SYNC_STAGES-2:0], b_clear_i};
            b_clear_ack_sync_a <= {b_clear_ack_sync_a[SYNC_STAGES-2:0], b_clear_ack_i};
            b_isolate_ack_sync_a <= {b_isolate_ack_sync_a[SYNC_STAGES-2:0], b_isolate_ack_i};
        end
    end

    // Peer status registers in A domain (driven by B domain signals)
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_peer_active_reg <= 1'b0;
            a_peer_done_reg <= 1'b0;
        end else begin
            a_peer_active_reg <= a_isolate_ack_i; // Peer active when isolate ack is seen
            a_peer_done_reg <= a_clear_ack_i;     // Peer done when clear ack is seen
        end
    end

    // Peer status registers in B domain (driven by A domain signals)
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_peer_active_reg <= 1'b0;
            b_peer_done_reg <= 1'b0;
        end else begin
            b_peer_active_reg <= b_isolate_ack_i; // Peer active when isolate ack is seen
            b_peer_done_reg <= b_clear_ack_i;     // Peer done when clear ack is seen
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            STATE_IDLE: begin
                // Check if either side requests clear
                if (a_clear_i || b_clear_i) begin
                    next_state = STATE_ISOLATING;
                end
            end

            STATE_ISOLATING: begin
                // Wait for both isolate acks
                if (a_isolate_ack_i && b_isolate_ack_i) begin
                    next_state = STATE_CLEARING;
                end
            end

            STATE_CLEARING: begin
                // Wait for both clear acks
                if (a_clear_ack_i && b_clear_ack_i) begin
                    next_state = STATE_DONE;
                end
            end

            STATE_DONE: begin
                // Wait for peer completion handshake before releasing
                // Peer progress: idle -> active (isolate_ack) -> done (clear_ack) -> idle
                // We must ensure peer has reached 'done' before we go back to idle
                
                // Check if peer has completed the clear sequence
                if (a_peer_done && b_peer_done) begin
                    next_state = STATE_IDLE;
                end
            end

            default: next_state = STATE_IDLE;
        endcase
    end

endmodule
```<|im_end|>
