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

  // Sender side (src_clk_i domain)
  // State machine for 4-phase handshake:
  // IDLE -> WAIT_VALID -> WAIT_READY -> IDLE
  // We also need to handle the reset message if enabled.
  
  localparam STATE_IDLE = 2'b00;
  localparam STATE_WAIT_VALID = 2'b01;
  localparam STATE_WAIT_READY = 2'b10;
  localparam STATE_SEND_RESET = 2'b11;

  reg [1:0] sender_state;
  reg [WIDTH-1:0] sender_data_reg;
  reg sender_valid_reg;
  reg sender_ready_reg;
  
  // Internal signals for handshake
  wire src_valid_internal;
  wire src_ready_internal;

  assign src_valid_internal = (sender_state == STATE_WAIT_VALID) ? sender_valid_reg : 1'b0;
  assign src_ready_internal = (sender_state == STATE_WAIT_READY) ? sender_ready_reg : 1'b0;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sender_state <= STATE_IDLE;
      sender_data_reg <= '0;
      sender_valid_reg <= 1'b0;
      sender_ready_reg <= 1'b0;
    end else begin
      case (sender_state)
        STATE_IDLE: begin
          if (src_valid_i) begin
            sender_state <= STATE_WAIT_VALID;
            sender_data_reg <= src_data_i;
            sender_valid_reg <= 1'b1;
          end
          // src_ready_o is driven by the receiver's ready signal in the receiver side logic? 
          // No, in 4-phase handshake, the sender drives ready when it is waiting for valid, 
          // and drives valid when it is waiting for ready.
          // Actually, standard 4-phase:
          // 1. Sender sets Valid (and Ready=1)
          // 2. Receiver sees Valid, sets Ready (and Valid=0)
          // 3. Sender sees Ready, sets Valid=0 (data stable)
          // 4. Receiver sees Valid=0, sets Ready=0 (data consumed)
          
          // Let's refine the state machine logic based on standard 4-phase protocol:
          // State 0 (IDLE): Wait for Valid. Output: Valid=0, Ready=1.
          // State 1 (WAIT_VALID): Valid is asserted. Output: Valid=1, Ready=1.
          // State 2 (WAIT_READY): Ready is asserted by receiver. Output: Valid=1, Ready=0.
          // State 3 (DONE): Ready was asserted. Output: Valid=0, Ready=0.
          
          // However, the problem asks for a specific 4-phase valid/ready channel.
          // Common implementation:
          // Sender:
          //   - On Valid input: Set internal_valid = 1, internal_ready = 1.
          //   - On internal_ready & dst_ready_i: Set internal_valid = 0, internal_ready = 0.
          //   - On internal_ready & !dst_ready_i: Keep internal_valid = 1, internal_ready = 0.
          
          // Let's stick to the state machine approach for clarity and robustness.
          
          if (src_valid_i) begin
            sender_state <= STATE_WAIT_VALID;
            sender_data_reg <= src_data_i;
            sender_valid_reg <= 1'b1;
            sender_ready_reg <= 1'b1;
          end else if (sender_state == STATE_WAIT_VALID) begin
            sender_state <= STATE_WAIT_READY;
            sender_ready_reg <= 1'b0;
          end else if (sender_state == STATE_WAIT_READY) begin
            if (dst_ready_i) begin
              sender_state <= STATE_IDLE;
              sender_valid_reg <= 1'b0;
              sender_ready_reg <= 1'b1;
            end
            // If !dst_ready_i, stay in WAIT_READY, keep valid=1, ready=0
          end else begin
            sender_state <= STATE_IDLE;
            sender_valid_reg <= 1'b0;
            sender_ready_reg <= 1'b1;
          end
        end
      endcase
    end
  end

  // Receiver side (dst_clk_i domain)
  // State machine:
  // IDLE -> WAIT_VALID -> WAIT_READY -> IDLE
  
  localparam RSTATE_IDLE = 2'b00;
  localparam RSTATE_WAIT_VALID = 2'b01;
  localparam RSTATE_WAIT_READY = 2'b10;
  localparam RSTATE_SEND_RESET = 2'b11;

  reg [1:0] receiver_state;
  reg [WIDTH-1:0] receiver_data_reg;
  reg receiver_valid_reg;
  reg receiver_ready_reg;
  
  // Internal signals for handshake
  wire dst_valid_internal;
  wire dst_ready_internal;

  assign dst_valid_internal = (receiver_state == RSTATE_WAIT_VALID) ? receiver_valid_reg : 1'b0;
  assign dst_ready_internal = (receiver_state == RSTATE_WAIT_READY) ? receiver_ready_reg : 1'b0;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      receiver_state <= RSTATE_IDLE;
      receiver_data_reg <= '0;
      receiver_valid_reg <= 1'b0;
      receiver_ready_reg <= 1'b0;
    end else begin
      case (receiver_state)
        RSTATE_IDLE: begin
          if (src_valid_internal) begin
            receiver_state <= RSTATE_WAIT_VALID;
            receiver_data_reg <= src_data_i;
            receiver_valid_reg <= 1'b1;
            receiver_ready_reg <= 1'b1;
          end
        end
        RSTATE_WAIT_VALID: begin
          if (src_valid_internal) begin
            // Data is stable, now wait for ready
            receiver_state <= RSTATE_WAIT_READY;
            receiver_ready_reg <= 1'b0;
          end
        end
        RSTATE_WAIT_READY: begin
          if (src_valid_internal && dst_ready_i) begin
            receiver_state <= RSTATE_IDLE;
            receiver_valid_reg <= 1'b0;
            receiver_ready_reg <= 1'b1;
          end
          // If !dst_ready_i, stay in WAIT_READY, keep valid=1, ready=0
        end
        RSTATE_SEND_RESET: begin
          if (src_valid_internal) begin
            receiver_state <= RSTATE_IDLE;
            receiver_valid_reg <= 1'b0;
            receiver_ready_reg <= 1'b1;
          end
        end
      endcase
    end
  end

  // Output assignments
  assign src_ready_o = (sender_state == STATE_WAIT_VALID) ? 1'b1 : 1'b0;
  assign dst_data_o = receiver_data_reg;
  assign dst_valid_o = dst_valid_internal;

  // Reset message handling
  if (SEND_RESET_MSG) begin
    // If the receiver is in reset state or needs to send reset message
    // This is a bit tricky in a 4-phase handshake. Usually, reset messages are sent 
    // when the system comes out of reset.
    // We will implement a simple version: if SEND_RESET_MSG is 1, and we are in IDLE,
    // we might need to send the reset message.
    // However, the prompt says "Respect the decoupled option and the configured reset-message behavior."
    // Without a specific protocol for reset messages (e.g., specific pattern), 
    // we assume that if SEND_RESET_MSG is 1, the sender should send RESET_MSG when it first becomes valid after reset.
    
    // Let's modify the sender state machine to handle reset messages.
    // If SEND_RESET_MSG is 1, the first valid pulse after reset should carry RESET_MSG.
    
    // Re-implementing sender state machine with reset message support
    // States: IDLE, WAIT_VALID, WAIT_READY, SEND_RESET_MSG_STATE
    
    // Actually, let's keep the state machine simple and handle the reset message in the data path.
    // If SEND_RESET_MSG is 1, we need to ensure the first data sent is RESET_MSG.
    // We can use a flag to track if we have sent the reset message.
    
    reg [WIDTH-1:0] sender_data_reg_reset;
    reg sender_reset_sent;
    
    always @(posedge src_clk_i or negedge src_rst_ni) begin
      if (!src_rst_ni) begin
        sender_reset_sent <= 1'b0;
        sender_data_reg_reset <= '0;
      end else begin
        if (src_valid_i) begin
          if (!sender_reset_sent) begin
            sender_data_reg_reset <= RESET_MSG;
            sender_reset_sent <= 1'b1;
          end else begin
            sender_data_reg_reset <= src_data_i;
          end
        end
      end
    end
    
    // Update sender_data_reg to use the reset message logic if enabled
    if (SEND_RESET_MSG) begin
      sender_data_reg <= sender_data_reg_reset;
    end else begin
      sender_data_reg <= src_data_i;
    end
  end

  // Similarly for the receiver side if SEND_RESET_MSG is 1, we might need to handle it differently?
  // Usually, the sender sends the reset message, and the receiver just consumes it.
  // The receiver doesn't need to do anything special unless it needs to acknowledge it, 
  // but the prompt doesn't specify an acknowledgment for the reset message.
  // So the receiver just consumes whatever is sent.

  // Re-checking the sender state machine logic with the reset message integration.
  // The previous state machine logic for sender was:
  // IDLE -> WAIT_VALID (on src_valid_i) -> WAIT_READY (on src_valid_i) -> IDLE (on dst_ready_i)
  
  // With reset message, the first valid pulse after reset should carry RESET_MSG.
  // The state machine logic remains the same, but the data loaded into sender_data_reg is modified.
  
  // Let's re-verify the sender state machine logic.
  // In the previous block, I had:
  // if (src_valid_i) ... sender_data_reg <= src_data_i;
  // This needs to be updated to use sender_data_reg_reset if SEND_RESET_MSG is 1.
  
  // Corrected sender logic:
  // The state machine determines the handshake signals (src_ready_o, dst_valid_o).
  // The data path determines what data is sent.
  
  // Let's rewrite the sender block cleanly.
  
  // Sender State Machine
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sender_state <= STATE_IDLE;
      sender_valid_reg <= 1'b0;
      sender_ready_reg <= 1'b1;
    end else begin
      case (sender_state)
        STATE_IDLE: begin
          if (src_valid_i) begin
            sender_state <= STATE_WAIT_VALID;
            sender_valid_reg <= 1'b1;
            sender_ready_reg <= 1'b1;
          end
        end
        STATE_WAIT_VALID: begin
          if (src_valid_i) begin
            sender_state <= STATE_WAIT_READY;
            sender_ready_reg <= 1'b0;
          end
        end
        STATE_WAIT_READY: begin
          if (src_valid_i && dst_ready_i) begin
            sender_state <= STATE_IDLE;
            sender_valid_reg <= 1'b0;
            sender_ready_reg <= 1'b1;
          end
          // If !dst_ready_i, stay in WAIT_READY, valid=1, ready=0
        end
      endcase
    end
  end

  // Sender Data Logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sender_data_reg <= '0;
    end else begin
      if (src_valid_i) begin
        if (SEND_RESET_MSG) begin
          // Check if we have already sent the reset message
          // We can use a separate flag or check the state.
          // Since we are in STATE_WAIT_VALID when src_valid_i is high, 
          // we can check if we have sent the reset message.
          // But the state machine doesn't track this.
          // Let's add a flag.
        end else begin
          sender_data_reg <= src_data_i;
        end
      end
    end
  end

  // To properly handle the reset message, we need a flag in the sender.
  reg sender_reset_sent;
  
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sender_reset_sent <= 1'b0;
    end else begin
      if (src_valid_i) begin
        if (!sender_reset_sent) begin
          sender_data_reg <= RESET_MSG;
          sender_reset_sent <= 1'b1;
        end else begin
          sender_data_reg <= src_data_i;
        end
      end
    end
  end

  // Receiver State Machine
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      receiver_state <= RSTATE_IDLE;
      receiver_valid_reg <= 1'b0;
      receiver_ready_reg <= 1'b1;
    end else begin
      case (receiver_state)
        RSTATE_IDLE: begin
          if (src_valid_internal) begin
            receiver_state <= RSTATE_WAIT_VALID;
            receiver_valid_reg <= 1'b1;
            receiver_ready_reg <= 1'b1;
          end
        end
        RSTATE_WAIT_VALID: begin
          if (src_valid_internal) begin
            receiver_state <= RSTATE_WAIT_READY;
            receiver_ready_reg <= 1'b0;
          end
        end
        RSTATE_WAIT_READY: begin
          if (src_valid_internal && dst_ready_i) begin
            receiver_state <= RSTATE_IDLE;
            receiver_valid_reg <= 1'b0;
            receiver_ready_reg <= 1'b1;
          end
          // If !dst_ready_i, stay in WAIT_READY, valid=1, ready=0
        end
      endcase
    end
  end

  // Receiver Data Logic
  // The receiver just captures the data when it is in WAIT_VALID state.
  // The data is stable when the sender is in WAIT_READY state.
  // So we capture the data when transitioning from WAIT_VALID to WAIT_READY?
  // No, the data is stable when the sender is in WAIT_READY.
  // The receiver should capture the data when it sees the valid signal going high?
  // No, in 4-phase handshake, the data is stable when the sender is in WAIT_READY.
  // The receiver sees the valid signal going high in WAIT_VALID state.
  // The data is stable at that moment.
  // So we can capture the data in the WAIT_VALID state.
  
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      receiver_data_reg <= '0;
    end else begin
      if (src_valid_internal) begin
        // When src_valid_internal is high, the data is stable.
        // We capture it here.
        receiver_data_reg <= src_data_i;
      end
    end
  end

  // Output assignments
  assign src_ready_o = (sender_state == STATE_WAIT_VALID) ? 1'b1 : 1'b0;
  assign dst_valid_o = dst_valid_internal;
  assign dst_data_o = receiver_data_reg;

endmodule
```<|im_end|>
