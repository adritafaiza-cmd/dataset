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
    // CDC Synchronizers
    // ------------------------------------------------------------------
    // Synchronize signals from Domain A to Domain B
    logic [SYNC_STAGES-1:0] a_clear_sync_b;
    logic [SYNC_STAGES-1:0] a_clear_ack_sync_b;
    logic [SYNC_STAGES-1:0] a_isolate_sync_b;
    logic [SYNC_STAGES-1:0] a_isolate_ack_sync_b;
    logic [SYNC_STAGES-1:0] b_clear_sync_a;
    logic [SYNC_STAGES-1:0] b_clear_ack_sync_a;
    logic [SYNC_STAGES-1:0] b_isolate_sync_a;
    logic [SYNC_STAGES-1:0] b_isolate_ack_sync_a;

    // Generate synchronizer chains
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_a_to_b
            always @(posedge b_clk_i or negedge b_rst_ni) begin : sync_a_to_b
                if (!b_rst_ni)
                    a_clear_sync_b[i] <= 1'b0;
                else
                    a_clear_sync_b[i] <= a_clear_i;
            end
        end
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_ack_a_to_b
            always @(posedge b_clk_i or negedge b_rst_ni) begin : sync_ack_a_to_b
                if (!b_rst_ni)
                    a_clear_ack_sync_b[i] <= 1'b0;
                else
                    a_clear_ack_sync_b[i] <= a_clear_ack_i;
            end
        end
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_iso_a_to_b
            always @(posedge b_clk_i or negedge b_rst_ni) begin : sync_iso_a_to_b
                if (!b_rst_ni)
                    a_isolate_sync_b[i] <= 1'b0;
                else
                    a_isolate_sync_b[i] <= a_isolate_i; // Note: a_isolate_i is internal logic, see below
            end
        end
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_ack_iso_a_to_b
            always @(posedge b_clk_i or negedge b_rst_ni) begin : sync_ack_iso_a_to_b
                if (!b_rst_ni)
                    a_isolate_ack_sync_b[i] <= 1'b0;
                else
                    a_isolate_ack_sync_b[i] <= a_isolate_ack_i;
            end
        end

        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_b_to_a
            always @(posedge a_clk_i or negedge a_rst_ni) begin : sync_b_to_a
                if (!a_rst_ni)
                    b_clear_sync_a[i] <= 1'b0;
                else
                    b_clear_sync_a[i] <= b_clear_i;
            end
        end
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_ack_b_to_a
            always @(posedge a_clk_i or negedge a_rst_ni) begin : sync_ack_b_to_a
                if (!a_rst_ni)
                    b_clear_ack_sync_a[i] <= 1'b0;
                else
                    b_clear_ack_sync_a[i] <= b_clear_ack_i;
            end
        end
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_iso_b_to_a
            always @(posedge a_clk_i or negedge a_rst_ni) begin : sync_iso_b_to_a
                if (!a_rst_ni)
                    b_isolate_sync_a[i] <= 1'b0;
                else
                    b_isolate_sync_a[i] <= b_isolate_i; // Note: b_isolate_i is internal logic, see below
            end
        end
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_ack_iso_b_to_a
            always @(posedge a_clk_i or negedge a_rst_ni) begin : sync_ack_iso_b_to_a
                if (!a_rst_ni)
                    b_isolate_ack_sync_a[i] <= 1'b0;
                else
                    b_isolate_ack_sync_a[i] <= b_isolate_ack_i;
            end
        end
    endgenerate

    // ------------------------------------------------------------------
    // Internal State Machines
    // ------------------------------------------------------------------
    // State Encoding:
    // 0: IDLE
    // 1: A_ISOLATE
    // 2: B_ISOLATE
    // 3: A_CLEAR
    // 4: B_CLEAR
    // 5: A_ACK_WAIT
    // 6: B_ACK_WAIT
    // 7: DONE

    localparam IDLE = 3'b000;
    localparam A_ISOLATE = 3'b001;
    localparam B_ISOLATE = 3'b010;
    localparam A_CLEAR = 3'b011;
    localparam B_CLEAR = 3'b100;
    localparam A_ACK_WAIT = 3'b101;
    localparam B_ACK_WAIT = 3'b110;
    localparam DONE = 3'b111;

    logic [2:0] state, next_state;
    logic a_req, b_req;
    logic a_isolate_req, b_isolate_req;
    logic a_clear_req, b_clear_req;
    logic a_isolate_ack, b_isolate_ack;
    logic a_clear_ack, b_clear_ack;

    // Internal request flags (synchronized versions used for logic)
    logic a_clear_req_sync_b;
    logic b_clear_req_sync_a;
    logic a_isolate_req_sync_b;
    logic b_isolate_req_sync_a;

    // Assign synchronized requests to internal logic
    assign a_clear_req_sync_b = a_clear_sync_b[SYNC_STAGES-1];
    assign b_clear_req_sync_a = b_clear_sync_a[SYNC_STAGES-1];
    
    // We need to generate the isolate requests internally based on state and peer status
    // But the handshake protocol requires us to drive the output and wait for ack.
    // The "request" to isolate is driven when the state machine enters the isolate state.
    // The "ack" comes from the peer.
    
    // Let's refine the logic flow:
    // 1. Detect local clear request.
    // 2. If both sides have requests (or one side has request and other is idle), enter Isolate phase.
    //    Actually, the prompt says: "When either side requests a clear, isolate both sides before clearing either".
    //    This implies a global isolation step.
    //    Sequence:
    //    - Local Clear Request detected.
    //    - Drive Isolate Out (A and B).
    //    - Wait for Peer Isolate Ack (Cross domain).
    //    - Wait for Local Isolate Ack (Same domain).
    //    - Once both sides are isolated (A_ack & B_ack received), proceed to Clear.
    //    - Drive Clear Out.
    //    - Wait for Peer Clear Ack.
    //    - Wait for Local Clear Ack.
    //    - Release.

    // Re-evaluating the handshake protocol described:
    // "Peer progress arrives in order: idle, then active, then done, then idle."
    // "Each step is observed one handshake after the local transition."
    // "Do not release isolate or clear before the peer completion has been observed."

    // Let's define the state machine logic more precisely.
    // Inputs to FSM (from sync):
    // - a_clear_req_sync_b: Request from A side (seen by B logic)
    // - b_clear_req_sync_a: Request from B side (seen by A logic)
    // - a_isolate_ack_sync_b: Ack from A side (seen by B logic)
    // - b_isolate_ack_sync_a: Ack from B side (seen by A logic)
    // - a_clear_ack_sync_b: Ack from A side (seen by B logic)
    // - b_clear_ack_sync_a: Ack from B side (seen by A logic)

    // Since the FSM needs to run in both domains, we will instantiate two FSMs?
    // No, the state machine logic is identical for both domains, just the inputs/outputs differ.
    // However, the state machine must be synchronized.
    // Let's create a single state machine logic block that runs in both domains, 
    // but since the state variables must be stable in the current domain, 
    // we can use a single state machine per domain that reacts to the synchronized signals.
    
    // Actually, a simpler approach for a symmetric controller:
    // Instantiate the same state machine logic twice, once for A domain, once for B domain.
    // They will share the same logic structure but operate on their respective clocks and sync signals.

    // ------------------------------------------------------------------
    // Domain A State Machine
    // ------------------------------------------------------------------
    logic [2:0] a_state, a_next_state;
    logic a_isolate_req_int, a_clear_req_int;
    logic a_isolate_ack_int, a_clear_ack_int;

    // Internal flags for A domain
    assign a_clear_req_int = a_clear_req_sync_b;
    assign a_isolate_ack_int = a_isolate_ack_sync_b;
    assign a_clear_ack_int = a_clear_ack_sync_b;

    // B side status seen by A
    logic b_isolate_req_seen_a;
    logic b_isolate_ack_seen_a;
    logic b_clear_req_seen_a;
    logic b_clear_ack_seen_a;

    assign b_isolate_req_seen_a = b_isolate_req_sync_a;
    assign b_isolate_ack_seen_a = b_isolate_ack_sync_a;
    assign b_clear_req_seen_a = b_clear_req_sync_a;
    assign b_clear_ack_seen_a = b_clear_ack_sync_a;

    // A State Machine Logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin : a_fsm
        if (!a_rst_ni)
            a_state <= IDLE;
        else
            a_state <= a_next_state;
    end

    always @(posedge a_clk_i or negedge a_rst_ni) begin : a_next_state_logic
        if (!a_rst_ni)
            a_next_state <= IDLE;
        else
            case (a_state)
                IDLE: begin
                    // Check if any clear request is active
                    if (a_clear_req_int || b_clear_req_seen_a)
                        a_next_state <= A_ISOLATE;
                    else
                        a_next_state <= IDLE;
                end
                A_ISOLATE: begin
                    // Drive isolate outputs
                    a_isolate_o <= 1'b0;
                    b_isolate_o <= 1'b0; // Drive peer isolate
                    
                    // Wait for peer isolate ack and local isolate ack
                    // "Each step is observed one handshake after the local transition."
                    // We need to wait for both acks before moving to clear.
                    if (a_isolate_ack_int && b_isolate_ack_seen_a)
                        a_next_state <= A_CLEAR;
                    else
                        a_next_state <= A_ISOLATE;
                end
                A_CLEAR: begin
                    // Drive clear outputs
                    a_clear_o <= 1'b0;
                    b_clear_o <= 1'b0; // Drive peer clear
                    
                    // Wait for peer clear ack and local clear ack
                    if (a_clear_ack_int && b_clear_ack_seen_a)
                        a_next_state <= DONE;
                    else
                        a_next_state <= A_CLEAR;
                end
                DONE: begin
                    // Release everything
                    a_isolate_o <= 1'b1;
                    b_isolate_o <= 1'b1;
                    a_clear_o <= 1'b1;
                    b_clear_o <= 1'b1;
                    
                    if (!a_clear_req_int && !b_clear_req_seen_a)
                        a_next_state <= IDLE;
                    else
                        a_next_state <= DONE;
                end
                default: a_next_state <= IDLE;
            endcase
    end

    // ------------------------------------------------------------------
    // Domain B State Machine
    // ------------------------------------------------------------------
    logic [2:0] b_state, b_next_state;
    logic b_isolate_req_int, b_clear_req_int;
    logic b_isolate_ack_int, b_clear_ack_int;

    // Internal flags for B domain
    assign b_clear_req_int = b_clear_req_sync_a;
    assign b_isolate_ack_int = b_isolate_ack_sync_a;
    assign b_clear_ack_int = b_clear_ack_sync_a;

    // A side status seen by B
    logic a_isolate_req_seen_b;
    logic a_isolate_ack_seen_b;
    logic a_clear_req_seen_b;
    logic a_clear_ack_seen_b;

    assign a_isolate_req_seen_b = a_isolate_req_int; // Wait, a_isolate_req_int is internal to A FSM. 
    // We need to drive the isolate output in A FSM so B can see it.
    // The output a_isolate_o is driven by A FSM. B sees it via sync.
    // So in B FSM, we need to sync a_isolate_o.
    
    // Let's add sync for the outputs of the other domain to the current domain FSM.
    logic [SYNC_STAGES-1:0] a_isolate_o_sync_b;
    logic [SYNC_STAGES-1:0] a_clear_o_sync_b;
    logic [SYNC_STAGES-1:0] b_isolate_o_sync_a;
    logic [SYNC_STAGES-1:0] b_clear_o_sync_a;

    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_a_out_to_b
            always @(posedge b_clk_i or negedge b_rst_ni) begin : sync_a_out_to_b
                if (!b_rst_ni)
                    a_isolate_o_sync_b[i] <= 1'b1;
                else
                    a_isolate_o_sync_b[i] <= a_isolate_o;
            end
        end
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_a_clear_out_to_b
            always @(posedge b_clk_i or negedge b_rst_ni) begin : sync_a_clear_out_to_b
                if (!b_rst_ni)
                    a_clear_o_sync_b[i] <= 1'b1;
                else
                    a_clear_o_sync_b[i] <= a_clear_o;
            end
        end
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_b_out_to_a
            always @(posedge a_clk_i or negedge a_rst_ni) begin : sync_b_out_to_a
                if (!a_rst_ni)
                    b_isolate_o_sync_a[i] <= 1'b1;
                else
                    b_isolate_o_sync_a[i] <= b_isolate_o;
            end
        end
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_b_clear_out_to_a
            always @(posedge a_clk_i or negedge a_rst_ni) begin : sync_b_clear_out_to_a
                if (!a_rst_ni)
                    b_clear_o_sync_a[i] <= 1'b1;
                else
                    b_clear_o_sync_a[i] <= b_clear_o;
            end
        end
    endgenerate

    assign a_isolate_req_seen_b = a_isolate_o_sync_b[SYNC_STAGES-1];
    assign a_clear_req_seen_b = a_clear_o_sync_b[SYNC_STAGES-1];
    assign b_isolate_req_seen_a = b_isolate_o_sync_a[SYNC_STAGES-1];
    assign b_clear_req_seen_a = b_clear_o_sync_a[SYNC_STAGES-1];

    always @(posedge b_clk_i or negedge b_rst_ni) begin : b_fsm
        if (!b_rst_ni)
            b_state <= IDLE;
        else
            b_state <= b_next_state;
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin : b_next_state_logic
        if (!b_rst_ni)
            b_next_state <= IDLE;
        else
            case (b_state)
                IDLE: begin
                    if (b_clear_req_int || a_clear_req_seen_b)
                        b_next_state <= B_ISOLATE;
                    else
                        b_next_state <= IDLE;
                end
                B_ISOLATE: begin
                    b_isolate_o <= 1'b0;
                    a_isolate_o <= 1'b0;
                    
                    if (b_isolate_ack_int && a_isolate_ack_seen_b)
                        b_next_state <= B_CLEAR;
                    else
                        b_next_state <= B_ISOLATE;
                end
                B_CLEAR: begin
                    b_clear_o <= 1'b0;
                    a_clear_o <= 1'b0;
                    
                    if (b_clear_ack_int && a_clear_ack_seen_b)
                        b_next_state <= DONE;
                    else
                        b_next_state <= B_CLEAR;
                end
                DONE: begin
                    b_isolate_o <= 1'b1;
                    a_isolate_o <= 1'b1;
                    b_clear_o <= 1'b1;
                    a_clear_o <= 1'b1;
                    
                    if (!b_clear_req_int && !a_clear_req_seen_b)
                        b_next_state <= IDLE;
                    else
                        b_next_state <= DONE;
                end
                default: b_next_state <= IDLE;
            endcase
    end

    // ------------------------------------------------------------------
    // Output Drivers
    // ------------------------------------------------------------------
    // The state machine logic already drives the outputs in the case statements.
    // However, to ensure clean transitions and avoid glitches during state changes,
    // we can use combinational logic driven by the state register.
    
    assign a_isolate_o = (a_state == A_ISOLATE) ? 1'b0 : 1'b1;
    assign a_clear_o = (a_state == A_CLEAR) ? 1'b0 : 1'b1;
    
    assign b_isolate_o = (b_state == B_ISOLATE) ? 1'b0 : 1'b1;
    assign b_clear_o = (b_state == B_CLEAR) ? 1'b0 : 1'b1;

    // Ensure outputs are high during reset
    // The case statements handle this, but explicit assignment ensures no floating.
    // The logic above covers all states except default, which goes to IDLE (high).
    // Reset logic in FSM ensures IDLE on reset.

endmodule
```<|im_end|>
