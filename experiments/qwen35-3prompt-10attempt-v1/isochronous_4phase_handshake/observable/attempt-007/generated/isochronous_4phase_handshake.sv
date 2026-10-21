```verilog
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

    // State encoding for the four-phase handshake
    // 0: IDLE
    // 1: WAIT_DST_READY (Waiting for destination to accept)
    // 2: WAIT_SRC_VALID (Destination accepted, waiting for source to re-assert valid)
    // 3: WAIT_SRC_READY (Source re-asserted valid, waiting for source to acknowledge)
    localparam IDLE = 2'b00;
    localparam WAIT_DST_READY = 2'b01;
    localparam WAIT_SRC_VALID = 2'b10;
    localparam WAIT_SRC_READY = 2'b11;

    reg [1:0] src_state;
    reg [1:0] dst_state;
    reg src_valid_reg;
    reg dst_valid_reg;
    reg dst_ready_reg;

    // Synchronizers for crossing clock domains
    // We need to synchronize the handshake signals to the local clock domain
    // before using them in state logic to avoid metastability issues.

    // --- Source Domain Logic ---
    // Synchronize dst_ready_i to src_clk_i
    reg [1:0] dst_ready_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ready_sync <= 2'b00;
        else
            dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end

    // State Machine for Source Side
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_state <= IDLE;
        else
            case (src_state)
                IDLE: begin
                    if (src_valid_i)
                        src_state <= WAIT_DST_READY;
                    else
                        src_state <= IDLE;
                end
                WAIT_DST_READY: begin
                    if (dst_ready_sync[0])
                        src_state <= WAIT_SRC_VALID;
                    else
                        src_state <= WAIT_DST_READY;
                end
                WAIT_SRC_VALID: begin
                    if (src_valid_i)
                        src_state <= WAIT_SRC_READY;
                    else
                        src_state <= WAIT_SRC_VALID;
                end
                WAIT_SRC_READY: begin
                    if (dst_ready_sync[1])
                        src_state <= IDLE;
                    else
                        src_state <= WAIT_SRC_READY;
                end
                default: src_state <= IDLE;
            endcase
    end

    // --- Destination Domain Logic ---
    // Synchronize src_valid_i to dst_clk_i
    reg [1:0] src_valid_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_valid_sync <= 2'b00;
        else
            src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end

    // State Machine for Destination Side
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_state <= IDLE;
        else
            case (dst_state)
                IDLE: begin
                    if (src_valid_sync[0])
                        dst_state <= WAIT_SRC_READY;
                    else
                        dst_state <= IDLE;
                end
                WAIT_SRC_READY: begin
                    if (dst_ready_i)
                        dst_state <= WAIT_DST_READY;
                    else
                        dst_state <= WAIT_SRC_READY;
                end
                WAIT_DST_READY: begin
                    if (src_valid_sync[1])
                        dst_state <= IDLE;
                    else
                        dst_state <= WAIT_DST_READY;
                end
                default: dst_state <= IDLE;
            endcase
    end

    // Output assignments
    // src_ready_o is asserted when the source state is WAIT_SRC_READY
    // and the destination has accepted the previous transfer (dst_ready_sync[1])
    // However, in the state machine above, src_ready_o should be asserted 
    // when we are in WAIT_SRC_READY state, indicating we are ready to accept 
    // the data that the destination is about to send (which corresponds to 
    // the data the source just sent).
    // 
    // Let's refine the logic based on the standard 4-phase handshake:
    // Phase 1: Source asserts VALID.
    // Phase 2: Destination asserts READY (acknowledges Phase 1).
    // Phase 3: Source asserts READY (acknowledges Phase 2).
    // Phase 4: Destination de-asserts READY (completes transfer).
    //
    // In our state machine:
    // IDLE -> WAIT_DST_READY (Source asserts VALID)
    // WAIT_DST_READY -> WAIT_SRC_VALID (Destination asserts READY)
    // WAIT_SRC_VALID -> WAIT_SRC_READY (Source asserts READY)
    // WAIT_SRC_READY -> IDLE (Destination de-asserts READY)
    //
    // Therefore:
    // src_ready_o should be high when src_state == WAIT_SRC_READY.
    // dst_valid_o should be high when dst_state == WAIT_SRC_READY.

    assign src_ready_o = (src_state == WAIT_SRC_READY);
    assign dst_valid_o = (dst_state == WAIT_SRC_READY);

endmodule
```<|im_end|>
