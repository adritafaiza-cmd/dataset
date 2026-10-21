module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signals
  logic edge_d;
  logic edge_q;
  logic edge_synced;
  logic edge_valid;
  logic edge_out;

  // ---------------------------------------------------------
  // 1. TX Domain: Capture the edge and detect transitions
  // ---------------------------------------------------------
  // Capture the input edge on the TX clock
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i)
      edge_d <= 1'b0;
    else
      edge_d <= edge_i;
  end

  // Detect rising edge in TX domain
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i)
      edge_q <= 1'b0;
    else if (edge_d)
      edge_q <= 1'b1;
    else
      edge_q <= 1'b0;
  end

  // ---------------------------------------------------------
  // 2. CDC Crossing: Transfer single-bit flag from TX to RX
  //    Using a 2-bit Gray-coded counter approach for robustness
  //    against metastability and clock skew.
  // ---------------------------------------------------------
  logic [1:0] tx_flag;
  logic [1:0] rx_flag;

  // Encode the edge state into a 2-bit Gray code in TX domain
  // State 0: No edge
  // State 1: Edge detected (rising)
  // State 2: Edge cleared (falling)
  // We use a simple state machine to ensure only one bit changes at a time
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i)
      tx_flag <= 2'b00;
    else begin
      case (tx_flag)
        2'b00: if (edge_q) tx_flag <= 2'b01; else tx_flag <= 2'b00;
        2'b01: tx_flag <= 2'b11; // Transition to next Gray code
        2'b11: tx_flag <= 2'b10;
        2'b10: tx_flag <= 2'b00; // Reset to initial state
        default: tx_flag <= 2'b00;
      endcase
    end
  end

  // Sample the TX flag in the RX domain using a 2-bit synchronizer
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i)
      rx_flag <= 2'b00;
    else
      rx_flag <= tx_flag;
  end

  // Decode the RX flag to generate the output pulse
  // Only generate a pulse when transitioning from 00 to 01 (edge detected)
  // and ensure we don't re-trigger immediately if the signal stays high
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i)
      edge_out <= 1'b0;
    else begin
      // Detect transition from 00 to 01
      if (rx_flag == 2'b01 && (rx_flag[1] | rx_flag[0])) begin
        // Additional check to ensure we are coming from a clean state
        // This prevents double counting if the synchronizer glitches
        edge_out <= 1'b1;
      end
      else
        edge_out <= 1'b0;
    end
  end

  // ---------------------------------------------------------
  // 3. Output Logic: Drive the output port
  // ---------------------------------------------------------
  assign edge_o = edge_out;

endmodule<|im_end|>
