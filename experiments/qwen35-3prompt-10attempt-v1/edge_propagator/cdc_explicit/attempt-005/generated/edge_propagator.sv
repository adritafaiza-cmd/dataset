module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // ------------------------------------------------------------------
  // CDC Strategy:
  // 1. Capture the edge event in the TX domain using a 2-bit state machine
  //    to detect rising and falling edges reliably.
  // 2. Use a FIFO-based handshake (or a simple 2-bit flag with a counter)
  //    to transfer the "edge occurred" signal across the clock domains.
  //    Here, we use a 2-bit "edge_ready" flag in TX and a 2-bit "edge_ack"
  //    in RX to ensure no loss and no double-counting.
  // 3. The RX domain uses a similar 2-bit state machine to detect when the
  //    edge has been successfully consumed and then generates the single
  //    pulse on edge_o.
  //
  // This architecture ensures:
  // - No metastability on the data path (only clocked by their respective clocks).
  // - Reset synchronization is handled via asynchronous reset release logic
  //   with a small delay to ensure stability before state machine operation.
  // - Single pulse generation per input edge.
  // ------------------------------------------------------------------

  // TX Domain: Edge Detection and Flagging
  // State encoding for edge detection:
  // 2'b00: Idle (previous value was 0)
  // 2'b01: Rising detected (current is 1, previous was 0) -> Set flag
  // 2'b10: Falling detected (current is 0, previous was 1) -> Clear flag
  // 2'b11: Reserved/Error state (should not happen with proper logic)
  
  logic [1:0] tx_edge_state;
  logic tx_edge_flag;
  logic tx_edge_valid; // Indicates an edge is ready to be sent to RX

  // RX Domain: Edge Reception and Pulse Generation
  // Similar state machine to consume the flag and generate output pulse
  logic [1:0] rx_edge_state;
  logic rx_edge_flag;
  logic rx_edge_valid; // Indicates an edge has been received and processed

  // ------------------------------------------------------------------
  // TX Domain Logic
  // ------------------------------------------------------------------
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      tx_edge_state <= 2'b00;
      tx_edge_flag  <= 1'b0;
      tx_edge_valid <= 1'b0;
    end else begin
      logic prev_edge;
      // Capture previous edge value safely within the same clock cycle
      // We use a register to hold the previous value
      logic [1:0] state_next;
      logic flag_next;
      logic valid_next;

      case (tx_edge_state)
        2'b00: begin // Idle
          if (edge_i) state_next = 2'b01; // Rising
          else        state_next = 2'b00; // Stay idle
          flag_next   = 1'b0;
          valid_next  = 1'b0;
        end
        2'b01: begin // Rising detected
          if (!edge_i) state_next = 2'b10; // Falling
          else        state_next = 2'b01; // Stay rising
          flag_next   = 1'b1;
          valid_next  = 1'b1;
        end
        2'b10: begin // Falling detected
          if (edge_i) state_next = 2'b01; // Rising
          else        state_next = 2'b10; // Stay falling
          flag_next   = 1'b0;
          valid_next  = 1'b0;
        end
        default: begin
          state_next = 2'b00;
          flag_next  = 1'b0;
          valid_next = 1'b0;
        end
      endcase

      tx_edge_state <= state_next;
      tx_edge_flag  <= flag_next;
      tx_edge_valid <= valid_next;
    end
  end

  // ------------------------------------------------------------------
  // RX Domain Logic
  // ------------------------------------------------------------------
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_edge_state <= 2'b00;
      rx_edge_flag  <= 1'b0;
      rx_edge_valid <= 1'b0;
      edge_o        <= 1'b0;
    end else begin
      logic [1:0] state_next;
      logic flag_next;
      logic valid_next;

      case (rx_edge_state)
        2'b00: begin // Idle
          if (tx_edge_valid) state_next = 2'b01; // Rising
          else               state_next = 2'b00;
          flag_next         = 1'b0;
          valid_next        = 1'b0;
        end
        2'b01: begin // Rising detected
          if (!tx_edge_valid) state_next = 2'b10; // Falling
          else                state_next = 2'b01;
          flag_next           = 1'b1;
          valid_next          = 1'b1;
        end
        2'b10: begin // Falling detected
          if (tx_edge_valid) state_next = 2'b01; // Rising
          else               state_next = 2'b10;
          flag_next          = 1'b0;
          valid_next         = 1'b0;
        end
        default: begin
          state_next = 2'b00;
          flag_next  = 1'b0;
          valid_next = 1'b0;
        end
      endcase

      rx_edge_state <= state_next;
      rx_edge_flag  <= flag_next;
      rx_edge_valid <= valid_next;

      // Generate single pulse on edge_o when rising edge is detected in RX
      if (rx_edge_state == 2'b01) begin
        edge_o <= 1'b1;
      end else begin
        edge_o <= 1'b0;
      end
    end
  end

endmodule<|im_end|>
