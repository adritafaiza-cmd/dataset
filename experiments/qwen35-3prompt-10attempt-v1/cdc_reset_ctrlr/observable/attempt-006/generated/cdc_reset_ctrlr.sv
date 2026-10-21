```verilog
module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  a_clk_i,
    input  a_rst_ni,
    input  a_clear_i,
    output a_clear_o,
    input  a_clear_ack_i,
    output a_isolate_o,
    input  a_isolate_ack_i,
    input  b_clk_i,
    input  b_rst_ni,
    input  b_clear_i,
    output b_clear_o,
    input  b_clear_ack_i,
    output b_isolate_o,
    input  b_isolate_ack_i
);

    // ------------------------------------------------------------------
    // CDC Logic: Cross Clock Domain Signals
    // ------------------------------------------------------------------
    
    // Signals from Domain A to Domain B
    wire a_clear_req;
    wire a_isolate_req;
    wire a_clear_ack;
    wire a_isolate_ack;
    
    // Signals from Domain B to Domain A
    wire b_clear_req;
    wire b_isolate_req;
    wire b_clear_ack;
    wire b_isolate_ack;

    // Synchronizers for A -> B
    reg [SYNC_STAGES-1:0] a_clear_req_sync_b;
    reg [SYNC_STAGES-1:0] a_isolate_req_sync_b;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync_b;
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync_b;

    // Synchronizers for B -> A
    reg [SYNC_STAGES-1:0] b_clear_req_sync_a;
    reg [SYNC_STAGES-1:0] b_isolate_req_sync_a;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync_a;
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync_a;

    // ------------------------------------------------------------------
    // CDC Generation: A -> B
    // ------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_a_to_b
            always @(posedge a_clk_i or negedge a_rst_ni) begin
                if (!a_rst_ni)
                    a_clear_req_sync_b[i] <= 1'b0;
                else if (i == 0)
                    a_clear_req_sync_b[i] <= a_clear_req;
                else
                    a_clear_req_sync_b[i] <= a_clear_req_sync_b[i-1];
            end

            always @(posedge a_clk_i or negedge a_rst_ni) begin
                if (!a_rst_ni)
                    a_isolate_req_sync_b[i] <= 1'b0;
                else if (i == 0)
                    a_isolate_req_sync_b[i] <= a_isolate_req;
                else
                    a_isolate_req_sync_b[i] <= a_isolate_req_sync_b[i-1];
            end

            always @(posedge a_clk_i or negedge a_rst_ni) begin
                if (!a_rst_ni)
                    a_clear_ack_sync_b[i] <= 1'b0;
                else if (i == 0)
                    a_clear_ack_sync_b[i] <= a_clear_ack;
                else
                    a_clear_ack_sync_b[i] <= a_clear_ack_sync_b[i-1];
            end

            always @(posedge a_clk_i or negedge a_rst_ni) begin
                if (!a_rst_ni)
                    a_isolate_ack_sync_b[i] <= 1'b0;
                else if (i == 0)
                    a_isolate_ack_sync_b[i] <= a_isolate_ack;
                else
                    a_isolate_ack_sync_b[i] <= a_isolate_ack_sync_b[i-1];
            end
        end
    endgenerate

    // ------------------------------------------------------------------
    // CDC Generation: B -> A
    // ------------------------------------------------------------------
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_b_to_a
            always @(posedge b_clk_i or negedge b_rst_ni) begin
                if (!b_rst_ni)
                    b_clear_req_sync_a[i] <= 1'b0;
                else if (i == 0)
                    b_clear_req_sync_a[i] <= b_clear_req;
                else
                    b_clear_req_sync_a[i] <= b_clear_req_sync_a[i-1];
            end

            always @(posedge b_clk_i or negedge b_rst_ni) begin
                if (!b_rst_ni)
                    b_isolate_req_sync_a[i] <= 1'b0;
                else if (i == 0)
                    b_isolate_req_sync_a[i] <= b_isolate_req;
                else
                    b_isolate_req_sync_a[i] <= b_isolate_req_sync_a[i-1];
            end

            always @(posedge b_clk_i or negedge b_rst_ni) begin
                if (!b_rst_ni)
                    b_clear_ack_sync_a[i] <= 1'b0;
                else if (i == 0)
                    b_clear_ack_sync_a[i] <= b_clear_ack;
                else
                    b_clear_ack_sync_a[i] <= b_clear_ack_sync_a[i-1];
            end

            always @(posedge b_clk_i or negedge b_rst_ni) begin
                if (!b_rst_ni)
                    b_isolate_ack_sync_a[i] <= 1'b0;
                else if (i == 0)
                    b_isolate_ack_sync_a[i] <= b_isolate_ack;
                else
                    b_isolate_ack_sync_a[i] <= b_isolate_ack_sync_a[i-1];
            end
        end
    endgenerate

    // ------------------------------------------------------------------
    // Control Logic: Domain A
    // ------------------------------------------------------------------
    
    // Local State Machine for Domain A
    // States: IDLE, ISOLATING, CLEARING, DONE
    // We use a simple state machine to manage the handshake protocol.
    // Protocol:
    // 1. Request Isolate (if not already isolated)
    // 2. Wait for Peer Isolate Ack
    // 3. Request Clear (if not already clearing)
    // 4. Wait for Peer Clear Ack
    // 5. Release Clear
    // 6. Release Isolate
    
    // Inputs to FSM
    wire a_clear_req_local;
    wire a_isolate_req_local;
    wire a_clear_ack_local;
    wire a_isolate_ack_local;
    
    // Synchronized inputs from B
    wire b_clear_req_synced;
    wire b_isolate_req_synced;
    wire b_clear_ack_synced;
    wire b_isolate_ack_synced;

    assign a_clear_req_local = a_clear_i;
    assign a_isolate_req_local = a_clear_i; // Isolate is triggered by clear request
    assign a_clear_ack_local = a_clear_ack_i;
    assign a_isolate_ack_local = a_isolate_ack_i;

    assign b_clear_req_synced = a_clear_req_sync_b[SYNC_STAGES-1];
    assign b_isolate_req_synced = a_isolate_req_sync_b[SYNC_STAGES-1];
    assign b_clear_ack_synced = a_clear_ack_sync_b[SYNC_STAGES-1];
    assign b_isolate_ack_synced = a_isolate_ack_sync_b[SYNC_STAGES-1];

    reg [2:0] a_state;
    reg a_state_isolate_pending;
    reg a_state_clear_pending;
    reg a_state_peer_isolate_ack;
    reg a_state_peer_clear_ack;
    reg a_state_peer_isolate_req_seen;
    reg a_state_peer_clear_req_seen;

    parameter IDLE = 3'b000;
    parameter ISOLATING = 3'b001;
    parameter CLEARING = 3'b010;
    parameter DONE = 3'b011;

    // Output registers
    reg a_clear_o_reg;
    reg a_isolate_o_reg;

    // State Register
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= IDLE;
            a_state_isolate_pending <= 1'b0;
            a_state_clear_pending <= 1'b0;
            a_state_peer_isolate_ack <= 1'b0;
            a_state_peer_clear_ack <= 1'b0;
            a_state_peer_isolate_req_seen <= 1'b0;
            a_state_peer_clear_req_seen <= 1'b0;
            a_clear_o_reg <= 1'b1;
            a_isolate_o_reg <= 1'b0;
        end
        else begin
            a_state <= next_state_a;
            a_state_isolate_pending <= next_isolate_pending_a;
            a_state_clear_pending <= next_clear_pending_a;
            a_state_peer_isolate_ack <= next_peer_isolate_ack_a;
            a_state_peer_clear_ack <= next_peer_clear_ack_a;
            a_state_peer_isolate_req_seen <= next_peer_isolate_req_seen_a;
            a_state_peer_clear_req_seen <= next_peer_clear_req_seen_a;
            a_clear_o_reg <= next_clear_out_a;
            a_isolate_o_reg <= next_isolate_out_a;
        end
    end

    // Next State Logic
    assign next_state_a = a_state;
    assign next_isolate_pending_a = a_state_isolate_pending;
    assign next_clear_pending_a = a_state_clear_pending;
    assign next_peer_isolate_ack_a = a_state_peer_isolate_ack;
    assign next_peer_clear_ack_a = a_state_peer_clear_ack;
    assign next_peer_isolate_req_seen_a = a_state_peer_isolate_req_seen;
    assign next_peer_clear_req_seen_a = a_state_peer_clear_req_seen;

    // Combinational Logic for Next State and Outputs
    always @(*) begin
        next_state_a = a_state;
        next_isolate_pending_a = a_state_isolate_pending;
        next_clear_pending_a = a_state_clear_pending;
        next_peer_isolate_ack_a = a_state_peer_isolate_ack;
        next_peer_clear_ack_a = a_state_peer_clear_ack;
        next_peer_isolate_req_seen_a = a_state_peer_isolate_req_seen;
        next_peer_clear_req_seen_a = a_state_peer_clear_req_seen;
        next_clear_out_a = a_clear_o_reg;
        next_isolate_out_a = a_isolate_o_reg;

        // Default values
        case (a_state)
            IDLE: begin
                // If local clear request comes, start isolation
                if (a_clear_req_local) begin
                    next_state_a = ISOLATING;
                    next_isolate_pending_a = 1'b1;
                    next_clear_pending_a = 1'b0;
                    next_peer_isolate_ack_a = 1'b0;
                    next_peer_clear_ack_a = 1'b0;
                    next_peer_isolate_req_seen_a = 1'b0;
                    next_peer_clear_req_seen_a = 1'b0;
                end
                // If peer requests clear, we must also isolate
                else if (b_clear_req_synced) begin
                    next_state_a = ISOLATING;
                    next_isolate_pending_a = 1'b1;
                    next_clear_pending_a = 1'b0;
                    next_peer_isolate_ack_a = 1'b0;
                    next_peer_clear_ack_a = 1'b0;
                    next_peer_isolate_req_seen_a = 1'b0;
                    next_peer_clear_req_seen_a = 1'b0;
                end
                else begin
                    next_isolate_out_a = 1'b0;
                    next_clear_out_a = 1'b1;
                end
            end

            ISOLATING: begin
                // Wait for peer isolate ack
                if (b_isolate_ack_synced) begin
                    next_state_a = CLEARING;
                    next_isolate_pending_a = 1'b0;
                    next_clear_pending_a = 1'b1;
                    next_peer_isolate_ack_a = 1'b1;
                    next_peer_clear_ack_a = 1'b0;
                    next_peer_isolate_req_seen_a = 1'b0;
                    next_peer_clear_req_seen_a = 1'b0;
                end
                else begin
                    next_isolate_out_a = 1'b1;
                    next_clear_out_a = 1'b1;
                end
            end

            CLEARING: begin
                // Wait for peer clear ack
                if (b_clear_ack_synced) begin
                    next_state_a = DONE;
                    next_isolate_pending_a = 1'b0;
                    next_clear_pending_a = 1'b0;
                    next_peer_isolate_ack_a = 1'b1;
                    next_peer_clear_ack_a = 1'b1;
                    next_peer_isolate_req_seen_a = 1'b0;
                    next_peer_clear_req_seen_a = 1'b0;
                end
                else begin
                    next_isolate_out_a = 1'b1;
                    next_clear_out_a = 1'b0;
                end
            end

            DONE: begin
                // Release clear first, then isolate
                if (a_clear_ack_local) begin
                    next_state_a = IDLE;
                    next_isolate_pending_a = 1'b0;
                    next_clear_pending_a = 1'b0;
                    next_peer_isolate_ack_a = 1'b0;
                    next_peer_clear_ack_a = 1'b0;
                    next_peer_isolate_req_seen_a = 1'b0;
                    next_peer_clear_req_seen_a = 1'b0;
                    next_clear_out_a = 1'b1;
                    next_isolate_out_a = 1'b0;
                end
                else begin
                    next_isolate_out_a = 1'b1;
                    next_clear_out_a = 1'b0;
                end
            end

            default: begin
                next_isolate_out_a = 1'b0;
                next_clear_out_a = 1'b1;
            end
        endcase
    end

    assign a_clear_o = a_clear_o_reg;
    assign a_isolate_o = a_isolate_o_reg;

    // ------------------------------------------------------------------
    // Control Logic: Domain B
    // ------------------------------------------------------------------
    
    // Local State Machine for Domain B
    // Similar logic to Domain A but mirrored for B inputs/outputs
    
    // Inputs to FSM
    wire b_clear_req_local;
    wire b_isolate_req_local;
    wire b_clear_ack_local;
    wire b_isolate_ack_local;
    
    // Synchronized inputs from A
    wire a_clear_req_synced;
    wire a_isolate_req_synced;
    wire a_clear_ack_synced;
    wire a_isolate_ack_synced;

    assign b_clear_req_local = b_clear_i;
    assign b_isolate_req_local = b_clear_i;
    assign b_clear_ack_local = b_clear_ack_i;
    assign b_isolate_ack_local = b_isolate_ack_i;

    assign a_clear_req_synced = b_clear_req_sync_a[SYNC_STAGES-1];
    assign a_isolate_req_synced = b_isolate_req_sync_a[SYNC_STAGES-1];
    assign a_clear_ack_synced = b_clear_ack_sync_a[SYNC_STAGES-1];
    assign a_isolate_ack_synced = b_isolate_ack_sync_a[SYNC_STAGES-1];

    reg [2:0] b_state;
    reg b_state_isolate_pending;
    reg b_state_clear_pending;
    reg b_state_peer_isolate_ack;
    reg b_state_peer_clear_ack;
    reg b_state_peer_isolate_req_seen;
    reg b_state_peer_clear_req_seen;

    parameter IDLE = 3'b000;
    parameter ISOLATING = 3'b001;
    parameter CLEARING = 3'b010;
    parameter DONE = 3'b011;

    // Output registers
    reg b_clear_o_reg;
    reg b_isolate_o_reg;

    // State Register
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= IDLE;
            b_state_isolate_pending <= 1'b0;
            b_state_clear_pending <= 1'b0;
            b_state_peer_isolate_ack <= 1'b0;
            b_state_peer_clear_ack <= 1'b0;
            b_state_peer_isolate_req_seen <= 1'b0;
            b_state_peer_clear_req_seen <= 1'b0;
            b_clear_o_reg <= 1'b1;
            b_isolate_o_reg <= 1'b0;
        end
        else begin
            b_state <= next_state_b;
            b_state_isolate_pending <= next_isolate_pending_b;
            b_state_clear_pending <= next_clear_pending_b;
            b_state_peer_isolate_ack <= next_peer_isolate_ack_b;
            b_state_peer_clear_ack <= next_peer_clear_ack_b;
            b_state_peer_isolate_req_seen <= next_peer_isolate_req_seen_b;
            b_state_peer_clear_req_seen <= next_peer_clear_req_seen_b;
            b_clear_o_reg <= next_clear_out_b;
            b_isolate_o_reg <= next_isolate_out_b;
        end
    end

    // Next State Logic
    assign next_state_b = b_state;
    assign next_isolate_pending_b = b_state_isolate_pending;
    assign next_clear_pending_b = b_state_clear_pending;
    assign next_peer_isolate_ack_b = b_state_peer_isolate_ack;
    assign next_peer_clear_ack_b = b_state_peer_clear_ack;
    assign next_peer_isolate_req_seen_b = b_state_peer_isolate_req_seen;
    assign next_peer_clear_req_seen_b = b_state_peer_clear_req_seen;

    // Combinational Logic for Next State and Outputs
    always @(*) begin
        next_state_b = b_state;
        next_isolate_pending_b = b_state_isolate_pending;
        next_clear_pending_b = b_state_clear_pending;
        next_peer_isolate_ack_b = b_state_peer_isolate_ack;
        next_peer_clear_ack_b = b_state_peer_clear_ack;
        next_peer_isolate_req_seen_b = b_state_peer_isolate_req_seen;
        next_peer_clear_req_seen_b = b_state_peer_clear_req_seen;
        next_clear_out_b = b_clear_o_reg;
        next_isolate_out_b = b_isolate_o_reg;

        // Default values
        case (b_state)
            IDLE: begin
                // If local clear request comes, start isolation
                if (b_clear_req_local) begin
                    next_state_b = ISOLATING;
                    next_isolate_pending_b = 1'b1;
                    next_clear_pending_b = 1'b0;
                    next_peer_isolate_ack_b = 1'b0;
                    next_peer_clear_ack_b = 1'b0;
                    next_peer_isolate_req_seen_b = 1'b0;
                    next_peer_clear_req_seen_b = 1'b0;
                end
                // If peer requests clear, we must also isolate
                else if (a_clear_req_synced) begin
                    next_state_b = ISOLATING;
                    next_isolate_pending_b = 1'b1;
                    next_clear_pending_b = 1'b0;
                    next_peer_isolate_ack_b = 1'b0;
                    next_peer_clear_ack_b = 1'b0;
                    next_peer_isolate_req_seen_b = 1'b0;
                    next_peer_clear_req_seen_b = 1'b0;
                end
                else begin
                    next_isolate_out_b = 1'b0;
                    next_clear_out_b = 1'b1;
                end
            end

            ISOLATING: begin
                // Wait for peer isolate ack
                if (a_isolate_ack_synced) begin
                    next_state_b = CLEARING;
                    next_isolate_pending_b = 1'b0;
                    next_clear_pending_b = 1'b1;
                    next_peer_isolate_ack_b = 1'b1;
                    next_peer_clear_ack_b = 1'b0;
                    next_peer_isolate_req_seen_b = 1'b0;
                    next_peer_clear_req_seen_b = 1'b0;
                end
                else begin
                    next_isolate_out_b = 1'b1;
                    next_clear_out_b = 1'b1;
                end
            end

            CLEARING: begin
                // Wait for peer clear ack
                if (a_clear_ack_synced) begin
                    next_state_b = DONE;
                    next_isolate_pending_b = 1'b0;
                    next_clear_pending_b = 1'b0;
                    next_peer_isolate_ack_b = 1'b1;
                    next_peer_clear_ack_b = 1'b1;
                    next_peer_isolate_req_seen_b = 1'b0;
                    next_peer_clear_req_seen_b = 1'b0;
                end
                else begin
                    next_isolate_out_b = 1'b1;
                    next_clear_out_b = 1'b0;
                end
            end

            DONE: begin
                // Release clear first, then isolate
                if (b_clear_ack_local) begin
                    next_state_b = IDLE;
                    next_isolate_pending_b = 1'b0;
                    next_clear_pending_b = 1'b0;
                    next_peer_isolate_ack_b = 1'b0;
                    next_peer_clear_ack_b = 1'b0;
                    next_peer_isolate_req_seen_b = 1'b0;
                    next_peer_clear_req_seen_b = 1'b0;
                    next_clear_out_b = 1'b1;
                    next_isolate_out_b = 1'b0;
                end
                else begin
                    next_isolate_out_b = 1'b1;
                    next_clear_out_b = 1'b0;
                end
            end

            default: begin
                next_isolate_out_b = 1'b0;
                next_clear_out_b = 1'b1;
            end
        endcase
    end

    assign b_clear_o = b_clear_o_reg;
    assign b_isolate_o = b_isolate_o_reg;

endmodule
```<|im_end|>
