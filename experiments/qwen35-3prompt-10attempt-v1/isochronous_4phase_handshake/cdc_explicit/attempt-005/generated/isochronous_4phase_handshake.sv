module isochronous_4phase_handshake (
    input  src_clk_i,
    input  src_rst_ni,
    input  src_valid_i,
    output src_ready_o,
    input  dst_clk_i,
    input  dst_rst_ni,
    output dst_valid_o,
    input  dst_ready_i
);

    // CDC Strategy:
    // 1. Use a 2-bit state machine in the source domain to track the handshake phase.
    //    States: IDLE, REQ_SENT, ACK_RCVD, WAIT_ACK.
    //    - IDLE: src_valid=0, src_ready=0
    //    - REQ_SENT: src_valid=1, src_ready=0 (Waiting for ACK)
    //    - ACK_RCVD: src_valid=0, src_ready=1 (Waiting for next request)
    //    - WAIT_ACK: src_valid=0, src_ready=0 (Transient state after ACK, before next req)
    //    Actually, a simpler 4-phase flow for "no data" is:
    //    Phase 1: src_valid goes high.
    //    Phase 2: dst_valid goes high (acknowledges receipt).
    //    Phase 3: dst_ready goes high (acknowledges processing).
    //    Phase 4: src_ready goes high (acknowledges completion).
    //
    //    To implement this safely across clocks:
    //    - We need to capture the handshake signals in the destination domain to drive the next phase.
    //    - We need to capture the destination's response in the source domain to complete the cycle.
    //
    //    Architecture:
    //    Source Domain:
    //      - State Machine tracks local phase.
    //      - Captures dst_valid_o (which is driven by dest domain logic) to know when to release src_ready.
    //      - Captures dst_ready_i to know when to assert dst_valid_o.
    //
    //    Destination Domain:
    //      - State Machine tracks local phase.
    //      - Captures src_valid_i to know when to assert dst_valid_o.
    //      - Captures src_ready_o (which is driven by src domain logic) to know when to release dst_ready.
    //
    //    Since there is no data payload, we only need to synchronize the control signals.
    //    We will use a 2-bit state machine in each domain.
    //
    //    Source States:
    //      0: IDLE (src_valid=0, src_ready=0)
    //      1: REQ (src_valid=1, src_ready=0) -> Wait for dst_valid
    //      2: ACK (src_valid=0, src_ready=1) -> Wait for dst_ready
    //      3: WAIT (src_valid=0, src_ready=0) -> Transient, wait for next cycle to go back to IDLE or REQ?
    //
    //    Let's refine the 4-phase sequence strictly:
    //    1. src_valid_i = 1
    //    2. dst_valid_o = 1 (driven by dest)
    //    3. dst_ready_i = 1
    //    4. src_ready_o = 1 (driven by src)
    //
    //    Source Logic:
    //      - If IDLE and src_valid_i -> Go to REQ (src_valid=1, src_ready=0)
    //      - If REQ and dst_valid_o (captured) -> Go to ACK (src_valid=0, src_ready=1)
    //      - If ACK and dst_ready_i (captured) -> Go to WAIT (src_valid=0, src_ready=0)
    //      - If WAIT and src_valid_i (new request) -> Go to REQ
    //
    //    Destination Logic:
    //      - If IDLE and src_valid_i (captured) -> Go to REQ (dst_valid=1, dst_ready=0)
    //      - If REQ and src_ready_o (captured) -> Go to ACK (dst_valid=0, dst_ready=1)
    //      - If ACK and src_valid_i (new request) -> Go to REQ
    //
    //    This ensures the 4-phase order: Valid -> ValidAck -> Ready -> ReadyAck.

    // Source Domain State Machine
    typedef enum logic [1:0] {
        SRC_IDLE,
        SRC_REQ,
        SRC_ACK,
        SRC_WAIT
    } src_state_t;

    src_state_t src_state_reg, src_state_next;
    logic src_valid_next;
    logic src_ready_next;

    // Destination Domain State Machine
    typedef enum logic [1:0] {
        DST_IDLE,
        DST_REQ,
        DST_ACK,
        DST_WAIT
    } dst_state_t;

    dst_state_t dst_state_reg, dst_state_next;
    logic dst_valid_next;
    logic dst_ready_next;

    // Synchronization for cross-domain signals
    // Capture dst_valid_o in source domain (2 stages)
    logic dst_valid_synced_1, dst_valid_synced_2;
    // Capture dst_ready_i in source domain (2 stages)
    logic dst_ready_synced_1, dst_ready_synced_2;
    // Capture src_valid_i in destination domain (2 stages)
    logic src_valid_synced_1, src_valid_synced_2;
    // Capture src_ready_o in destination domain (2 stages)
    logic src_ready_synced_1, src_ready_synced_2;

    // ------------------------------------------------------------------
    // Source Domain Logic
    // ------------------------------------------------------------------
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state_reg <= SRC_IDLE;
            src_valid_next <= 1'b0;
            src_ready_next <= 1'b0;
        end else begin
            src_state_reg <= src_state_next;
            src_valid_next <= src_valid_next_calc;
            src_ready_next <= src_ready_next_calc;
        end
    end

    // Combinational logic for next state and outputs in Source Domain
    always_comb begin
        src_state_next = SRC_IDLE;
        src_valid_next = 1'b0;
        src_ready_next = 1'b0;

        case (src_state_reg)
            SRC_IDLE: begin
                if (src_valid_i)
                    src_state_next = SRC_REQ;
                // src_valid_next = 0; src_ready_next = 0;
            end
            SRC_REQ: begin
                // Wait for dst_valid_o (acknowledged receipt)
                if (dst_valid_synced_2)
                    src_state_next = SRC_ACK;
                // src_valid_next = 1; src_ready_next = 0;
            end
            SRC_ACK: begin
                // Wait for dst_ready_i (processing complete)
                if (dst_ready_synced_2)
                    src_state_next = SRC_WAIT;
                // src_valid_next = 0; src_ready_next = 1;
            end
            SRC_WAIT: begin
                // Transient state. If new request comes, go to REQ.
                // Otherwise, stay in WAIT until next clock edge? 
                // Actually, in SRC_WAIT, we have just received dst_ready.
                // We need to be ready for the next src_valid.
                // If src_valid_i is high, we transition to SRC_REQ.
                if (src_valid_i)
                    src_state_next = SRC_REQ;
                // src_valid_next = 0; src_ready_next = 0;
            end
        endcase

        // Assign outputs based on current state
        case (src_state_reg)
            SRC_IDLE: begin
                src_valid_next = 1'b0;
                src_ready_next = 1'b0;
            end
            SRC_REQ: begin
                src_valid_next = 1'b1;
                src_ready_next = 1'b0;
            end
            SRC_ACK: begin
                src_valid_next = 1'b0;
                src_ready_next = 1'b1;
            end
            SRC_WAIT: begin
                src_valid_next = 1'b0;
                src_ready_next = 1'b0;
            end
        endcase
    end

    assign src_ready_o = src_ready_next;
    assign dst_valid_o = dst_valid_next; // Driven by dest logic below

    // ------------------------------------------------------------------
    // Destination Domain Logic
    // ------------------------------------------------------------------
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state_reg <= DST_IDLE;
            dst_valid_next <= 1'b0;
            dst_ready_next <= 1'b0;
        end else begin
            dst_state_reg <= dst_state_next;
            dst_valid_next <= dst_valid_next_calc;
            dst_ready_next <= dst_ready_next_calc;
        end
    end

    // Combinational logic for next state and outputs in Destination Domain
    always_comb begin
        dst_state_next = DST_IDLE;
        dst_valid_next = 1'b0;
        dst_ready_next = 1'b0;

        case (dst_state_reg)
            DST_IDLE: begin
                if (src_valid_synced_2)
                    dst_state_next = DST_REQ;
                // dst_valid_next = 0; dst_ready_next = 0;
            end
            DST_REQ: begin
                // Wait for src_ready_o (acknowledged processing)
                if (src_ready_synced_2)
                    dst_state_next = DST_ACK;
                // dst_valid_next = 1; dst_ready_next = 0;
            end
            DST_ACK: begin
                // Wait for src_valid_i (new request)
                if (src_valid_synced_2)
                    dst_state_next = DST_REQ;
                // dst_valid_next = 0; dst_ready_next = 1;
            end
            DST_WAIT: begin
                // Transient state. If new request comes, go to REQ.
                if (src_valid_synced_2)
                    dst_state_next = DST_REQ;
                // dst_valid_next = 0; dst_ready_next = 0;
            end
        endcase

        // Assign outputs based on current state
        case (dst_state_reg)
            DST_IDLE: begin
                dst_valid_next = 1'b0;
                dst_ready_next = 1'b0;
            end
            DST_REQ: begin
                dst_valid_next = 1'b1;
                dst_ready_next = 1'b0;
            end
            DST_ACK: begin
                dst_valid_next = 1'b0;
                dst_ready_next = 1'b1;
            end
            DST_WAIT: begin
                dst_valid_next = 1'b0;
                dst_ready_next = 1'b0;
            end
        endcase
    end

    // ------------------------------------------------------------------
    // Synchronization Logic (CDC)
    // ------------------------------------------------------------------
    // Capture dst_valid_o in Source Domain (2 stages)
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_valid_synced_1 <= 1'b0;
            dst_valid_synced_2 <= 1'b0;
        end else begin
            dst_valid_synced_1 <= dst_valid_o;
            dst_valid_synced_2 <= dst_valid_synced_1;
        end
    end

    // Capture dst_ready_i in Source Domain (2 stages)
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_synced_1 <= 1'b0;
            dst_ready_synced_2 <= 1'b0;
        end else begin
            dst_ready_synced_1 <= dst_ready_i;
            dst_ready_synced_2 <= dst_ready_synced_1;
        end
    end

    // Capture src_valid_i in Destination Domain (2 stages)
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_synced_1 <= 1'b0;
            src_valid_synced_2 <= 1'b0;
        end else begin
            src_valid_synced_1 <= src_valid_i;
            src_valid_synced_2 <= src_valid_synced_1;
        end
    end

    // Capture src_ready_o in Destination Domain (2 stages)
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ready_synced_1 <= 1'b0;
            src_ready_synced_2 <= 1'b0;
        end else begin
            src_ready_synced_1 <= src_ready_o;
            src_ready_synced_2 <= src_ready_synced_1;
        end
    end

endmodule<|im_end|>
