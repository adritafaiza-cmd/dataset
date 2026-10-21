```systemverilog
module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // ---------------------------------------------------------
  // Source Domain Logic
  // ---------------------------------------------------------
  logic src_state;
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_state_next;
  logic src_data_next;
  logic src_valid_next;
  logic src_ready;

  // State encoding:
  // 0: IDLE
  // 1: WAIT_DST_READY (holding data, waiting for dst_ready)
  // 2: ACCEPT_NEW (if DECOUPLED, can accept new data while waiting)
  
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= 1'b0;
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
    end else begin
      src_state <= src_state_next;
      src_data_reg <= src_data_next;
      src_valid_reg <= src_valid_next;
    end
  end

  assign src_ready = (src_state == 1'b0) || (src_state == 1'b2);

  always_comb begin
    src_state_next = src_state;
    src_data_next = src_data_reg;
    src_valid_next = src_valid_reg;

    case (src_state)
      1'b0: begin // IDLE
        if (src_valid_i && dst_ready_i) begin
          src_state_next = 1'b1;
          src_data_next = src_data_i;
          src_valid_next = 1'b1;
        end else if (DECOUPLED && src_valid_i && dst_ready_i) begin
          // If decoupled, we can immediately accept and move to wait state
          // But standard 4-phase usually waits for ready before accepting.
          // However, the requirement says "source may accept a new item before 
          // the previous destination handshake returns".
          // This implies: Accept -> Move to Wait -> Wait for Ready -> Send.
          // So if we are in IDLE and get valid+ready, we go to WAIT.
          // If we are in WAIT and get valid+ready, we go to ACCEPT_NEW.
          src_state_next = 1'b2;
          src_data_next = src_data_i;
          src_valid_next = 1'b1;
        end
      end

      1'b1: begin // WAIT_DST_READY (Holding data, waiting for dst_ready)
        if (dst_ready_i) begin
          src_state_next = 1'b0;
          src_valid_next = 1'b0;
        end
      end

      1'b2: begin // ACCEPT_NEW (Can accept new data while waiting for previous to clear)
        if (src_valid_i && dst_ready_i) begin
          src_state_next = 1'b1; // Move to wait for the NEW item
          src_data_next = src_data_i;
          src_valid_next = 1'b1;
        end else if (dst_ready_i) begin
          // Previous item sent, go back to idle
          src_state_next = 1'b0;
          src_valid_next = 1'b0;
        end
      end
    endcase
  end

  // ---------------------------------------------------------
  // Destination Domain Logic (4-Phase FIFO)
  // ---------------------------------------------------------
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_state;
  logic dst_state_next;
  logic dst_data_next;
  logic dst_valid_next;
  logic dst_reset_msg;

  // State encoding:
  // 0: IDLE
  // 1: WAIT_SRC_VALID (holding data, waiting for src_valid)
  // 2: WAIT_SRC_READY (holding data, waiting for src_ready)
  // 3: SEND (sending data, waiting for dst_ready)
  // 4: RESET_MSG (sending reset message)

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= 1'b0;
      dst_data_reg <= '0;
      dst_valid_reg <= 1'b0;
      dst_reset_msg <= 1'b0;
    end else begin
      dst_state <= dst_state_next;
      dst_data_reg <= dst_data_next;
      dst_valid_reg <= dst_valid_next;
      dst_reset_msg <= 1'b0; // Reset message is transient, cleared after send
    end
  end

  assign dst_valid_o = (dst_state == 1'b1) || (dst_state == 1'b2) || (dst_state == 1'b3) || (dst_state == 1'b4);
  assign dst_data_o = (dst_state == 1'b1) || (dst_state == 1'b2) || (dst_state == 1'b3) || (dst_state == 1'b4) ? dst_data_reg : '0;

  always_comb begin
    dst_state_next = dst_state;
    dst_data_next = dst_data_reg;
    dst_valid_next = dst_valid_reg;
    dst_reset_msg = 1'b0;

    case (dst_state)
      1'b0: begin // IDLE
        if (src_valid_reg) begin
          dst_state_next = 1'b1;
          dst_data_next = src_data_reg;
          dst_valid_next = 1'b1;
        end
      end

      1'b1: begin // WAIT_SRC_VALID (Data captured, waiting for src_ready)
        if (src_ready_o) begin
          dst_state_next = 1'b2;
        end
      end

      1'b2: begin // WAIT_SRC_READY (Src ready acknowledged, waiting for dst_ready)
        if (dst_ready_i) begin
          dst_state_next = 1'b3;
        end
      end

      1'b3: begin // SEND (Sending data, waiting for dst_ready)
        if (dst_ready_i) begin
          dst_state_next = 1'b0;
          dst_valid_next = 1'b0;
        end
      end

      1'b4: begin // SEND_RESET_MSG
        if (dst_ready_i) begin
          dst_state_next = 1'b0;
          dst_valid_next = 1'b0;
        end
      end
    endcase
  end

  // ---------------------------------------------------------
  // Reset Message Logic
  // ---------------------------------------------------------
  logic reset_msg_active;
  logic [WIDTH-1:0] reset_msg_data;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      reset_msg_active <= 1'b0;
    end else begin
      if (SEND_RESET_MSG && !dst_rst_ni) begin
        // Detect reset release
        reset_msg_active <= 1'b1;
      end else if (SEND_RESET_MSG && dst_rst_ni) begin
        reset_msg_active <= 1'b0;
      end else if (SEND_RESET_MSG && reset_msg_active && dst_ready_i) begin
        // Send the message and clear flag
        reset_msg_active <= 1'b0;
      end
    end
  end

  // Override data and state if reset message is active
  // We need to inject the reset message into the state machine or override outputs.
  // To ensure CDC safety, we will override the state machine behavior when reset_msg_active is high.
  
  // Re-evaluate state machine with reset message injection
  // The previous state machine logic needs to be modified to handle the reset message path.
  // Let's refactor the destination state machine to include the reset message path explicitly.

  logic [WIDTH-1:0] dst_data_override;
  logic dst_valid_override;
  logic dst_state_override;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state_override <= 1'b0;
      dst_data_override <= '0;
      dst_valid_override <= 1'b0;
    end else begin
      if (SEND_RESET_MSG && !dst_rst_ni) begin
        // Reset release detected
        dst_state_override <= 1'b4;
        dst_data_override <= RESET_MSG;
        dst_valid_override <= 1'b1;
      end else if (SEND_RESET_MSG && dst_rst_ni) begin
        dst_state_override <= 1'b0;
        dst_data_override <= '0;
        dst_valid_override <= 1'b0;
      end else if (SEND_RESET_MSG && dst_state_override == 1'b4 && dst_ready_i) begin
        dst_state_override <= 1'b0;
        dst_data_override <= '0;
        dst_valid_override <= 1'b0;
      end else begin
        // Normal operation
        dst_state_override <= dst_state_next;
        dst_data_override <= dst_data_next;
        dst_valid_override <= dst_valid_next;
      end
    end
  end

  // Re-implement the state transitions for normal operation considering the reset message path
  // We need to separate the state machine logic from the reset message logic to avoid conflicts.
  
  logic [WIDTH-1:0] dst_data_fsm;
  logic dst_valid_fsm;
  logic dst_state_fsm;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state_fsm <= 1'b0;
      dst_data_fsm <= '0;
      dst_valid_fsm <= 1'b0;
    end else begin
      if (SEND_RESET_MSG && !dst_rst_ni) begin
        dst_state_fsm <= 1'b4;
        dst_data_fsm <= RESET_MSG;
        dst_valid_fsm <= 1'b1;
      end else if (SEND_RESET_MSG && dst_rst_ni) begin
        dst_state_fsm <= 1'b0;
        dst_data_fsm <= '0;
        dst_valid_fsm <= 1'b0;
      end else if (SEND_RESET_MSG && dst_state_fsm == 1'b4 && dst_ready_i) begin
        dst_state_fsm <= 1'b0;
        dst_data_fsm <= '0;
        dst_valid_fsm <= 1'b0;
      end else begin
        dst_state_fsm <= dst_state_next;
        dst_data_fsm <= dst_data_next;
        dst_valid_fsm <= dst_valid_next;
      end
    end
  end

  // Re-implement state transitions for normal operation
  always_comb begin
    dst_state_next = dst_state_fsm;
    dst_data_next = dst_data_fsm;
    dst_valid_next = dst_valid_fsm;

    case (dst_state_fsm)
      1'b0: begin // IDLE
        if (src_valid_reg) begin
          dst_state_next = 1'b1;
          dst_data_next = src_data_reg;
          dst_valid_next = 1'b1;
        end
      end

      1'b1: begin // WAIT_SRC_VALID
        if (src_ready_o) begin
          dst_state_next = 1'b2;
        end
      end

      1'b2: begin // WAIT_SRC_READY
        if (dst_ready_i) begin
          dst_state_next = 1'b3;
        end
      end

      1'b3: begin // SEND
        if (dst_ready_i) begin
          dst_state_next = 1'b0;
          dst_valid_next = 1'b0;
        end
      end

      1'b4: begin // SEND_RESET_MSG
        if (dst_ready_i) begin
          dst_state_next = 1'b0;
          dst_valid_next = 1'b0;
        end
      end
    endcase
  end

  // Final outputs
  assign dst_data_o = (SEND_RESET_MSG && !dst_rst_ni) ? RESET_MSG : dst_data_fsm;
  assign dst_valid_o = (SEND_RESET_MSG && !dst_rst_ni) ? 1'b1 : dst_valid_fsm;

  // Note: The reset message logic above has a potential issue with the state machine reset.
  // When reset is released, we force state to 4. But if the state machine was in a different state,
  // we need to ensure we don't lose the current data if we were in the middle of a transfer.
  // However, the requirement says "Reset must not create a spurious destination beat unless SEND_RESET_MSG is set."
  // This implies that during reset, we should not send data.
  // The logic above handles this by only entering state 4 on reset release.
  // But we need to ensure that if we were in state 1, 2, or 3 during reset, we don't send data.
  // The current logic sets dst_valid_o to 1'b1 only if SEND_RESET_MSG is set AND !dst_rst_ni.
  // This means if we are in state 1, 2, or 3 during reset, dst_valid_o will be 0 (because the override condition fails).
  // Wait, the override logic:
  // if (SEND_RESET_MSG && !dst_rst_ni) -> State 4, Valid 1
  // else if (SEND_RESET_MSG && dst_rst_ni) -> State 0, Valid 0
  // else if (SEND_RESET_MSG && State 4 && Ready) -> State 0, Valid 0
  // else -> Normal FSM.
  
  // If we are in State 1, 2, or 3 during reset (dst_rst_ni == 0), the 'else' branch is taken.
  // In the 'else' branch, we update the FSM state.
  // But we also need to ensure that dst_valid_o is 0 during reset if we are not sending the reset message.
  // The current logic for dst_valid_o is:
  // (SEND_RESET_MSG && !dst_rst_ni) ? 1'b1 : dst_valid_fsm;
  // If SEND_RESET_MSG is 1 and dst_rst_ni is 0 (reset active), dst_valid_o becomes 0.
  // This is correct.
  // If SEND_RESET_MSG is 0, dst_valid_o is dst_valid_fsm.
  // If SEND_RESET_MSG is 1 and dst_rst_ni is 1 (reset inactive), dst_valid_o is dst_valid_fsm.
  // BUT, if we are in state 1, 2, or 3 during reset release, we might have valid data.
  // The requirement says "Reset must not create a spurious destination beat unless SEND_RESET_MSG is set."
  // This means if SEND_RESET_MSG is 0, we should not send data during reset.
  // So we need to gate the FSM output with the reset signal if SEND_RESET_MSG is 0.
  
  // Let's refine the output logic:
  // If SEND_RESET_MSG is 0:
  //   If dst_rst_ni is 0 (reset active), dst_valid_o = 0.
  //   If dst_rst_ni is 1 (reset inactive), dst_valid_o = dst_valid_fsm.
  // If SEND_RESET_MSG is 1:
  //   If dst_rst_ni is 0 (reset active), dst_valid_o = 0.
  //   If dst_rst_ni is 1 (reset inactive):
  //     If we just released reset, send RESET_MSG.
  //     Else, send normal data.
  
  // The current logic for dst_valid_o:
  // assign dst_valid_o = (SEND_RESET_MSG && !dst_rst_ni) ? 1'b1 : dst_valid_fsm;
  // This is incorrect because if SEND_RESET_MSG is 0 and dst_rst_ni is 0, dst_valid_o is dst_valid_fsm.
  // We need to ensure dst_valid_o is 0 during reset if SEND_RESET_MSG is 0.
  
  // Correct logic:
  // If SEND_RESET_MSG is 0:
  //   dst_valid_o = (!dst_rst_ni) ? 1'b0 : dst_valid_fsm;
  // If SEND_RESET_MSG is 1:
  //   dst_valid_o = (dst_rst_ni) ? 1'b0 : ((reset_msg_active) ? 1'b1 : dst_valid_fsm);
  
  // Let's simplify:
  // We can use a combined logic for dst_valid_o.
  // If SEND_RESET_MSG is 0:
  //   dst_valid_o = (!dst_rst_ni) ? 1'b0 : dst_valid_fsm;
  // If SEND_RESET_MSG is 1:
  //   dst_valid_o = (dst_rst_ni) ? 1'b0 : ((reset_msg_active) ? 1'b1 : dst_valid_fsm);
  
  // Actually, the reset_msg_active logic is already handled in the FSM state machine.
  // If SEND_RESET_MSG is 1 and !dst_rst_ni, we force state to 4 and valid to 1.
  // So the FSM state machine will output valid=1 in state 4.
  // But if we are in state 1, 2, or 3 during reset release, the FSM state machine will update the state.
  // We need to ensure that during reset release, we don't send the old data.
  // The current logic for dst_valid_o:
  // assign dst_valid_o = (SEND_RESET_MSG && !dst_rst_ni) ? 1'b1 : dst_valid_fsm;
  // This means if SEND_RESET_MSG is 1 and !dst_rst_ni, dst_valid_o is 1.
  // But if we are in state 1, 2, or 3 during reset release, dst_valid_fsm might be 1.
  // We need to ensure that during reset release, we only send RESET_MSG.
  
  // Let's restructure the destination logic to be cleaner.
  
  logic [WIDTH-1:0] dst_data_final;
  logic dst_valid_final;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state_fsm <= 1'b0;
      dst_data_fsm <= '0;
      dst_valid_fsm <= 1'b0;
      reset_msg_active <= 1'b0;
    end else begin
      if (SEND_RESET_MSG && !dst_rst_ni) begin
        // Reset release
        dst_state_fsm <= 1'b4;
        dst_data_fsm <= RESET_MSG;
        dst_valid_fsm <= 1'b1;
        reset_msg_active <= 1'b1;
      end else if (SEND_RESET_MSG && dst_rst_ni) begin
        dst_state_fsm <= 1'b0;
        dst_data_fsm <= '0;
        dst_valid_fsm <= 1'b0;
        reset_msg_active <= 1'b0;
      end else if (SEND_RESET_MSG && dst_state_fsm == 1'b4 && dst_ready_i) begin
        dst_state_fsm <= 1'b0;
        dst_data_fsm <= '0;
        dst_valid_fsm <= 1'b0;
        reset_msg_active <= 1'b0;
      end else begin
        dst_state_fsm <= dst_state_next;
        dst_data_fsm <= dst_data_next;
        dst_valid_fsm <= dst_valid_next;
        reset_msg_active <= 1'b0;
      end
    end
  end

  // State transitions for normal operation
  always_comb begin
    dst_state_next = dst_state_fsm;
    dst_data_next = dst_data_fsm;
    dst_valid_next = dst_valid_fsm;

    case (dst_state_fsm)
      1'b0: begin // IDLE
        if (src_valid_reg) begin
          dst_state_next = 1'b1;
          dst_data_next = src_data_reg;
          dst_valid_next = 1'b1;
        end
      end

      1'b1: begin // WAIT_SRC_VALID
        if (src_ready_o) begin
          dst_state_next = 1'b2;
        end
      end

      1'b2: begin // WAIT_SRC_READY
        if (dst_ready_i) begin
          dst_state_next = 1'b3;
        end
      end

      1'b3: begin // SEND
        if (dst_ready_i) begin
          dst_state_next = 1'b0;
          dst_valid_next = 1'b0;
        end
      end

      1'b4: begin // SEND_RESET_MSG
        if (dst_ready_i) begin
          dst_state_next = 1'b0;
          dst_valid_next = 1'b0;
        end
      end
    endcase
  end

  // Final output logic
  if (SEND_RESET_MSG) begin
    assign dst_data_o = (dst_state_fsm == 1'b4) ? RESET_MSG : dst_data_fsm;
    assign dst_valid_o = (dst_state_fsm == 1'b4) ? 1'b1 : dst_valid_fsm;
  end else begin
    assign dst_data_o = dst_data_fsm;
    assign dst_valid_o = (!dst_rst_ni) ? dst_valid_fsm : 1'b0;
  end

endmodule
```<|im_end|>
