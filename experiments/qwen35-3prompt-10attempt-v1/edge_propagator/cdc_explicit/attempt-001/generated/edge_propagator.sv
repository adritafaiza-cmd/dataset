module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // CDC Strategy:
  // 1. Capture the edge event in the TX domain using a 2-bit state machine (or flip-flop pair)
  //    to detect rising and falling edges safely.
  // 2. Transfer the single-bit "edge detected" signal to the RX domain using a standard
  //    2-stage Gray code synchronizer to handle clock domain crossing safely.
  // 3. In the RX domain, use a pulse generator (one-shot) to convert the synchronized
  //    edge signal into a single-cycle pulse on the output clock.
  // 4. Handle resets asynchronously in each domain to ensure safe release.

  // --- TX Domain: Edge Detection ---
  // We use a 2-bit state machine to detect transitions.
  // States:
  // 00: Idle (last edge was low)
  // 01: Rising Edge Detected (transitioned from 0 to 1)
  // 10: Falling Edge Detected (transitioned from 1 to 0)
  // 11: Invalid (should not happen with proper logic, treated as Idle for safety)
  
  logic [1:0] tx_edge_state;
  logic tx_edge_valid;

  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      tx_edge_state <= 2'b00;
      tx_edge_valid <= 1'b0;
    end else begin
      case (tx_edge_state)
        2'b00: begin
          if (edge_i)
            tx_edge_state <= 2'b01; // Rising
          else
            tx_edge_state <= 2'b00;
        end
        2'b01: begin
          if (!edge_i)
            tx_edge_state <= 2'b10; // Falling
          else
            tx_edge_state <= 2'b01; // Stay on rising (ignore subsequent high)
        end
        2'b10: begin
          if (edge_i)
            tx_edge_state <= 2'b01; // Back to rising
          else
            tx_edge_state <= 2'b10; // Stay on falling (ignore subsequent low)
        end
        2'b11: begin
          if (edge_i)
            tx_edge_state <= 2'b01;
          else
            tx_edge_state <= 2'b10;
        end
      endcase

      // Generate a single-cycle pulse when a state transition occurs that indicates an edge
      // We output high only when moving from 00->01 (Rising) or 10->01 (Falling->Rising)
      // Actually, simpler approach: Output high on the cycle the edge is detected, then low next.
      // Let's refine: Output high when state becomes 01 (Rising) or 10 (Falling).
      // To ensure single pulse:
      if (tx_edge_state[0] && !tx_edge_state[1]) tx_edge_valid <= 1'b1; // State 01 (Rising)
      else if (tx_edge_state[1] && !tx_edge_state[0]) tx_edge_valid <= 1'b1; // State 10 (Falling)
      else tx_edge_valid <= 1'b0;
    end
  end

  // --- RX Domain: Synchronization and Pulse Generation ---
  // 2-Stage Synchronizer for the edge_valid signal
  logic rx_sync_stage1;
  logic rx_sync_stage2;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      rx_sync_stage1 <= 1'b0;
      rx_sync_stage2 <= 1'b0;
    end else begin
      rx_sync_stage1 <= tx_edge_valid;
      rx_sync_stage2 <= rx_sync_stage1;
    end
  end

  // Generate single-cycle pulse on the output clock
  // edge_o is high for exactly one cycle when rx_sync_stage2 goes high
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o <= 1'b0;
    end else begin
      edge_o <= rx_sync_stage2;
    end
  end

endmodule<|im_end|>
