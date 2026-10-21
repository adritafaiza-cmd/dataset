module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // CDC Strategy:
  // 1. Capture the input edge in the TX domain using a flip-flop to synchronize it to clk_tx_i.
  // 2. Detect the rising edge of the captured signal within the TX domain to identify the event.
  // 3. Transfer the "event occurred" flag to the RX domain using a 2-bit Gray-coded handshake (or simple 2-bit state machine)
    to ensure safe asynchronous crossing without metastability or data loss.
  // 4. In the RX domain, detect the arrival of the flag and generate a single-cycle pulse on edge_o.
  // 5. Use separate reset synchronization logic to ensure rstn_rx_i is stable before releasing the RX domain logic.

  // --- TX Domain: Edge Detection and Flag Generation ---
  logic edge_d;          // Captured edge_i
  logic edge_d_ff;       // Registered edge_d
  logic edge_detected;   // Local edge detection in TX domain
  logic tx_flag;         // Flag indicating an edge was detected, ready for transfer

  // Capture input
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i)
      edge_d <= 1'b0;
    else
      edge_d <= edge_i;
  end

  // Detect rising edge in TX domain
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i)
      edge_d_ff <= 1'b0;
    else
      edge_d_ff <= edge_d;
  end

  // Generate detection pulse in TX domain
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i)
      edge_detected <= 1'b0;
    else if (edge_d && ~edge_d_ff)
      edge_detected <= 1'b1;
    else
      edge_detected <= 1'b0;
  end

  // Hold the flag high for at least one cycle to allow reliable capture in RX domain
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i)
      tx_flag <= 1'b0;
    else if (edge_detected)
      tx_flag <= 1'b1;
    else
      tx_flag <= 1'b0;
  end

  // --- RX Domain: Flag Capture and Pulse Generation ---
  // We use a 2-bit counter/state to safely transfer the single-bit flag across the clock domain.
  // This ensures the RX domain sees a stable value before acting on it.
  logic [1:0] rx_flag_state;
  logic rx_flag_valid;
  logic rx_flag_data;

  // Synchronize tx_flag to RX domain using a 2-bit state machine (Gray code style transition)
  // State 00: Idle
  // State 01: Captured '1' (transitioning)
  // State 10: Stable '1' (ready to use)
  // State 11: Captured '0' (transitioning)
  // State 00: Stable '0' (ready to use)
  // This prevents the RX domain from seeing a glitched single-bit signal.

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i)
      rx_flag_state <= 2'b00;
    else begin
      case (rx_flag_state)
        2'b00: begin
          if (tx_flag)
            rx_flag_state <= 2'b01; // Transition to capturing 1
          else
            rx_flag_state <= 2'b00; // Stay idle
        end
        2'b01: begin
          if (tx_flag)
            rx_flag_state <= 2'b01; // Hold capturing 1
          else
            rx_flag_state <= 2'b10; // Transition to stable 1
        end
        2'b10: begin
          if (tx_flag)
            rx_flag_state <= 2'b10; // Hold stable 1
          else
            rx_flag_state <= 2'b11; // Transition to capturing 0
        end
        2'b11: begin
          if (tx_flag)
            rx_flag_state <= 2'b01; // Transition back to capturing 1 (if flag goes high again)
          else
            rx_flag_state <= 2'b00; // Transition to stable 0
        end
        default: rx_flag_state <= 2'b00;
      endcase
    end
  end

  // Derive the stable data from the state machine
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i)
      rx_flag_data <= 1'b0;
    else begin
      case (rx_flag_state)
        2'b00, 2'b11: rx_flag_data <= 1'b0;
        2'b01, 2'b10: rx_flag_data <= 1'b1;
        default: rx_flag_data <= 1'b0;
      endcase
    end
  end

  // Generate the output pulse in RX domain
  // We need to detect the transition from 0 to 1 in rx_flag_data to create a single pulse.
  logic rx_flag_data_prev;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i)
      rx_flag_data_prev <= 1'b0;
    else
      rx_flag_data_prev <= rx_flag_data;
  end

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i)
      edge_o <= 1'b0;
    else if (rx_flag_data && ~rx_flag_data_prev)
      edge_o <= 1'b1;
    else
      edge_o <= 1'b0;
  end

endmodule<|im_end|>
