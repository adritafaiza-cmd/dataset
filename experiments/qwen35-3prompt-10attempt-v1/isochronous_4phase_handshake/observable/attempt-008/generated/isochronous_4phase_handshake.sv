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

    // Synchronizer for dst_ready_i to src_clk domain
    // We need to detect the rising edge of dst_ready to know when the transfer is accepted
    wire dst_ready_sync_1;
    wire dst_ready_sync_2;
    wire dst_ready_sync_3;
    wire dst_ready_sync_4;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_sync_1 <= 1'b0;
            dst_ready_sync_2 <= 1'b0;
            dst_ready_sync_3 <= 1'b0;
            dst_ready_sync_4 <= 1'b0;
        end else begin
            dst_ready_sync_1 <= dst_ready_i;
            dst_ready_sync_2 <= dst_ready_sync_1;
            dst_ready_sync_3 <= dst_ready_sync_2;
            dst_ready_sync_4 <= dst_ready_sync_3;
        end
    end

    // Synchronizer for src_valid_i to dst_clk domain
    // We need to detect the rising edge of src_valid to know when data is presented
    wire src_valid_sync_1;
    wire src_valid_sync_2;
    wire src_valid_sync_3;
    wire src_valid_sync_4;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync_1 <= 1'b0;
            src_valid_sync_2 <= 1'b0;
            src_valid_sync_3 <= 1'b0;
            src_valid_sync_4 <= 1'b0;
        end else begin
            src_valid_sync_1 <= src_valid_i;
            src_valid_sync_2 <= src_valid_sync_1;
            src_valid_sync_3 <= src_valid_sync_2;
            src_valid_sync_4 <= src_valid_sync_3;
        end
    end

    // State machine in src_clk domain
    // States: IDLE, WAIT_DST_READY, ACK_SENT
    localparam IDLE = 2'b00;
    localparam WAIT_DST_READY = 2'b01;
    localparam ACK_SENT = 2'b10;

    reg [1:0] src_state;
    reg src_valid_reg;
    reg dst_ready_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state <= IDLE;
            src_valid_reg <= 1'b0;
            dst_ready_reg <= 1'b0;
            src_ready_o <= 1'b0;
        end else begin
            // State Logic
            case (src_state)
                IDLE: begin
                    if (src_valid_i) begin
                        src_valid_reg <= 1'b1;
                        src_state <= WAIT_DST_READY;
                    end else begin
                        src_valid_reg <= 1'b0;
                    end
                    src_ready_o <= 1'b0;
                end

                WAIT_DST_READY: begin
                    if (dst_ready_sync_4) begin
                        // Transfer accepted. 
                        // We set src_ready to acknowledge immediately.
                        // We will set dst_valid on the next cycle of src_clk to ensure 
                        // the handshake completes before we try to assert dst_valid again.
                        src_ready_o <= 1'b1;
                        src_state <= ACK_SENT;
                    end else begin
                        src_ready_o <= 1'b0;
                    end
                end

                ACK_SENT: begin
                    // Wait for the next cycle to assert dst_valid
                    // This ensures we don't assert dst_valid while src_ready is still high
                    // or before we have a clean edge to detect in dst domain.
                    src_ready_o <= 1'b0;
                    src_state <= IDLE;
                    // src_valid_reg is cleared in the IDLE logic of next cycle if src_valid_i is low,
                    // but we need to ensure we don't re-assert immediately if src_valid_i is still high.
                    // The IDLE logic handles src_valid_i check.
                end
            endcase

            // Update internal registers for cross-domain logic
            dst_ready_reg <= dst_ready_sync_4;
            src_valid_reg <= src_valid_i;
        end
    end

    // State machine in dst_clk domain
    // States: IDLE, WAIT_SRC_VALID, ACK_SENT
    localparam IDLE = 2'b00;
    localparam WAIT_SRC_VALID = 2'b01;
    localparam ACK_SENT = 2'b10;

    reg [1:0] dst_state;
    reg src_valid_reg_dst;
    reg src_ready_reg_dst;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state <= IDLE;
            src_valid_reg_dst <= 1'b0;
            src_ready_reg_dst <= 1'b0;
            dst_valid_o <= 1'b0;
        end else begin
            case (dst_state)
                IDLE: begin
                    if (src_valid_sync_4) begin
                        src_valid_reg_dst <= 1'b1;
                        dst_state <= WAIT_SRC_READY; // Renamed for clarity in dst domain
                    end else begin
                        src_valid_reg_dst <= 1'b0;
                    end
                    dst_valid_o <= 1'b0;
                end

                WAIT_SRC_READY: begin
                    if (src_ready_sync_4) begin
                        // Transfer accepted by src.
                        // Assert dst_valid to complete the handshake.
                        dst_valid_o <= 1'b1;
                        dst_state <= ACK_SENT;
                    end else begin
                        dst_valid_o <= 1'b0;
                    end
                end

                ACK_SENT: begin
                    // Wait for next cycle to clear dst_valid and reset state
                    dst_valid_o <= 1'b0;
                    dst_state <= IDLE;
                    src_valid_reg_dst <= 1'b0;
                    src_ready_reg_dst <= 1'b0;
                end
            endcase

            // Update internal registers for cross-domain logic
            src_valid_reg_dst <= src_valid_sync_4;
            src_ready_reg_dst <= src_ready_sync_4;
        end
    end

    // Note: The above implementation has a slight logical flow adjustment to ensure 
    // strict 4-phase handshake semantics without glitches.
    // 
    // Revised Logic Explanation:
    // 1. Src Domain:
    //    - IDLE: Wait for src_valid_i. If high, set internal valid_reg, go to WAIT_DST_READY.
    //    - WAIT_DST_READY: Wait for dst_ready_sync_4. If high, assert src_ready_o, go to ACK_SENT.
    //    - ACK_SENT: De-assert src_ready_o, go to IDLE. (src_valid_reg is handled by IDLE logic).
    //
    // 2. Dst Domain:
    //    - IDLE: Wait for src_valid_sync_4. If high, set internal valid_reg, go to WAIT_SRC_READY.
    //    - WAIT_SRC_READY: Wait for src_ready_sync_4. If high, assert dst_valid_o, go to ACK_SENT.
    //    - ACK_SENT: De-assert dst_valid_o, go to IDLE.
    //
    // This ensures:
    // - No transfer is accepted if reset is active.
    // - src_ready is only asserted after src_valid is stable and dst_ready is detected.
    // - dst_valid is only asserted after src_ready is detected.
    // - Both sides de-assert their signals in the cycle after the handshake completes.

    // Re-implementing the FSMs with the corrected state names and logic flow for clarity and correctness.
    
    // Src Domain FSM
    reg [1:0] src_fsm_state;
    reg src_valid_src_reg;
    reg dst_ready_src_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_fsm_state <= 2'b00;
            src_valid_src_reg <= 1'b0;
            dst_ready_src_reg <= 1'b0;
            src_ready_o <= 1'b0;
        end else begin
            case (src_fsm_state)
                2'b00: begin // IDLE
                    if (src_valid_i) begin
                        src_valid_src_reg <= 1'b1;
                        src_fsm_state <= 2'b01; // WAIT_DST_READY
                    end else begin
                        src_valid_src_reg <= 1'b0;
                    end
                    src_ready_o <= 1'b0;
                end
                2'b01: begin // WAIT_DST_READY
                    if (dst_ready_sync_4) begin
                        src_ready_o <= 1'b1;
                        src_fsm_state <= 2'b10; // ACK_SENT
                    end else begin
                        src_ready_o <= 1'b0;
                    end
                end
                2'b10: begin // ACK_SENT
                    src_ready_o <= 1'b0;
                    src_fsm_state <= 2'b00; // IDLE
                    // src_valid_src_reg will be cleared in next cycle if src_valid_i is low
                    // or handled by the IDLE logic if it stays high (but we don't re-assert valid here)
                end
            endcase
            dst_ready_src_reg <= dst_ready_sync_4;
        end
    end

    // Dst Domain FSM
    reg [1:0] dst_fsm_state;
    reg src_valid_dst_reg;
    reg src_ready_dst_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_fsm_state <= 2'b00;
            src_valid_dst_reg <= 1'b0;
            src_ready_dst_reg <= 1'b0;
            dst_valid_o <= 1'b0;
        end else begin
            case (dst_fsm_state)
                2'b00: begin // IDLE
                    if (src_valid_sync_4) begin
                        src_valid_dst_reg <= 1'b1;
                        dst_fsm_state <= 2'b01; // WAIT_SRC_READY
                    end else begin
                        src_valid_dst_reg <= 1'b0;
                    end
                    dst_valid_o <= 1'b0;
                end
                2'b01: begin // WAIT_SRC_READY
                    if (src_ready_sync_4) begin
                        dst_valid_o <= 1'b1;
                        dst_fsm_state <= 2'b10; // ACK_SENT
                    end else begin
                        dst_valid_o <= 1'b0;
                    end
                end
                2'b10: begin // ACK_SENT
                    dst_valid_o <= 1'b0;
                    dst_fsm_state <= 2'b00; // IDLE
                    src_valid_dst_reg <= 1'b0;
                    src_ready_dst_reg <= 1'b0;
                end
            endcase
            src_ready_dst_reg <= src_ready_sync_4;
        end
    end

endmodule
```<|im_end|>
