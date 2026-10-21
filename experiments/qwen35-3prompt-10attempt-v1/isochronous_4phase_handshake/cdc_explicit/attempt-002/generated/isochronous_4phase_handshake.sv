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
    //    States: IDLE, REQ_SENT, ACK_WAIT, ACK_SENT.
    //    - IDLE: Waiting for src_valid_i.
    //    - REQ_SENT: src_valid_i asserted, waiting for dst_ready_i (via cross-domain flip-flops).
    //    - ACK_WAIT: dst_ready_i received, asserting dst_valid_o, waiting for src_ready_o.
    //    - ACK_SENT: src_ready_o received, deasserting dst_valid_o, returning to IDLE.
    // 2. Cross-domain signals (dst_ready_i, src_ready_o) are captured using a 2-stage pipeline
    //    in the receiving domain to ensure setup/hold compliance and metastability resolution.
    // 3. Reset synchronization is handled by capturing the active-low reset in both domains
    //    with a 2-stage pipeline to ensure safe release.

    // --------------------------------------------------------------------------
    // Source Domain State Machine
    // --------------------------------------------------------------------------
    typedef enum logic [1:0] {
        SRC_IDLE,
        SRC_REQ_SENT,
        SRC_ACK_WAIT,
        SRC_ACK_SENT
    } src_state_t;

    src_state_t src_state_curr, src_state_next;
    logic       src_valid_reg;

    // --------------------------------------------------------------------------
    // Destination Domain State Machine
    // --------------------------------------------------------------------------
    typedef enum logic [1:0] {
        DST_IDLE,
        DST_REQ_WAIT,
        DST_ACK_SENT,
        DST_ACK_WAIT
    } dst_state_t;

    dst_state_t dst_state_curr, dst_state_next;
    logic       dst_valid_reg;

    // --------------------------------------------------------------------------
    // Cross-Domain Signal Synchronization
    // --------------------------------------------------------------------------
    // Capture dst_ready_i in source domain (2-stage pipeline)
    logic dst_ready_sync1, dst_ready_sync2;
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_sync1 <= 1'b0;
            dst_ready_sync2 <= 1'b0;
        end else begin
            dst_ready_sync1 <= dst_ready_i;
            dst_ready_sync2 <= dst_ready_sync1;
        end
    end

    // Capture src_ready_o in destination domain (2-stage pipeline)
    logic src_ready_sync1, src_ready_sync2;
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ready_sync1 <= 1'b0;
            src_ready_sync2 <= 1'b0;
        end else begin
            src_ready_sync1 <= src_ready_o;
            src_ready_sync2 <= src_ready_sync1;
        end
    end

    // Capture resets in both domains (2-stage pipeline)
    logic src_rst_sync1, src_rst_sync2;
    always_ff @(posedge src_clk_i) begin
        if (src_rst_ni) begin
            src_rst_sync1 <= 1'b1;
            src_rst_sync2 <= 1'b1;
        end else begin
            src_rst_sync1 <= src_rst_sync2;
            src_rst_sync2 <= src_rst_sync1;
        end
    end

    logic dst_rst_sync1, dst_rst_sync2;
    always_ff @(posedge dst_clk_i) begin
        if (dst_rst_ni) begin
            dst_rst_sync1 <= 1'b1;
            dst_rst_sync2 <= 1'b1;
        end else begin
            dst_rst_sync1 <= dst_rst_sync2;
            dst_rst_sync2 <= dst_rst_sync1;
        end
    end

    // --------------------------------------------------------------------------
    // Source Domain Logic
    // --------------------------------------------------------------------------
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state_curr <= SRC_IDLE;
            src_valid_reg  <= 1'b0;
        end else begin
            src_state_curr <= src_state_next;
            src_valid_reg  <= src_valid_i;
        end
    end

    always_comb begin
        src_state_next = src_state_curr;
        src_ready_o    = 1'b0;

        case (src_state_curr)
            SRC_IDLE: begin
                if (src_valid_i)
                    src_state_next = SRC_REQ_SENT;
            end

            SRC_REQ_SENT: begin
                if (dst_ready_sync2)
                    src_state_next = SRC_ACK_WAIT;
            end

            SRC_ACK_WAIT: begin
                // Wait for acknowledgment from destination
                if (src_ready_sync2)
                    src_state_next = SRC_ACK_SENT;
            end

            SRC_ACK_SENT: begin
                src_state_next = SRC_IDLE;
            end
        endcase
    end

    // --------------------------------------------------------------------------
    // Destination Domain Logic
    // --------------------------------------------------------------------------
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state_curr <= DST_IDLE;
            dst_valid_reg  <= 1'b0;
        end else begin
            dst_state_curr <= dst_state_next;
            dst_valid_reg  <= dst_valid_o;
        end
    end

    always_comb begin
        dst_state_next = dst_state_curr;
        dst_valid_o    = 1'b0;

        case (dst_state_curr)
            DST_IDLE: begin
                if (src_ready_sync2)
                    dst_state_next = DST_REQ_WAIT;
            end

            DST_REQ_WAIT: begin
                if (dst_ready_i)
                    dst_state_next = DST_ACK_SENT;
            end

            DST_ACK_SENT: begin
                if (src_ready_sync2)
                    dst_state_next = DST_ACK_WAIT;
            end

            DST_ACK_WAIT: begin
                dst_state_next = DST_IDLE;
            end
        endcase
    end

    // --------------------------------------------------------------------------
    // Output Assignment
    // --------------------------------------------------------------------------
    // src_ready_o is driven based on the source state machine
    always_comb begin
        case (src_state_curr)
            SRC_IDLE:    src_ready_o = 1'b0;
            SRC_REQ_SENT: src_ready_o = 1'b0;
            SRC_ACK_WAIT: src_ready_o = 1'b1;
            SRC_ACK_SENT: src_ready_o = 1'b0;
        endcase
    end

    // dst_valid_o is driven based on the destination state machine
    always_comb begin
        case (dst_state_curr)
            DST_IDLE:    dst_valid_o = 1'b0;
            DST_REQ_WAIT: dst_valid_o = 1'b0;
            DST_ACK_SENT: dst_valid_o = 1'b1;
            DST_ACK_WAIT: dst_valid_o = 1'b0;
        endcase
    end

endmodule<|im_end|>
