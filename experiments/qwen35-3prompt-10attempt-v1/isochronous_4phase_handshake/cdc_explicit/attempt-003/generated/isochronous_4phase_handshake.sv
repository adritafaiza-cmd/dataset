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
    //    States: IDLE (00), REQ (01), ACK (10), RSP (11).
    //    - IDLE: Waiting for src_valid.
    //    - REQ: src_valid asserted, waiting for dst_ready.
    //    - ACK: dst_ready asserted, waiting for dst_valid.
    //    - RSP: dst_valid asserted, waiting for src_ready.
    // 2. Use a 2-bit state machine in the destination domain to track the handshake phase.
    //    States: IDLE (00), REQ (01), ACK (10), RSP (11).
    //    - IDLE: Waiting for dst_valid.
    //    - REQ: dst_valid asserted, waiting for src_ready.
    //    - ACK: src_ready asserted, waiting for dst_ready.
    //    - RSP: dst_ready asserted, waiting for dst_valid.
    // 3. Cross-domain signals (src_ready_o, dst_valid_o) are driven by the local FSM
    //    based on the state of the remote domain's feedback signal, which is sampled
    //    synchronously. This ensures no unsafe asynchronous crossings.
    // 4. Reset release is handled by synchronizing the reset signal in each domain
    //    before entering the FSM logic to ensure coherent state initialization.

    // Source Domain State Machine
    typedef enum logic [1:0] {
        SRC_IDLE = 2'b00,
        SRC_REQ  = 2'b01,
        SRC_ACK  = 2'b10,
        SRC_RSP  = 2'b11
    } src_state_t;

    src_state_t src_state_reg, src_state_next;
    logic       src_valid_sync;

    // Destination Domain State Machine
    typedef enum logic [1:0] {
        DST_IDLE = 2'b00,
        DST_REQ  = 2'b01,
        DST_ACK  = 2'b10,
        DST_RSP  = 2'b11
    } dst_state_t;

    dst_state_t dst_state_reg, dst_state_next;
    logic       dst_ready_sync;

    // Synchronize src_valid in destination domain
    logic [1:0] src_valid_sync_dst;
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_valid_sync_dst <= 2'b00;
        else
            src_valid_sync_dst <= {src_valid_sync_dst[0], src_valid_sync_dst[1]};
    end

    // Synchronize dst_ready in source domain
    logic [1:0] dst_ready_sync_src;
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ready_sync_src <= 2'b00;
        else
            dst_ready_sync_src <= {dst_ready_sync_src[0], dst_ready_sync_src[1]};
    end

    // Synchronize resets in each domain to ensure coherent state initialization
    logic src_rst_sync, dst_rst_sync;

    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_rst_sync <= 1'b1;
        else
            src_rst_sync <= 1'b0;
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_rst_sync <= 1'b1;
        else
            dst_rst_sync <= 1'b0;
    end

    // Source Domain Logic
    always_comb begin
        src_state_next = src_state_reg;
        src_ready_o    = 1'b0;

        case (src_state_reg)
            SRC_IDLE: begin
                if (src_valid_i && !src_rst_sync)
                    src_state_next = SRC_REQ;
            end
            SRC_REQ: begin
                if (dst_ready_sync_src[1] && !src_rst_sync)
                    src_state_next = SRC_ACK;
            end
            SRC_ACK: begin
                if (dst_valid_o && !src_rst_sync)
                    src_state_next = SRC_RSP;
            end
            SRC_RSP: begin
                if (src_valid_i && !src_rst_sync)
                    src_state_next = SRC_IDLE;
            end
            default: src_state_next = SRC_IDLE;
        endcase
    end

    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_state_reg <= SRC_IDLE;
        else
            src_state_reg <= src_state_next;
    end

    // Drive outputs based on state
    always_comb begin
        case (src_state_reg)
            SRC_IDLE: begin
                src_ready_o = 1'b0;
            end
            SRC_REQ: begin
                src_ready_o = 1'b0;
            end
            SRC_ACK: begin
                src_ready_o = 1'b1;
            end
            SRC_RSP: begin
                src_ready_o = 1'b1;
            end
            default: begin
                src_ready_o = 1'b0;
            end
        endcase
    end

    // Destination Domain Logic
    always_comb begin
        dst_state_next = dst_state_reg;
        dst_valid_o    = 1'b0;

        case (dst_state_reg)
            DST_IDLE: begin
                if (src_valid_sync_dst[1] && !dst_rst_sync)
                    dst_state_next = DST_REQ;
            end
            DST_REQ: begin
                if (src_ready_o && !dst_rst_sync)
                    dst_state_next = DST_ACK;
            end
            DST_ACK: begin
                if (dst_ready_i && !dst_rst_sync)
                    dst_state_next = DST_RSP;
            end
            DST_RSP: begin
                if (src_valid_sync_dst[1] && !dst_rst_sync)
                    dst_state_next = DST_IDLE;
            end
            default: dst_state_next = DST_IDLE;
        endcase
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_state_reg <= DST_IDLE;
        else
            dst_state_reg <= dst_state_next;
    end

    // Drive outputs based on state
    always_comb begin
        case (dst_state_reg)
            DST_IDLE: begin
                dst_valid_o = 1'b0;
            end
            DST_REQ: begin
                dst_valid_o = 1'b0;
            end
            DST_ACK: begin
                dst_valid_o = 1'b1;
            end
            DST_RSP: begin
                dst_valid_o = 1'b1;
            end
            default: begin
                dst_valid_o = 1'b0;
            end
        endcase
    end

endmodule<|im_end|>
